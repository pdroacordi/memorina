"""Draw the waterfall garden's small and repeating props pixel by pixel (STORY-05, design drafts/camada_pessoal.md section 1).

Usage: python -I tools/art/draw_garden_props.py <kind> <out.png>
    kind: swing | swing_fallen | swing_rise | falls | falls_foam | lantern | ribbon_branch | ribbon_hand | ribbon_flight
          | flower_bed_yellow | flower_bed_white | flower_bed_mixed
       python -I tools/art/draw_garden_props.py ivo_ribbon <clean sheet.png> <out.png>

Each is drawn at art size and written at 2x. Strips are frames side by side. falls repeats vertically: every frame's
period is its height, and frame f is frame 0 moved down by f * height / frames, so the loop closes. The
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


def _tongue(cells, w: int, h: int, cx: float, y0: int, half: float, length: int, colour) -> None:
	"""A streak that tapers to a point downward, wrapping the vertical period."""
	for k in range(length):
		r = half * (1 - k / length) ** 0.8
		for x in range(math.floor(cx - r), math.ceil(cx + r) + 1):
			if 0 <= x < w and abs(x - cx) <= r + 0.25:
				cells[(y0 + k) % h][x] = colour


def falls(frames: int = 6) -> Image.Image:
	"""The big fall: 52 art px wide, a 96 art px vertical period; deep tongues and bright streaks over pale water."""
	w, h = 52, 96
	rng = random.Random(17)
	cells = [[WATER_HI] * w for _ in range(h)]
	for y in range(h):
		for x in range(w):
			if min(x, w - 1 - x) < 3:
				cells[y][x] = WATER_LIGHT
	# Broad tongues first, then deeper cores inside some of them, then a few bright streaks.
	cols = [3 + i * (w - 6) / 9 + rng.uniform(-1.5, 1.5) for i in range(10)]
	for i, cx in enumerate(cols):
		for _n in range(2):
			y0, length, half = rng.randrange(h), rng.randrange(30, 56), rng.uniform(2.2, 3.4)
			_tongue(cells, w, h, cx, y0, half, length, WATER_LIGHT)
			if rng.random() < 0.55:
				_tongue(cells, w, h, cx + rng.uniform(-0.6, 0.6), y0 + 4, half * 0.5, length * 2 // 3, WATER)
	for _n in range(7):
		_tongue(cells, w, h, rng.uniform(5, w - 6), rng.randrange(h), rng.uniform(0.8, 1.2), rng.randrange(12, 22), FOAM)
	# Ragged sides: the outer columns break into short runs of air and spray.
	for x, depth in ((0, 3), (w - 1, 3)):
		inward = 1 if x == 0 else -1
		y = 0
		while y < h:
			run = rng.randrange(3, 9)
			bite = rng.randrange(0, depth + 1)
			for k in range(run):
				for d in range(bite):
					cells[(y + k) % h][x + inward * d] = CLEAR
			if bite and rng.random() < 0.5:
				cells[(y + run // 2) % h][x + inward * bite] = WATER_HI
			y += run
	sheet = Image.new("RGBA", (w * frames, h), CLEAR)
	px = sheet.load()
	step = h // frames
	for f in range(frames):
		for y in range(h):
			for x in range(w):
				px[f * w + x, y] = cells[(y - f * step) % h][x]
	return sheet


def falls_foam(frames: int = 6) -> Image.Image:
	"""The big fall's foot: foam puffs churning on the pool's surface (bottom row), mist and spray, looping over frames."""
	w, h = 84, 30
	cx = (w - 1) / 2
	rng = random.Random(29)
	puffs = []
	for i in range(26):
		d = -1 + 2 * i / 25 + rng.uniform(-0.04, 0.04)
		x = cx + d * 32
		rise = (1 - abs(d) ** 1.5) * 13
		puffs.append((x, h - 3 - rise * rng.uniform(0.6, 1.0), (6.5 - abs(d) * 3.5) * rng.uniform(0.85, 1.1), rng.random()))
	mist = [(cx + rng.uniform(-30, 30), rng.uniform(4, 10), rng.uniform(2.0, 3.0), rng.random()) for _ in range(4)]
	sheet = Image.new("RGBA", (w * frames, h), CLEAR)
	px = sheet.load()
	for f in range(frames):
		ox = f * w
		t = f / frames
		layer = [[CLEAR] * w for _ in range(h)]
		# Mist: pale rounds drifting up, each on its own phase.
		for mx, my, mr, ph in mist:
			p = (t + ph) % 1.0
			y = my - p * 8
			r = mr * (1 - 0.5 * p)
			for yy in range(h):
				for xx in range(w):
					if (xx - mx) ** 2 + (yy - y) ** 2 <= r * r:
						layer[yy][xx] = WATER_HI
		# Foam puffs: each swells and settles once per loop.
		for x, y, r, ph in puffs:
			s = 0.9 + 0.15 * math.sin(2 * math.pi * (t + ph))
			rr = r * s
			yy0 = y - 1.5 * math.sin(2 * math.pi * (t + ph))
			for yy in range(h):
				for xx in range(w):
					d2 = (xx - x) ** 2 + (yy - yy0) ** 2
					if d2 <= rr * rr:
						layer[yy][xx] = FOAM if yy < yy0 + rr * 0.2 or d2 <= (rr * 0.55) ** 2 else WATER_HI
		# The mound is solid down to the surface: no air under a puff.
		for xx in range(w):
			top = next((yy for yy in range(h) if layer[yy][xx] in (FOAM, WATER_HI) and yy > h - 20), None)
			if top is not None:
				for yy in range(top, h):
					if layer[yy][xx] == CLEAR:
						layer[yy][xx] = WATER_HI
		# A skirt of churned water spreading on the surface rows.
		for xx in range(w):
			d = abs(xx - cx)
			wob = math.sin(2 * math.pi * t + xx * 0.7)
			skirt = max(0, round(3.2 - d * 0.07 + 0.8 * wob))
			for k in range(skirt):
				yy = h - 1 - k
				if layer[yy][xx] == CLEAR:
					layer[yy][xx] = WATER_LIGHT if k == 0 else WATER_HI
		# Spray: droplets on arcs out of the foam, looping.
		srng = random.Random(61)
		for _n in range(8):
			side = -1 if srng.random() < 0.5 else 1
			reach, top, ph = srng.uniform(18, 40), srng.uniform(8, 18), srng.random()
			p = (t + ph) % 1.0
			xx = round(cx + side * (10 + reach * p))
			yy = round(h - 6 - top * 4 * p * (1 - p))
			if 0 <= xx < w and 0 <= yy < h and layer[yy][xx] == CLEAR:
				layer[yy][xx] = FOAM if p < 0.6 else WATER_LIGHT
		for yy in range(h):
			for xx in range(w):
				px[ox + xx, yy] = layer[yy][xx]
	return sheet


IRON = (46, 46, 58, 255)
IRON_HI = (74, 74, 90, 255)
GLASS = (84, 98, 124, 255)
GLASS_HI = (116, 132, 158, 255)
CANDLE = (226, 216, 190, 255)
PANE_LIT = (246, 206, 86, 255)
PANE_GLOW = (252, 234, 156, 255)
FLAME = (236, 142, 48, 255)


def lantern(frames: int = 4) -> Image.Image:
	"""A lantern hung from a crook post, 16x34 art px: frame 0 unlit, frames 1-3 lit (the flame flickers in the panes)."""
	w, h = 16, 34
	sheet = Image.new("RGBA", (w * frames, h), CLEAR)
	px = sheet.load()
	for f in range(frames):
		o = f * w

		def put(x: int, y: int, c) -> None:
			px[o + x, y] = c

		# The post, its flared foot and the crook curling over to the hook at x 10.
		for y in range(3, h):
			put(2, y, IRON)
			put(3, y, IRON_HI)
		for x in range(0, 6):
			put(x, h - 1, IRON)
		for x in range(1, 5):
			put(x, h - 2, IRON)
		put(2, 2, IRON)
		put(3, 2, IRON)
		put(3, 1, IRON)
		put(4, 1, IRON)
		for x in range(4, 10):
			put(x, 0, IRON)
		for x in range(5, 9):
			put(x, 1, IRON_HI)
		put(10, 1, IRON)
		put(11, 1, IRON)
		put(12, 2, IRON)
		put(12, 3, IRON_HI)
		put(11, 4, IRON)
		# The hanger from the crook's end: a chain link and a ring.
		put(10, 2, IRON_HI)
		put(10, 3, IRON)
		put(10, 5, IRON)
		put(9, 6, IRON)
		put(11, 6, IRON)
		put(10, 7, IRON)
		# The cap.
		put(10, 8, IRON)
		for x in range(9, 12):
			put(x, 9, IRON)
		for x in range(7, 14):
			put(x, 10, IRON_HI if x < 10 else IRON)
		for x in range(6, 15):
			put(x, 11, IRON)
		# The body: three bars and two panes, rows 12-17.
		for y in range(12, 18):
			for x in (7, 10, 13):
				put(x, y, IRON)
			for x in (8, 9, 11, 12):
				put(x, y, GLASS if f == 0 else PANE_LIT)
		if f == 0:
			put(8, 12, GLASS_HI)
			put(11, 12, GLASS_HI)
			put(9, 16, CANDLE)
			put(9, 17, CANDLE)
		else:
			# The flame shows in both panes, its tip one row higher or lower per frame.
			tip = (14, 13, 15)[f - 1]
			for x in (9, 11):
				for y in range(tip, 18):
					put(x, y, FLAME if y > tip else PANE_GLOW)
			for x in (8, 12):
				put(x, 17, PANE_GLOW)
		# The tray.
		for x in range(6, 15):
			put(x, 18, IRON)
		for x in range(8, 13):
			put(x, 19, IRON_HI)
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
		"falls": falls,
		"falls_foam": falls_foam,
		"lantern": lantern,
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
