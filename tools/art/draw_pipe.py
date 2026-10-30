"""Draw a guardian's pipe over chosen frames of a strip: a 4 px tube from the muzzle to its tip, with dark holes.

python -I tools/art/draw_pipe.py <strip.png> <frame width> <out.png> --line=X0,Y0,X1,Y1 [--frames=0,1,2]
    [--follow=<ref.png> --region=X0,Y0,X1,Y1] [--clear=X0,Y0,X1,Y1] [--colours=#light,#body,#shade,#hole] [--holes=5]
--line runs from the mouth end (X0,Y0) to the open end (X1,Y1), art px of a frame. --follow registers each chosen
frame against a single-frame reference (the integer shift, within 8 px, that best matches the opaque pixels of
--region, default rows 20-60: the head and the paws that hold the pipe) and moves the line and --clear with it, so the pipe stays at the muzzle while the body sways.
--clear makes a rectangle transparent first (a stub the generator drew). The tube's top row is the light colour, its
two middle rows the body colour, its bottom the shade; a 2x2 hole (the hole colour) sits on the middle rows every
--holes px from the open end, which is the hole colour too. Used where animate-with-text-v3 drew a pipe that read as
a block (the sun-lion, GRD-04).
"""
import sys

import numpy as np
from PIL import Image


def rgb(h: str) -> tuple:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shift_of(frame: np.ndarray, ref: np.ndarray, region: list) -> tuple:
    x0, y0, x1, y1 = region
    a = frame[y0:y1, x0:x1, 3] > 0
    best, arg = None, (0, 0)
    for dy in range(-8, 9):
        for dx in range(-8, 9):
            b = np.roll(np.roll(ref[..., 3] > 0, dy, 0), dx, 1)[y0:y1, x0:x1]
            score = int((a ^ b).sum())
            if best is None or score < best:
                best, arg = score, (dx, dy)
    return arg


def draw(frame: np.ndarray, line: list, colours: list, every: int) -> None:
    x0, y0, x1, y1 = line
    n = max(abs(x1 - x0), abs(y1 - y0))
    light, body, shade, hole = colours
    for i in range(n + 1):
        x = round(x0 + (x1 - x0) * i / n)
        y = round(y0 + (y1 - y0) * i / n)
        from_tip = n - i
        holed = from_tip == 0 or (i > 3 and from_tip % every in (every // 2, every // 2 + 1))
        mid = hole if holed else body
        for dy, colour in ((-1, light), (0, mid), (1, mid), (2, shade)):
            if 0 <= y + dy < frame.shape[0] and 0 <= x < frame.shape[1]:
                frame[y + dy, x] = (*colour, 255)


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--"))
    strip = np.array(Image.open(args[0]).convert("RGBA"))
    fw = int(args[1])
    line = [int(v) for v in opts["line"].split(",")]
    count = strip.shape[1] // fw
    frames = [int(v) for v in opts["frames"].split(",")] if "frames" in opts else list(range(count))
    ref = np.array(Image.open(opts["follow"]).convert("RGBA")) if "follow" in opts else None
    clear = [int(v) for v in opts["clear"].split(",")] if "clear" in opts else None
    colours = [rgb(c) for c in opts.get("colours", "#fbd180,#f9ba5d,#ca8d59,#3f2e33").split(",")]
    every = int(opts.get("holes", 5))
    for k in frames:
        frame = strip[:, k * fw:(k + 1) * fw]
        region = [int(v) for v in opts.get("region", f"0,20,{fw},60").split(",")]
        dx, dy = shift_of(frame, ref, region) if ref is not None else (0, 0)
        if clear:
            frame[clear[1] + dy:clear[3] + dy + 1, clear[0] + dx:clear[2] + dx + 1] = 0
        draw(frame, [line[0] + dx, line[1] + dy, line[2] + dx, line[3] + dy], colours, every)
        print(f"frame {k}: pipe shifted {dx},{dy}")
    Image.fromarray(strip).save(args[2])


if __name__ == "__main__":
    main()
