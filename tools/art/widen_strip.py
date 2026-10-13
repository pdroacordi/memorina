"""Widen every frame of a strip by repeating one plain art column, as stretch_prop.py repeats a plain band of rows.

python -I tools/art/widen_strip.py <in.png> <out.png> --frames=N --column=C --repeat=K
    Art column C of each frame (a run of string between two flags, say) is written K more times in place, so the frame
    grows by K art px and every frame keeps its own copy of that column. Pick a column holding only a plain line in
    every frame, or the repeat shows. Read and written at 2x.
"""
import sys

import numpy as np
from PIL import Image


def main(src: str, out: str, frames: int, column: int, repeat: int) -> None:
    sheet = np.array(Image.open(src).convert("RGBA"))
    art = sheet[::2, ::2]
    fw = art.shape[1] // frames
    widened = []
    for f in range(frames):
        frame = art[:, f * fw:(f + 1) * fw]
        band = np.repeat(frame[:, column:column + 1], repeat, axis=1)
        widened.append(np.concatenate([frame[:, :column + 1], band, frame[:, column + 1:]], axis=1))
    strip = np.concatenate(widened, axis=1)
    Image.fromarray(strip, "RGBA").resize((strip.shape[1] * 2, strip.shape[0] * 2), Image.NEAREST).save(out)
    print(f"{out}: {frames} frames of {(fw + repeat) * 2}x{strip.shape[0] * 2}")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(args[0], args[1], int(opts["frames"]), int(opts["column"]), int(opts["repeat"]))
