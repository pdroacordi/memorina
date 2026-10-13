"""Turn a PixelLab still drawn at art size (1 px = 1 art px) into a 2x-density prop PNG.

python -I tools/art/clean_prop.py <in.png> <out.png> [--flat=N] [--base-shade] [--replace=#rrggbb:#rrggbb,...]
    Alpha becomes binary (opaque from 128), --replace repaints one exact colour with another, --flat=N reduces the
    object to N colours of its own and repaints specks (cut_props.flatten), --base-shade darkens the bottom row by a
    fifth, and the object is trimmed to its opaque bounds so its bottom row is its base. Written at 2x.
"""
import os
import sys

import numpy as np
from PIL import Image

# `python -I` leaves the script's own folder off the path.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cut_props import flatten, shade_base, trim  # noqa: E402
from cut_facades import save_2x  # noqa: E402


def hex_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)


def main(src: str, out: str, options: dict) -> None:
    art = np.array(Image.open(src).convert("RGBA"))
    opaque = art[..., 3] >= 128
    art[..., 3] = np.where(opaque, 255, 0)
    art[~opaque] = 0
    for pair in (p for p in options.get("replace", "").split(",") if p):
        before, after = (hex_rgb(c) for c in pair.split(":"))
        hit = (art[..., :3] == before).all(-1) & opaque
        art[hit, :3] = after
    if "flat" in options:
        flatten(art, int(options["flat"]))
    art = trim(art).copy()
    if "base-shade" in options:
        shade_base(art)
    image = save_2x(art, out)
    print(f"{os.path.basename(out)} {image.width}x{image.height}")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(args[0], args[1], opts)
