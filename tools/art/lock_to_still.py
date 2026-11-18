"""Lock a cut animation to a still: frame 0 is the still, and later frames draw only what moved (STORY-37's mentor).

python -I tools/art/lock_to_still.py <cut.png> <still.png> <out.png> --keep=0,1,2,3 [--mirror] [--still-box=x0,y0,x1,y1]
<cut.png> is a strip of 128 px frames (from cut_inhabitant.py); <still.png> one 128x128 frame on the target canvas.
--mirror flips each cut frame first (a generation from an east-facing reference, stored facing west). Each frame is
shifted by the even offset that best lays the generation's frame 0 on the still; a kept frame is the still with only the
pixels that differ from the generation's own frame 0 drawn over it, so nothing that does not move ever changes. Parts
under 4 art px are cleared. --still-box restores the still's pixels in that box on every frame (a hand that must hold
still). Our own art only.
"""
import sys

import numpy as np
from PIL import Image, ImageOps
from scipy import ndimage


def specks_cleared(a: np.ndarray) -> np.ndarray:
    labels, n = ndimage.label(a[:, :, 3] > 0)
    sizes = ndimage.sum(np.ones_like(labels), labels, range(1, n + 1))
    for i, size in enumerate(sizes, 1):
        if size < 16:
            a[labels == i] = 0
    return a


def shifted(a: np.ndarray, dx: int, dy: int) -> np.ndarray:
    out = Image.new("RGBA", (a.shape[1], a.shape[0]))
    out.alpha_composite(Image.fromarray(a), (max(dx, 0), max(dy, 0)), (max(-dx, 0), max(-dy, 0)))
    return np.array(out)


def best_shift(moving: np.ndarray, target: np.ndarray) -> tuple:
    m, t = moving[:, :, 3] > 0, target[:, :, 3] > 0
    tries = [(int(np.sum(np.roll(np.roll(m, dy, 0), dx, 1) != t)), dx, dy)
             for dx in range(-8, 9, 2) for dy in range(-8, 9, 2)]
    return min(tries)[1:]


def main(argv: list) -> None:
    args = [a for a in argv if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in argv if a.startswith("--"))
    sheet = Image.open(args[0]).convert("RGBA")
    still = np.array(Image.open(args[1]).convert("RGBA"))
    keep = [int(v) for v in opts["keep"].split(",")]
    raw = []
    for i in range(sheet.width // 128):
        frame = sheet.crop((128 * i, 0, 128 * i + 128, 128))
        raw.append(specks_cleared(np.array(ImageOps.mirror(frame) if "mirror" in opts else frame)))
    dx, dy = best_shift(raw[0], still)
    base = shifted(raw[0], dx, dy)
    box = tuple(int(v) for v in opts["still-box"].split(",")) if opts.get("still-box") else None
    out = Image.new("RGBA", (128 * len(keep), 128))
    for k, i in enumerate(keep):
        frame = shifted(raw[i], dx, dy)
        moved = np.any(frame != base, axis=2)
        made = still.copy()
        made[moved] = frame[moved]
        made = specks_cleared(made) if k > 0 else still.copy()
        if box is not None:
            made[box[1]:box[3], box[0]:box[2]] = still[box[1]:box[3], box[0]:box[2]]
        out.alpha_composite(Image.fromarray(made), (128 * k, 0))
    out.save(args[2])
    print(f"{args[2]}: {len(keep)} frames, shift {dx},{dy}")


if __name__ == "__main__":
    main(sys.argv[1:])
