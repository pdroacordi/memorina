"""Stretch a cut prop's top up to a given height (a chimney breast rising to the ceiling).

python -I tools/art/stretch_prop.py <in.png> <out.png> <height px>
Repeats the band between 12% and 36% of the sprite's height (even rows, so the 2x pixel grid holds) until the sprite
is <height> px tall. Above the band's end only the columns solid through 80% of the band are kept, so the cap and the
stray pixels beside the breast do not repeat up its side.
"""
import sys

import numpy as np
from PIL import Image


def stretch(src: str, dst: str, height: int) -> None:
    im = np.asarray(Image.open(src).convert("RGBA")).copy()
    h = im.shape[0]
    a = (int(h * 0.12) // 2) * 2
    b = (int(h * 0.36) // 2) * 2
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
    stretch(sys.argv[1], sys.argv[2], int(sys.argv[3]))
