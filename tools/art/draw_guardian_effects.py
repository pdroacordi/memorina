"""Draw a guardian's spawned-attack strips (GRD-18; contracts tools/art/prompts/guardian_<name>_effect_*.md).

Usage: python -I tools/art/draw_guardian_effects.py <bloom|frost>

Each frame is drawn in art px from a character grid and written at 2x, frames side by side, the bottom row the floor
(a pod is centred instead). Colours are the guardian's own (tools/art/sources/guardians/bloom_palette.png, sampled from
its sheets); a dark rim of its darkest brown against its pale wood keeps each readable in the grey and over grass.
Bloom: a thorn spike in four rise stages (16 to 28 game px, so each clears the 16 px grass; full in blossom), a seed pod in four spin frames (one
asymmetric pod turned 90 degrees a frame), a thorn tuft in three rise stages (sprout, half, full).
Frost (tools/art/sources/guardians/frost_still.png: blue-grey stone, pale blue ice): an ice shard for the slam's wave in
three rise stages (16, 20, 24 px) and one for the body drop's shock (16, 18, 20 px), each on a stone base; an icicle
hanging (forming small, forming, whole, whole with a glint beside its top; drawn top-aligned so it grows down from where
it hangs); the icicle bursting on the floor in two stages (10 and 18 px).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
GUARDIANS = ROOT / "assets/sprites/characters/guardians"

BLOOM_COLOURS = {
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


FROST_COLOURS = {
	".": (0, 0, 0, 0),
	"d": (38, 43, 73, 255),  # rim, the darkest stone
	"s": (50, 56, 94, 255),  # stone
	"S": (85, 95, 139, 255),  # stone, lit
	"D": (76, 160, 246, 255),  # ice, deep
	"M": (120, 190, 242, 255),  # ice
	"L": (136, 213, 251, 255),  # ice, light
	"W": (208, 239, 252, 255),  # ice, white
}

# 6 art px wide; a runner plants one every frame width (12 px). The slam's wave is 24 px tall, the shock 20.
SHARD_W, WAVE_H, SHOCK_H = 6, 12, 10
WAVE = [
	[
		"..d...",
		".dWd..",
		".dWMd.",
		"dWLMd.",
		"dWLMDd",
		"dLLMDd",
		"sSsdsS",
		"dsSssd",
	],
	[
		"..d...",
		".dWd..",
		".dWd..",
		".dWMd.",
		"dWLMd.",
		"dWLMDd",
		"dWLMDd",
		"dLLMDd",
		"sSsdsS",
		"dsSssd",
	],
	[
		"..d...",
		".dWd..",
		".dWd..",
		".dWMd.",
		".dWMd.",
		"dWLMd.",
		"dWLMDd",
		"dWLMDd",
		"dWLMDd",
		"dLLMDd",
		"sSsdsS",
		"dsSssd",
	],
]
# Two shards splayed apart, so the shock reads apart from the wave.
SHOCK = [
	[
		"d....d",
		"Wd..dL",
		"dWddMd",
		"dWLMDd",
		"dWLMDd",
		"dLLMDd",
		"sSsdsS",
		"dsSssd",
	],
	[
		"d.....",
		"Wd...d",
		"dWd.dL",
		"dWddMd",
		"dWLMDd",
		"dWLMDd",
		"dLLMDd",
		"sSsdsS",
		"dsSssd",
	],
	[
		"d.....",
		"Wd....",
		"dWd..d",
		"dWd.dL",
		"dWddMd",
		"dWLMDd",
		"dWLMDd",
		"dLLMDd",
		"sSsdsS",
		"dsSssd",
	],
]

# 8x14 art px, hanging: its body is the 6x12 art px hit (12x24 game px) under two rows where the glint sparkles.
ICICLE_W, ICICLE_H = 8, 14
_ICICLE_WHOLE = [
	"........",
	"........",
	".dsSSsd.",
	".dWLMDd.",
	".dWLMDd.",
	"..dWMDd.",
	"..dWMd..",
	"..dWMd..",
	"..dLDd..",
	"...dLd..",
	"...dLd..",
	"...dWd..",
	"....d...",
	"....d...",
]
ICICLE = [
	_ICICLE_WHOLE[:5],
	_ICICLE_WHOLE[:9],
	_ICICLE_WHOLE,
	[
		"......W.",
		".....WWW",
		".dsSssdW",
	] + _ICICLE_WHOLE[3:],
]
# 10x9 art px on the floor: the icicle bursting where it struck, then sinking.
SHATTER_W, SHATTER_H = 10, 9
SHATTER = [
	[
		"..d...d...",
		"..dWd.dL..",
		"...dWLMd..",
		"..dsSsdsd.",
		".dsSsdsSd.",
	],
	[
		"....d.....",
		"d...Wd..d.",
		"Wd..Wd.dL.",
		"dWd.dWddM.",
		".dWdLWdMd.",
		"..dWLMDd..",
		"..dWLLDd..",
		".dsSsdsSd.",
		"dsSssdsSsd",
	],
]


def grid(rows: list[str], width: int, height: int, colours: dict = BLOOM_COLOURS, hang: bool = False) -> np.ndarray:
	"""A frame from `rows`, bottom-aligned in a `width` x `height` canvas (top-aligned when it `hang`s)."""
	frame = np.zeros((height, width, 4), np.uint8)
	top = 0 if hang else height - len(rows)
	for y, row in enumerate(rows):
		assert len(row) == width, row
		for x, key in enumerate(row):
			frame[top + y, x] = colours[key]
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


def frost() -> dict[str, Image.Image]:
	c = FROST_COLOURS
	return {
		"frost_ice_wave.png": strip([grid(rows, SHARD_W, WAVE_H, c) for rows in WAVE]),
		"frost_ice_shock.png": strip([grid(rows, SHARD_W, SHOCK_H, c) for rows in SHOCK]),
		"frost_icicle.png": strip([grid(rows, ICICLE_W, ICICLE_H, c, hang=True) for rows in ICICLE]),
		"frost_icicle_shatter.png": strip([grid(rows, SHATTER_W, SHATTER_H, c) for rows in SHATTER]),
	}


def main(guardian: str) -> None:
	sheets = {"bloom": bloom, "frost": frost}[guardian]()
	out = GUARDIANS / f"{guardian}_guardian" / "effects"
	out.mkdir(parents=True, exist_ok=True)
	for name, image in sheets.items():
		image.save(out / name)
		print(out / name, image.size)


if __name__ == "__main__":
	main(sys.argv[1])
