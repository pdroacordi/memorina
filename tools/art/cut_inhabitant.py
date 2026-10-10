"""Turn a PixelLab animation (frames at 2x) into an inhabitant's strip on the 2x grid, in its still's colours.

python -I tools/art/cut_inhabitant.py <frames dir> <name> <still.png> <out.png> [--frames=8]
Reads <name>_0.png .. <name>_<frames-1>.png (animate-with-text-v3 returns frames+1; the last one repeats the first, so
the loop closes and it is dropped), reduces each 2x2 block to its most common colour, snaps every pixel to the
nearest colour of the still (the frame the animation started from, at art size), and writes the frames side by side
at 2x (Sprite2D.hframes = frames).
"""
import sys
from collections import Counter

import numpy as np
from PIL import Image

ART_SCALE = 2


def to_art(frame):
    h, w = frame.shape[0] // ART_SCALE, frame.shape[1] // ART_SCALE
    art = np.zeros((h, w, 4), dtype=np.uint8)
    for y in range(h):
        for x in range(w):
            block = frame[y * ART_SCALE:(y + 1) * ART_SCALE, x * ART_SCALE:(x + 1) * ART_SCALE].reshape(-1, 4)
            opaque = block[block[:, 3] >= 128]
            # Alpha is binary: a block is opaque when most of it is.
            if len(opaque) * 2 > len(block):
                art[y, x, :3] = Counter(map(tuple, opaque[:, :3])).most_common(1)[0][0]
                art[y, x, 3] = 255
    return art


def main(frames_dir, name, still_path, out_path, frames):
    still = np.asarray(Image.open(still_path).convert("RGBA"))
    palette = np.array(sorted({tuple(c) for c in still[still[..., 3] > 0][:, :3]}), dtype=int)
    arts = []
    for i in range(frames):
        art = to_art(np.asarray(Image.open(f"{frames_dir}/{name}_{i}.png").convert("RGBA")))
        opaque = art[..., 3] > 0
        px = art[..., :3][opaque].astype(int)
        art[..., :3][opaque] = palette[((px[:, None] - palette[None]) ** 2).sum(-1).argmin(1)]
        arts.append(art)
    strip = Image.fromarray(np.concatenate(arts, axis=1), "RGBA")
    strip.resize((strip.width * ART_SCALE, strip.height * ART_SCALE), Image.NEAREST).save(out_path)
    print(f"{name}: {frames} frames of {arts[0].shape[1] * ART_SCALE}x{arts[0].shape[0] * ART_SCALE}")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(args[0], args[1], args[2], args[3], int(opts.get("frames", 8)))
