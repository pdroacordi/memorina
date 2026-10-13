"""Stack a nature prop's spring art into its three season bands (spring, autumn, winter; systems/seasonal-art).

python -I tools/art/season_bands.py <spring.png> <out.png>
    The spring strip is band 0 unchanged. Autumn and winter are recolours of it, so the silhouette holds: every
    foliage pixel (green hue) is mapped by its brightness rank onto a flat autumn ramp (rust to amber) or a winter ramp
    (blue-grey to snow); wood, stone, pots and flowers keep their colours. No new shape, no blending.
"""
import colorsys
import sys

import numpy as np
from PIL import Image

AUTUMN = [(110, 52, 30), (156, 74, 34), (196, 108, 44), (226, 152, 64)]
WINTER = [(122, 132, 146), (168, 180, 192), (210, 218, 226), (240, 244, 248)]


def foliage(rgb: tuple) -> bool:
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    return 60 / 360 <= h <= 170 / 360 and s > 0.18 and v > 0.12


def recolour(art: np.ndarray, ramp: list) -> np.ndarray:
    out = art.copy()
    opaque = art[..., 3] > 0
    greens = sorted({tuple(c) for c in art[opaque][:, :3] if foliage(tuple(c))}, key=lambda c: sum(c))
    for rank, colour in enumerate(greens):
        target = ramp[min(len(ramp) - 1, rank * len(ramp) // max(1, len(greens)))]
        hit = (art[..., :3] == colour).all(-1) & opaque
        out[hit, :3] = target
    return out


def main(src: str, out: str) -> None:
    spring = np.array(Image.open(src).convert("RGBA"))
    sheet = np.concatenate([spring, recolour(spring, AUTUMN), recolour(spring, WINTER)])
    Image.fromarray(sheet, "RGBA").save(out)
    print(f"{out} {sheet.shape[1]}x{sheet.shape[0]}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
