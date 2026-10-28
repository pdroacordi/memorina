"""Draws the found-piece pickups: a letter and a songbook propped on the floor (tools/art/prompts/pickup_letter.md, pickup_songbook.md).

Flat values, no outlines, like the farmhouse props; strong value contrast and a height over the grass, because the greyhush leaves only value (playtests/2026-10-28-story06-found-pieces). Usage: python -I tools/art/draw_found_pickups.py
"""
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "assets" / "sprites" / "world" / "pickups"
COLOURS = {
	".": (0, 0, 0, 0),
	"p": (240, 232, 210, 255),  # paper
	"s": (176, 160, 128, 255),  # paper shade
	"f": (98, 84, 66, 255),  # fold line, dark so it reads in the grey
	"r": (168, 48, 40, 255),  # wax seal
	"c": (52, 34, 70, 255),  # cover, dark against grass and stone
	"d": (30, 20, 42, 255),  # cover shade and spine
	"g": (236, 196, 92, 255),  # gilt note
}
# A sealed envelope propped on its long edge, taller than the grass; the flap's V and the seal carry the shape.
LETTER = [
	"pppppppppppp",
	"pfpppppppfps",
	"ppfpppppfpps",
	"pppffpffppps",
	"pppppfrrppps",
	"pppppprpppps",
	"ppppppppppps",
	"ppppppppppps",
	"ppppppppppps",
	"sssssssssss.",
]
# A songbook standing on its bottom edge, cover out: a dark cover, the gilt note, the light page block beside the spine.
SONGBOOK = [
	"dccccccccpp.",
	"dccccccccpps",
	"dcccccgccpps",
	"dcccccggcpps",
	"dcccccgcgpps",
	"dcccccgccpps",
	"dccccggccpps",
	"dcccgggccpps",
	"dcccggcccpps",
	"dccccccccpps",
	"dccccccccpps",
	"dccccccccpps",
	"ddddddddddds",
]


def draw(rows: list[str], name: str) -> None:
	image = Image.new("RGBA", (len(rows[0]), len(rows)))
	for y, row in enumerate(rows):
		assert len(row) == len(rows[0]), f"{name} row {y} is {len(row)} wide"
		for x, key in enumerate(row):
			image.putpixel((x, y), COLOURS[key])
	image.save(OUT / f"{name}.png")


if __name__ == "__main__":
	draw(LETTER, "letter")
	draw(SONGBOOK, "songbook")
