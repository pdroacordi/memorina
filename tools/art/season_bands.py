"""Stack a nature prop's spring art into its three season bands (spring, autumn, winter; systems/seasonal-art).

python -I tools/art/season_bands.py <spring.png> <out.png> [--autumn]
    The spring strip is band 0 unchanged. Autumn and winter are recolours of it, so the silhouette holds: every
    foliage pixel (green hue) is mapped by its brightness rank onto a flat autumn ramp (rust to amber) or a winter ramp
    (blue-grey to snow); wood, stone, pots and flowers keep their colours. No new shape, no blending.
    --autumn reads the input as the autumn band (a tree drawn in its fruiting season, WORLD-42): it stays the autumn band,
    and spring is its warm foliage mapped by brightness rank onto the village tree's greens.
"""
import colorsys
import sys
from collections.abc import Callable

import numpy as np
from PIL import Image

AUTUMN = [(110, 52, 30), (156, 74, 34), (196, 108, 44), (226, 152, 64)]
# The village tree's spring foliage (props/village/village_tree.png band 0), dark to light.
SPRING = [(67, 83, 46), (101, 117, 49), (119, 130, 52), (149, 157, 54), (158, 167, 54)]
WINTER = [(122, 132, 146), (168, 180, 192), (210, 218, 226), (240, 244, 248)]


def foliage(rgb: tuple) -> bool:
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    return 60 / 360 <= h <= 170 / 360 and s > 0.18 and v > 0.12


def warm_foliage(rgb: tuple) -> bool:
    """Autumn leaves: bright orange to yellow, or a yellow-olive; bark highlights are darker and redder than both."""
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    bright = h <= 75 / 360 and s > 0.45 and v > 0.8
    olive = 34 / 360 <= h <= 75 / 360 and s > 0.5 and v > 0.55
    return bright or olive or foliage(rgb)


def recolour(art: np.ndarray, ramp: list, leaf: Callable[[tuple], bool] = foliage) -> np.ndarray:
    out = art.copy()
    opaque = art[..., 3] > 0
    greens = sorted({tuple(c) for c in art[opaque][:, :3] if leaf(tuple(c))}, key=lambda c: sum(c))
    for rank, colour in enumerate(greens):
        target = ramp[min(len(ramp) - 1, rank * len(ramp) // max(1, len(greens)))]
        hit = (art[..., :3] == colour).all(-1) & opaque
        out[hit, :3] = target
    return out


def main(src: str, out: str, autumn_input: bool = False) -> None:
    art = np.array(Image.open(src).convert("RGBA"))
    if autumn_input:
        spring = recolour(art, SPRING, warm_foliage)
        sheet = np.concatenate([spring, art, recolour(spring, WINTER)])
    else:
        sheet = np.concatenate([art, recolour(art, AUTUMN), recolour(art, WINTER)])
    Image.fromarray(sheet, "RGBA").save(out)
    print(f"{out} {sheet.shape[1]}x{sheet.shape[0]}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], "--autumn" in sys.argv[3:])
