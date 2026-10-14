"""Draw the caldera crater's rim layer: the basalt wall's own texture continued upward into a ragged row of column tops.

Usage: python -I tools/art/draw_crater_rim.py <wall.png> <out.png> [--rows=32] [--seed=30]

The wall repeats on both axes, so rim row r (art px) copies wall row (r - rows) mod height: where the rim meets the
wall's top row the pixels continue without a seam. The strip runs OVERLAP rows on over the wall's top, the same pixels,
so the two quads never leave a row between them. Every column keeps at least MIN_HEIGHT art px, so the wall's
straight top never shows. Drawn at 2x like every backdrop (tools/art/prompts/backdrop_caldera_crater_rim.md).
"""

import random
import sys

from PIL import Image

MIN_HEIGHT = 4  # art px of rim over the wall's top in every column
OVERLAP = 4  # art rows the rim runs on over the wall's top, in the wall's own pixels
HEADROOM = 8  # empty art rows over the tallest column; a full top row would read as art cut flat (backdrop_set_test)
MIN_WIDTH = 8  # art px per basalt column
MAX_WIDTH = 16
MAX_TILT = 3  # art px a column's top falls across its width
CAP = [(56, 59, 64, 255), (48, 51, 56, 255)]  # lit top face, top row first; one and two steps over the wall's lightest
EDGE = (29, 31, 34, 255)  # the shaded front edge under the top face
ASH = (70, 69, 75, 255)  # ash settled on a cap; the ash tiles' darkest value, hazed down to sit behind the play plane
JOINT = (23, 25, 28, 255)  # the wall's darkest colour


def columns(width: int, rows: int, rng: random.Random) -> list[tuple[int, int, int, int]]:
    """(x0, x1, height, tilt) per column, widths summing to `width` so the strip wraps."""
    spans: list[int] = []
    left = width
    while left > 0:
        w = rng.randint(MIN_WIDTH, MAX_WIDTH)
        if left - w < MIN_WIDTH:
            w = left
        spans.append(w)
        left -= w
    out: list[tuple[int, int, int, int]] = []
    x = 0
    tallest = rows - HEADROOM
    height = rng.randint(tallest // 3, tallest * 2 // 3)
    for w in spans:
        # A walk with the odd broken stump or tall column, so the line reads as a ridge of columns, not noise.
        step = rng.choice([-4, -3, -2, -1, 1, 2, 3, 4])
        if rng.random() < 0.12:
            step = rng.choice([-8, 8])
        # Pulled back toward the middle height so the ridge never lies flat on its floor or ceiling for long.
        step += round((tallest * 0.6 - height) * 0.3)
        height = max(MIN_HEIGHT + MAX_TILT, min(tallest, height + step))
        out.append((x, x + w, height, rng.randint(-MAX_TILT, MAX_TILT)))
        x += w
    return out


def main(wall_path: str, out_path: str, rows: int, seed: int) -> None:
    wall = Image.open(wall_path).convert("RGBA")
    art = wall.resize((wall.width // 2, wall.height // 2), Image.NEAREST)
    width, height = art.size
    rng = random.Random(seed)
    rim = Image.new("RGBA", (width, rows + OVERLAP), (0, 0, 0, 0))
    for x0, x1, h, tilt in columns(width, rows, rng):
        w = x1 - x0
        for x in range(x0, x1):
            # The top falls by `tilt` across the column, from its high side.
            fall = round(abs(tilt) * ((x - x0) if tilt > 0 else (x1 - 1 - x)) / max(1, w - 1))
            top = rows - h + fall
            for r in range(top, rows + OVERLAP):
                rim.putpixel((x, r), art.getpixel((x, (r - rows) % height)))
            # Lit top face, a shaded front edge under it, a little ash on it; the corners stay plain.
            if x0 < x < x1 - 1:
                for i, colour in enumerate(CAP):
                    rim.putpixel((x, top + i), colour)
                rim.putpixel((x, top + len(CAP)), EDGE)
                if rng.random() < 0.3:
                    rim.putpixel((x, top), ASH)
            else:
                rim.putpixel((x, top), CAP[1])
        # The joint to the next column, fading out a few rows under the cap so no line reaches the wall's top.
        top = rows - h + (abs(tilt) if tilt > 0 else 0)
        for r in range(top, min(rows - 2, top + len(CAP) + rng.randint(3, 8))):
            rim.putpixel((x1 - 1, r), JOINT)
    rim.resize((width * 2, (rows + OVERLAP) * 2), Image.NEAREST).save(out_path)


if __name__ == "__main__":
    opts = dict(a[2:].split("=", 1) for a in sys.argv[3:] if a.startswith("--"))
    main(sys.argv[1], sys.argv[2], int(opts.get("rows", 32)), int(opts.get("seed", 30)))
