"""Draw a region's pressure plate strip (tools/art/prompts/pressure_plate*.md).

Usage: python -I tools/art/draw_pressure_plate.py <village|caldera|orchard> <out.png>

Two 16x6 art px frames at 2x (64x12): raised, a slab 3 art px tall on a 1 px socket; pressed, the slab sunk to 1 px.
The bottom row is the floor line. Colours are the region's tiles and gate (WORLD-42), so a plate matches the gate it opens.
"""
import sys

from PIL import Image

FW, FH = 16, 6
# top light, face, shade, inlay, socket.
REGIONS = {
	# tilesets/village/stone.png cobbles, an iron inlay, an oak socket.
	"village": ((136, 124, 115), (118, 108, 101), (102, 91, 85), (62, 60, 57), (113, 67, 29)),
	# tilesets/summer_caldera/stone.png basalt, a sandstone sun inlay.
	"caldera": ((112, 110, 120), (84, 82, 94), (63, 61, 70), (208, 168, 106), (43, 42, 51)),
	# The orchard gate's limestone and its carving.
	"orchard": ((225, 188, 113), (196, 161, 98), (168, 132, 79), (140, 95, 52), (140, 95, 52)),
}


def slab(px, x0: int, height: int, colours) -> None:
	top, face, shade, inlay, socket = colours
	floor = FH - 1
	for x in range(FW):
		px[x0 + x, floor] = socket
	for y in range(floor - height, floor):
		for x in range(1, FW - 1):
			px[x0 + x, y] = face
		px[x0 + 1, y] = shade
		px[x0 + FW - 2, y] = shade
	for x in range(2, FW - 2):
		px[x0 + x, floor - height] = top
	# The inlay: two art px on the top face, centred, where the foot lands.
	px[x0 + 7, floor - height] = inlay
	px[x0 + 8, floor - height] = inlay


def main(region: str, out: str) -> None:
	colours = tuple(c + (255,) for c in REGIONS[region])
	art = Image.new("RGBA", (FW * 2, FH), (0, 0, 0, 0))
	px = art.load()
	slab(px, 0, 3, colours)
	slab(px, FW, 1, colours)
	art.resize((art.width * 2, art.height * 2), Image.NEAREST).save(out)


if __name__ == "__main__":
	main(sys.argv[1], sys.argv[2])
