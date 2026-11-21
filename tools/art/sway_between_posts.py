"""Sway what hangs between two posts (a net, fish on a rack) on the art grid, the posts and crossbar held still.

python -I tools/art/sway_between_posts.py <still.png> <out.png> --posts=L,R --hinge=ROW [--frames=4]
    <still.png> is a 2x prop. Art columns L+1..R-1 below art row ROW shift sideways in proportion to their distance
    below it, 0, +1, 0, -1 art px at the lowest row over four frames (sheared, never rotated off the grid); columns
    outside L..R and rows at or above ROW are repeated unchanged. Writes the frames side by side at 2x.
"""
import sys

import numpy as np
from PIL import Image


def main(args: list[str]) -> None:
    opts = dict(a[2:].split("=", 1) for a in args if a.startswith("--"))
    src, out = [a for a in args if not a.startswith("--")]
    left, right = (int(v) for v in opts["posts"].split(","))
    hinge = int(opts["hinge"])
    frames = int(opts.get("frames", 4))
    art = np.array(Image.open(src).convert("RGBA"))[::2, ::2]
    h, w = art.shape[:2]
    depth = max(1, h - 1 - hinge)
    swing = [0, 1, 0, -1] if frames == 4 else [round(np.sin(2 * np.pi * i / frames)) for i in range(frames)]
    strip = np.zeros((h, w * frames, 4), np.uint8)
    for f in range(frames):
        frame = art.copy()
        inner = art[hinge + 1:, left + 1:right].copy()
        frame[hinge + 1:, left + 1:right] = 0
        for r in range(inner.shape[0]):
            dx = round(swing[f] * (r + 1) / depth)
            row = np.roll(inner[r], dx, axis=0)
            if dx > 0:
                row[:dx] = 0
            elif dx < 0:
                row[dx:] = 0
            target = frame[hinge + 1 + r, left + 1:right]
            keep = row[:, 3] > 0
            target[keep] = row[keep]
        strip[:, f * w:(f + 1) * w] = frame
    Image.fromarray(strip).resize((w * frames * 2, h * 2), Image.NEAREST).save(out)


if __name__ == "__main__":
    main(sys.argv[1:])
