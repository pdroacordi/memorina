"""Make a recoil strip from one frame by leaning the body back above a pivot row.

python -I tools/art/lean_frames.py <frame.png> <out.png> --pivot=ROW --lean=0,5,9,8,6,3,1 [--back=1]
Each value of --lean makes one frame: the frame's top opaque row moves that many px, rows between it and --pivot
move in proportion (whole px), rows below the pivot stay. --back=1 leans toward +x (a west-facing body thrown
back); -1 leans toward -x. Used where animate-with-text-v3 painted effects into every recoil frame.
"""
import sys

import numpy as np
from PIL import Image


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--"))
    src = np.array(Image.open(args[0]).convert("RGBA"))
    pivot = int(opts["pivot"])
    leans = [int(v) for v in opts["lean"].split(",")]
    sign = int(opts.get("back", 1))
    h, w = src.shape[:2]
    top = int(np.nonzero(src[..., 3].any(1))[0].min())
    frames = []
    for lean in leans:
        out = np.zeros_like(src)
        for y in range(h):
            dx = 0 if y >= pivot else round(lean * (pivot - y) / (pivot - top)) * sign
            row = src[y]
            if dx > 0:
                out[y, dx:] = row[:w - dx]
            elif dx < 0:
                out[y, :w + dx] = row[-dx:]
            else:
                out[y] = row
        frames.append(out)
    Image.fromarray(np.concatenate(frames, axis=1)).save(args[1])


if __name__ == "__main__":
    main()
