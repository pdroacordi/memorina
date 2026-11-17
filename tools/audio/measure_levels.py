"""Measures what every SoundCue, MusicCue and Song plays at, after its own trim (systems/sound-effects, Levels).

A sound effect is read by its loudest momentary loudness (EBU R128 M, 400 ms window), which suits a short hit; music
and a song's track or excerpt by integrated loudness (I) over the whole file. Both are LUFS of the file plus the
resource's trim. Run from the project root:

    python tools/audio/measure_levels.py [--json out.json]   reports every level, loudest first
    python tools/audio/measure_levels.py --apply             also writes each SoundCue's volume_db from SFX_TARGETS
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SFX_CUES = ROOT / "resources" / "audio" / "sfx"
MUSIC_CUES = ROOT / "resources" / "music"
SONGS = ROOT / "resources" / "songs"
# ebur128 needs a full 400 ms window; a short hit is padded with silence so it still gets one.
PAD_SECONDS = 0.5
# No music cue, track or excerpt plays above this, LUFS integrated.
MUSIC_CEILING = -22.0

# What each SoundCue plays at, its loudest moment in LUFS before bus volume, spatial falloff or ImpactLevel. Tiers:
# a step under everything, a body sound, a menu click, a world event, a hit. Nothing passes -23 (user, 2026-11-17:
# "uma normalização em músicas e sfx para nenhum ser muito alto").
SFX_TARGETS = {
	"ivo/step_earth": -37.0, "ivo/step_snow": -37.0, "ivo/step_stone": -37.0, "ivo/step_water": -37.0,
	"ivo/step_wood": -37.0, "ivo/climb_step": -35.0,
	"ivo/land_earth": -32.0, "ivo/land_snow": -32.0, "ivo/land_stone": -32.0, "ivo/land_water": -32.0,
	"ivo/land_wood": -32.0, "ivo/jump": -31.0, "ivo/double_jump": -31.0, "ivo/climb_grab": -31.0,
	"ivo/swing": -29.0, "ivo/rest": -29.0, "ivo/land_hard": -25.0, "ivo/hurt": -23.0, "ivo/death": -24.0,
	"combat/struck": -26.0, "combat/blocked": -28.0, "combat/creature_death": -26.0, "combat/guardian_struck": -24.0,
	"world/door_open": -27.0, "world/door_close": -27.0, "world/door_open_alt": -27.0, "world/door_close_alt": -27.0,
	"world/door_knock": -27.0, "world/pickup": -26.0, "world/letter": -28.0, "world/seeds": -28.0,
	"world/songbook": -28.0, "world/splash_small": -29.0, "world/splash_large": -25.0,
	"menu/move": -40.0, "menu/confirm": -33.0, "menu/back": -33.0, "menu/open": -31.0, "menu/close": -31.0,
	"menu/page": -31.0, "menu/notice": -29.0,
}

_M_LINE = re.compile(r"\bM:\s*(-?[\d.]+|-inf)")
_I_SUMMARY = re.compile(r"I:\s*(-?[\d.]+|-inf)\s*LUFS")
_VOLUME = re.compile(r"^volume_db = .*$", re.M)


def res_path(res: str) -> Path:
	return ROOT / res.removeprefix("res://")


def ebur128(*paths: Path) -> tuple[float, float]:
	"""Returns (loudest momentary, integrated) LUFS of one file, or of several summed as they play together."""
	inputs = [arg for path in paths for arg in ("-i", str(path))]
	mix = f"amix=inputs={len(paths)}:normalize=0:duration=longest," if len(paths) > 1 else ""
	cmd = [
		"ffmpeg", "-nostats", "-hide_banner", "-v", "verbose", *inputs,
		"-filter_complex", f"{mix}apad=pad_dur={PAD_SECONDS},ebur128=framelog=verbose", "-f", "null", "-",
	]
	out = subprocess.run(cmd, capture_output=True, text=True, errors="replace").stderr
	moments = [float(v) for v in _M_LINE.findall(out) if v != "-inf"]
	summary = _I_SUMMARY.findall(out)
	integrated = float(summary[-1]) if summary and summary[-1] != "-inf" else float("-inf")
	return (max(moments) if moments else float("-inf"), integrated)


def streams_of(tres: str) -> list[str]:
	return re.findall(r'type="AudioStream" (?:uid="[^"]*" )?path="([^"]+)"', tres)


def number(tres: str, key: str) -> float:
	found = re.search(rf"^{key} = (-?[\d.]+)", tres, re.M)
	return float(found.group(1)) if found else 0.0


def with_volume(tres: str, volume: float) -> str:
	"""The cue's text with volume_db set; Godot omits a 0 default, so the line is added after `stream =`."""
	line = f"volume_db = {volume:g}"
	if _VOLUME.search(tres):
		return _VOLUME.sub(line, tres)
	return re.sub(r"^(stream = .*)$", rf"\1\n{line}", tres, count=1, flags=re.M)


def sfx_rows(apply: bool) -> list[dict]:
	rows = []
	for cue in sorted(SFX_CUES.rglob("*.tres")):
		tres = cue.read_text(encoding="utf-8")
		if "script_class=\"SoundCue\"" not in tres:
			continue
		files = streams_of(tres)
		if not files:
			continue
		levels = [ebur128(res_path(f))[0] for f in files]
		file_lufs = sum(levels) / len(levels)
		name = cue.relative_to(SFX_CUES).with_suffix("").as_posix()
		volume = number(tres, "volume_db")
		if apply and name in SFX_TARGETS:
			# Half-dB steps, never a boost: a group the peak cap held low plays as loud as it can.
			volume = min(0.0, round((SFX_TARGETS[name] - file_lufs) * 2) / 2)
			cue.write_text(with_volume(tres, volume), encoding="utf-8", newline="\n")
		rows.append({
			"cue": name,
			"files": len(files),
			"file_m": round(file_lufs, 1),
			"spread": round(max(levels) - min(levels), 1),
			"volume_db": volume,
			"plays_at": round(file_lufs + volume, 1),
			"target": SFX_TARGETS.get(name),
		})
	return rows


def music_rows() -> list[dict]:
	rows = []
	for cue in sorted(MUSIC_CUES.glob("*.tres")):
		tres = cue.read_text(encoding="utf-8")
		files = streams_of(tres)
		if not files:
			continue
		# A stemmed cue is measured with every stem up, its loudest mix.
		integrated = ebur128(*[res_path(f) for f in files])[1]
		gain = number(tres, "gain_db")
		rows.append({"cue": cue.stem, "file_i": round(integrated, 1), "gain_db": gain,
					 "plays_at": round(integrated + gain, 1)})
	return rows


def song_rows() -> list[dict]:
	rows = []
	for song in sorted(SONGS.glob("*.tres")):
		tres = song.read_text(encoding="utf-8")
		for field in ("track", "excerpt"):
			found = re.search(rf'^{field} = ExtResource\("([^"]+)"\)', tres, re.M)
			if not found:
				continue
			path = re.search(rf'path="([^"]+)" id="{re.escape(found.group(1))}"', tres)
			integrated = ebur128(res_path(path.group(1)))[1]
			gain = number(tres, f"{field}_gain_db")
			rows.append({"cue": f"{song.stem}.{field}", "file_i": round(integrated, 1), "gain_db": gain,
						 "plays_at": round(integrated + gain, 1)})
	return rows


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("--json")
	parser.add_argument("--apply", action="store_true")
	args = parser.parse_args()
	report = {"sfx": sfx_rows(args.apply), "music": music_rows(), "songs": song_rows()}
	for row in sorted(report["sfx"], key=lambda r: -r["plays_at"]):
		target = f"target {row['target']:5.1f}" if row["target"] is not None else "no target"
		print(f"{row['plays_at']:7.1f}  M {row['file_m']:6.1f} {row['volume_db']:+5.1f}  spread {row['spread']:4.1f}  {target}  {row['cue']}")
	for kind in ("music", "songs"):
		print()
		for row in sorted(report[kind], key=lambda r: -r["plays_at"]):
			over = "  OVER" if row["plays_at"] > MUSIC_CEILING else ""
			print(f"{row['plays_at']:7.1f}  I {row['file_i']:6.1f} {row['gain_db']:+5.1f}  {row['cue']}{over}")
	if args.json:
		Path(args.json).write_text(json.dumps(report, indent="\t"), encoding="utf-8")
	return 0


if __name__ == "__main__":
	sys.exit(main())
