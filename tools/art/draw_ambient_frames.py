"""Procedural ambient frames for the village (architecture/props-and-ambient-life sections 5 and 4): lit panes and smoke.

Lights: python -I tools/art/draw_ambient_frames.py lights <facade.png> <out.png> [--frames=3]
    Finds the front's dark window panes (dark, mostly filled, 3x3 to 13x15 art px; the doorway recess reaches the
    bottom row and is skipped) and writes a strip of `frames` overlays the facade's size: each pane filled with three
    flat warm tones, its deep tone rising and falling per frame and the bright corner going out on one frame, a flame's
    flicker. No glow, no blend: the light is painted pixels, greyed by the greyhush like the wall around it.
Flame: python -I tools/art/draw_ambient_frames.py flame <lantern.png> <out.png> [--frames=3]
    A lantern's lit glass (its warm, bright pixels) flickers as one pane; the rest of the lantern is repeated per frame.
Swing: python -I tools/art/draw_ambient_frames.py swing <sign.png> <out.png> --hinge=ROW
    A hanging sign swaying on its hooks: art rows below the hinge row shift sideways in proportion to their distance
    from it, 0, +1, 0, -1 art px at the bottom over four frames (sheared, never rotated off the grid).
Smoke: python -I tools/art/draw_ambient_frames.py smoke <out.png> [--frames=8]
    A seamless loop of three puffs rising and drifting right, shrinking as they go, 12x32 art px per frame.
Both work on the art grid and write at 2x.
"""
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

WARM = [(170, 104, 52), (214, 150, 72), (240, 196, 110)]  # deep, base, bright
SMOKE_LIGHT, SMOKE_MID = (208, 206, 200), (172, 170, 166)
DEEP_FROM = (0.62, 0.5, 0.7)


def art_of(path: str) -> np.ndarray:
    image = Image.open(path).convert("RGBA")
    return np.array(image.resize((image.width // 2, image.height // 2), Image.NEAREST)).astype(int)


def panes(art: np.ndarray) -> list[np.ndarray]:
    dark = (art[..., 3] > 0) & (art[..., :3].sum(-1) < 110)
    labels, _count = ndimage.label(dark)
    found = []
    for i, box in enumerate(ndimage.find_objects(labels)):
        h, w = box[0].stop - box[0].start, box[1].stop - box[1].start
        area = (labels[box] == i + 1).sum()
        if box[0].stop >= art.shape[0] - 1:
            continue
        if w < 3 or h < 3 or w > 13 or h > 15 or area < 8 or area < 0.75 * w * h:
            continue
        found.append(labels == i + 1)
    return found


def lights(src: str, out: str, frames: int) -> None:
    art = art_of(src)
    write_panes(art, panes(art), np.zeros_like(art, dtype=np.uint8), out, frames)


def flame(src: str, out: str, frames: int) -> None:
    art = art_of(src)
    r, g, b = art[..., 0], art[..., 1], art[..., 2]
    glass = (art[..., 3] > 0) & (r > 170) & (g > 110) & (b < 130) & (r > b + 60)
    write_panes(art, [glass], art.astype(np.uint8), out, frames)


def write_panes(art: np.ndarray, found: list[np.ndarray], base: np.ndarray, out: str, frames: int) -> None:
    h, w = art.shape[:2]
    strip = np.concatenate([base] * frames, axis=1)
    for frame in range(frames):
        for k, mask in enumerate(found):
            ys, xs = np.nonzero(mask)
            y0, y1, x0 = ys.min(), ys.max(), xs.min()
            phase = (frame + k) % 3
            for y, x in zip(ys, xs):
                tone = 0 if (y - y0) / max(1, y1 - y0) > DEEP_FROM[phase] else 1
                if phase != 2 and y - y0 < 2 and x - x0 < 2:
                    tone = 2
                strip[y, frame * w + x] = (*WARM[tone], 255)
    Image.fromarray(strip, "RGBA").resize((w * frames * 2, h * 2), Image.NEAREST).save(out)
    print(f"{out}: {len(found)} panes, {frames} frames of {w * 2}x{h * 2}")


def swing(src: str, out: str, hinge: int) -> None:
    art = art_of(src).astype(np.uint8)
    h, w = art.shape[:2]
    pad = np.zeros((h, w + 2, 4), np.uint8)
    pad[:, 1:-1] = art
    frames = []
    for lean in (0, 1, 0, -1):
        frame = np.zeros_like(pad)
        for y in range(h):
            dx = round(lean * max(0, y - hinge) / max(1, h - 1 - hinge))
            frame[y] = np.roll(pad[y], dx, axis=0)
        frames.append(frame)
    strip = np.concatenate(frames, axis=1)
    Image.fromarray(strip, "RGBA").resize((strip.shape[1] * 2, h * 2), Image.NEAREST).save(out)
    print(f"{out}: 4 frames of {(w + 2) * 2}x{h * 2}")


def smoke(out: str, frames: int, w: int = 12, h: int = 32) -> None:
    strip = np.zeros((h, w * frames, 4), np.uint8)
    for f in range(frames):
        for p in range(3):
            t = ((f / frames) + p / 3) % 1.0
            cy, cx, r = h - 3 - t * (h - 6), 4 + t * 4 + (1 if p == 1 else 0), 3.2 - t * 2.0
            for y in range(h):
                for x in range(w):
                    if ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 <= r:
                        colour = SMOKE_LIGHT if (y < cy and x < cx + 1) else SMOKE_MID
                        strip[y, f * w + x] = (*colour, 255)
    Image.fromarray(strip, "RGBA").resize((w * frames * 2, h * 2), Image.NEAREST).save(out)
    print(f"{out}: {frames} frames of {w * 2}x{h * 2}")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    if args[0] == "lights":
        lights(args[1], args[2], int(opts.get("frames", 3)))
    elif args[0] == "swing":
        swing(args[1], args[2], int(opts["hinge"]))
    elif args[0] == "flame":
        flame(args[1], args[2], int(opts.get("frames", 3)))
    else:
        smoke(args[1], int(opts.get("frames", 8)))
