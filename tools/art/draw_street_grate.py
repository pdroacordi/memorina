"""Draw the village street grate (tools/art/prompts/village_street_grate.md).

Usage: python -I tools/art/draw_street_grate.py <out.png>

64x16 art px at 2x (128x32): a cut-stone block at each end in the village cobble colours (tilesets/village/stone.png),
between them an iron frame with bars every 4 art px and one cross bar in the fact barrier's iron colours. The gaps between
the bars stay transparent, so the vault under the road shows through.
"""
import sys

from PIL import Image

W, H = 64, 16
BLOCK = 6  # art px of stone at each end
DARK = (34, 25, 17, 255)
IRON = (46, 35, 39, 255)
MID = (70, 61, 54, 255)
LIGHT = (99, 82, 68, 255)
# Sampled from assets/sprites/world/tilesets/village/stone.png: highlight, face, shade, mortar.
STONE_HI = (136, 124, 115, 255)
STONE = (118, 108, 101, 255)
STONE_SHADE = (102, 91, 85, 255)
MORTAR = (62, 60, 57, 255)


def stone_block(px, x0):
    for x in range(x0, x0 + BLOCK):
        for y in range(H):
            px[x, y] = STONE
        px[x, 0] = STONE_HI
        px[x, H - 1] = MORTAR
        px[x, H - 2] = STONE_SHADE
        px[x, 7] = MORTAR  # the course line between two stones
    for y in range(H):
        px[x0, y] = MORTAR if y % 8 != 0 else STONE_HI
        px[x0 + BLOCK - 1, y] = STONE_SHADE if y not in (0, 7, H - 1) else px[x0 + BLOCK - 1, y]
    for y in range(1, 7):
        px[x0 + 1, y] = STONE_HI


def main(out):
    art = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = art.load()
    stone_block(px, 0)
    stone_block(px, W - BLOCK)
    left, right = BLOCK, W - BLOCK
    for x in range(left, right):
        px[x, 0] = LIGHT
        px[x, 1] = MID
        px[x, H - 2] = IRON
        px[x, H - 1] = DARK
        px[x, 7] = MID
        px[x, 8] = IRON
    for x in range(left + 2, right - 2, 4):
        for y in range(2, H - 2):
            px[x, y] = MID
            px[x + 1, y] = IRON
    art.resize((W * 2, H * 2), Image.NEAREST).save(out)
    print("wrote", out)


main(sys.argv[1])
