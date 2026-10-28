"""Draws the notebook's fifth tab (Found) and its letter icon (tools/art/prompts/notebook_tab_05_*.md, notebook_icon_letter.md).

The tab is the pack's tab 01 with its two body colours swapped for blue; the icon is drawn here in the icons' four values.
"""
import sys

from PIL import Image

TAB_BODY = (230, 69, 57, 255)  # tab 01's main and shade values
TAB_SHADE = (173, 47, 69, 255)
BLUE_BODY = (77, 155, 230, 255)
BLUE_SHADE = (77, 101, 180, 255)

# The pack icons' values, dark to light.
DARK, MID, LIGHT, PAPER = (104, 111, 153, 255), (163, 167, 194, 255), (223, 224, 232, 255), (245, 255, 232, 255)
# A folded letter, its flap open: o outline, p paper, s shade, f flap line.
LETTER = [
	"................",
	"................",
	"................",
	"................",
	"..oooooooooooo..",
	"..offpppppppfo..",
	"..oppffpppffpo..",
	"..oppppffffppo..",
	"..opppppppppso..",
	"..opppppppppso..",
	"..opppppppppso..",
	"..osssssssssso..",
	"..oooooooooooo..",
	"................",
	"................",
	"................",
]
LETTER_COLOURS = {"o": DARK, "p": PAPER, "s": LIGHT, "f": MID}


def recolour_tab(source: str, target: str) -> None:
	image = Image.open(source).convert("RGBA")
	pixels = image.load()
	for y in range(image.height):
		for x in range(image.width):
			if pixels[x, y] == TAB_BODY:
				pixels[x, y] = BLUE_BODY
			elif pixels[x, y] == TAB_SHADE:
				pixels[x, y] = BLUE_SHADE
	image.save(target)


def draw_letter(target: str) -> None:
	image = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
	for y, row in enumerate(LETTER):
		assert len(row) == 16, row
		for x, cell in enumerate(row):
			if cell in LETTER_COLOURS:
				image.putpixel((x, y), LETTER_COLOURS[cell])
	image.save(target)


def main(folder: str) -> None:
	for state in ("normal", "selected"):
		recolour_tab(f"{folder}/tab_01_{state}.png", f"{folder}/tab_05_{state}.png")
	draw_letter(f"{folder}/icon_letter.png")


if __name__ == "__main__":
	main(sys.argv[1])
