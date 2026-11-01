"""Clear the flute PixelLab drew at the mentor's mouth: his hand is empty (user, 2026-10-30, "Mão vazia erguida").

python -I tools/art/sources/guardians/mentor_no_flute.py <strip.png> <frame width> --rows=TOP-BOTTOM [--dark=100] [--max=7]
In each row of the band, a leading run of dark pixels (every channel <= --dark) at the row's left end, at most --max px
long and followed by a paler pixel, is the pipe's tip sticking out past the hand; it is cleared.
"""
import sys

import numpy as np
from PIL import Image

args = [a for a in sys.argv[1:] if not a.startswith("--")]
opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--"))
strip = np.array(Image.open(args[0]).convert("RGBA"))
fw = int(args[1]); top, bottom = map(int, opts["rows"].split("-"))
dark, most = int(opts.get("dark", 100)), int(opts.get("max", 7))
for k in range(strip.shape[1] // fw):
    f = strip[:, k * fw:(k + 1) * fw]
    cleared = 0
    for y in range(top, bottom):
        xs = np.nonzero(f[y, :, 3])[0]
        if not len(xs):
            continue
        x = xs[0]; run = 0
        while x + run < fw and f[y, x + run, 3] and (f[y, x + run, :3] <= dark).all():
            run += 1
        if 0 < run <= most and x + run < fw and f[y, x + run, 3]:
            f[y, x:x + run] = 0; cleared += run
    print(f"frame {k}: cleared {cleared} px")
Image.fromarray(strip).save(args[0])
