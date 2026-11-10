"""Clears the letter of the W note key into the blank note key (tools/art/prompts/input_key_blank.md)."""
import sys
from pathlib import Path

from PIL import Image

TOP_ROW = (163, 167, 194, 255)  # the key face's top highlight
FACE = (104, 111, 153, 255)  # the key face
LETTER_X = range(5, 10)  # the letter's columns, the same in both states
LETTER_TOP = 5


def main(art_dir: str) -> None:
	folder = Path(art_dir)
	for state in ("normal", "selected"):
		image = Image.open(folder / f"input_key_w_{state}.png").convert("RGBA")
		for x in LETTER_X:
			image.putpixel((x, LETTER_TOP), TOP_ROW)
			for y in range(LETTER_TOP + 1, LETTER_TOP + 5):
				image.putpixel((x, y), FACE)
		image.save(folder / f"input_key_blank_{state}.png")


if __name__ == "__main__":
	main(sys.argv[1])
