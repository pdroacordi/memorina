"""short_flute.py <strip.png> <out.png> [--length=14] [--span=15] [--rows=50]: redraw the bone pipe as a short flute.

Per 128 px frame: the pipe is the leftmost opaque part above --rows. Everything left of (its tip + length) above that
row is cleared; from there for --span px toward the mouth the pipe is redrawn 3 px thick along its own slope (top row
pale bone, middle bone with three dark finger holes, bottom shaded bone), the end column shaded, and the old pipe's
thicker underside cleared except where a hand grips it from below.
"""
import sys

import numpy as np
from PIL import Image

args = [a for a in sys.argv[1:] if not a.startswith("--")]
opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--"))
length, span, rows = int(opts.get("length", 14)), int(opts.get("span", 15)), int(opts.get("rows", 50))
P, M, O, HOLE = (242, 218, 183), (228, 185, 133), (208, 151, 99), (75, 32, 24)
BONE = {P, M, O}


def top_at(f, x):
	ys = [y for y in range(rows) if f[y, x, 3] and tuple(int(v) for v in f[y, x, :3]) in BONE]
	return min(ys)


s = np.array(Image.open(args[0]).convert("RGBA"))
for i in range(s.shape[1] // 128):
	f = s[:, i * 128:(i + 1) * 128]
	ys, xs = np.nonzero(f[:rows, :, 3])
	cut = int(xs.min()) + length
	f[:rows, :cut] = 0
	t0, t1 = top_at(f, cut), top_at(f, cut + span - 4)
	for k in range(span):
		x = cut + k
		t = int(round(t0 + (t1 - t0) * min(k, span - 4) / (span - 4)))
		f[t, x] = (*P, 255)
		f[t + 1, x] = (*(HOLE if k in (3, 6, 9) else M), 255)
		f[t + 2, x] = (*O, 255)
		# The old pipe was thicker: clear its underside unless a hand holds it from below.
		for y in (t + 3, t + 4):
			if k < span - 3 and f[y, x, 3] and not f[y + 1, x, 3]:
				f[y, x, 3] = 0
		if k < span - 3 and f[t - 1, x, 3] and tuple(int(v) for v in f[t - 1, x, :3]) in BONE and not f[t - 2, x, 3]:
			f[t - 1, x, 3] = 0
	f[t0:t0 + 3, cut, :3] = O
	f[f[..., 3] == 0] = 0
	print(f"frame {i}: tip {xs.min()} cut {cut} rows {t0}->{t1}")
Image.fromarray(s).save(args[1])
