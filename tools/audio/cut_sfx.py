"""Cuts SND-01's game sound effects from the raw downloads (tools/audio/sfx_sources/sources.md).

    python -I tools/audio/cut_sfx.py <raw dir> <out dir>        writes every cue, prints the "Game files" table
    python -I tools/audio/cut_sfx.py analyse <file> [gap_s]     lists the onset segments of one source

Decoding goes through ffmpeg (mono, 44.1 kHz, 60 Hz high-pass). Every output is a 16-bit mono WAV: cut at the
onset, tail trimmed below TAIL_DB under its loudest frame, capped, faded out, then set to one loudness per group
(level()): a cue's files play alike and its volume_db alone sets what it plays at (systems/sound-effects, Levels).
"""
import os, re, subprocess, sys, wave

import numpy as np
from scipy.signal import butter, sosfiltfilt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from loudness import momentary_max  # noqa: E402

RATE = 44100
FRAME = 0.005  # s, envelope frame
TAIL_DB = -45.0  # dB under the loudest frame where the tail is cut
FILE_LUFS = -24.0  # every file's loudest momentary loudness, unless its group's peaks cannot reach it
PEAK_CAP_DB = -1.0  # dBFS no file's peak passes
STEP_ATTACK_DB = -14.0  # dB under the peak where a step or landing is cut (its impact)
ATTACK_PREROLL = 0.004  # s kept before the impact, faded in
ATTACK_LEAD = 0.03  # s an attack cut reaches before its slice for the impact's start
HIGH_PASS = butter(2, 60, "highpass", fs=RATE, output="sos")  # handling rumble: half the wood file's energy is under 40 Hz


def decode(path, semitones=0.0):
	"""Mono float at RATE, high-passed; a pitch shift resamples (tape-style, so length grows)."""
	# Resampled to RATE before asetrate, which reads the input as RATE (the Nox files are 48 kHz).
	shift = f",asetrate={RATE}*{2 ** (semitones / 12):.6f},aresample={RATE}" if semitones else ""
	raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-af", f"aresample={RATE}{shift}", "-ar", str(RATE), "-f", "f32le", "-"],
						 capture_output=True, check=True).stdout
	x = np.frombuffer(raw, dtype=np.float32).astype(np.float64)
	return sosfiltfilt(HIGH_PASS, x)  # zero-phase, so the onset stays where it was


def envelope(x):
	n = int(FRAME * RATE)
	k = len(x) // n
	return np.sqrt(np.mean(x[:k * n].reshape(k, n) ** 2, axis=1) + 1e-20)


def db(v):
	return 20 * np.log10(max(v, 1e-12))


def centroid(x):
	"""Spectral centroid in Hz, power-weighted."""
	if len(x) < 64:
		return 0.0
	spec = np.abs(np.fft.rfft(x * np.hanning(len(x))))
	freqs = np.fft.rfftfreq(len(x), 1 / RATE)
	return float(np.sum(freqs * spec ** 2) / (np.sum(spec ** 2) + 1e-20))


def segments(x, gap=0.12, floor_db=-30.0):
	"""(start s, end s) of each burst above floor_db under the loudest frame; bursts closer than gap merge."""
	on = envelope(x) > envelope(x).max() * 10 ** (floor_db / 20)
	out = []
	gap_f = int(gap / FRAME)
	i = 0
	while i < len(on):
		if not on[i]:
			i += 1
			continue
		j = last = i
		while j < len(on) and j - last <= gap_f:
			if on[j]:
				last = j
			j += 1
		out.append((i * FRAME, (last + 1) * FRAME))
		i = j
	return out


def onset_index(x):
	"""First sample above -40 dB under the clip's peak, backed off at most 3 ms to the zero crossing before it."""
	peak = np.max(np.abs(x))
	i = int(np.argmax(np.abs(x) > peak * 10 ** (-40 / 20)))
	j = i
	while j > 0 and np.sign(x[j]) == np.sign(x[j - 1]) and i - j < int(0.003 * RATE):
		j -= 1
	return j


def tail_index(x):
	"""End of the last 5 ms frame above TAIL_DB under the loudest frame."""
	env = envelope(x)
	above = np.nonzero(env > env.max() * 10 ** (TAIL_DB / 20))[0]
	return min(len(x), (above[-1] + 1) * int(FRAME * RATE))


def finish(x, max_len, fade_out=0.02, fade_in=0.0, attack_db=None):
	"""Onset cut, tail trim, length cap, fades, peak at 0 dBFS. attack_db cuts at the first sample that loud under the
	peak instead, ATTACK_PREROLL before it, faded in: a step sounds on its impact, not on the scuff before it (SND-07)."""
	if attack_db is None:
		x = x[onset_index(x):]
	else:
		i = int(np.argmax(np.abs(x) > np.max(np.abs(x)) * 10 ** (attack_db / 20)))
		start = max(0, i - int(ATTACK_PREROLL * RATE))
		x = x[start:].copy()
		ramp = max(i - start, int(ATTACK_PREROLL * RATE))  # a slice that opens inside its impact still fades in
		x[:ramp] *= np.linspace(0, 1, ramp)
	x = x[:tail_index(x)].copy()
	if max_len and len(x) > int(max_len * RATE):
		x = x[:int(max_len * RATE)]
	if fade_in:  # a swell, not an onset
		fi = int(fade_in * RATE)
		x[:fi] *= np.linspace(0, 1, fi)
	elif attack_db is None and abs(x[0]) > 0.03 * np.max(np.abs(x)):  # starts off zero: a 3 ms fade-in avoids the click
		fi = int(0.003 * RATE)
		x[:fi] *= np.linspace(0, 1, fi)
	fo = min(int(fade_out * RATE), len(x) // 2)
	x[-fo:] *= np.linspace(1, 0, fo) ** 2
	return x / np.max(np.abs(x))


def group_of(out):
	"""The cue a file plays in: its name without the _NN of its variant."""
	return re.sub(r"_\d\d$", "", os.path.splitext(out)[0])


def level(rendered):
	"""Gains every file to FILE_LUFS; a group whose loudest-peaked file would pass PEAK_CAP_DB all sit lower together."""
	loud = {out: momentary_max(x, RATE) for out, x in rendered.items()}
	reach = {}
	for out, x in rendered.items():
		room = loud[out] + PEAK_CAP_DB - db(np.max(np.abs(x)))
		reach[group_of(out)] = min(reach.get(group_of(out), FILE_LUFS), room)
	return {out: x * 10 ** ((reach[group_of(out)] - loud[out]) / 20) for out, x in rendered.items()}


def write_wav(path, x):
	os.makedirs(os.path.dirname(path), exist_ok=True)
	pcm = np.clip(np.round(x * 32767), -32768, 32767).astype("<i2")
	with wave.open(path, "wb") as w:
		w.setnchannels(1)
		w.setsampwidth(2)
		w.setframerate(RATE)
		w.writeframes(pcm.tobytes())


def describe(x, a, b):
	s = x[int(a * RATE):int(b * RATE)]
	return f"{a:7.3f}-{b:7.3f}  len {b - a:5.3f}  peak {db(np.max(np.abs(s))):6.1f}  rms {db(np.sqrt(np.mean(s ** 2))):6.1f}  cen {centroid(s):6.0f}"


def analyse(path, gap):
	x = decode(path)
	print(f"{os.path.basename(path)}: {len(x) / RATE:.3f} s, peak {db(np.max(np.abs(x))):.1f}, cen {centroid(x):.0f}")
	for n, (a, b) in enumerate(segments(x, gap)):
		print(f"  {n:2d} {describe(x, a, b)}")


FS = "freesound/"
GRASS = FS + "556042__nox_sound__footsteps_mountain_boots_grass_mono.wav"
MUD = FS + "548384__nox_sound__footsteps_mountain_boots_mud_mono.wav"
ROCK = FS + "558472__nox_sound__footsteps_mountain_boots_rock_walk_sequence_mono.wav"
SNOW = FS + "613849__nox_sound__footsteps_mountain_boots_snow_walk_mono.wav"
WOOD = FS + "543685__nox_sound__footsteps_wood_walk_mono.wav"
WATER = FS + "x_37492__romankolachnik__water-footsteps/"
SWING = FS + "x_27423__joao_janz__swings-and-whooshes/"
GRUNT = FS + "547209__mrfossy__voice_adultmale_paingrunts_09.wav"
FLOUR = FS + "382642__bbrocer__bag-of-flour-dropped-on-counter-top.wav"
BUSH = FS + "764900__joshua_van_zyl__vegemisc-ext.wav"
DOOR = FS + "814857__morenaluz__oldwoodendooropenand.wav"
SPLASH = FS + "390391__n-razm__small_splashes.wav"
RPG = "kenney_rpg_audio/"
UI = "kenney_interface_sounds/Audio/"


class Cue:
	"""One output file: a slice of a source (seconds), its processing, and an optional layer (src, st, gain dB, offset s)."""

	def __init__(self, out, src, a=0.0, b=None, max_len=1.0, fade=0.02, st=0.0, fade_in=0.0, layer=None, lowpass=0, note="", attack_db=None):
		self.out, self.src, self.a, self.b, self.max_len = out, src, a, b, max_len
		self.attack_db = attack_db
		self.fade, self.st, self.fade_in, self.layer, self.lowpass, self.note = fade, st, fade_in, layer, lowpass, note


def walk_picks(path, t0, t1, n):
	"""The n walk segments in [t0, t1) nearest the median RMS, bright outliers dropped; (start, end) each."""
	x = decode(path)
	every = segments(x, 0.08)
	segs = [s for s in every if t0 <= s[0] < t1 and s[1] - s[0] >= 0.04]
	rms = np.array([db(np.sqrt(np.mean(x[int(a * RATE):int(b * RATE)] ** 2))) for a, b in segs])
	cen = np.array([centroid(x[int(a * RATE):int(b * RATE)]) for a, b in segs])
	score = np.abs(rms - np.median(rms)) + np.where(cen > 1.5 * np.median(cen), 100, 0)
	out = []
	for i in sorted(np.argsort(score, kind="stable")[:n]):
		a = segs[i][0]
		nxt = min([s[0] for s in every if s[0] > a + 0.05] + [a + 0.45])
		out.append((round(max(0.0, a - 0.01), 3), round(min(a + 0.45, nxt - 0.01), 3)))
	return out


def cues():
	c = []
	step = dict(max_len=0.35, fade=0.04, attack_db=STEP_ATTACK_DB)
	# Grass: Walk x19 ends at 20.5 s (then Run, Jump & Land, Scrape, Scuff). Mud: Walk x5 ends at 5 s.
	for name, src, t0, t1 in (("earth", GRASS, 0, 20.5), ("stone", ROCK, 0, 19.1), ("snow", SNOW, 0, 11.3)):
		for k, (a, b) in enumerate(walk_picks(RAW + src, t0, t1, 6)):
			c.append(Cue(f"ivo/step_{name}_{k + 1:02d}.wav", src, a, b, **step))
	wood = [(21.19, 21.6), (22.165, 22.6), (23.095, 23.5)]  # Mountain Boots, the file's 7th shoe (steps 19-21)
	for k, (a, b) in enumerate(wood + wood):
		st = (0.0, 0.0, 0.0, -1.0, 1.0, -0.5)[k]
		c.append(Cue(f"ivo/step_wood_{k + 1:02d}.wav", WOOD, a, b, st=st, note=f"{st:+.1f} st" if st else "", **step))
	for k, (a, b) in enumerate(walk_picks(RAW + MUD, 0, 5, 5)):
		c.append(Cue(f"ivo/step_mud_{k + 1:02d}.wav", MUD, a, b, **step))
	for k, f in enumerate(("01", "03", "04", "05", "06", "07")):  # 02 is the brightest (2.9 kHz)
		src = WATER + [n for n in sorted(os.listdir(RAW + WATER)) if n.endswith(f"footsteps_{f}.wav")][0]
		c.append(Cue(f"ivo/step_water_{k + 1:02d}.wav", src, max_len=0.35, fade=0.08, attack_db=STEP_ATTACK_DB))
	land = dict(max_len=0.5, fade=0.06, attack_db=STEP_ATTACK_DB)
	for k, a in enumerate((51.205, 52.46, 57.005, 58.055)):  # grass Jump & Land, the four lowest centroids
		c.append(Cue(f"ivo/land_earth_{k + 1:02d}.wav", GRASS, a - 0.02, a + 0.6, **land))
	for k, a in enumerate((10.9, 12.14, 13.12)):  # mud Land x3
		c.append(Cue(f"ivo/land_mud_{k + 1:02d}.wav", MUD, a - 0.02, a + 0.6, **land))
	c += [
		Cue("ivo/land_hard.wav", GRASS, 51.185, 51.8, max_len=0.6, fade=0.08, layer=(RPG + "dropLeather.ogg", -3.0, -4.0), note="+ dropLeather.ogg -3 st, -4 dB"),
		Cue("ivo/jump.wav", RPG + "cloth3.ogg", max_len=0.4, fade=0.05),
		Cue("ivo/climb_grab.wav", BUSH, 2.12, 2.42, max_len=0.3, fade=0.05, lowpass=5000, note="low-pass 5 kHz"),
		Cue("ivo/climb_step_01.wav", BUSH, 2.42, 2.68, max_len=0.3, fade=0.05, lowpass=5000, note="low-pass 5 kHz"),
		Cue("ivo/climb_step_02.wav", BUSH, 2.68, 2.95, max_len=0.3, fade=0.05, lowpass=5000, note="low-pass 5 kHz"),
		Cue("ivo/swing_01.wav", SWING + "485266__joao_janz__knife-swing-1_4.wav", max_len=0.4, fade=0.06),
		Cue("ivo/swing_02.wav", SWING + "485265__joao_janz__knife-swing-1_5.wav", max_len=0.4, fade=0.06),
		Cue("ivo/swing_03.wav", SWING + "485276__joao_janz__wooden-stick-swing-1_3.wav", max_len=0.4, fade=0.06),
		Cue("ivo/swing_04.wav", SWING + "485278__joao_janz__wooden-stick-swing-1_5.wav", max_len=0.4, fade=0.06),
		Cue("ivo/hurt.wav", GRUNT, fade=0.03),
		Cue("ivo/hurt_low.wav", GRUNT, fade=0.03, st=-3.0, note="-3 st"),
		Cue("ivo/death.wav", FS + "235702__speedygonzo__bodyfall_wood-surface.wav", 1.70, 2.8, fade=0.1),
		Cue("ivo/rest.wav", FS + "454378__kyles__wood-creak-low-sit-down-on-loose-park-bench-and-get-up.flac", 0.70, 1.75, fade=0.1),
		Cue("combat/struck_01.wav", FLOUR, 0.235, 0.6, max_len=0.25, fade=0.05),
		Cue("combat/struck_02.wav", FLOUR, 1.77, 2.1, max_len=0.25, fade=0.05),
		Cue("combat/struck_03.wav", FLOUR, 3.49, 3.9, max_len=0.25, fade=0.05),
		Cue("combat/creature_death.wav", FLOUR, 5.29, 6.2, max_len=0.6, fade=0.1),
		Cue("combat/guardian_struck.wav", RPG + "dropLeather.ogg", max_len=0.4, fade=0.05, st=-3.0, note="-3 st"),
		Cue("world/door_open.wav", DOOR, 3.85, 5.5, fade=0.15),
		Cue("world/door_close.wav", DOOR, 8.95, 10.0, fade=0.05),
		Cue("world/door_open_alt.wav", RPG + "doorOpen_1.ogg", fade=0.05),
		Cue("world/door_close_alt.wav", RPG + "doorClose_4.ogg", fade=0.05),
		Cue("world/door_knock.wav", RPG + "bookPlace1.ogg", max_len=0.6, fade=0.05, layer=(RPG + "bookPlace1.ogg", 0.0, -2.0, 0.2), note="two raps 0.2 s apart, the second -2 dB"),
		Cue("world/pickup.wav", FS + "659909__panpiper5__kalimba.wav", fade=0.3),
		Cue("world/letter.wav", FS + "698199__aurelon__opening-and-closing-a-letter.mp3", 1.65, 2.75, fade=0.08),
		Cue("world/songbook.wav", RPG + "bookOpen.ogg", max_len=0.5, fade=0.03),
		Cue("world/seeds.wav", FS + "531829__reactorfactory__seed-in-envelope-shake.m4a", 0.03, 1.3, fade=0.1),
		Cue("world/splash_small_01.wav", SPLASH, 2.50, 3.3, fade=0.08),
		Cue("world/splash_small_02.wav", SPLASH, 8.22, 9.2, fade=0.08),
		Cue("world/splash_small_03.wav", SPLASH, 15.47, 16.4, fade=0.08),
		Cue("world/splash_large.wav", FS + "280220__yurkobb__jump-into-water-02.flac", 0.2, 1.5, fade=0.25),
		Cue("world/gust.wav", FS + "726319__zipcreates__wind-8.wav", 4.0, 7.0, max_len=3.0, fade=0.8, fade_in=1.6, note="swell 1.6 s, decay 0.8 s"),
		Cue("menu/move.wav", UI + "click_001.ogg", fade=0.01),
		Cue("menu/confirm.wav", UI + "select_002.ogg", fade=0.01),
		Cue("menu/back.wav", UI + "back_002.ogg", fade=0.01),
		Cue("menu/open.wav", RPG + "bookOpen.ogg", fade=0.03),
		Cue("menu/close.wav", RPG + "bookClose.ogg", fade=0.03),
		Cue("menu/page.wav", FS + "484968__spacejoe__quiet-page-turn-8.wav", fade=0.05),
		Cue("menu/notice.wav", FS + "464302__eyesonlegs__paperslide.wav", 0.05, 1.6, fade=0.2),
	]
	return c


def render(cue):
	full = decode(RAW + cue.src, cue.st)
	if cue.lowpass:
		full = sosfiltfilt(butter(4, cue.lowpass, "lowpass", fs=RATE, output="sos"), full)
	k = 2 ** (cue.st / 12)  # a pitch shift stretches source time by 1/k
	# An attack cut looks ATTACK_LEAD earlier, so a slice picked inside the impact still holds its start.
	lead = ATTACK_LEAD if cue.attack_db is not None and cue.a > 0 else 0.0
	a = int(max(0.0, cue.a - lead) / k * RATE)
	b = int(cue.b / k * RATE) if cue.b is not None else len(full)
	x = full[a:b]
	if cue.layer:
		src, st, gain = cue.layer[:3]
		off = int(cue.layer[3] * RATE) if len(cue.layer) > 3 else 0
		y = decode(RAW + src, st)
		y = y[onset_index(y):] * 10 ** (gain / 20) * np.max(np.abs(x)) / np.max(np.abs(y))
		x = x[onset_index(x):]
		mix = np.zeros(max(len(x), off + len(y)))
		mix[:len(x)] += x
		mix[off:off + len(y)] += y
		x = mix
	return finish(x, cue.max_len, cue.fade, cue.fade_in, cue.attack_db)


def main(out_dir):
	print("| File | Source | Slice (s) | Processing | Length (s) | Peak (dBFS) | Loudest (LUFS) |")
	print("|---|---|---|---|---|---|---|")
	every = cues()
	leveled = level({cue.out: render(cue) for cue in every})
	for cue in every:
		x = leveled[cue.out]
		write_wav(os.path.join(out_dir, cue.out), x)
		span = f"{cue.a:.3f}-{cue.b:.3f}" if cue.b is not None else "whole"
		print(f"| `{cue.out}` | `{os.path.basename(cue.src)}` | {span} | {cue.note} | {len(x) / RATE:.3f} | {db(np.max(np.abs(x))):.1f} | {momentary_max(x, RATE):.1f} |")


RAW = ""

if __name__ == "__main__":
	if sys.argv[1] == "analyse":
		analyse(sys.argv[2], float(sys.argv[3]) if len(sys.argv) > 3 else 0.12)
	else:
		RAW = sys.argv[1].rstrip("/\\") + "/"
		main(sys.argv[2])
