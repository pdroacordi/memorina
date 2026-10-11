"""Turn a PixelLab animation (frames at 2x) into an inhabitant's strip on the 2x grid, in its still's colours.

python -I tools/art/cut_inhabitant.py <frames dir> <name> <still.png> <out.png> [--frames=8] [--keep=a-b[,c-d]]
    [--frame=128 --at=x,y] [--strip=64]
Reads <name>_<i>.png (animate-with-text-v3 returns frames 0..N, N usually repeating 0). By default it keeps
0..frames-1, so a loop closes; --keep lists the frames kept in sheet order, each range inclusive and allowed to run
downwards (a one-shot that returns to its first pose keeps 1..N-1 or 1..N; 5-10,9-6 is a ping-pong loop;
architecture/ivo-at-2x). Each 2x2 block becomes its most common colour and every pixel snaps to the nearest colour of
the still (the frame the animation started from, or a palette strip). With --frame each frame is pasted onto a
transparent square of that size with its top-left at x,y (even game px); a frame cut by the square is an error.
The frames are written side by side at 2x (Sprite2D.hframes = frames kept). --strip=W reads <name>.png, an already cut
strip of W px frames, instead of PixelLab's frame files (an approved pilot re-framed).
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


def framed(art, size, at, label):
    """Pastes art onto a transparent size x size square (game px) with its top-left at `at` (game px)."""
    side = size // ART_SCALE
    ox, oy = at[0] // ART_SCALE, at[1] // ART_SCALE
    out = np.zeros((side, side, 4), dtype=np.uint8)
    ys, xs = np.nonzero(art[..., 3])
    if len(ys) and (ys.min() + oy < 0 or xs.min() + ox < 0 or ys.max() + oy >= side or xs.max() + ox >= side):
        sys.exit(f"{label}: the frame does not fit a {size} px square at {at[0]},{at[1]}")
    y0, x0 = max(0, oy), max(0, ox)
    y1, x1 = min(side, oy + art.shape[0]), min(side, ox + art.shape[1])
    out[y0:y1, x0:x1] = art[y0 - oy:y1 - oy, x0 - ox:x1 - ox]
    return out


def source_frame(frames_dir, name, index, strip_width):
    if strip_width:
        strip = np.asarray(Image.open(f"{frames_dir}/{name}.png").convert("RGBA"))
        return strip[:, index * strip_width:(index + 1) * strip_width]
    return np.asarray(Image.open(f"{frames_dir}/{name}_{index}.png").convert("RGBA"))


def main(frames_dir, name, still_path, out_path, keep, size, at, strip_width):
    still = np.asarray(Image.open(still_path).convert("RGBA"))
    palette = np.array(sorted({tuple(c) for c in still[still[..., 3] > 0][:, :3]}), dtype=int)
    arts = []
    for i in keep:
        art = to_art(source_frame(frames_dir, name, i, strip_width))
        opaque = art[..., 3] > 0
        px = art[..., :3][opaque].astype(int)
        art[..., :3][opaque] = palette[((px[:, None] - palette[None]) ** 2).sum(-1).argmin(1)]
        arts.append(framed(art, size, at, f"{name}_{i}") if size else art)
    strip = Image.fromarray(np.concatenate(arts, axis=1), "RGBA")
    strip.resize((strip.width * ART_SCALE, strip.height * ART_SCALE), Image.NEAREST).save(out_path)
    print(f"{name}: frames {','.join(map(str, keep))} ({len(arts)}) of {arts[0].shape[1] * ART_SCALE}x{arts[0].shape[0] * ART_SCALE}")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    keep = []
    for segment in opts.get("keep", f"0-{int(opts.get('frames', 8)) - 1}").split(","):
        bounds = segment.split("-")
        if len(bounds) != 2 or not all(b.strip().isdigit() for b in bounds):
            sys.exit(f"--keep: '{segment}' is not a range a-b (one frame is 6-6)")
        first, last = int(bounds[0]), int(bounds[1])
        keep += list(range(first, last + 1)) if last >= first else list(range(first, last - 1, -1))
    offset = tuple(map(int, opts.get("at", "0,0").split(",")))
    if offset[0] % ART_SCALE or offset[1] % ART_SCALE:
        sys.exit("--at must be even game px, on the 2x grid")
    main(args[0], args[1], args[2], args[3], keep, int(opts.get("frame", 0)), offset, int(opts.get("strip", 0)))
