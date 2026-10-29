"""Cut a Codex sheet of separate creatures, already drawn on a coarse pixel grid, into 1x and 2x art stills.

python -I tools/art/cut_creatures.py <sheet.png> <out dir> --names=a,b,... [--merge=24] [--colors=12]
    [--size=name:wN,name:hN,...]
    Objects are the magenta-keyed sheet's connected parts (merged when closer than --merge source px), in left-to-right
    order, written as <name>_still.png (art px) and <name>_still_2x.png (game px); `-` skips one. Codex draws a sheet
    on its own pixel grid (about 12-14 source px per drawn pixel): each object's pitch and phase are measured from its
    colour edges and every drawn pixel is read once, by the most common colour of its cell's middle, so the still is
    the drawing itself, not a resample of it. --size then reduces a named still to its width (wN) or height (hN) in art
    px, each target pixel the most common colour of the drawn pixels it covers. Each still is cut to --colors colours of
    its own and trimmed to its opaque bounds, so its bottom row is its feet. --dot=name:x.y:rrggbb,... paints one
    art px of a still after the cut (an eye a reduction dropped).
"""
import os
import sys
from collections import Counter

import numpy as np
from PIL import Image

# `python -I` leaves the script's own folder off the path.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cut_facades import keyed  # noqa: E402
from cut_props import objects, trim, despeckle  # noqa: E402


def edge_profile(rgb: np.ndarray, axis: int) -> np.ndarray:
    d = np.abs(np.diff(rgb, axis=axis)).sum(2).sum(1 - axis)
    return d / max(1e-9, d.mean())


def grid(profile: np.ndarray, low: float, high: float) -> tuple[float, float]:
    """The pitch in [low, high] whose edges line up best, and the phase of its first edge (source px)."""
    best = (0.0, low, 0.0)
    index = np.arange(len(profile))
    for pitch in np.arange(low, high, 0.05):
        z = (profile * np.exp(2j * np.pi * index / pitch)).sum() / profile.sum()
        if abs(z) > best[0]:
            best = (abs(z), pitch, (np.angle(z) / (2 * np.pi)) % 1 * pitch)
    # A diff at i is the edge between source px i and i + 1.
    return best[1], best[2] + 1


def drawn(rgb: np.ndarray, mask: np.ndarray, pitch_range: tuple[float, float]) -> np.ndarray:
    px, ox = grid(edge_profile(rgb * mask[..., None], 1), *pitch_range)
    py, oy = grid(edge_profile(rgb * mask[..., None], 0), *pitch_range)
    pitch = (px + py) / 2
    xs = np.arange(ox - pitch * np.ceil(ox / pitch), rgb.shape[1], pitch)
    ys = np.arange(oy - pitch * np.ceil(oy / pitch), rgb.shape[0], pitch)
    art = np.zeros((len(ys), len(xs), 4), dtype=np.uint8)
    inset = pitch * 0.25
    for j, y in enumerate(ys):
        for i, x in enumerate(xs):
            y0, y1 = int(max(0, y + inset)), int(min(rgb.shape[0], y + pitch - inset))
            x0, x1 = int(max(0, x + inset)), int(min(rgb.shape[1], x + pitch - inset))
            if y1 <= y0 or x1 <= x0:
                continue
            cell = mask[y0:y1, x0:x1]
            if cell.mean() < 0.5:
                continue
            colours = (rgb[y0:y1, x0:x1][cell] // 8) * 8
            common = Counter(map(tuple, colours)).most_common(1)[0][0]
            art[j, i, :3] = rgb[y0:y1, x0:x1][cell][(colours == common).all(1)].mean(0)
            art[j, i, 3] = 255
    print(f"  pitch {pitch:.2f} source px")
    return trim(art)


def reduced(art: np.ndarray, aw: int, ah: int) -> np.ndarray:
    out = np.zeros((ah, aw, 4), dtype=np.uint8)
    fx, fy = art.shape[1] / aw, art.shape[0] / ah
    for y in range(ah):
        for x in range(aw):
            block = art[int(y * fy):max(int(y * fy) + 1, int((y + 1) * fy)),
                int(x * fx):max(int(x * fx) + 1, int((x + 1) * fx))].reshape(-1, 4)
            opaque = block[block[:, 3] > 0]
            if len(opaque) * 2 < len(block):
                continue
            out[y, x, :3] = Counter(map(tuple, opaque[:, :3])).most_common(1)[0][0]
            out[y, x, 3] = 255
    return trim(out)


def own_colours(art: np.ndarray, colors: int) -> None:
    opaque = art[..., 3] > 0
    px = art[..., :3][opaque]
    if len({tuple(c) for c in px}) <= colors:
        return
    quant = Image.fromarray(px.reshape(-1, 1, 3)).quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
    palette = np.array(quant.getpalette()[: 3 * colors]).reshape(-1, 3)
    art[..., :3][opaque] = palette[((px[:, None].astype(int) - palette[None]) ** 2).sum(-1).argmin(1)]


def main(sheet: str, out_dir: str, options: dict) -> None:
    rgb, solid = keyed(sheet)
    found = sorted(objects(solid, int(options.get("merge", 24))), key=lambda o: o[1].start)
    names = options["names"].split(",")
    sizes = dict((k, v) for k, v in (s.split(":") for s in options.get("size", "").split(",") if s))
    pitch_range = tuple(map(float, options.get("pitch", "10-16").split("-")))
    for (ys, xs, mask), name in zip(found, names):
        if name == "-":
            continue
        print(name)
        art = drawn(rgb[ys, xs], mask, pitch_range)
        print(f"  drawn {art.shape[1]}x{art.shape[0]} art px")
        size = sizes.get(name)
        if size:
            k = int(size[1:]) / (art.shape[1] if size[0] == "w" else art.shape[0])
            art = reduced(art, max(1, round(art.shape[1] * k)), max(1, round(art.shape[0] * k)))
        own_colours(art, int(options.get("colors", 12)))
        if "despeckle" in options:
            despeckle(art)
        for dot in (d for d in options.get("dot", "").split(",") if d.startswith(name + ":")):
            _name, at, colour = dot.split(":")
            x, y = map(int, at.split("."))
            art[y, x] = (int(colour[0:2], 16), int(colour[2:4], 16), int(colour[4:6], 16), 255)
        Image.fromarray(art, "RGBA").save(f"{out_dir}/{name}_still.png")
        image = Image.fromarray(art, "RGBA")
        image.resize((image.width * 2, image.height * 2), Image.NEAREST).save(f"{out_dir}/{name}_still_2x.png")
        print(f"  still {art.shape[1]}x{art.shape[0]} art px")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(args[0], args[1], opts)
