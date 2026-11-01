"""Lean every frame of a strip back above a pivot row: the mentor's past self stands straighter than the guardian.

python -I tools/art/sources/guardians/mentor_upright.py <in.png> <out.png> <frame width> --pivot=ROW --lean=PX
Rows above --pivot move toward +x (back, for a west-facing body) in proportion, up to --lean px at the top opaque row.
"""
import sys

import numpy as np
from PIL import Image

args = [a for a in sys.argv[1:] if not a.startswith("--")]
opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--"))
src = np.array(Image.open(args[0]).convert("RGBA"))
fw, pivot, lean = int(args[2]), int(opts["pivot"]), int(opts["lean"])
out = np.zeros_like(src)
for k in range(src.shape[1] // fw):
    f = src[:, k * fw:(k + 1) * fw]
    top = int(np.nonzero(f[..., 3].any(1))[0].min())
    o = out[:, k * fw:(k + 1) * fw]
    for y in range(f.shape[0]):
        dx = 0 if y >= pivot else round(lean * (pivot - y) / (pivot - top))
        o[y, dx:] = f[y, :fw - dx]
Image.fromarray(out).save(args[1])
