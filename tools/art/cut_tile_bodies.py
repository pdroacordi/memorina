"""Cut a Codex tile sheet into seamless 16 art px bodies for a tile recipe (tools/art/tiles/<biome>_<look>.json).

python -I tools/art/cut_tile_bodies.py <sheet.png> <row> <out_stem> [--base=0] [--variants=1,2,3] [--colors=6]
    [--ramp=#hex,...] [--saturation=1] [--value=1] [--contrast=1] [--seed-shift=8] [--keep-edges]
    [--recolour=<stem>]

Slices the sheet on its magenta gutters (row <row>, 0-based, four tiles across), reduces each tile to 16 art px by each
block's most common colour, and snaps the row to --colors shared colours (toned by --saturation/--value/--contrast, or
mapped by value rank onto --ramp: one body, several palettes). The base tile is made seamless by image quilting: the
tile rolled by half (--seed-shift) wraps cleanly at its edges, and its middle seam is cut out along the paths of least
difference to the unrolled tile, so pixels are cut, never blended. Each variant keeps the base's outer 2 art px ring
and takes the variant tile's middle along a minimum cut (scipy max-flow), so every variant tiles with the base and
with every other variant (systems/art-pipeline). Writes <out_stem>_0.png (base) .. _N.png and prints each wrap score:
the mean colour step across the wrapped edge over the mean step inside (about 1 = seamless).
--keep-edges skips the quilting for a tile that already wraps (its row of joints on the tile edge).
--recolour=<stem> reads finished bodies <stem>_0.png.. instead of a sheet and only maps them onto --ramp.
"""
import colorsys
import glob
import sys
from collections import Counter

import numpy as np
from PIL import Image
from scipy.sparse import csr_matrix
from scipy.sparse.csgraph import maximum_flow

ART = 16
RING = 2


def runs(flags, least=20):
    out, start = [], None
    for i, f in enumerate(list(flags) + [False]):
        if f and start is None:
            start = i
        elif not f and start is not None:
            if i - start > least:
                out.append((start, i))
            start = None
    return out


def reduce(block):
    h, w, _ = block.shape
    art = np.zeros((ART, ART, 3), dtype=np.uint8)
    for y in range(ART):
        for x in range(ART):
            y0, y1 = int(y * h / ART), int((y + 1) * h / ART)
            x0, x1 = int(x * w / ART), int((x + 1) * w / ART)
            # Inner 60 % of the cell: the generator's pixel edges are soft.
            my, mx = (y1 - y0) // 5, (x1 - x0) // 5
            px = block[y0 + my:y1 - my, x0 + mx:x1 - mx].reshape(-1, 3).astype(int)
            snapped = (px // 10) * 10
            common = Counter(map(tuple, snapped)).most_common(1)[0][0]
            art[y, x] = px[(snapped == common).all(axis=1)].mean(axis=0)
    return art


def slice_row(path, row):
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(int)
    mag = (rgb[..., 0] > 150) & (rgb[..., 2] > 150) & (rgb[..., 1] < 110)
    y0, y1 = runs((~mag).mean(axis=1) > 0.3)[row]
    tiles = []
    for x0, x1 in runs((~mag[y0:y1]).mean(axis=0) > 0.5):
        ys, xs = np.nonzero(~mag[y0:y1, x0:x1])
        tiles.append(reduce(rgb[y0 + ys.min():y0 + ys.max() + 1, x0 + xs.min():x0 + xs.max() + 1]))
    return tiles


def palette_of(tiles, colors):
    strip = np.concatenate(tiles, axis=1).astype(np.uint8)
    quant = Image.fromarray(strip).quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
    return np.array(quant.getpalette()[: 3 * colors]).reshape(-1, 3)


def snap(tile, palette):
    d = ((tile[:, :, None, :].astype(int) - palette[None, None]) ** 2).sum(-1)
    return palette[d.argmin(-1)]


def toned(palette, saturation, value, contrast):
    mean = palette.mean(axis=0)
    out = []
    for c in palette:
        c = mean + (c - mean) * contrast
        h, s, v = colorsys.rgb_to_hsv(*(np.clip(c, 0, 255) / 255.0))
        out.append(np.array(colorsys.hsv_to_rgb(h, min(1, s * saturation), min(1, v * value))) * 255)
    return np.round(np.array(out)).astype(int)


def ramped(palette, ramp):
    # Each colour takes the ramp colour at its value rank: one drawing, another palette.
    order = np.argsort([colorsys.rgb_to_hsv(*(c / 255.0))[2] for c in palette])
    out = palette.copy()
    for rank, i in enumerate(order):
        out[i] = ramp[round(rank * (len(ramp) - 1) / max(1, len(palette) - 1))]
    return out


def cost(a, b):
    return np.abs(a.astype(int) - b.astype(int)).sum(-1)


def cyclic_path(c, lo, hi):
    # The cheapest top-to-bottom path through columns lo..hi-1, one column per row at most, ending beside its start.
    rows = c.shape[0]
    best = None
    for start in range(lo, hi):
        total = np.full(c.shape, np.inf)
        total[0, start] = c[0, start]
        for y in range(1, rows):
            for x in range(lo, hi):
                total[y, x] = c[y, x] + total[y - 1, max(lo, x - 1):min(hi, x + 2)].min()
        for end in range(max(lo, start - 1), min(hi, start + 2)):
            if best is None or total[-1, end] < best[0]:
                best = (total[-1, end], start, end, total)
    _, _, end, total = best
    path = [end]
    for y in range(rows - 2, -1, -1):
        x = path[-1]
        lo2 = max(lo, x - 1)
        path.append(lo2 + int(total[y, lo2:min(hi, x + 2)].argmin()))
    return path[::-1]


def wrap_x(tile, shift):
    # The rolled tile wraps at its edges; its middle seam (column ART - shift) is replaced by the unrolled tile between
    # two cuts of least difference, one each side of it.
    rolled = np.roll(tile, shift, axis=1)
    seam = shift
    c = cost(rolled, tile)
    left = cyclic_path(c, max(1, seam - 6), seam)
    right = cyclic_path(c, seam + 1, min(ART - 1, seam + 7))
    out = rolled.copy()
    for y in range(ART):
        out[y, left[y]:right[y]] = tile[y, left[y]:right[y]]
    return out


def seamless(tile, shift):
    tile = wrap_x(tile, shift)
    return wrap_x(tile.transpose(1, 0, 2), shift).transpose(1, 0, 2)


def transplant(base, variant):
    # Min cut between the base's outer ring (source) and the variant's core (sink): the variant's middle is laid into
    # the base along the cheapest boundary, its detail inside it.
    n = ART * ART
    src, sink = n, n + 1
    rows, cols, caps = [], [], []
    diff = cost(base, variant)
    common = Counter(map(tuple, base.reshape(-1, 3))).most_common()
    usual = {c for c, k in common if k >= 6}
    for y in range(ART):
        for x in range(ART):
            i = y * ART + x
            for dy, dx in ((0, 1), (1, 0)):
                yy, xx = y + dy, x + dx
                if yy < ART and xx < ART:
                    w = 1 + int(diff[y, x] + diff[yy, xx])
                    j = yy * ART + xx
                    rows += [i, j]
                    cols += [j, i]
                    caps += [w, w]
            edge = min(x, y, ART - 1 - x, ART - 1 - y)
            if edge < RING:
                rows.append(src)
                cols.append(i)
                caps.append(10 ** 6)
            elif (6 <= x <= 9 and 6 <= y <= 9) or (edge >= RING + 1 and tuple(variant[y, x]) not in usual):
                rows.append(i)
                cols.append(sink)
                caps.append(10 ** 6)
    graph = csr_matrix((np.array(caps, dtype=np.int32), (rows, cols)), shape=(n + 2, n + 2))
    flow = maximum_flow(graph, src, sink).flow
    residual = (graph - flow).tocsr()
    seen = {src}
    stack = [src]
    while stack:
        u = stack.pop()
        row = residual.getrow(u)
        for v, c in zip(row.indices, row.data):
            if c > 0 and v not in seen:
                seen.add(v)
                stack.append(v)
    out = variant.copy()
    for i in seen:
        if i < n:
            out[i // ART, i % ART] = base[i // ART, i % ART]
    return out


def wrap_score(t):
    t = t.astype(int)
    inner = (np.abs(np.diff(t, axis=1)).sum(-1).mean() + np.abs(np.diff(t, axis=0)).sum(-1).mean()) / 2
    edge = (np.abs(t[:, 0] - t[:, -1]).sum(-1).mean() + np.abs(t[0] - t[-1]).sum(-1).mean()) / 2
    return edge / max(inner, 1e-6)


def hexes(spec):
    return np.array([[int(h.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4)] for h in spec.split(",")])


def save(tile, path):
    Image.fromarray(tile.astype(np.uint8), "RGB").convert("RGBA").save(path)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    if "recolour" in opts:
        stem_in, out_stem = opts["recolour"], args[0]
        tiles = [np.asarray(Image.open(p).convert("RGB")).astype(int) for p in sorted(glob.glob(stem_in + "_[0-9].png"))]
        # The bodies' own colours, so every one is mapped and none is merged.
        palette = np.unique(np.concatenate([t.reshape(-1, 3) for t in tiles]), axis=0)
        mapping = {tuple(a): tuple(b) for a, b in zip(palette, ramped(palette, hexes(opts["ramp"])))}
        for i, t in enumerate(tiles):
            out = np.array([[mapping[tuple(c)] for c in row] for row in t])
            save(out, f"{out_stem}_{i}.png")
            print(f"{out_stem}_{i} wrap {wrap_score(out):.2f}")
        return
    sheet, row, out_stem = args[0], int(args[1]), args[2]
    tiles = slice_row(sheet, row)
    base_i = int(opts.get("base", 0))
    variants = [int(v) for v in opts.get("variants", "1,2,3").split(",") if v != ""]
    palette = palette_of([tiles[base_i]] + [tiles[v] for v in variants], int(opts.get("colors", 6)))
    target = (ramped(palette, hexes(opts["ramp"])) if "ramp" in opts else
              toned(palette, float(opts.get("saturation", 1)), float(opts.get("value", 1)), float(opts.get("contrast", 1))))
    mapping = {tuple(a): b for a, b in zip(palette, target)}

    def coloured(t):
        return np.array([[mapping[tuple(c)] for c in r] for r in snap(t, palette)])

    base = snap(tiles[base_i], palette)
    if "keep-edges" not in opts:
        base = seamless(base, int(opts.get("seed-shift", ART // 2)))
    out = [base] + [transplant(base, snap(tiles[v], palette)) for v in variants]
    for i, t in enumerate(out):
        t = coloured(t)
        save(t, f"{out_stem}_{i}.png")
        print(f"{out_stem}_{i} wrap {wrap_score(t):.2f}")


if __name__ == "__main__":
    main()
