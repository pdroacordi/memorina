"""Crop every frame of a strip to the frames' shared opaque bounds, so the strip's bottom row is the prop's base.

python -I tools/art/trim_strip.py <in.png> <out.png> --frames=N [--bands=B]
    The strip holds N frames side by side (and B season bands stacked); one box, the union of every frame's and
    band's opaque pixels, is cut from each, so frames stay aligned and nothing floats over the floor. Edges stay on
    even game px (the 2x art grid).
"""
import sys

import numpy as np
from PIL import Image


def main(src: str, out: str, frames: int, bands: int) -> None:
    sheet = np.array(Image.open(src).convert("RGBA"))
    fw, fh = sheet.shape[1] // frames, sheet.shape[0] // bands
    cells = [sheet[b * fh:(b + 1) * fh, f * fw:(f + 1) * fw] for b in range(bands) for f in range(frames)]
    alpha = np.any([c[..., 3] > 0 for c in cells], axis=0)
    ys, xs = np.nonzero(alpha)
    y0, y1 = ys.min() // 2 * 2, (ys.max() + 2) // 2 * 2
    x0, x1 = xs.min() // 2 * 2, (xs.max() + 2) // 2 * 2
    rows = [np.concatenate([cells[b * frames + f][y0:y1, x0:x1] for f in range(frames)], axis=1) for b in range(bands)]
    Image.fromarray(np.concatenate(rows, axis=0), "RGBA").save(out)
    print(f"{out}: {frames} frames of {x1 - x0}x{y1 - y0}, {bands} band(s)")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(args[0], args[1], int(opts.get("frames", 1)), int(opts.get("bands", 1)))
