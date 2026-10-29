"""Clear stray specks from a cut strip: every 8-connected part of a frame smaller than --min px goes.

python -I tools/art/despeckle.py <strip.png> <frame width> [--min=6] [--out=<png>]
PixelLab leaves a few loose pixels of an effect behind after cut_inhabitant.py snaps and drops; they are smaller
than any body part a guardian draws. Prints what it cleared per frame. Writes in place unless --out is given.
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--"))
    path, fw = args[0], int(args[1])
    least = int(opts.get("min", 6))
    out = opts.get("out", path)
    strip = np.array(Image.open(path).convert("RGBA"))
    for k in range(strip.shape[1] // fw):
        frame = strip[:, k * fw:(k + 1) * fw]
        labels, count = ndimage.label(frame[..., 3] > 0, structure=np.ones((3, 3)))
        sizes = ndimage.sum(np.ones_like(labels), labels, range(1, count + 1))
        small = [i + 1 for i, s in enumerate(sizes) if s < least]
        if small:
            frame[np.isin(labels, small)] = 0
            print(f"frame {k}: cleared {len(small)} part(s), {int(sum(sizes[i - 1] for i in small))} px")
    Image.fromarray(strip).save(out)


if __name__ == "__main__":
    main()
