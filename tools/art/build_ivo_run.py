"""Build Ivo's run sheet from PixelLab's frames: cut, settle the flight frames, recolour the jaw's stubble.

python -I tools/art/build_ivo_run.py [--out=<png>] [--preview=<dir>]
Cuts the kept frames of tools/art/sources/ivo/run_v5/ivo_run_t2_passing/ (animate-with-text-v3, 64 px) exactly as
`cut_inhabitant.py ... --keep=2-3,5-8,0-1 --frame=128 --at=32,34 --centre=0-128` does. Then each ground frame's lowest
pixel goes on the floor line (row 95); a FLIGHT frame keeps PixelLab's own height above the take's ground level,
limited to 1-3 art px. Last, STUBBLE pixels in the top HEAD_ROWS rows of the figure become SKIN. The run clip keeps 8
frames at 1/12 s (architecture/ivo-at-2x). --preview writes preview_run.png (6x, floor line) and preview_run.gif
(4x, 12 fps) into the directory.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

# `python -I` leaves the script's own folder off the path.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cut_inhabitant import framed, settled, to_art  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TAKE = os.path.join(ROOT, "tools/art/sources/ivo/run_v5/ivo_run_t2_passing")
PALETTE = os.path.join(ROOT, "tools/art/sources/ivo/ivo_palette.png")
OUT = os.path.join(ROOT, "assets/sprites/characters/ivo/ivo_run.png")
SIDE = 64  # art px: a 128 game px frame
FLOOR = 47  # art row of the feet
AXIS = (SIDE - 1) / 2
KEEP = [2, 3, 5, 6, 7, 8, 0, 1]  # returned frames, in sheet order: contact, down, push-off, flight, twice
FLIGHT = {3, 4, 7}  # sheet frames with both boots off the floor
LIFT = (1, 3)  # art px: a flight frame's height above the floor
HEAD_ROWS = 10  # art rows from the top of the figure: the head, above the shirt
STUBBLE = (141, 115, 63)  # the olive PixelLab put on his jaw (architecture/ivo-at-2x, sixth round)
SKIN = (191, 126, 74)
SPEED = 8  # art px per frame: move_speed 192 px/s at 12 fps is 16 game px
BACKDROP = (58, 66, 74, 255)


def cut():
    """The kept frames in art px, snapped and framed as cut_inhabitant.py does, centred on the axis."""
    still = np.asarray(Image.open(PALETTE).convert("RGBA"))
    palette = np.array(sorted({tuple(c) for c in still[still[..., 3] > 0][:, :3]}), dtype=int)
    arts = []
    for index in KEEP:
        art = to_art(np.asarray(Image.open(f"{TAKE}/ivo_run_t2_passing_{index}.png").convert("RGBA")))
        opaque = art[..., 3] > 0
        px = art[..., :3][opaque].astype(int)
        art[..., :3][opaque] = palette[((px[:, None] - palette[None]) ** 2).sum(-1).argmin(1)]
        art = framed(art, SIDE * 2, (32, 34), f"ivo_run_t2_passing_{index}")
        arts.append(settled(art, 0, (0, SIDE * 2), f"ivo_run_t2_passing_{index}"))
    return arts


def settle(arts):
    """Ground frames on the floor line; flight frames at PixelLab's own lift, limited to LIFT."""
    lowest = [np.nonzero(art[..., 3])[0].max() for art in arts]
    ground = int(round(np.median([low for i, low in enumerate(lowest) if i not in FLIGHT])))
    out = []
    for i, art in enumerate(arts):
        lift = min(LIFT[1], max(LIFT[0], ground - lowest[i])) if i in FLIGHT else 0
        out.append(np.roll(art, FLOOR - lift - lowest[i], axis=0))
    return out


def shave(art):
    top = np.nonzero(art[..., 3])[0].min()
    head = art[top:top + HEAD_ROWS]
    stubble = (head[..., 3] > 0) & (head[..., :3] == STUBBLE).all(-1)
    head[stubble, :3] = SKIN
    return art


def report(arts):
    print("frame  head-y  lowest  boot-x  slip  centroid-x   (art px; x from the axis, slip 0 = no sliding)")
    previous = None
    for i, art in enumerate(arts):
        ys, xs = np.nonzero(art[..., 3])
        head = ys[ys < ys.min() + HEAD_ROWS].mean()
        low = ys.max()
        boot = xs[ys == low].mean() - AXIS
        slip = boot - previous + SPEED if previous is not None and low == FLOOR else float("nan")
        print(f"{i:5} {head:7.1f} {low:7} {boot:7.1f} {slip:5.1f} {xs.mean() - AXIS:11.1f}")
        previous = boot if low == FLOOR else None


def save_previews(arts, preview):
    strip = np.concatenate(arts, axis=1)
    big = Image.new("RGBA", (strip.shape[1], SIDE), BACKDROP)
    big.alpha_composite(Image.fromarray(strip, "RGBA"))
    big = big.resize((big.width * 12, big.height * 12), Image.NEAREST)  # 6x the 2x game sheet
    draw = ImageDraw.Draw(big)
    draw.line([(0, (FLOOR + 1) * 12), (big.width, (FLOOR + 1) * 12)], fill=(220, 90, 60, 255), width=2)
    for i in range(1, len(arts)):
        draw.line([(i * SIDE * 12, 0), (i * SIDE * 12, big.height)], fill=(80, 90, 100, 255), width=1)
    big.save(os.path.join(preview, "preview_run.png"))
    gif = []
    for art in arts:
        frame = Image.new("RGBA", (SIDE, SIDE), BACKDROP)
        frame.alpha_composite(Image.fromarray(art, "RGBA"))
        frame = frame.resize((SIDE * 8, SIDE * 8), Image.NEAREST)  # 4x the 2x game frame
        ImageDraw.Draw(frame).line([(0, (FLOOR + 1) * 8), (SIDE * 8, (FLOOR + 1) * 8)], fill=(120, 130, 140), width=1)
        gif.append(frame.convert("RGB"))
    gif[0].save(os.path.join(preview, "preview_run.gif"), save_all=True, append_images=gif[1:], duration=83, loop=0)


def main(out, preview):
    arts = [shave(art) for art in settle(cut())]
    strip = Image.fromarray(np.concatenate(arts, axis=1), "RGBA")
    strip.resize((strip.width * 2, strip.height * 2), Image.NEAREST).save(out)
    report(arts)
    if preview:
        save_previews(arts, preview)


if __name__ == "__main__":
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(opts.get("out") or OUT, opts.get("preview", ""))
