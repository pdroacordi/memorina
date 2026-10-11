"""Paint the village plank tiles (tools/art/tiles/village_wood.json): 16 art px, two 7 px boards with a 1 px gap,
grain streaks, and on the variants staggered butt joints with nails, in the colours of the PixelLab plank body.

python -I tools/art/tiles/paint_planks.py   (from the repo root; writes tools/art/tiles/sources/village_planks_0..4.png)
"""
from PIL import Image

HI, TOP, MID, GRAIN, GAP, NAIL = "#9c7a52", "#8c6a44", "#805532", "#6f4a2c", "#3a2a1e", "#4a3424"
OUT = "tools/art/tiles/sources"

def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)

# Grain per board: (row inside the board, first x, length); wraps at 16.
GRAIN_RUNS = [[(3, 2, 5), (5, 10, 4)], [(2, 7, 6), (4, 13, 4), (5, 1, 3)]]

def tile(joints, grain=GRAIN_RUNS):
    """joints: per board, an x for a butt joint or None."""
    im = Image.new("RGBA", (16, 16))
    for board in range(2):
        y0 = board * 8
        for y in range(y0, y0 + 8):
            for x in range(16):
                r = y - y0
                c = HI if r == 0 else GAP if r == 7 else TOP if r == 1 else MID
                im.putpixel((x, y), rgb(c))
        for r, x0, n in grain[board]:
            for i in range(n):
                im.putpixel(((x0 + i) % 16, y0 + r), rgb(GRAIN))
        j = joints[board]
        if j is not None:
            for y in range(y0, y0 + 7):
                im.putpixel((j, y), rgb(GAP))
            im.putpixel(((j + 1) % 16, y0 + 1), rgb(HI))
            for dx in (-2, 2):
                for r in (2, 5):
                    im.putpixel(((j + dx) % 16, y0 + r), rgb(NAIL))
    return im

tile([None, None]).save(f"{OUT}/village_planks_0.png")
tile([5, None], [[(4, 9, 5)], [(2, 1, 4), (5, 8, 6)]]).save(f"{OUT}/village_planks_1.png")
tile([None, 11], [[(2, 13, 6), (5, 4, 3)], [(4, 3, 5)]]).save(f"{OUT}/village_planks_2.png")
tile([12, 3], [[(3, 2, 6)], [(5, 6, 4)]]).save(f"{OUT}/village_planks_3.png")
tile([None, None], [[(2, 6, 7), (5, 0, 3)], [(3, 11, 6)]]).save(f"{OUT}/village_planks_4.png")
