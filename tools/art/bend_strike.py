"""Bend the part of one strip frame that lies ahead of a pivot, so a reach drawn over a target's head comes down to it.

Usage: python -I tools/art/bend_strike.py <strip.png> <frame width> <frame> <pivot ahead> <pivot row> reflect
       python -I tools/art/bend_strike.py <strip.png> <frame width> <frame> <pivot ahead> <pivot row> droop <slope>

The frame faces west, as guardian sheets are authored: "ahead" is art px from the frame's centre toward column 0 (a
pixel's front edge), a row is art px above the bottom row. Every opaque pixel at or beyond `pivot ahead` moves:
`reflect` mirrors it about the pivot row (a reach rising from the hand falls from it instead); `droop` lowers it by
`slope` rows per px past the pivot (a level reach tilts down from the hand). Pixels are moved, never blended; the strip
is rewritten in place. The Bloom back-lash's vine was drawn at 60-74 px, over Ivo's 50 px hurtbox (GRD-18,
systems/guardians).
"""
import sys

from PIL import Image


def main(path: str, width: int, frame: int, pivot: int, row: float, mode: str, slope: float) -> None:
	image = Image.open(path).convert("RGBA")
	px = image.load()
	height = image.height
	left = frame * width
	moved = []
	for c in range(width):
		ahead = width // 2 - c
		if ahead < pivot:
			continue
		for y in range(height):
			colour = px[left + c, y]
			if colour[3] == 0:
				continue
			up = height - 1 - y
			if mode == "reflect":
				new_up = round(2 * row - up)
			else:
				new_up = up - round((ahead - pivot) * slope)
			moved.append((c, new_up, colour))
			px[left + c, y] = (0, 0, 0, 0)
	for c, up, colour in moved:
		if 0 <= up < height:
			px[left + c, height - 1 - up] = colour
	image.save(path)
	print(path, "frame", frame, "moved", len(moved))


if __name__ == "__main__":
	args = sys.argv[1:]
	main(args[0], int(args[1]), int(args[2]), int(args[3]), float(args[4]), args[5], float(args[6]) if len(args) > 6 else 0.0)
