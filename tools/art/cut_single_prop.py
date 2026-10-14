"""Cut one magenta-keyed Codex drawing into a 2x-density prop PNG, in the colours of props we already have.

python -I tools/art/cut_single_prop.py <raw.png> <out.png> --width=ART_PX --palette=a.png,b.png,...
        [--height=ART_PX] [--parts] [--colors=N]
    The subject is the drawing's largest non-magenta part, cropped to its bounds and reduced to ART_PX art px wide
    (its height follows its aspect) by each block's most common colour, snapped to the colours the given props use and
    written at 2x. Prints the sheet's size, game px.
    --height fixes the height too (a slight stretch, for a contract's exact size); --parts keeps every part at least 2%
    of the largest (a tangle drawn in pieces); --colors reduces the snapped art to N colours (a busy drawing that
    would read as speckle at its size).
"""
import os
import sys

import numpy as np
from scipy import ndimage

# `python -I` leaves the script's own folder off the path.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cut_facades import keyed, palette_of, reduce, save_2x, snap_to  # noqa: E402


def main(raw: str, out: str, width: int, palette_paths: list[str], height: int = 0, parts: bool = False,
        colors: int = 0) -> None:
    rgb, solid = keyed(raw)
    labels, count = ndimage.label(solid)
    sizes = ndimage.sum(solid, labels, range(1, count + 1))
    if parts:
        subject = np.isin(labels, [i + 1 for i, size in enumerate(sizes) if size >= sizes.max() * 0.02])
    else:
        subject = labels == (int(np.argmax(sizes)) + 1)
    ys, xs = np.nonzero(subject)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    if height <= 0:
        height = round(width * (y1 - y0) / (x1 - x0))
    art = reduce(rgb[y0:y1, x0:x1], subject[y0:y1, x0:x1], width, height)
    snap_to([art], palette_of(palette_paths))
    if colors > 0:
        art = fewer_colors(art, colors)
    image = save_2x(art, out)
    print(out, image.width, image.height)


def fewer_colors(art, colors: int):
    """The opaque pixels reduced to `colors` colours by median cut; transparency kept."""
    from PIL import Image
    image = Image.fromarray(art, "RGBA")
    rgb = image.convert("RGB").quantize(colors=colors, method=Image.Quantize.MEDIANCUT).convert("RGB")
    return np.array(Image.merge("RGBA", (*rgb.split(), image.getchannel("A"))))


if __name__ == "__main__":
    opts = dict(a[2:].split("=", 1) for a in sys.argv[3:] if a.startswith("--") and "=" in a)
    main(sys.argv[1], sys.argv[2], int(opts["width"]), opts["palette"].split(","), int(opts.get("height", 0)),
         "--parts" in sys.argv[3:], int(opts.get("colors", 0)))
