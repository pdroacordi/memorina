"""Draw the waterfall garden's small and repeating props pixel by pixel (STORY-05, design drafts/camada_pessoal.md section 1).

Usage: python -I tools/art/draw_garden_props.py <kind> <out.png>
    kind: swing | swing_fallen | swing_rise | waterfall_fall | waterfall_splash | ribbon_branch | ribbon_hand | ribbon_flight
          | flower_bed_yellow | flower_bed_white | flower_bed_mixed
       python -I tools/art/draw_garden_props.py ivo_ribbon <clean sheet.png> <out.png>

Each is drawn at art size and written at 2x. Strips are frames side by side. waterfall_fall repeats vertically: every
frame's period is its height, and frame f is frame 0 moved down by f * height / frames, so the loop closes. The
ribbon is Alba's cornflower blue (story/alba/standing.png), the water the game water's colours (world/water), the wood
the village planks, the greens the village bush. Anything this small turned to mush when cut from Codex
(systems/art-pipeline, Puzzle parts).
"""
import math
import random
import sys

from PIL import Image

CLEAR = (0, 0, 0, 0)
ROPE_HI = (214, 184, 132, 255)
ROPE = (184, 148, 98, 255)
ROPE_SHADE = (138, 104, 66, 255)
WOOD_HI = (156, 122, 82, 255)
WOOD = (128, 85, 50, 255)
WOOD_SHADE = (96, 63, 37, 255)
WOOD_DARK = (58, 42, 30, 255)
BARK = (81, 62, 43, 255)
BARK_DARK = (64, 49, 34, 255)
LEAF_HI = (123, 143, 59, 255)
LEAF = (88, 132, 45, 255)
LEAF_SHADE = (52, 88, 45, 255)
LEAF_DARK = (36, 59, 38, 255)
RIBBON_HI = (150, 182, 222, 255)
RIBBON = (118, 152, 199, 255)
RIBBON_SHADE = (84, 114, 166, 255)
FOAM = (236, 244, 250, 255)
WATER_HI = (214, 228, 244, 255)
WATER_LIGHT = (170, 215, 245, 255)
WATER = (120, 176, 226, 255)
WATER_DEEP = (90, 150, 215, 255)
YELLOW_HI = (244, 214, 92, 255)
YELLOW = (222, 178, 54, 255)
WHITE = (242, 238, 226, 255)
WHITE_SHADE = (204, 204, 196, 255)
HEART = (214, 160, 56, 255)


def swing() -> Image.Image:
	"""Rope loops round the branch (rows 0-2), two ropes, the seat. Rope from row 3 to the seat's top row 39."""
	w, rope_end = 18, 39
	art = Image.new("RGBA", (w, rope_end + 4), CLEAR)
	px = art.load()
	for rx in (2, 15):
		for y in range(3):
			for dx in (-1, 0, 1):
				px[rx + dx, y] = ROPE_SHADE if (y + dx) % 2 else ROPE_HI
		for y in range(3, rope_end):
			px[rx, y] = ROPE if (y // 2) % 2 else ROPE_HI
			if y % 4 == 1:
				px[rx, y] = ROPE_SHADE
	# The seat: one plank, its top worn light, a knot under each end.
	for x in range(w):
		px[x, rope_end] = WOOD_HI
		px[x, rope_end + 1] = WOOD
		px[x, rope_end + 2] = WOOD_SHADE
	for rx in (2, 15):
		px[rx, rope_end] = ROPE
		px[rx, rope_end + 1] = ROPE_SHADE
		px[rx, rope_end + 3] = ROPE_SHADE
	px[0, rope_end + 2] = WOOD_DARK
	px[w - 1, rope_end + 2] = WOOD_DARK
	return art


def swing_fallen() -> Image.Image:
	"""The seat flat on the ground, its left end on a coil of its own rope, the other rope trailing loose to the right."""
	w, h = 34, 6
	art = Image.new("RGBA", (w, h), CLEAR)
	px = art.load()
	# The coil, a low loop of rope 8x4, behind the seat's left end.
	for x in range(1, 9):
		px[x, h - 4] = ROPE_HI if x % 2 else ROPE
		px[x, h - 1] = ROPE_SHADE
	for y in range(h - 4, h):
		px[0, y] = ROPE
		px[9, y] = ROPE_SHADE
	for x in range(2, 8):
		px[x, h - 2] = ROPE if x % 2 else ROPE_SHADE
	# The seat, flat, its left end raised one row on the coil.
	for x in range(5, 24):
		top = 1 if x < 9 else 2
		px[x, top] = WOOD_HI
		px[x, top + 1] = WOOD
		px[x, top + 2] = WOOD_SHADE
		if top + 3 < h:
			px[x, top + 3] = WOOD_DARK
	# The second rope out of the seat's right end, along the ground in a loose wave, frayed at its end.
	px[24, 3] = ROPE_SHADE
	px[24, 4] = ROPE
	for x in range(25, w):
		y = h - 1 - (1 if 27 <= x <= 29 else 0)
		px[x, y] = ROPE if x % 2 else ROPE_HI
	px[w - 1, h - 2] = ROPE_SHADE
	return art


def swing_rise(frames: int = 3) -> Image.Image:
	"""The fallen swing raised by a held Up (flashback 3): frame k (of `frames`) is step k + 1 of frames + 1. The seat lifts
	from the ground to its hanging row and the two ropes climb from it towards the branch, their loose ends frayed. 18x49 art
	px per frame, the ground under row 48; the hanging swing's rows are 0-42 of the same frame."""
	w, h, hang_top = 18, 49, 39
	sheet = Image.new("RGBA", (w * frames, h), CLEAR)
	for f in range(frames):
		t = (f + 1) / (frames + 1)
		art = Image.new("RGBA", (w, h), CLEAR)
		px = art.load()
		seat = round(46 + (hang_top - 46) * t)
		rope_top = round(seat - (seat - 3) * t)
		for rx in (2, 15):
			for y in range(rope_top, seat):
				px[rx, y] = ROPE if (y // 2) % 2 else ROPE_HI
				if y % 4 == 1:
					px[rx, y] = ROPE_SHADE
			# The loose end, bent and frayed.
			px[rx + (1 if rx == 2 else -1), rope_top] = ROPE_SHADE
			px[rx, rope_top] = ROPE_HI
		for x in range(w):
			px[x, seat] = WOOD_HI
			px[x, seat + 1] = WOOD
			px[x, seat + 2] = WOOD_SHADE
		for rx in (2, 15):
			px[rx, seat] = ROPE
			px[rx, seat + 1] = ROPE_SHADE
			if seat + 3 < h:
				px[rx, seat + 3] = ROPE_SHADE
		px[0, seat + 2] = WOOD_DARK
		px[w - 1, seat + 2] = WOOD_DARK
		sheet.paste(art, (f * w, 0))
	return sheet


def waterfall_fall(frames: int = 4) -> Image.Image:
	"""A narrow fall 14 art px wide; light streaks run down a 32 px period, edges ragged."""
	w, h = 14, 32
	rng = random.Random(5)
	base = [[CLEAR] * w for _ in range(h)]
	shade = [WATER_DEEP, WATER, WATER_LIGHT, WATER_LIGHT, WATER, WATER_LIGHT, WATER_LIGHT, WATER, WATER_LIGHT, WATER_LIGHT,
		WATER, WATER_LIGHT, WATER, WATER_DEEP]
	for x in range(w):
		for y in range(h):
			base[y][x] = shade[x]
	# Streaks: each column gets a few dashes that wrap the period.
	for x in range(1, w - 1):
		for _n in range(2):
			start, length = rng.randrange(h), rng.randrange(4, 10)
			colour = WATER_HI if shade[x] == WATER_LIGHT else WATER_LIGHT
			for k in range(length):
				base[(start + k) % h][x] = colour
		if rng.random() < 0.5:
			base[rng.randrange(h)][x] = FOAM
	# Ragged edges: the outer columns drop out in short runs.
	for x in (0, w - 1):
		for start in rng.sample(range(h), 3):
			for k in range(rng.randrange(2, 5)):
				base[(start + k) % h][x] = CLEAR
	sheet = Image.new("RGBA", (w * frames, h), CLEAR)
	px = sheet.load()
	step = h // frames
	for f in range(frames):
		for y in range(h):
			for x in range(w):
				px[f * w + x, y] = base[(y - f * step) % h][x]
	return sheet


def waterfall_splash(frames: int = 4) -> Image.Image:
	"""Foam where the fall meets the pool: a white mound on the bottom rows over a pale skirt, spray changing each frame."""
	w, h = 30, 12
	sheet = Image.new("RGBA", (w * frames, h), CLEAR)
	px = sheet.load()
	cx = (w - 1) / 2
	for f in range(frames):
		rng = random.Random(40 + f)
		ox = f * w
		for x in range(w):
			d = abs(x - cx)
			wobble = math.sin(2 * math.pi * f / frames + x * 1.1)
			skirt = max(0, round(3.0 - d * 0.16 + 0.6 * wobble))
			mound = max(0, round(7.0 - d * 0.62 + 0.9 * wobble))
			for k in range(max(skirt, mound)):
				y = h - 1 - k
				if k < mound:
					px[ox + x, y] = WATER_HI if k == mound - 1 and d > 3 else FOAM
				else:
					px[ox + x, y] = WATER_LIGHT if k == skirt - 1 else WATER_HI
		# Spray: droplets thrown out of the mound, on both sides.
		for _n in range(12):
			side = -1 if rng.random() < 0.5 else 1
			dx = rng.randrange(4, 14)
			x = round(cx + side * dx)
			y = h - 5 - rng.randrange(0, 6) + dx // 3
			if 0 <= x < w and 0 <= y < h - 1 and px[ox + x, y][3] == 0:
				px[ox + x, y] = FOAM if rng.random() < 0.5 else WATER_LIGHT
	return sheet


RIBBON_DARK = (62, 86, 134, 255)
# Ivo's raised hand in each frame of ivo_ribbon.png (game px in its 128 px frame): the bow's knot is drawn there.
IVO_HANDS = [(74, 77), (76, 77), (80, 75), (82, 75), (86, 71), (84, 69), (86, 61), (84, 57), (82, 59)]
# The flight's knot per frame (art px in its 32x96 frame), rising up and away from the wall; the last two are empty.
FLIGHT_PATH = [(6, 86), (8, 76), (12, 67), (16, 61), (16, 51), (15, 40), (15, 29), (17, 20), (20, 13), (23, 5)]


def _put(px, size, x, y, colour) -> None:
	if 0 <= x < size[0] and 0 <= y < size[1]:
		px[x, y] = colour


def _loop(px, size, cx: float, cy: float, rx: float, ry: float) -> None:
	"""One loop of the bow: an oval band of cloth, light on top, shaded under, dark inside, its middle open."""
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
			if d > 1.0:
				continue
			if d < 0.16:
				continue
			if d < 0.4:
				colour = RIBBON_DARK
			elif y < cy - ry * 0.35:
				colour = RIBBON_HI
			elif y > cy + ry * 0.35:
				colour = RIBBON_SHADE
			else:
				colour = RIBBON
			_put(px, size, x, y, colour)


def _tail(px, size, x0: int, y0: int, length: int, drift: float, sway: float, f: int, frames: int, offset: float) -> None:
	"""A loose end, 3 px wide then 2, waving down its length; a wave runs down it frame by frame; a notched end."""
	for k in range(length):
		t = (k + 1) / length
		wave = math.sin(2 * math.pi * f / frames - k * 0.45 + offset) * sway * t
		x = round(x0 + drift * k + wave)
		y = y0 + k
		width = 3 if k < length // 2 else 2
		if k >= length - 2:
			# The cut end: a V notch, only the outer pixel on the last row.
			_put(px, size, x, y, RIBBON_SHADE)
			if k == length - 2:
				_put(px, size, x + width - 1, y, RIBBON_SHADE)
			else:
				_put(px, size, x + width - 1, y, RIBBON_DARK)
			continue
		_put(px, size, x, y, RIBBON_HI if k % 5 else RIBBON)
		_put(px, size, x + 1, y, RIBBON)
		if width == 3:
			_put(px, size, x + 2, y, RIBBON_SHADE)
		else:
			_put(px, size, x + 1, y, RIBBON_SHADE if (k // 3) % 2 else RIBBON)


def _bow(px, size, kx: int, ky: int, f: int, frames: int, tail: int, loop: tuple, sway: float) -> None:
	"""The bow: two loops either side of a 3x3 knot at (kx, ky) top left, two long ends from under the knot."""
	rx, ry = loop
	_loop(px, size, kx - rx + 0.5, ky + 1, rx, ry)
	_loop(px, size, kx + 2 + rx - 0.5, ky + 1, rx, ry)
	_tail(px, size, kx - 1, ky + 3, tail, -0.18, sway, f, frames, 0.0)
	_tail(px, size, kx + 1, ky + 3, tail + 2, 0.22, sway, f, frames, 1.7)
	for dy in range(3):
		for dx in range(3):
			_put(px, size, kx + dx, ky + dy, RIBBON_DARK if dy == 2 or dx == 2 else RIBBON_SHADE)
	_put(px, size, kx + 1, ky, RIBBON)


def _twig(px, kx: int, ky: int) -> None:
	"""A dead twig from the frame's top left corner (it roots in rock or bark there) to the knot at (kx, ky), two leaves on it."""
	for x in range(0, kx + 1):
		y = x * ky // kx
		px[x, y] = BARK
		px[x, y + 1] = BARK_DARK
		if x < kx // 3:
			px[x, y + 2] = BARK_DARK
	for (x, y), colour in {(3, 2): LEAF_SHADE, (4, 3): LEAF_DARK, (7, 0): LEAF, (8, 0): LEAF_HI, (9, 1): LEAF_SHADE}.items():
		px[x, y] = colour


def ribbon_branch(frames: int = 4) -> Image.Image:
	"""Alba's ribbon tied in a bow round a twig end; the twig leaves the frame's top left; two long ends wave."""
	# 24 art px (48 game px) per frame: at 72 game px it read larger than Ivo's torso (systems/cutscenes, "The ribbon's art").
	w, h = 24, 24
	sheet = Image.new("RGBA", (w * frames, h), CLEAR)
	for f in range(frames):
		art = Image.new("RGBA", (w, h), CLEAR)
		px = art.load()
		_twig(px, 14, 4)
		_bow(px, (w, h), 14, 4, f, frames, 16, (4.0, 3.0), 2.0)
		sheet.paste(art, (f * w, 0))
	return sheet


def ribbon_hand() -> Image.Image:
	"""The ribbon in Ivo's hand: the bow's knot at (5, 1), its two loops and two ends hanging under the hand."""
	w, h = 12, 11
	art = Image.new("RGBA", (w, h), CLEAR)
	_bow(art.load(), (w, h), 5, 1, 0, 4, 7, (2.6, 2.0), 0.6)
	return art


def ribbon_flight(frames: int = 12) -> Image.Image:
	"""The ribbon let go: the free bow rising up and away (FLIGHT_PATH), its ends trailing and waving; then gone."""
	w, h = 32, 96
	sheet = Image.new("RGBA", (w * frames, h), CLEAR)
	for f, (kx, ky) in enumerate(FLIGHT_PATH):
		art = Image.new("RGBA", (w, h), CLEAR)
		_bow(art.load(), (w, h), kx, ky, f, 4, 12, (4.0, 2.6), 2.5)
		sheet.paste(art, (f * w, 0))
	return sheet


def ivo_ribbon(clean: str) -> Image.Image:
	"""Ivo's ribbon clip with the ribbon in his raised hand: ribbon_hand at 2x on each frame's hand (IVO_HANDS)."""
	sheet = Image.open(clean).convert("RGBA")
	bow = ribbon_hand()
	bow = bow.resize((bow.width * 2, bow.height * 2), Image.NEAREST)
	for f, (hx, hy) in enumerate(IVO_HANDS):
		# The knot's centre is art (6, 2), game (12, 4).
		sheet.alpha_composite(bow, (f * 128 + hx - 12, hy - 4))
	return sheet


def flower_bed(w: int, h: int, seed: int, petals: list[tuple], frames: int = 4) -> Image.Image:
	"""A low wild clump: a leafy mound of round leaf lumps in the bush's greens, 2x2 flower heads on and above it.

	Frames side by side: the mound holds still and the heads nod 1 art px on their stems (0, +1, 0, -1, half of them the
	other way), so frame 0 is the still.
	"""
	rng = random.Random(seed)
	base = Image.new("RGBA", (w, h), CLEAR)
	px = base.load()
	# Leaf lumps: overlapping half-discs along the floor, taller in the middle.
	heights = [0] * w
	x = 0
	while x < w:
		r = rng.randrange(3, 5)
		cx = min(w - 1, x + r - 1)
		d = abs(cx - (w - 1) / 2) / ((w - 1) / 2)
		top = round((h - 3) * (1 - 0.55 * d * d))
		for xx in range(max(0, cx - r), min(w, cx + r + 1)):
			hh = round(top * math.sqrt(max(0.0, 1 - ((xx - cx) / (r + 0.5)) ** 2)))
			heights[xx] = max(heights[xx], hh, 1)
		x += r + rng.randrange(0, 2)
	for xx in range(w):
		top = h - heights[xx]
		for y in range(top, h):
			depth = y - top
			px[xx, y] = LEAF_HI if depth == 0 else LEAF if depth <= 2 else LEAF_SHADE if y < h - 1 else LEAF_DARK
	# Flower heads, 2x2, on stems over or on the mound, never touching each other.
	placed: list[tuple[int, int, int, tuple, tuple]] = []
	for _try in range(300):
		x = rng.randrange(0, w - 1)
		top = h - max(heights[x], heights[x + 1])
		y = top - rng.randrange(1, 3)
		if y < 0 or any(abs(x - a) < 4 and abs(y - b) < 3 for a, b, *_rest in placed):
			continue
		hi, lo = petals[len(placed) % len(petals)]
		placed.append((x, y, top, hi, lo))
		if len(placed) >= w // 4:
			break
	sheet = Image.new("RGBA", (w * frames, h), CLEAR)
	for f in range(frames):
		art = base.copy()
		fx = art.load()
		nod = round(math.sin(2 * math.pi * f / frames))
		for i, (x, y, top, hi, lo) in enumerate(placed):
			dx = nod if i % 2 == 0 else -nod
			hx = min(max(x + dx, 0), w - 2)
			for yy in range(y + 2, top + 1):
				fx[hx if yy < y + 3 else x, yy] = LEAF_SHADE
			fx[hx, y] = hi
			fx[hx + 1, y] = hi
			fx[hx, y + 1] = lo
			fx[hx + 1, y + 1] = HEART if hi == WHITE else lo
		sheet.paste(art, (f * w, 0))
	return sheet


def main(kind: str, out: str, clean: str = "") -> None:
	if kind == "ivo_ribbon":
		# Already at game size: the clean sheet is cut_inhabitant's output without the ribbon.
		ivo_ribbon(clean).save(out)
		return
	yellow = [(YELLOW_HI, YELLOW)]
	white = [(WHITE, WHITE_SHADE)]
	art = {
		"swing": swing,
		"swing_fallen": swing_fallen,
		"swing_rise": swing_rise,
		"waterfall_fall": waterfall_fall,
		"waterfall_splash": waterfall_splash,
		"ribbon_branch": ribbon_branch,
		"ribbon_hand": ribbon_hand,
		"ribbon_flight": ribbon_flight,
		"flower_bed_yellow": lambda: flower_bed(20, 10, 11, yellow),
		"flower_bed_white": lambda: flower_bed(18, 9, 23, white),
		"flower_bed_mixed": lambda: flower_bed(24, 10, 37, yellow + white),
	}[kind]()
	art.resize((art.width * 2, art.height * 2), Image.NEAREST).save(out)


if __name__ == "__main__":
	if sys.argv[1] == "ivo_ribbon":
		main(sys.argv[1], sys.argv[3], sys.argv[2])
	else:
		main(sys.argv[1], sys.argv[2])
