"""Draw the puzzle parts that repeat along their length, and the seesaw pivot (WORLD-42).

Usage: python -I tools/art/draw_puzzle_strips.py <drawbridge_plank|seesaw_plank|seesaw_fulcrum|root_strand> <out.png>

Each is drawn at art size and written at 2x. A strip's period is its width, so the scenes' TEXTURE_REPEAT tiles it
without a seam: drawbridge_plank 64x6 art px, seesaw_plank 80x4 (its pivot band centred, where seesaw.gd centres the
region), root_strand 16x5. The planks are the village planks (tilesets/village/wood.png), which the orchard and the
Caldera reuse; the pivot is Caldera basalt (tilesets/summer_caldera/stone.png); the roots are the root wall's colours
(props/spring_woods/root_wall.png).
"""
import math
import sys

from PIL import Image

WOOD_HI = (156, 122, 82, 255)
WOOD = (128, 85, 50, 255)
WOOD_MID = (111, 74, 44, 255)
WOOD_SHADE = (96, 63, 37, 255)
WOOD_DARK = (58, 42, 30, 255)
IRON = (66, 61, 54, 255)
IRON_HI = (102, 96, 88, 255)
BASALT_HI = (112, 110, 120, 255)
BASALT = (84, 82, 94, 255)
BASALT_SHADE = (63, 61, 70, 255)
SAND = (208, 168, 106, 255)
ROOT_HI = (161, 101, 66, 255)
ROOT = (109, 70, 52, 255)
ROOT_DARK = (59, 40, 34, 255)
SHOOT = (99, 120, 52, 255)


def drawbridge_plank() -> Image.Image:
	w, h = 64, 6
	art = Image.new("RGBA", (w, h), WOOD)
	px = art.load()
	for x in range(w):
		px[x, 0] = WOOD_HI
		px[x, 3] = WOOD_MID
		px[x, h - 1] = WOOD_DARK
	# Plank ends, staggered between the two boards.
	for x in (12, 44):
		px[x, 1] = WOOD_DARK
		px[x, 2] = WOOD_DARK
	for x in (28, 60):
		px[x, 4] = WOOD_DARK
	# Iron straps every 32 art px, a rivet on each.
	for x0 in (4, 36):
		for y in range(h):
			px[x0, y] = IRON
			px[x0 + 1, y] = IRON
		px[x0, 2] = IRON_HI
	return art


def seesaw_plank() -> Image.Image:
	w, h = 80, 4
	art = Image.new("RGBA", (w, h), WOOD)
	px = art.load()
	for x in range(w):
		px[x, 0] = WOOD_HI
		px[x, h - 1] = WOOD_SHADE
	for x in (9, 23, 56, 70):
		px[x, 1] = WOOD_MID
		px[x + 1, 2] = WOOD_MID
	# The band where it rests on the pivot, centred.
	for x in range(37, 43):
		px[x, 0] = WOOD_SHADE
		for y in range(1, h):
			px[x, y] = WOOD_DARK
	return art


def seesaw_fulcrum() -> Image.Image:
	w, h = 12, 12
	art = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	px = art.load()
	for y in range(h):
		inset = (h - 1 - y) * 4 // h
		for x in range(inset, w - inset):
			px[x, y] = BASALT
		px[inset, y] = BASALT_HI
		px[w - 1 - inset, y] = BASALT_SHADE
	for x in range(w):
		px[x, h - 1] = BASALT_SHADE
	# The sandstone pin the plank turns on.
	for x in (5, 6):
		px[x, 0] = SAND
		px[x, 1] = SAND
	return art


def root_strand() -> Image.Image:
	w, h = 16, 5
	art = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	px = art.load()
	# A thick root, 3 art px, with a gentle swell; a thin root winds round it, behind it on the way down.
	for x in range(w):
		top = 1 if x < 9 else 2 if x < 14 else 1
		for y in range(top, top + 3):
			px[x, y] = ROOT
		px[x, top] = ROOT_HI if x % 5 != 2 else ROOT
		px[x, top + 2] = ROOT_DARK
	for x in range(w):
		y = round(2 + 2 * math.sin(2 * math.pi * x / w))
		rising = math.cos(2 * math.pi * x / w) < 0
		if rising or not 1 <= y <= 3:
			px[x, y] = ROOT_DARK if rising else ROOT_HI
	px[4, 0] = SHOOT
	return art


def main(kind: str, out: str) -> None:
	art = {"drawbridge_plank": drawbridge_plank, "seesaw_plank": seesaw_plank,
		"seesaw_fulcrum": seesaw_fulcrum, "root_strand": root_strand}[kind]()
	art.resize((art.width * 2, art.height * 2), Image.NEAREST).save(out)


if __name__ == "__main__":
	main(sys.argv[1], sys.argv[2])
