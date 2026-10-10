"""Cut a Codex landscape strip into a seamless 2x backdrop layer sheet with spring, autumn and winter bands.

Layer: python -I tools/art/cut_backdrop.py layer <strip.png> <out.png> --kind=mountains|hills|trees --colors=N --top=ROW
    [--x-max=PX] [--cut=X0,X1] [--overlap=ART_PX]. Keys the magenta, cuts the strip between the two columns whose
    silhouettes match best (or at --cut, source px), reduces it to 512x192 art px with its silhouette top at art row
    ROW, stitches the wrap through up to --overlap art px of strip past the cut along the cut of least difference,
    snaps it to N colours, removes single-pixel
    speckle, recolours the autumn and winter bands from the spring drawing and mixes each band toward its season's
    horizon sky by the layer's depth (AERIAL). --x-max ignores the strip right of PX (the hills' sea cliff cannot wrap).
Sky: python -I tools/art/cut_backdrop.py sky <out.png>: stepped bands and four flat clouds, per season.
Layout rules (one flat EDGE row per band, a transparent top row): architecture/vertical-backdrops, "Art contract".
"""
import colorsys
import sys
from collections import Counter

import numpy as np
from PIL import Image

W, H = 512, 192
ART_SCALE = 2
# Art px of strip kept past the cut, through which the wrap is stitched.
OVERLAP = 32
BANDS = ("spring", "autumn", "winter")
# Each season's horizon sky: the sky layer's lowest step.
HORIZON = {"spring": (186, 214, 228), "autumn": (214, 210, 196), "winter": (208, 216, 222)}
ZENITH = {"spring": (86, 136, 200), "autumn": (110, 140, 180), "winter": (128, 148, 170)}
CLOUD = {"spring": ((242, 244, 246), (206, 218, 230)), "autumn": ((236, 232, 224), (200, 198, 196)),
         "winter": ((226, 230, 234), (196, 204, 212))}
# 0..1 mix toward the horizon sky: atmospheric depth, so the play plane stands out (systems/backdrops).
AERIAL = {"mountains": 0.5, "hills": 0.42, "trees": 0.32}


def keyed(path):
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(int)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    return rgb, ~((r > 150) & (b > 150) & (g < 110))


def seam_cut(rgb, solid, width):
    top = np.array([np.argmax(solid[:, x]) for x in range(solid.shape[1])])
    best = None
    for x0 in range(0, width // 3, 2):
        for x1 in range(x0 + int(width * 0.6), width - 3, 2):
            cost = abs(top[x0] - top[x1]) * 4 + abs(top[x0 + 2] - top[x1 + 2]) * 2
            cost += abs(top[max(0, x0 - 2)] - top[x1 - 2]) * 2
            cost += np.abs(rgb[top[x0]:, x0] - rgb[top[x0]:, x1]).mean() * 0.1 if top[x0] == top[x1] else 50
            cost -= (x1 - x0) / width * 10  # prefer a long strip
            if best is None or cost < best[0]:
                best = (cost, x0, x1)
    return best[1], best[2]


def reduce(rgb, mask, aw, ah):
    art = np.zeros((ah, aw, 4), dtype=np.uint8)
    fx, fy = rgb.shape[1] / aw, rgb.shape[0] / ah
    for y in range(ah):
        for x in range(aw):
            sy0, sx0 = int(y * fy), int(x * fx)
            sy1, sx1 = max(sy0 + 1, int((y + 1) * fy)), max(sx0 + 1, int((x + 1) * fx))
            block = mask[sy0:sy1, sx0:sx1]
            if block.mean() < 0.5:
                continue
            px = rgb[sy0:sy1, sx0:sx1][block]
            # The most common colour after a coarse snap, so render noise does not decide the block.
            snapped = (px // 12) * 12
            common = Counter(map(tuple, snapped)).most_common(1)[0][0]
            art[y, x, :3] = px[(snapped == common).all(axis=1)].mean(axis=0)
            art[y, x, 3] = 255
    return art


def snap(art, colors):
    opaque = art[..., 3] > 0
    px = art[..., :3][opaque].astype(np.uint8)
    quant = Image.fromarray(px.reshape(-1, 1, 3)).quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
    palette = np.array(quant.getpalette()[: 3 * colors]).reshape(-1, 3)
    art[..., :3][opaque] = palette[((px[:, None].astype(int) - palette[None]) ** 2).sum(-1).argmin(1)]


def despeckle(a, passes=2):
    # A pixel with no 4-neighbour of its own colour takes its neighbours' most common colour (wrapping sideways).
    for _ in range(passes):
        out = a.copy()
        for y in range(1, H - 1):
            for x in range(W):
                if a[y, x, 3] == 0:
                    continue
                around = [tuple(a[y - 1, x]), tuple(a[y + 1, x]), tuple(a[y, (x - 1) % W]), tuple(a[y, (x + 1) % W])]
                if tuple(a[y, x]) not in around:
                    common = Counter(v for v in around if v[3] > 0).most_common(1)
                    if common:
                        out[y, x] = common[0][0]
        a = out
    return a


def hsv_to_rgb(h, s, v):
    return tuple(int(round(c * 255)) for c in colorsys.hsv_to_rgb(h % 1.0, min(1, max(0, s)), min(1, max(0, v))))


def season(colour, kind, band):
    h, s, v = colorsys.rgb_to_hsv(*(np.array(colour) / 255.0))
    green = 0.15 < h < 0.48 and s > 0.15
    if band == "autumn":
        if kind == "mountains" or not green or (kind == "trees" and v < 0.36):
            return tuple(colour)  # rock, snow and pines keep their colour
        if kind == "trees":
            return hsv_to_rgb(0.075 - (0.55 - v) * 0.12, s * 1.15 + 0.2, v * 1.04)  # orange and russet crowns
        return hsv_to_rgb(0.105 - (0.5 - v) * 0.1, s * 1.15 + 0.15, v * 1.04)  # golden fields, rust groves
    if band == "winter":
        if kind == "mountains":
            return tuple(colour)
        if not green:
            return hsv_to_rgb(0.58, s * 0.3, min(1, v * 1.08))
        if kind == "trees" and v < 0.6:
            # Bare crowns stay a dark mass against the snowy hills; pines stay dark green.
            return hsv_to_rgb(0.45, s * 0.45, v * 0.95) if v < 0.36 else hsv_to_rgb(0.03, 0.16, 0.30 + v * 0.35)
        if v >= 0.42:
            return hsv_to_rgb(0.58, 0.06 + (1 - v) * 0.1, 0.80 + v * 0.12)  # snow
        return hsv_to_rgb(0.45, s * 0.45, v * 0.95)
    return tuple(colour)


def band_of(spring, kind, band):
    out = spring.copy()
    opaque = spring[..., 3] > 0
    mapping = {c: season(c, kind, band) for c in {tuple(c) for c in spring[opaque][:, :3]}}
    recoloured = np.array([mapping[tuple(p)] for p in spring[..., :3][opaque]], dtype=float)
    k = AERIAL[kind]
    out[..., :3][opaque] = np.round(recoloured * (1 - k) + np.array(HORIZON[band]) * k).astype(np.uint8)
    out[-8:] = out[-9, 0]  # EDGE below: the bottom rows are one colour
    out[0, :, 3] = 0  # NONE above: the top row is transparent
    return out


def wrap_columns(img, n):
    # Columns n.. continue column n-1; the cut of least difference decides, per row, where the start of the strip
    # takes over from them (image quilting: pixels are cut, never blended).
    band = img.shape[1] - n
    if band < 2:
        return img[:, :n].copy()
    after, start = img[:, n:].astype(int), img[:, :band].astype(int)
    cost = np.abs(after - start).sum(axis=2).astype(float)
    total = cost.copy()
    for y in range(1, cost.shape[0]):
        for x in range(band):
            total[y, x] += total[y - 1, max(0, x - 1):min(band, x + 2)].min()
    path = [int(total[-1].argmin())]
    for y in range(cost.shape[0] - 2, -1, -1):
        lo = max(0, path[-1] - 1)
        path.append(lo + int(total[y, lo:min(band, path[-1] + 2)].argmin()))
    out = img[:, :n].copy()
    for y, x in enumerate(path[::-1]):
        out[y, :x] = img[y, n:n + x]
    return out


def layer(strip, out_path, kind, colors, top_row, x_max, cut, overlap):
    rgb, solid = keyed(strip)
    x0, x1 = cut or seam_cut(rgb, solid, (x_max or rgb.shape[1]) - OVERLAP * 4)
    scale = (x1 - x0) / W
    # Art columns past the cut (as many as the strip has), so the wrap is stitched along the least visible path.
    x2 = min(rgb.shape[1], x1 + round(overlap * scale))
    wide = W + round((x2 - x1) / scale)
    art = reduce(rgb[:, x0:x2], solid[:, x0:x2], wide, round(rgb.shape[0] / scale))
    shift = top_row - np.nonzero(art[..., 3].any(1))[0].min()
    placed = np.zeros((H, wide, 4), dtype=np.uint8)
    for y in range(max(0, shift), H):
        placed[y] = art[min(art.shape[0] - 1, y - shift)]
    snap(placed, colors)
    spring = despeckle(wrap_columns(placed, W))
    write(np.concatenate([band_of(spring, kind, b) for b in BANDS]), out_path)
    print(f"{kind}: cut {x0}..{x1}, {scale:.2f} source px per art px")


def sky(out_path):
    bands = []
    for band in BANDS:
        a = np.zeros((H, W, 4), dtype=np.uint8)
        a[..., 3] = 255
        top, low = np.array(ZENITH[band]), np.array(HORIZON[band])
        steps, start, end = 6, 8, 116
        for y in range(H):
            t = min(1.0, max(0.0, (y - start) / (end - start)))
            a[y, :, :3] = top + (low - top) * (min(steps - 1, int(t * steps)) / (steps - 1))
        lit, shade = CLOUD[band]
        for cx, cy, size in [(40, 34, 1.0), (170, 22, 0.7), (300, 44, 1.2), (420, 28, 0.8)]:
            puffs = [(cx + dx * size, cy + dy * size, r * size) for dx, dy, r in
                     [(-14, 2, 7), (-5, -3, 9), (6, -1, 8), (15, 3, 6), (0, 4, 8), (-22, 5, 4), (22, 5, 4)]]
            for y in range(8, 90):
                for x in range(W):
                    for px, py, r in puffs:
                        dx = min(abs(x - px), W - abs(x - px))
                        if (dx / 1.6) ** 2 + (y - py) ** 2 <= r * r:
                            a[y, x, :3] = shade if y > cy + 3 * size else lit
                            break
        bands.append(a)
    write(np.concatenate(bands), out_path)


def write(sheet, path):
    image = Image.fromarray(sheet, "RGBA")
    image.resize((image.width * ART_SCALE, image.height * ART_SCALE), Image.NEAREST).save(path)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    if args[0] == "sky":
        sky(args[1])
    else:
        cut = tuple(int(v) for v in opts["cut"].split(",")) if opts.get("cut") else None
        layer(args[1], args[2], opts["kind"], int(opts["colors"]), int(opts["top"]), int(opts.get("x-max", 0)), cut,
                int(opts.get("overlap", OVERLAP)))
