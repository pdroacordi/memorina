"""Draw a guardian's spawned-attack strips (GRD-18; contracts tools/art/prompts/guardian_<name>_effect_*.md).

Usage: python -I tools/art/draw_guardian_effects.py <bloom|frost|autumn|summer>

Each frame is drawn in art px from a character grid and written at 2x, frames side by side, the bottom row the floor
(a pod is centred instead). Colours are the guardian's own (tools/art/sources/guardians/bloom_palette.png, sampled from
its sheets); a dark rim of its darkest brown against its pale wood keeps each readable in the grey and over grass.
Bloom: a thorn spike in four rise stages (16 to 28 game px, so each clears the 16 px grass; full in blossom), a seed pod in four spin frames (one
asymmetric pod turned 90 degrees a frame), a thorn tuft in three rise stages (sprout, half, full).
Frost (tools/art/sources/guardians/frost_still.png: blue-grey stone, pale blue ice): an ice shard for the slam's wave in
three rise stages (16, 20, 24 px) and one for the body drop's shock (16, 18, 20 px), each on a stone base; an icicle
hanging (forming small, forming, whole, whole with a glint beside its top; drawn top-aligned so it grows down from where
it hangs); the icicle bursting on the floor in two stages (10 and 18 px).
Autumn (tools/art/sources/guardians/scarecrow_still.png: rust, amber, pale bone): a leaf blade in four spin frames (one
diagonal leaf turned 90 degrees a frame) and the swirl's leaf, flat and edge-on.
Summer (tools/art/sources/guardians/sun_lion_still.png: charcoal stone, orange, gold): an ember in four spin frames, its
patch and the pounce's running embers each in three rise stages (each 16 px or more, over the grass). Flames are
tongues of given heights (`flames`), orange at the edge, gold to pale at the root.
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


AUTUMN_COLOURS = {
	".": (0, 0, 0, 0),
	"d": (75, 32, 24, 255),  # rim, the darkest rust
	"r": (151, 65, 48, 255),  # rust midrib
	"L": (229, 122, 60, 255),  # amber leaf
	"l": (240, 156, 86, 255),  # amber, lit
	"P": (242, 218, 183, 255),  # pale bone, the lit edge
}

# 10x10 art px, square so a quarter turn keeps the frame; the blade's hit is 16x12 game px at its centre.
BLADE_W = 10
BLADE = [
	".......dd.",
	"......dPld",
	".....dPlLd",
	"....dPlrLd",
	"...dPlrLd.",
	"..dPlrLLd.",
	".dllrLLd..",
	".dLrLLd...",
	".drddd....",
	"dd........",
]
# 4x3 art px: flat, then edge-on as it turns.
SWIRL_W, SWIRL_H = 4, 3
SWIRL = [
	[
		".dd.",
		"dlLd",
		".dd.",
	],
	[
		"dd..",
		"dlLd",
		"..dd",
	],
]

SUMMER_COLOURS = {
	".": (0, 0, 0, 0),
	"d": (51, 39, 40, 255),  # rim, the darkest stone
	"c": (90, 66, 64, 255),  # cinder stone
	"o": (188, 105, 60, 255),  # ember, dark orange
	"O": (245, 161, 78, 255),  # orange
	"Y": (249, 186, 93, 255),  # gold
	"W": (251, 209, 128, 255),  # pale gold, the hottest
}

# 8x8 art px; the ember's hit is 12x12 game px at its centre.
EMBER_W = 8
EMBER = [
	"..dd....",
	".dOOdd..",
	"dOYYOOd.",
	"dOYWYOd.",
	"dOOYYOcd",
	".dOOOccd",
	"..dccdd.",
	"...dd...",
]
# The patch is 24x9 art px (48x18 game px), the runner 12x9: tongues of fire, each (centre column, height in rows),
# over a 2-row cinder bed; every stage's tallest tongue reaches the top, so it stands 16 px or more over the grass.
PATCH_W, PATCH_H = 24, 9
PATCH = [
	[(4, 2), (9, 7), (14, 2), (19, 4)],
	[(3, 4), (8, 7), (13, 5), (18, 7), (21, 3)],
	[(2, 6), (6, 7), (10, 5), (13, 7), (17, 6), (21, 7)],
]
BURST_W, BURST_H = 12, 9
BURST = [
	[(5, 7), (9, 2)],
	[(3, 3), (6, 7), (9, 4)],
	[(2, 5), (6, 6), (9, 7)],
]
_HEAT = ".do OYW"


def flames(tongues: list[tuple[int, int]], width: int, height: int) -> list[str]:
	"""Rows for tongues of fire over a 2-row cinder bed: each tongue widens from its tip, orange at the edge and gold to
	pale at its root's centre, the hotter colour kept where two meet; a dark rim closes every flame against the grey."""
	rows = [["."] * width for _ in range(height)]
	for x in range(width):
		rows[height - 1][x] = "d" if x % 3 == 0 else "c"
		rows[height - 2][x] = "Y" if x % 4 == 1 else "o"
	for centre, h in tongues:
		top = height - 2 - h
		for depth in range(h):
			half = 0 if depth < 2 else 1 if depth < 4 else 2
			for dx in range(-half, half + 1):
				x = centre + dx
				if not 0 <= x < width:
					continue
				edge = half > 0 and abs(dx) == half
				key = "o" if edge or depth == 0 else "W" if depth >= h - 2 and dx == 0 else "Y" if dx == 0 and depth >= h // 2 else "O"
				y = top + depth
				if _HEAT.index(key) > _HEAT.index(rows[y][x]):
					rows[y][x] = key
	for y in range(height - 2):
		for x in range(width):
			if rows[y][x] != ".":
				continue
			near = [rows[y + dy][x + dx] for dx, dy in ((1, 0), (-1, 0), (0, 1)) if 0 <= x + dx < width and y + dy < height - 2]
			if any(n not in ".d" for n in near):
				rows[y][x] = "d"
	return ["".join(row) for row in rows]


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


def autumn() -> dict[str, Image.Image]:
	c = AUTUMN_COLOURS
	blade = grid(BLADE, BLADE_W, BLADE_W, c)
	return {
		# A quarter turn a frame, clockwise for a blade thrown east (Boomerang flips it west).
		"autumn_leaf_blade.png": strip([np.rot90(blade, -k).copy() for k in range(4)]),
		"autumn_swirl_leaf.png": strip([grid(rows, SWIRL_W, SWIRL_H, c) for rows in SWIRL]),
	}


def summer() -> dict[str, Image.Image]:
	c = SUMMER_COLOURS
	ember = grid(EMBER, EMBER_W, EMBER_W, c)
	return {
		"summer_ember.png": strip([np.rot90(ember, -k).copy() for k in range(4)]),
		"summer_ember_patch.png": strip([grid(flames(t, PATCH_W, PATCH_H), PATCH_W, PATCH_H, c) for t in PATCH]),
		"summer_ember_burst.png": strip([grid(flames(t, BURST_W, BURST_H), BURST_W, BURST_H, c) for t in BURST]),
	}


def main(guardian: str) -> None:
	sheets = {"bloom": bloom, "frost": frost, "autumn": autumn, "summer": summer}[guardian]()
	out = GUARDIANS / f"{guardian}_guardian" / "effects"
	out.mkdir(parents=True, exist_ok=True)
	for name, image in sheets.items():
		image.save(out / name)
		print(out / name, image.size)


if __name__ == "__main__":
	main(sys.argv[1])
