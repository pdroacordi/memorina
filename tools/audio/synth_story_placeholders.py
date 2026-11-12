"""Synthesize the stand-in sounds of the opening (STORY-03) until the user's recordings replace them.

python -I tools/audio/synth_story_placeholders.py [out_dir] [name ...]
    out_dir defaults to assets/audios/sfx/story; names (file stems) limit what is written. Writes:
    guitar_c.wav, guitar_d.wav, guitar_e.wav, guitar_g.wav  one nylon-string pluck each, an octave under the
        Memorina's C4 D4 E4 G4, so the guitar beat reads the same four note inputs;
    wife_hum_opening.wav  the morning song's first four notes hummed by a woman in one breath (the mentor's flicker);
    daughter_hum_four.wav, daughter_hum_five.wav  the first four (then five) notes hummed by a child: thinner and less
        steady than the woman's, the pitch wandering a little (the lowered guitar, then the return);
    guitar_muted.wav  a string damped under the hand: the press at the gap, which plays nothing;
    memorina_flat.wav  one flat, breathy note on the pipes, a little under pitch: "[Play it again]" in the lighthouse;
    morning_room.wav  (STORY-16) the opening's morning: a soft room tone with faint, far, high chirps;
    gate_bolt.wav  (STORY-16) the village's east gate unbolted, heard from indoors: a wooden bolt sliding, then a clack.
    rope_creak.wav  (STORY-05) the fallen swing's call: a rope creaking on a branch out and back, as if someone swung.
    waterfall_night.wav  (STORY-05) flashback 4's garden at night: a small waterfall into a pool, a seamless 6 s loop
        (written without the room; its import loops it forward).
    The morning song is E G E D | C D E C, beats 1 1 1.5 0.5 1 1 1 2.5 at 0.42 s ("Approve melody (Recommended)",
    user, 2026-10-15). A real recording replaces a file of the same name.
"""
import os
import sys
import wave

import numpy as np
from scipy import signal

SR = 44100
PITCH = {"c": 261.63, "d": 293.66, "e": 329.63, "g": 392.00}
MELODY = ["e", "g", "e", "d", "c", "d", "e", "c"]
BEATS = [1.0, 1.0, 1.5, 0.5, 1.0, 1.0, 1.0, 2.5]
STEP = 0.42


def guitar(f: float, dur: float = 2.2, seed: int = 0) -> np.ndarray:
    """Karplus-Strong with a soft low-passed thumb, plucked away from the bridge, through a wooden body."""
    rng = np.random.default_rng(seed)
    n = int(round(SR / f))
    excitation = signal.lfilter(*signal.butter(2, 1800 / (SR / 2)), rng.uniform(-1, 1, n))
    excitation = excitation - np.roll(excitation, int(n * 0.18))
    length = int(SR * dur)
    y = np.zeros(length)
    y[:n] = excitation
    for i in range(n + 1, length):
        y[i] = 0.4985 * (y[i - n] + y[i - n - 1])
    body = np.zeros_like(y)
    for fc, q, gain in [(105, 4, 0.9), (210, 5, 0.6), (390, 6, 0.35), (2600, 1.2, 0.12)]:
        b, a = signal.iirpeak(fc / (SR / 2), q)
        body += gain * signal.lfilter(b, a, y)
    y = signal.lfilter(*signal.butter(2, 4200 / (SR / 2)), 0.55 * y + body)
    return y * np.minimum(1, np.arange(length) / (0.004 * SR))


def hum(notes: list[str], beats: list[float]) -> np.ndarray:
    """One breath, legato, gliding between notes an octave over the Memorina; a closed-mouth murmur."""
    total = sum(beats) * STEP
    length = int(SR * (total + 0.6))
    t = np.arange(length) / SR
    f = np.zeros(length)
    at, previous = 0.0, None
    for note, beat in zip(notes, beats):
        a, e, target = int(at * SR), int((at + beat * STEP) * SR), PITCH[note] * 2.0
        glide = 0 if previous is None else min(int(0.07 * SR), e - a)
        if glide:
            f[a:a + glide] = np.linspace(previous, target, glide)
        f[a + glide:e] = target
        previous, at = target, at + beat * STEP
    f[int(at * SR):] = previous
    phase = 2 * np.pi * np.cumsum(f * (1 + 0.006 * np.sin(2 * np.pi * 5.0 * t) * np.minimum(1, t / 0.6))) / SR
    source = sum((1.0 / k ** 1.6) * np.sin(k * phase) for k in range(1, 14))
    y = np.zeros(length)
    for fc, q, gain in [(f.mean(), 2.0, 1.0), (300, 3, 0.8), (2500, 6, 0.08)]:
        b, a = signal.iirpeak(min(fc, SR / 2 - 100) / (SR / 2), q)
        y += gain * signal.lfilter(b, a, source)
    y = signal.lfilter(*signal.butter(2, 1500 / (SR / 2)), y)
    breath = signal.lfilter(*signal.butter(2, [300 / (SR / 2), 3000 / (SR / 2)], btype="band"),
        np.random.default_rng(3).normal(0, 1, length)) * 0.02
    swell = np.ones(length)
    at = 0.0
    for beat in beats:
        a, e = int(at * SR), int((at + beat * STEP) * SR)
        swell[a:e] = 0.8 + 0.2 * np.sin(np.pi * np.arange(e - a) / max(1, e - a))
        at += beat * STEP
    envelope = np.minimum(1, t / 0.25) * np.clip((total + 0.4 - t) / 0.5, 0, 1)
    return (y + breath) * envelope * swell


def child_hum(notes: list[str], beats: list[float], seed: int) -> np.ndarray:
    """A child's murmur an octave over the Memorina: fewer partials, a faster and wider wobble, a slow drift."""
    total = sum(beats) * STEP
    length = int(SR * (total + 0.5))
    t = np.arange(length) / SR
    rng = np.random.default_rng(seed)
    f = np.zeros(length)
    at = 0.0
    for note, beat in zip(notes, beats):
        a, e = int(at * SR), int((at + beat * STEP) * SR)
        f[a:e] = PITCH[note] * 2.0 * (1 + rng.uniform(-0.012, 0.012))
        at += beat * STEP
    f[int(at * SR):] = f[int(at * SR) - 1]
    f = signal.lfilter(*signal.butter(1, 18 / (SR / 2)), f)
    drift = 1 + 0.01 * np.sin(2 * np.pi * 0.7 * t + rng.uniform(0, 6))
    wobble = 1 + 0.012 * np.sin(2 * np.pi * 6.5 * t) * np.minimum(1, t / 0.3)
    phase = 2 * np.pi * np.cumsum(f * drift * wobble) / SR
    source = sum((1.0 / k ** 2.2) * np.sin(k * phase) for k in range(1, 7))
    y = signal.lfilter(*signal.butter(2, 2200 / (SR / 2)), source)
    breath = signal.lfilter(*signal.butter(2, [600 / (SR / 2), 5000 / (SR / 2)], btype="band"),
        rng.normal(0, 1, length)) * 0.035
    swell = np.ones(length)
    at = 0.0
    for beat in beats:
        a, e = int(at * SR), int((at + beat * STEP) * SR)
        swell[a:e] = 0.7 + 0.3 * np.sin(np.pi * np.arange(e - a) / max(1, e - a))
        at += beat * STEP
    envelope = np.minimum(1, t / 0.15) * np.clip((total + 0.3 - t) / 0.35, 0, 1)
    return (y + breath) * envelope * swell


def muted_string(f: float) -> np.ndarray:
    """A pluck damped at once by the palm: a short dull knock with the string's pitch barely in it."""
    rng = np.random.default_rng(9)
    n = int(round(SR / f))
    length = int(SR * 0.35)
    y = np.zeros(length)
    y[:n] = signal.lfilter(*signal.butter(2, 700 / (SR / 2)), rng.uniform(-1, 1, n))
    for i in range(n + 1, length):
        y[i] = 0.47 * (y[i - n] + y[i - n - 1])
    knock = signal.lfilter(*signal.butter(2, 250 / (SR / 2)), rng.normal(0, 1, length)) * np.exp(-np.arange(length) / (0.02 * SR))
    y = signal.lfilter(*signal.butter(2, 1200 / (SR / 2)), 0.6 * y + 0.8 * knock)
    return y * np.exp(-np.arange(length) / (0.06 * SR))


def flat_pipe(f: float) -> np.ndarray:
    """One breathy pipe note a quarter-tone under pitch, sagging as the breath runs out."""
    length = int(SR * 1.3)
    t = np.arange(length) / SR
    sag = f * 2 ** (-0.5 / 12) * (1 - 0.01 * np.minimum(1, t / 1.2))
    phase = 2 * np.pi * np.cumsum(sag) / SR
    tone = np.sin(phase) + 0.15 * np.sin(2 * phase) + 0.05 * np.sin(3 * phase)
    breath = signal.lfilter(*signal.butter(2, [800 / (SR / 2), 6000 / (SR / 2)], btype="band"),
        np.random.default_rng(11).normal(0, 1, length)) * 0.25
    envelope = np.minimum(1, t / 0.08) * np.clip((1.25 - t) / 0.6, 0, 1)
    return (0.6 * tone + breath) * envelope


def morning_room(dur: float = 7.0) -> np.ndarray:
    """A still house in the morning: low brown room tone, and a few far birds, short high chirps falling in pitch."""
    rng = np.random.default_rng(21)
    length = int(SR * dur)
    t = np.arange(length) / SR
    tone = signal.lfilter(*signal.butter(2, 220 / (SR / 2)), np.cumsum(rng.normal(0, 1, length)))
    tone = (tone - signal.lfilter(*signal.butter(1, 20 / (SR / 2)), tone)) * 0.004
    chirps = np.zeros(length)
    for at in [0.6, 0.78, 2.1, 2.25, 2.4, 3.9, 5.2, 5.35, 6.1]:
        n = int(SR * rng.uniform(0.05, 0.09))
        start = int(SR * at)
        f0 = rng.uniform(3600, 4600)
        f = np.linspace(f0, f0 * 0.82, n)
        chirp = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * np.arange(n) / n) ** 2
        chirps[start:start + n] += 0.18 * chirp[:max(0, min(n, length - start))]
    chirps = signal.lfilter(*signal.butter(2, 7000 / (SR / 2)), chirps)
    envelope = np.minimum(1, t / 1.0) * np.clip((dur - t) / 1.2, 0, 1)
    return (tone + chirps) * envelope


def gate_bolt() -> np.ndarray:
    """A heavy wooden bolt drawn back, far off: a scraping slide, then the clack of it stopping."""
    rng = np.random.default_rng(23)
    length = int(SR * 0.9)
    t = np.arange(length) / SR
    slide_n = int(SR * 0.35)
    slide = signal.lfilter(*signal.butter(2, [500 / (SR / 2), 2400 / (SR / 2)], btype="band"), rng.normal(0, 1, slide_n))
    slide *= np.sin(np.pi * np.arange(slide_n) / slide_n) * 0.35
    clack_at = int(SR * 0.38)
    clack_n = length - clack_at
    clack = signal.lfilter(*signal.butter(2, [180 / (SR / 2), 1300 / (SR / 2)], btype="band"), rng.normal(0, 1, clack_n))
    for fc, q in [(240, 8), (610, 9)]:
        clack += 0.6 * signal.lfilter(*signal.iirpeak(fc / (SR / 2), q), clack)
    clack *= np.exp(-np.arange(clack_n) / (0.035 * SR))
    y = np.zeros(length)
    y[:slide_n] += slide
    y[clack_at:] += clack
    return signal.lfilter(*signal.butter(2, 3000 / (SR / 2)), y) * np.minimum(1, t / 0.01)


def rope_creak() -> np.ndarray:
    """Rope rubbing on bark, out and back: two stick-slip trains of clicks through woody resonances, 1.2 s apart."""
    rng = np.random.default_rng(31)
    length = int(SR * 2.0)
    y = np.zeros(length)
    for start, dur, rate in [(0.0, 0.5, (55, 95)), (1.2, 0.42, (70, 45))]:
        at = start
        end = start + dur
        while at < end:
            u = (at - start) / dur
            k = int(at * SR)
            if k < length:
                y[k] += np.sin(np.pi * u) * rng.uniform(0.6, 1.0)
            at += 1.0 / (rate[0] + (rate[1] - rate[0]) * u) * rng.uniform(0.85, 1.15)
    body = np.zeros_like(y)
    for fc in (330, 380, 820, 940, 1700):
        body += signal.lfilter(*signal.iirpeak(fc / (SR / 2), 14), y)
    body += 0.3 * signal.lfilter(*signal.butter(2, [900 / (SR / 2), 3200 / (SR / 2)], btype="band"), y)
    return signal.lfilter(*signal.butter(2, 4000 / (SR / 2)), body)


def waterfall_night(dur: float = 6.0) -> np.ndarray:
    """Falling water: band-passed noise with a slow swell and soft low splashes, its tail cross-faded into its head."""
    rng = np.random.default_rng(41)
    fade = int(SR * 0.5)
    length = int(SR * dur) + fade
    t = np.arange(length) / SR
    rush = signal.lfilter(*signal.butter(2, [350 / (SR / 2), 2600 / (SR / 2)], btype="band"), rng.normal(0, 1, length))
    hiss = signal.lfilter(*signal.butter(2, 5200 / (SR / 2), btype="high"), rng.normal(0, 1, length)) * 0.08
    low = signal.lfilter(*signal.butter(2, 260 / (SR / 2)), rng.normal(0, 1, length)) * 2.5
    swell = 1.0 + 0.12 * np.sin(2 * np.pi * t / dur) + 0.06 * np.sin(2 * np.pi * 3 * t / dur)
    y = (rush + hiss + low) * swell
    head, tail = y[:fade], y[-fade:]
    ramp = np.linspace(0, 1, fade)
    y = y[:-fade].copy()
    y[:fade] = head * ramp + tail * (1 - ramp)
    return y


def write_loop(path: str, sound: np.ndarray) -> None:
    """Normalized, 16-bit mono, with no room tail, so the last sample runs into the first."""
    sound = sound / np.max(np.abs(sound)) * 0.6
    with wave.open(path, "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(SR)
        file.writeframes((sound * 32767).astype(np.int16).tobytes())
    print(path)


def write(path: str, sound: np.ndarray) -> None:
    """Normalized, through a small room, 16-bit mono."""
    sound = sound / np.max(np.abs(sound))
    room = np.zeros(len(sound) + int(0.3 * SR))
    room[:len(sound)] += sound
    for delay, gain in [(0.031, 0.25), (0.047, 0.2), (0.073, 0.15), (0.11, 0.1), (0.17, 0.06)]:
        k = int(delay * SR)
        room[k:k + len(sound)] += gain * sound
    room = room / np.max(np.abs(room)) * 0.8
    with wave.open(path, "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(SR)
        file.writeframes((room * 32767).astype(np.int16).tobytes())
    print(path)


def main(out_dir: str, names: list[str]) -> None:
    os.makedirs(out_dir, exist_ok=True)
    sounds = {"guitar_%s" % note: (lambda n=note, i=i: guitar(PITCH[n] / 2, seed=i)) for i, note in enumerate(PITCH)}
    sounds.update({
        "wife_hum_opening": lambda: hum(MELODY[:4], BEATS[:4]),
        "daughter_hum_four": lambda: child_hum(MELODY[:4], BEATS[:4], seed=4),
        "daughter_hum_five": lambda: child_hum(MELODY[:5], BEATS[:5], seed=5),
        "guitar_muted": lambda: muted_string(PITCH["c"] / 2),
        "memorina_flat": lambda: flat_pipe(PITCH["e"]),
        "morning_room": morning_room,
        "gate_bolt": gate_bolt,
        "rope_creak": rope_creak,
        "waterfall_night": waterfall_night,
    })
    loops = {"waterfall_night"}
    for name, make in sounds.items():
        if not names or name in names:
            (write_loop if name in loops else write)(os.path.join(out_dir, name + ".wav"), make())


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/audios/sfx/story", sys.argv[2:])
