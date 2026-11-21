"""The Sun Guardian's burned shadow: one frame of its own sheet as a flat char silhouette (WORLD-17).

python -I tools/art/burned_shadow.py <sheet.png> <frame> <out.png> [--frame-width=192] [--alpha=136] [--flip]
    Cuts frame <frame> (art px, one art px per image px, as the guardian sheets are), keeps its opaque pixels as one
    flat char colour at <alpha> (0..255, so the basalt reads through), trims it to its opaque bounds and writes it at
    2x, the guardian's own Sprite2D scale. --flip mirrors it (the sheets face left).
"""
import sys

import numpy as np
from PIL import Image, ImageOps

CHAR = (24, 20, 20)


def main(args: list[str]) -> None:
    opts = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in args if a.startswith("--"))
    sheet, frame, out = [a for a in args if not a.startswith("--")]
    fw = int(opts.get("frame-width", 192))
    alpha = int(opts.get("alpha", 136))
    image = Image.open(sheet).convert("RGBA")
    cell = image.crop((int(frame) * fw, 0, (int(frame) + 1) * fw, image.height))
    mask = np.array(cell)[..., 3] > 0
    art = np.zeros((*mask.shape, 4), np.uint8)
    art[mask] = (*CHAR, alpha)
    shadow = Image.fromarray(art)
    shadow = shadow.crop(shadow.getbbox())
    if "flip" in opts:
        shadow = ImageOps.mirror(shadow)
    shadow.resize((shadow.width * 2, shadow.height * 2), Image.NEAREST).save(out)


if __name__ == "__main__":
    main(sys.argv[1:])
