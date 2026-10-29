"""Draws the season-seed art: the cache husk, its notice icon and the village garden beds (tools/art/prompts/pickup_seed.md,
item_icon_seed.md, village_garden_bed_bare.md, village_garden_bed_planted.md; systems/seeds-and-the-seller).

Flat values, no outlines; a dark side against a light side so the husk reads in the grey, where only value is left
(playtests/2026-10-28-story06-found-pieces). The husk and the beds are drawn in art px and doubled to the world's 2x
density; the icon is HUD art px. The planted bed gets the three season bands of tools/art/season_bands.py.
Usage: python -I tools/art/draw_seed_art.py
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from season_bands import AUTUMN, WINTER, recolour  # noqa: E402

COLOURS = {
	".": (0, 0, 0, 0),
	"d": (46, 32, 22, 255),  # husk, dark side
	"m": (112, 78, 44, 255),  # husk ridge
	"l": (226, 198, 142, 255),  # husk, lit side
	"w": (150, 106, 62, 255),  # bed plank
	"W": (92, 62, 36, 255),  # bed plank shade, the contact row
	"s": (66, 46, 34, 255),  # soil
	"S": (88, 64, 46, 255),  # soil furrow top
	"g": (58, 112, 52, 255),  # leaves, dark
	"G": (112, 168, 74, 255),  # leaves, lit
	"f": (232, 196, 82, 255),  # flower
}
# A hard husk standing on its base, its tip up: dark left, lit right, one ridge between and one on the lit side.
HUSK = [
	"...d...",
	"..dml..",
	".ddmll.",
	".ddmll.",
	"dddmlml",
	"dddmlml",
	".ddmll.",
	"..dml..",
	".ddmmm.",
]
# The same husk for the notice and the shop, centred with a 1 px margin, no ground line.
ICON = [
	"................",
	".......dd.......",
	"......ddml......",
	"......dmll......",
	".....ddmlll.....",
	"....dddmllll....",
	"....dddmlmll....",
	"...ddddmlmlll...",
	"...ddddmlmlll...",
	"...ddddmlmlll...",
	"....dddmlmll....",
	"....dddmllll....",
	".....ddmlll.....",
	"......dmll......",
	".......dm.......",
	"................",
]
BED_BARE = [
	"wSSSSSSSSSSSSSSSSSSSSSSw",
	"wssssssssssssssssssssssw",
	"wwwwwwwwwwwwwwwwwwwwwwww",
	"WWWWWWWWWWWWWWWWWWWWWWWW",
]
# Four leaf clumps with flowers between, over the same bed.
BED_PLANTED = [
	"..G.......G......G......",
	".GGG..f..GGG..f.GGG..f..",
	"GGgGG.f.GGgGG.f.GGgGG.f.",
	"GgggG.g.GgggG.g.GgggG.g.",
	"gggggggggggggggggggggggg",
	"wSSSSSSSSSSSSSSSSSSSSSSw",
	"wssssssssssssssssssssssw",
	"wwwwwwwwwwwwwwwwwwwwwwww",
	"WWWWWWWWWWWWWWWWWWWWWWWW",
]


def pixels(rows: list[str], name: str) -> np.ndarray:
	art = np.zeros((len(rows), len(rows[0]), 4), np.uint8)
	for y, row in enumerate(rows):
		assert len(row) == len(rows[0]), f"{name} row {y} is {len(row)} wide"
		for x, key in enumerate(row):
			art[y, x] = COLOURS[key]
	return art


def save(art: np.ndarray, scale: int, path: Path) -> None:
	path.parent.mkdir(parents=True, exist_ok=True)
	image = Image.fromarray(art, "RGBA")
	image = image.resize((image.width * scale, image.height * scale), Image.NEAREST)
	image.save(path)
	print(f"{path.relative_to(ROOT)} {image.width}x{image.height}")


if __name__ == "__main__":
	save(pixels(HUSK, "husk"), 2, ROOT / "assets/sprites/world/pickups/seed.png")
	save(pixels(ICON, "icon"), 1, ROOT / "assets/sprites/hud/items/item_icon_seed.png")
	props = ROOT / "assets/sprites/world/props/village"
	save(pixels(BED_BARE, "bare"), 2, props / "garden_bed_bare.png")
	spring = pixels(BED_PLANTED, "planted")
	save(np.concatenate([spring, recolour(spring, AUTUMN), recolour(spring, WINTER)]), 2, props / "garden_bed_planted.png")
