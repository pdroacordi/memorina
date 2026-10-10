"""Cut a Codex texture into a seamless 2x backdrop wall (caves, strata, interiors): opaque, one band, wraps both ways.

python -I tools/art/cut_wall.py <texture.png> <out.png> --colors=#hex,#hex,... [--size=512] [--tile=PX] [--levels=5]
Reduces the picture to size/2 + OVERLAP art px by each block's most common colour, snaps it to LEVELS colours, then
stitches each wrap along the cut of least colour difference through an OVERLAP-px band (image quilting: the pixels
are cut, never blended), and maps the value range onto the contract's colours (darkest to lightest) keeping each
colour's hue, so the wall stays one value step darker than the ground in front of it (architecture/backdrop-seams).
--tile cuts a smaller seamless tile (game px) and repeats it to fill the sheet: the picture's features shrink with it.
"""
import colorsys
import sys
from collections import Counter

import numpy as np
from PIL import Image

ART_SCALE = 2
OVERLAP = 32


def reduce(rgb, size):
    art = np.zeros((size, size, 3), dtype=np.uint8)
    f = rgb.shape[0] / size, rgb.shape[1] / size
    for y in range(size):
        for x in range(size):
            sy0, sx0 = int(y * f[0]), int(x * f[1])
            px = rgb[sy0:max(sy0 + 1, int((y + 1) * f[0])), sx0:max(sx0 + 1, int((x + 1) * f[1]))].reshape(-1, 3)
            snapped = (px // 12) * 12
            common = Counter(map(tuple, snapped)).most_common(1)[0][0]
            art[y, x] = px[(snapped == common).all(axis=1)].mean(axis=0)
    return art


def snap(art, levels):
    quant = Image.fromarray(art).quantize(colors=levels, method=Image.Quantize.MEDIANCUT)
    palette = np.array(quant.getpalette()[: 3 * levels]).reshape(-1, 3)
    return palette[np.asarray(quant)].astype(np.uint8)


def cut_path(cost):
    # The cheapest top-to-bottom path through cost (rows x band columns), moving at most one column per row.
    rows, cols = cost.shape
    total = cost.astype(float).copy()
    for y in range(1, rows):
        for x in range(cols):
            total[y, x] += total[y - 1, max(0, x - 1):min(cols, x + 2)].min()
    path = [int(total[-1].argmin())]
    for y in range(rows - 2, -1, -1):
        x = path[-1]
        lo = max(0, x - 1)
        path.append(lo + int(total[y, lo:min(cols, x + 2)].argmin()))
    return path[::-1]


def wrap_columns(img, n):
    # Columns n.. continue column n-1; the cut decides, per row, where the start of the tile takes over from them.
    after, start = img[:, n:n + OVERLAP].astype(int), img[:, :OVERLAP].astype(int)
    path = cut_path(np.abs(after - start).sum(axis=2))
    out = img[:, :n].copy()
    for y, x in enumerate(path):
        out[y, :x] = img[y, n:n + x]
    return out


def remap(art, colors):
    ramp = sorted((colorsys.rgb_to_hsv(*(np.array(c) / 255.0)) for c in colors), key=lambda hsv: hsv[2])
    v_lo, v_hi = ramp[0][2], ramp[-1][2]
    sat = np.mean([hsv[1] for hsv in ramp])
    flat = art.reshape(-1, 3)
    hsv = np.array([colorsys.rgb_to_hsv(*(c / 255.0)) for c in flat])
    lo, hi = hsv[:, 2].min(), hsv[:, 2].max()
    out = np.zeros_like(flat)
    for i, (h, s, v) in enumerate(hsv):
        t = (v - lo) / max(hi - lo, 1e-6)
        # Saturation leans to the contract's, so a bright Codex picture does not stay vivid when darkened.
        out[i] = np.round(np.array(colorsys.hsv_to_rgb(h, (s + sat) * 0.5, v_lo + (v_hi - v_lo) * t)) * 255)
    return out.reshape(art.shape)


def main(texture, out_path, colors, size, tile, levels):
    art_size = tile // ART_SCALE
    rgb = np.asarray(Image.open(texture).convert("RGB")).astype(int)
    art = snap(reduce(rgb, art_size + OVERLAP), levels)
    art = wrap_columns(art, art_size)
    art = wrap_columns(art.transpose(1, 0, 2), art_size).transpose(1, 0, 2)
    art = remap(art, colors)
    repeats = size // tile
    art = np.tile(art, (repeats, repeats, 1))
    image = Image.fromarray(art.astype(np.uint8), "RGB").convert("RGBA")
    image.resize((size, size), Image.NEAREST).save(out_path)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    hexes = [tuple(int(h.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4)) for h in opts["colors"].split(",")]
    size = int(opts.get("size", 512))
    main(args[0], args[1], hexes, size, int(opts.get("tile", size)), int(opts.get("levels", 5)))
