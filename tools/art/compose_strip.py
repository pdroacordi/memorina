"""Compose a strip from frames of other strips and stills, and optionally lift a colour ramp on chosen frames.

python -I tools/art/compose_strip.py <out.png> <frame width> <source>... [--lift=2,3:1] [--ramp=#4ca0f6,#78bef2,...]
                                     [--despeckle=3:10] [--grow=3,4:#d578a3 --grow-above=50]
A source is <strip.png>@<index> (one frame of a strip of <frame width> px frames) or a single-frame <still.png>; every
frame must be <frame width> wide and as tall as the first. Used where a one-shot must end on another clip's frame 0
exactly (a continuity frame), or a clip keeps the clean frames of several generations (systems/art-pipeline).
--lift=POSITIONS:STEPS moves every pixel of a --ramp colour STEPS colours up the ramp (clamped at its top) on those
sheet positions: the Frost crystals brightening on the beat without a new colour. --despeckle=POSITION:MIN clears
8-connected parts smaller than MIN px on that sheet position (an effect's loose flecks). --grow=POSITIONS:COLOUR
spreads every pixel of COLOUR one px into the transparent pixels left and right of it and above it, above game row
--grow-above: the Bloom antler blossoms opening on the beat.
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage


def frame_of(source: str, width: int) -> np.ndarray:
    path, _, index = source.partition("@")
    image = np.array(Image.open(path).convert("RGBA"))
    if not index:
        if image.shape[1] != width:
            sys.exit(f"{source}: {image.shape[1]} px wide, not {width}")
        return image
    k = int(index)
    if image.shape[1] < (k + 1) * width:
        sys.exit(f"{source}: the strip has no frame {k}")
    return image[:, k * width:(k + 1) * width].copy()


def lifted(frame: np.ndarray, ramp: list, steps: int) -> np.ndarray:
    out = frame.copy()
    for i, colour in enumerate(ramp):
        hit = (frame[..., 3] > 0) & (frame[..., :3] == colour).all(-1)
        out[hit, :3] = ramp[min(len(ramp) - 1, i + steps)]
    return out


def despeckled(frame: np.ndarray, least: int) -> np.ndarray:
    labels, count = ndimage.label(frame[..., 3] > 0, structure=np.ones((3, 3)))
    sizes = ndimage.sum(np.ones_like(labels), labels, range(1, count + 1))
    small = [i + 1 for i, s in enumerate(sizes) if s < least]
    frame[np.isin(labels, small)] = 0
    return frame


def grown(frame: np.ndarray, colour: tuple, above: int) -> np.ndarray:
    out = frame.copy()
    hit = (frame[..., 3] > 0) & (frame[..., :3] == colour).all(-1)
    hit[above:] = False
    for dy, dx in ((-1, 0), (0, -1), (0, 1)):
        moved = np.roll(np.roll(hit, dy, 0), dx, 1)
        free = moved & (out[..., 3] == 0)
        out[free, :3] = colour
        out[free, 3] = 255
    return out


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--"))
    out, width = args[0], int(args[1])
    frames = [frame_of(s, width) for s in args[2:]]
    if any(f.shape != frames[0].shape for f in frames):
        sys.exit("frames differ in size")
    for spec in filter(None, opts.get("despeckle", "").split(";")):
        position, least = spec.split(":")
        frames[int(position)] = despeckled(frames[int(position)], int(least))
    if opts.get("grow"):
        positions, colour = opts["grow"].split(":")
        rgb = tuple(int(colour.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))
        for p in map(int, positions.split(",")):
            frames[p] = grown(frames[p], rgb, int(opts.get("grow-above", frames[p].shape[0])))
    if opts.get("lift"):
        ramp = [tuple(int(c.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4)) for c in opts["ramp"].split(",")]
        for spec in opts["lift"].split(";"):
            positions, steps = spec.split(":")
            for p in map(int, positions.split(",")):
                frames[p] = lifted(frames[p], ramp, int(steps))
    Image.fromarray(np.concatenate(frames, axis=1), "RGBA").save(out)
    print(f"{out}: {len(frames)} frames of {width}x{frames[0].shape[0]}")


if __name__ == "__main__":
    main()
