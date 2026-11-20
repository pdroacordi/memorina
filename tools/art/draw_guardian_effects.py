"""Draw a guardian's spawned-attack strips (GRD-18; contracts tools/art/prompts/guardian_<name>_effect_*.md).

Usage: python -I tools/art/draw_guardian_effects.py bloom

Each frame is drawn in art px from a character grid and written at 2x, frames side by side, the bottom row the floor
(a pod is centred instead). Colours are the guardian's own (tools/art/sources/guardians/bloom_palette.png, sampled from
its sheets); a dark rim of its darkest brown against its pale wood keeps each readable in the grey and over grass.
Bloom: a thorn spike in four rise stages (16 to 28 game px, so each clears the 16 px grass; full in blossom), a seed pod in four spin frames (one
asymmetric pod turned 90 degrees a frame), a thorn tuft in three rise stages (sprout, half, full).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/sprites/characters/guardians/bloom_guardian/effects"

COLOURS = {
	".": (0, 0, 0, 0),
	"d": (55, 37, 31, 255),  # rim, the darkest brown
	"D": (70, 42, 35, 255),  # dark wood
	"b": (124, 79, 61, 255),  # wood
	"B": (139, 94, 76, 255),  # wood, light
	"p": (190, 144, 121, 255),  # pale wood
	"P": (233, 203, 175, 255),  # pale wood, lit
	"o": (69, 58, 36, 255),  # moss shade
	"g": (81, 99, 53, 255),  # moss
	"G": (132, 134, 84, 255),  # moss, lit
	"k": (213, 120, 163, 255),  # blossom
	"K": (178, 80, 129, 255),  # blossom shade
}

# 6x14 art px a frame; the hit is 20x28 game px at the runner's head, the spikes 8 px apart.
SPIKE_W, SPIKE_H = 6, 14
SPIKE = [
	[
		"..d...",
		"..d...",
		".dPd..",
		".dPd..",
		".dPbd.",
		"dPpbd.",
		"gGgbgg",
		"ogGggo",
	],
	[
		"..d...",
		"..d...",
		"..dd..",
		".dPd..",
		".dPbd.",
		".dPbd.",
		"dPpbd.",
		"dPpbbd",
		"gGgbgg",
		"ogGggo",
	],
	[
		"..d...",
		"..d...",
		"..dd..",
		".dPd..",
		".dPd..",
		".dPbd.",
		".dPbd.",
		"dPpbbd",
		"dPpbbd",
		"dPbbbd",
		"gGgbgg",
		"ogGggo",
	],
	[
		"..k...",
		".kPk..",
		"..Kd..",
		"..dd..",
		".dPd..",
		".dPbd.",
		".dPbd.",
		".dPbbd",
		"dPpbbd",
		"dPpbbd",
		"dPbbbd",
		"dPbbbd",
		"gGgbgg",
		"ogGggo",
	],
]

# 8x8 art px; the pod's hit is 12x12 game px, centred.
POD_W, POD_H = 8, 8
POD = [
	"...kgG..",
	"..ddgd..",
	".dBPBbd.",
	"dBPpBbbd",
	"dBpBBbDd",
	"dBBBbbDd",
	".dbbbDd.",
	"..dddd..",
]

# 8x11 art px; the patch is 48x22 game px, three tufts across.
TUFT_W, TUFT_H = 8, 11
TUFT = [
	[
		"...dd...",
		".gdPdgg.",
		"ogGggGgo",
	],
	[
		"...d....",
		"...dd...",
		"d..dPd.d",
		"dPddPbdd",
		"gdPdPbPg",
		"ogGggGgo",
	],
	[
		"...k....",
		"..kPk...",
		"...Kd...",
		"...dd...",
		"d..dPd..",
		"dd.dPd.d",
		"dPddPbdd",
		".dPdPbPd",
		".dPdPbbd",
		"gGgdpbgg",
		"ogGggGgo",
	],
]


def grid(rows: list[str], width: int, height: int) -> np.ndarray:
	"""A frame from `rows`, bottom-aligned in a `width` x `height` canvas."""
	frame = np.zeros((height, width, 4), np.uint8)
	top = height - len(rows)
	for y, row in enumerate(rows):
		assert len(row) == width, row
		for x, key in enumerate(row):
			frame[top + y, x] = COLOURS[key]
	return frame


def strip(frames: list[np.ndarray]) -> Image.Image:
	art = Image.fromarray(np.concatenate(frames, axis=1), "RGBA")
	return art.resize((art.width * 2, art.height * 2), Image.NEAREST)


def bloom() -> dict[str, Image.Image]:
	pod = grid(POD, POD_W, POD_H)
	return {
		"bloom_thorn_spike.png": strip([grid(rows, SPIKE_W, SPIKE_H) for rows in SPIKE]),
		# A quarter turn a frame, clockwise for a pod thrown east (Lob flips it west).
		"bloom_seed_pod.png": strip([np.rot90(pod, -k).copy() for k in range(4)]),
		"bloom_thorn_tuft.png": strip([grid(rows, TUFT_W, TUFT_H) for rows in TUFT]),
	}


def main(guardian: str) -> None:
	sheets = {"bloom": bloom}[guardian]()
	OUT.mkdir(parents=True, exist_ok=True)
	for name, image in sheets.items():
		image.save(OUT / name)
		print(OUT / name, image.size)


if __name__ == "__main__":
	main(sys.argv[1])
