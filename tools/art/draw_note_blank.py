"""Draws the Memorina sheet's blank note slot: an empty, dotted key outline (tools/art/prompts/note_blank.md)."""
import sys

from PIL import Image

INK = (104, 111, 153, 255)  # the glyphs' mid outline value
SIZE = 16
LEFT, TOP, RIGHT, BOTTOM = 3, 4, 11, 13  # the key glyphs' ink box


def main(out_path: str) -> None:
	image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	for x in range(LEFT, RIGHT + 1):
		for y in (TOP, BOTTOM):
			if (x + y) % 2 == 0:
				image.putpixel((x, y), INK)
	for y in range(TOP, BOTTOM + 1):
		for x in (LEFT, RIGHT):
			if (x + y) % 2 == 0:
				image.putpixel((x, y), INK)
	image.save(out_path)


if __name__ == "__main__":
	main(sys.argv[1])
