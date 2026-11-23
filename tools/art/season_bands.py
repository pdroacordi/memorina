"""Stack a nature prop's spring art into its three season bands (spring, autumn, winter; systems/seasonal-art).

python -I tools/art/season_bands.py <spring.png> <out.png> [--bare] [--autumn | --winter [--dry] [--melt=top|bottom|all]
    [--keep-white] [--twigs]]
    The spring strip is band 0 unchanged. Autumn and winter are recolours of it, so the silhouette holds: every
    foliage pixel (green hue) is mapped by its brightness rank onto a flat autumn ramp (rust to amber) or a winter ramp
    (blue-grey to snow); wood, stone, pots and flowers keep their colours. No new shape, no blending.
    --autumn reads the input as the autumn band (a tree drawn in its fruiting season, WORLD-42): it stays the autumn band,
    and spring is its warm foliage mapped by brightness rank onto the village tree's greens.
    --winter reads the input as the winter band (a Frozen Lake prop, WORLD-15): its snow, frost and ice pixels become
    spring's greens and autumn's ramp; --dry also maps its dry stalks and twigs. --melt shrinks ice back toward the edge
    it hangs from (top) or grows from (bottom): spring keeps MELT_SPRING of its rows recoloured to wet ice, autumn
    MELT_AUTUMN in its own colours (thin early ice); --melt=all keeps every row and recolours both wet.
    --keep-white keeps near-white pixels (feathers) white in every band; --twigs maps the grey twigs by brightness rank
    onto a spring olive and an autumn brown ramp (the Frost Edge gull nest, WORLD-13).
    --bare (spring input, a blossom tree, WORLD-14): autumn drops the blossom and keeps the foliage in the autumn ramp;
    winter drops blossom and foliage and keeps only the wood joined to the trunk, with snow on its flat tops (a top pixel
    two or more deep with a top pixel beside it).
    --snowcap (spring input, a prop with little or no foliage: mushrooms, mud, a scarecrow): autumn and winter recolour
    its foliage as usual, and winter also gets snow on its flat tops (WORLD-12, WORLD-14).
"""
import colorsys
import sys
from collections.abc import Callable

import numpy as np
from PIL import Image
from scipy import ndimage

AUTUMN = [(110, 52, 30), (156, 74, 34), (196, 108, 44), (226, 152, 64)]
# The village tree's spring foliage (props/village/village_tree.png band 0), dark to light.
SPRING = [(67, 83, 46), (101, 117, 49), (119, 130, 52), (149, 157, 54), (158, 167, 54)]
WINTER = [(122, 132, 146), (168, 180, 192), (210, 218, 226), (240, 244, 248)]
# Ice thawing: dark wet blue-greys, dark to light.
WET = [(58, 70, 84), (78, 94, 110), (102, 120, 136)]
# A nest's twigs out of the frost, dark to light.
TWIG_SPRING = [(70, 62, 42), (90, 82, 52), (110, 102, 62), (128, 120, 74), (146, 138, 86)]
TWIG_AUTUMN = [(84, 56, 36), (108, 72, 44), (134, 92, 54), (158, 112, 64), (178, 132, 76)]
SNOW = (240, 244, 248)
## Share of a melting prop's rows kept, from its attached edge (0..1).
MELT_SPRING = 0.35
MELT_AUTUMN = 0.65


def foliage(rgb: tuple) -> bool:
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    return 60 / 360 <= h <= 170 / 360 and s > 0.18 and v > 0.12


def warm_foliage(rgb: tuple) -> bool:
    """Autumn leaves: bright orange to yellow, or a yellow-olive; bark highlights are darker and redder than both."""
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    bright = h <= 75 / 360 and s > 0.45 and v > 0.8
    olive = 34 / 360 <= h <= 75 / 360 and s > 0.5 and v > 0.55
    return bright or olive or foliage(rgb)


def cold(rgb: tuple) -> bool:
    """Snow, frost and ice: very pale, or a pale blue."""
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    return (v > 0.72 and s < 0.22) or (170 / 360 <= h <= 250 / 360 and v > 0.5 and s > 0.08)


def dry(rgb: tuple) -> bool:
    """Dry reed stalks, seed heads and bare twigs: rose-brown to tan, not grey."""
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    return (h <= 60 / 360 or h >= 340 / 360) and s > 0.18 and v > 0.3


def white(rgb: tuple) -> bool:
    _h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    return v > 0.85 and s < 0.12


def grey(rgb: tuple) -> bool:
    _h, s, _v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    return s < 0.2 and not white(rgb)


def blossom(rgb: tuple) -> bool:
    """Pink to peach petals: light, warm or rose, a little saturated."""
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    return (h >= 300 / 360 or h <= 25 / 360) and s > 0.2 and v > 0.75


def dropped(art: np.ndarray, test: Callable[[tuple], bool]) -> np.ndarray:
    out = art.copy()
    opaque = art[..., 3] > 0
    for colour in {tuple(c) for c in art[opaque][:, :3] if test(tuple(c))}:
        out[(art[..., :3] == colour).all(-1) & opaque] = 0
    return out


def bare(art: np.ndarray) -> np.ndarray:
    autumn = recolour(dropped(art, blossom), AUTUMN)
    wood = dropped(dropped(art, blossom), foliage)
    labels, _count = ndimage.label(wood[..., 3] > 0, structure=np.ones((3, 3)))
    sizes = np.bincount(labels.ravel())
    sizes[0] = 0
    wood[labels != sizes.argmax()] = 0
    return np.concatenate([art, autumn, snowcapped(wood)])


def snowcapped(art: np.ndarray) -> np.ndarray:
    """Snow on the art's flat tops: a top pixel two or more deep with a top pixel beside it. No new shape."""
    winter = art.copy()
    solid = art[::2, ::2, 3] > 0  # the art grid: one art px is 2x2
    top = np.zeros_like(solid)
    top[1:-1] = solid[1:-1] & solid[2:] & ~solid[:-2]
    top[0] = solid[0] & solid[1]
    ledge = top & (np.roll(top, 1, axis=1) | np.roll(top, -1, axis=1))
    winter[np.repeat(np.repeat(ledge, 2, 0), 2, 1), :3] = SNOW
    return winter


def melted(art: np.ndarray, edge: str, keep: float, wet: bool) -> np.ndarray:
    """Keeps `keep` of the opaque rows nearest `edge` (top or bottom); `wet` turns every pixel to the wet ramp."""
    out = recolour(art, WET, lambda _rgb: True) if wet else art.copy()
    rows = np.where((art[..., 3] > 0).any(1))[0]
    if edge in ("top", "bottom") and len(rows):
        span = max(1, round(len(rows) * keep))
        cut = rows[0] + span if edge == "top" else rows[-1] + 1 - span
        if edge == "top":
            out[cut:, ..., 3] = 0
        else:
            out[:cut, ..., 3] = 0
    return out


def from_winter(art: np.ndarray, dry_too: bool, melt: str, keep_white: bool = False, twigs: bool = False) -> np.ndarray:
    if melt:
        return np.concatenate([melted(art, melt, MELT_SPRING, True), melted(art, melt, MELT_AUTUMN, melt == "all"), art])
    turns = (lambda rgb: cold(rgb) or dry(rgb)) if dry_too else cold
    if keep_white:
        base_turns = turns
        turns = lambda rgb: base_turns(rgb) and not white(rgb)  # noqa: E731
    spring, autumn = recolour(art, SPRING, turns), recolour(art, AUTUMN, turns)
    if twigs:
        spring, autumn = recolour(spring, TWIG_SPRING, grey), recolour(autumn, TWIG_AUTUMN, grey)
    return np.concatenate([spring, autumn, art])


def recolour(art: np.ndarray, ramp: list, leaf: Callable[[tuple], bool] = foliage) -> np.ndarray:
    out = art.copy()
    opaque = art[..., 3] > 0
    greens = sorted({tuple(c) for c in art[opaque][:, :3] if leaf(tuple(c))}, key=lambda c: sum(c))
    for rank, colour in enumerate(greens):
        target = ramp[min(len(ramp) - 1, rank * len(ramp) // max(1, len(greens)))]
        hit = (art[..., :3] == colour).all(-1) & opaque
        out[hit, :3] = target
    return out


def main(src: str, out: str, autumn_input: bool = False, winter_input: bool = False, dry_too: bool = False,
         melt: str = "", keep_white: bool = False, twigs: bool = False, bare_tree: bool = False,
         snowcap: bool = False) -> None:
    art = np.array(Image.open(src).convert("RGBA"))
    if bare_tree:
        sheet = bare(art)
    elif snowcap:
        sheet = np.concatenate([art, recolour(art, AUTUMN), snowcapped(recolour(art, WINTER))])
    elif winter_input:
        sheet = from_winter(art, dry_too, melt, keep_white, twigs)
    elif autumn_input:
        spring = recolour(art, SPRING, warm_foliage)
        sheet = np.concatenate([spring, art, recolour(spring, WINTER)])
    else:
        sheet = np.concatenate([art, recolour(art, AUTUMN), recolour(art, WINTER)])
    Image.fromarray(sheet, "RGBA").save(out)
    print(f"{out} {sheet.shape[1]}x{sheet.shape[0]}")


if __name__ == "__main__":
    flags = sys.argv[3:]
    melt_to = next((f.split("=", 1)[1] for f in flags if f.startswith("--melt=")), "")
    main(sys.argv[1], sys.argv[2], "--autumn" in flags, "--winter" in flags, "--dry" in flags, melt_to,
         "--keep-white" in flags, "--twigs" in flags, "--bare" in flags, "--snowcap" in flags)
