"""Stretch a cut prop's top up to a given height (a chimney breast rising to the ceiling).

python -I tools/art/stretch_prop.py <in.png> <out.png> <height px> [--band=TOP:BOTTOM] [--bricks]
Repeats a band of rows (default 12% to 36% of the sprite's height; --band names it in px) until the sprite is
<height> px tall; band ends are rounded to even rows so the 2x pixel grid holds. Above the band's end only the columns solid through 80% of the band are kept, so the cap and the
stray pixels beside the breast do not repeat up its side. --bricks fills the added rows with a running bond of 6x3
art px blocks in the band's most common colour, with its darkest common colour (or the stone a fifth darker) as mortar, instead of repeating a band too
short to tile without stripes.
"""
import sys
from collections import Counter

import numpy as np
from PIL import Image


def bricks(band: np.ndarray, rows: int) -> np.ndarray:
    """A running bond `rows` px tall over the band's opaque columns, at 2x (one art px is 2x2)."""
    solid = band[..., 3].max(axis=0) > 0
    colours = [np.array(c) for c, _n in Counter(tuple(c) for c in band[band[..., 3] > 0][:, :3]).most_common(4)]
    stone = colours[0]
    mortar = min(colours, key=lambda c: int(c.sum()))
    if int(stone.sum()) - int(mortar.sum()) < 60:
        mortar = stone * 4 // 5
    out = np.zeros((rows, band.shape[1], 4), dtype=np.uint8)
    for y in range(rows):
        ay = y // 2
        course = ay // 3
        for x in np.nonzero(solid)[0]:
            ax = x // 2 + (3 if course % 2 else 0)
            out[y, x, :3] = mortar if ay % 3 == 0 or ax % 6 == 0 else stone
            out[y, x, 3] = 255
    return out


def stretch(src: str, dst: str, height: int, band: tuple[int, int] | None = None, brick: bool = False) -> None:
    im = np.asarray(Image.open(src).convert("RGBA")).copy()
    h = im.shape[0]
    top, bottom = band if band else (int(h * 0.12), int(h * 0.36))
    a = (top // 2) * 2
    b = (bottom // 2) * 2
    solid = (im[a:b, :, 3] > 0).mean(axis=0) > 0.8
    im[:b, ~solid] = 0
    band = im[a:b]
    parts, grown = [im[:b]], h
    if brick and height > h:
        parts.append(bricks(band, height - h))
        grown = height
    while grown < height:
        take = min(band.shape[0], height - grown)
        parts.append(band[:take])
        grown += take
    parts.append(im[b:])
    Image.fromarray(np.concatenate(parts), "RGBA").save(dst)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    band_opt = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--band=")), None)
    stretch(args[0], args[1], int(args[2]), tuple(map(int, band_opt.split(":"))) if band_opt else None, "--bricks" in sys.argv)
