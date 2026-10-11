"""Cut one object drawn against a stone wall on an approved board (no magenta around it) into a 2x-density prop PNG.

python -I tools/art/cut_board_prop.py <board.png> <out.png> --box=x0,y0,x1,y1 --art-per-px=F [--colors=12] [--luma=75]
    [--opening=3] [--warm=0]
    The object is what is dark (luma below --luma) or not warm (red less than --warm above both green and blue) inside
    the box: the wall's ochre stones and their mortar are neither. Lines thinner than --opening board px are dropped,
    holes filled, and only the part touching the box's centre is kept. It is reduced to F art px per board px by each
    block's most common colour, snapped to --colors and written at 2x. Prints the sheet's size, game px.
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

# `python -I` leaves the script's own folder off the path.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cut_facades import LUMA, reduce, save_2x, snap  # noqa: E402


def main(board: str, out: str, box: list[int], art_per_px: float, colors: int, luma: float, opening: int, warm: int) -> None:
    rgb = np.asarray(Image.open(board).convert("RGB")).astype(int)
    x0, y0, x1, y1 = box
    part = rgb[y0:y1, x0:x1]
    mask = (part @ LUMA < luma) | (part[..., 0] - np.maximum(part[..., 1], part[..., 2]) < warm)
    # Mortar joints are as grey as the object; opening drops lines thinner than the object's parts.
    mask = ndimage.binary_fill_holes(ndimage.binary_opening(mask, iterations=opening))
    labels, _count = ndimage.label(mask)
    centre = labels[part.shape[0] // 2, part.shape[1] // 2]
    assert centre > 0, "the box's centre is not on the object"
    mask = labels == centre
    ys, xs = np.nonzero(mask)
    part, mask = part[ys.min():ys.max() + 1, xs.min():xs.max() + 1], mask[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    art = reduce(part, mask, max(1, round(part.shape[1] * art_per_px)), max(1, round(part.shape[0] * art_per_px)))
    snap([art], colors)
    image = save_2x(art, out)
    print(f"{os.path.basename(out)} {image.width}x{image.height}")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(args[0], args[1], [int(v) for v in opts["box"].split(",")], float(opts["art-per-px"]),
        int(opts.get("colors", 12)), float(opts.get("luma", 75)), int(opts.get("opening", 3)), int(opts.get("warm", 0)))
