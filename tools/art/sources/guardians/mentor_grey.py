"""Grey a strip of the mentor's colour palette into the stasis still's greys, pixel for pixel.

python -I tools/art/sources/guardians/mentor_grey.py <in.png> <out.png>
The map is read from empty_hand.png and stasis.png, which are the same figure pixel for pixel.
"""
import sys

import numpy as np
from PIL import Image

colour = np.array(Image.open("assets/sprites/world/story/mentor/empty_hand.png").convert("RGBA"))
grey = np.array(Image.open("assets/sprites/world/story/mentor/stasis.png").convert("RGBA"))
mask = colour[..., 3] > 0
table = {tuple(c): g for c, g in zip(colour[mask][:, :3], grey[mask][:, :3])}
src = np.array(Image.open(sys.argv[1]).convert("RGBA"))
out = src.copy()
for y, x in zip(*np.nonzero(src[..., 3] > 0)):
    out[y, x, :3] = table[tuple(src[y, x, :3])]
Image.fromarray(out).save(sys.argv[2])
