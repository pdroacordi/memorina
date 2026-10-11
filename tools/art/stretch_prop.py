"""Stretch a cut prop's top up to a given height (a chimney breast rising to the ceiling).

python -I tools/art/stretch_prop.py <in.png> <out.png> <height px> [--band=TOP:BOTTOM]
Repeats a band of rows (default 12% to 36% of the sprite's height; --band names it in px) until the sprite is
<height> px tall; band ends are rounded to even rows so the 2x pixel grid holds. Above the band's end only the columns solid through 80% of the band are kept, so the cap and the
stray pixels beside the breast do not repeat up its side.
"""
import sys

import numpy as np
from PIL import Image


def stretch(src: str, dst: str, height: int, band: tuple[int, int] | None = None) -> None:
    im = np.asarray(Image.open(src).convert("RGBA")).copy()
    h = im.shape[0]
    top, bottom = band if band else (int(h * 0.12), int(h * 0.36))
    a = (top // 2) * 2
    b = (bottom // 2) * 2
    solid = (im[a:b, :, 3] > 0).mean(axis=0) > 0.8
    im[:b, ~solid] = 0
    band = im[a:b]
    parts, grown = [im[:b]], h
    while grown < height:
        take = min(band.shape[0], height - grown)
        parts.append(band[:take])
        grown += take
    parts.append(im[b:])
    Image.fromarray(np.concatenate(parts), "RGBA").save(dst)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    band_opt = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--band=")), None)
    stretch(args[0], args[1], int(args[2]), tuple(map(int, band_opt.split(":"))) if band_opt else None)
