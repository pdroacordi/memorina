"""Cut one magenta-keyed Codex drawing into a 2x-density prop PNG, in the colours of props we already have.

python -I tools/art/cut_single_prop.py <raw.png> <out.png> --width=ART_PX --palette=a.png,b.png,...
    The subject is the drawing's largest non-magenta part, cropped to its bounds and reduced to ART_PX art px wide
    (its height follows its aspect) by each block's most common colour, snapped to the colours the given props use and
    written at 2x. Prints the sheet's size, game px.
"""
import os
import sys

import numpy as np
from scipy import ndimage

# `python -I` leaves the script's own folder off the path.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cut_facades import keyed, palette_of, reduce, save_2x, snap_to  # noqa: E402


def main(raw: str, out: str, width: int, palette_paths: list[str]) -> None:
    rgb, solid = keyed(raw)
    labels, count = ndimage.label(solid)
    sizes = ndimage.sum(solid, labels, range(1, count + 1))
    subject = labels == (int(np.argmax(sizes)) + 1)
    ys, xs = np.nonzero(subject)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    height = round(width * (y1 - y0) / (x1 - x0))
    art = reduce(rgb[y0:y1, x0:x1], subject[y0:y1, x0:x1], width, height)
    snap_to([art], palette_of(palette_paths))
    image = save_2x(art, out)
    print(out, image.width, image.height)


if __name__ == "__main__":
    opts = dict(a[2:].split("=", 1) for a in sys.argv[3:] if a.startswith("--"))
    main(sys.argv[1], sys.argv[2], int(opts["width"]), opts["palette"].split(","))
