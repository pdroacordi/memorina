"""Cut a Codex engraving board (four panels on magenta) into STORY-04 engraving layers, and draw the moving ink layers.

python -I tools/art/cut_engraving.py board <raw.png> <out_dir> --ink=#RRGGBB [--order=1,2,3,4] [--shift=n:dx,dy;...] [--chroma=0.16]
    Finds the four panels (the largest non-magenta parts, reading order), crops each to the 384x176 aspect, centred
    (--shift moves a frame's crop along the axis the aspect trims, raw px, kept inside the panel; --chroma is the least chroma, 0..1, that counts as ink: raise it when the
    drawing tints its fills in a pale ink), and writes <out_dir>/frame_<n>_base.png: an opaque 384x176 art px canvas
    (1 px per art px, shown at scale 2) of neutral greys from GREYS plus the key ink #FF00FF where the drawing's line
    work is in the --ink hue. Prints each frame's grey and ink share.
python -I tools/art/cut_engraving.py motes <out.png> <kind> --count=N --seed=S
    Draws an ink-only layer (key #FF00FF on transparent) of small motes, tileable on both axes, so a layer that
    drifts can repeat. Kinds: snow, flakes, leaves, birds, petals, embers, wind.
python -I tools/art/cut_engraving.py tube <raw.png> <out.png> --box=x0,y0,x1,y1 --width=W --height=H --colors=N
    Cuts one notebook tube drawing from a magenta board: the box's subject, reduced to W x H (aspect kept, centred),
    flattened to N colours, transparent elsewhere, 1 px per notebook px.

The engraving contract is tools/art/prompts/story_bearer_<guardian>.md; the shader that reads the layers is described
in docs/knowledge/architecture/story-04-bearer-fragments.md ("The look").
"""
import colorsys
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cut_facades import keyed, reduce  # noqa: E402
from cut_props import flatten, trim  # noqa: E402

CANVAS = (384, 176)
KEY = (255, 0, 255)
# Neutral greys, dark to paper. gh_print reduces them to luma, so only their values matter.
GREYS = np.array([60, 96, 140, 184])


def _hue_distance(a: np.ndarray, b: float) -> np.ndarray:
    d = np.abs(a - b) % 1.0
    return np.minimum(d, 1.0 - d)


def ink_mask(rgb: np.ndarray, ink: tuple[int, int, int], min_chroma: float) -> np.ndarray:
    """Pixels whose colour is the ink's hue with real chroma; the greys have none."""
    f = rgb.astype(float) / 255.0
    mx, mn = f.max(-1), f.min(-1)
    chroma = mx - mn
    r, g, b = f[..., 0], f[..., 1], f[..., 2]
    safe = np.where(chroma == 0, 1, chroma)
    h = np.where(mx == r, ((g - b) / safe) % 6, np.where(mx == g, (b - r) / safe + 2, (r - g) / safe + 4)) / 6.0
    ink_h = colorsys.rgb_to_hsv(*[c / 255.0 for c in ink])[0]
    return (chroma > min_chroma) & (_hue_distance(h, ink_h) < 0.12)


def panels(solid: np.ndarray, count: int = 4) -> list[tuple[int, int, int, int]]:
    labels, n = ndimage.label(ndimage.binary_opening(solid, iterations=3))
    sizes = ndimage.sum(solid, labels, range(1, n + 1))
    biggest = np.argsort(sizes)[::-1][:count] + 1
    boxes = []
    for i in biggest:
        sl = ndimage.find_objects((labels == i).astype(int))[0]
        boxes.append((sl[1].start, sl[0].start, sl[1].stop, sl[0].stop))
    # Reading order: rows by top edge (panels within 40 raw px share a row), then left to right.
    boxes.sort(key=lambda b: b[1])
    ordered, row = [], [boxes[0]]
    for b in boxes[1:]:
        if b[1] - row[0][1] < 40:
            row.append(b)
        else:
            ordered += sorted(row)
            row = [b]
    return ordered + sorted(row)


def crop_to_canvas(box: tuple[int, int, int, int], shift: tuple[int, int]) -> tuple[int, int, int, int]:
    x0, y0, x1, y1 = box
    inset = 6  # Codex's magenta fringes the panel edge.
    x0, y0, x1, y1 = x0 + inset, y0 + inset, x1 - inset, y1 - inset
    w, h = x1 - x0, y1 - y0
    aspect = CANVAS[0] / CANVAS[1]
    if w / h > aspect:
        nw = round(h * aspect)
        x0 += min(max((w - nw) // 2 + shift[0], 0), w - nw)
        x1 = x0 + nw
    else:
        nh = round(w / aspect)
        y0 += min(max((h - nh) // 2 + shift[1], 0), h - nh)
        y1 = y0 + nh
    return x0, y0, x1, y1


def _area(values: np.ndarray) -> np.ndarray:
    return np.asarray(Image.fromarray(values.astype(np.float32), "F").resize(CANVAS, Image.BOX))


def engrave(rgb: np.ndarray, ink: tuple[int, int, int], min_chroma: float) -> tuple[np.ndarray, np.ndarray]:
    """Returns (grey index per art px, ink mask per art px)."""
    is_ink = ink_mask(rgb, ink, min_chroma)
    coverage = _area(is_ink.astype(float))
    luma = rgb @ np.array([0.299, 0.587, 0.114])
    # Under the ink, the grey is the nearest non-ink grey, so a line never darkens its mass.
    _, (iy, ix) = ndimage.distance_transform_edt(is_ink, return_indices=True)
    luma = luma[iy, ix]
    # Blurred first, so fine grey hatching settles into flat masses instead of speckle.
    grey = ndimage.gaussian_filter(_area(luma), 0.8)
    index = _quantize(grey)
    index = ndimage.median_filter(index, size=3)
    art_ink = coverage >= 0.3
    # A lone ink pixel reads as dust, not a line.
    labels, n = ndimage.label(art_ink, structure=np.ones((3, 3)))
    sizes = ndimage.sum(art_ink, labels, range(1, n + 1))
    art_ink &= np.isin(labels, np.nonzero(sizes >= 2)[0] + 1)
    return index, art_ink


# How far below the paper (luma steps) a value must lie to print as each darker grey.
DROPS = (18, 45, 75)


def _quantize(grey: np.ndarray) -> np.ndarray:
    """Grey index per art px: darker steps by their drop below the paper."""
    hist, edges = np.histogram(grey, bins=64, range=(0, 256))
    # The brightest value that covers a real area, not the commonest: a night lake can outweigh the paper.
    paper = edges[np.nonzero(hist >= hist.max() * 0.2)[0].max()] + 2
    drop = paper - grey
    index = np.full(grey.shape, len(GREYS) - 1)
    for step, limit in enumerate(DROPS):
        index[drop >= limit] = len(GREYS) - 2 - step
    return index


def write_base(index: np.ndarray, art_ink: np.ndarray, path: str) -> None:
    out = np.zeros((CANVAS[1], CANVAS[0], 4), dtype=np.uint8)
    out[..., :3] = GREYS[index][..., None]
    out[art_ink, :3] = KEY
    out[..., 3] = 255
    Image.fromarray(out, "RGBA").save(path)


def board(raw: str, out_dir: str, ink: tuple[int, int, int], order: list[int], shifts: dict, min_chroma: float) -> None:
    rgb, solid = keyed(raw)
    os.makedirs(out_dir, exist_ok=True)
    boxes = panels(solid)
    for slot, n in enumerate(order):
        x0, y0, x1, y1 = crop_to_canvas(boxes[slot], shifts.get(n, (0, 0)))
        index, art_ink = engrave(rgb[y0:y1, x0:x1], ink, min_chroma)
        write_base(index, art_ink, os.path.join(out_dir, "frame_%d_base.png" % n))
        share = np.bincount(index.ravel(), minlength=len(GREYS)) / index.size
        print("frame %d: box %s, ink %.2f, greys %s" % (n, (x0, y0, x1, y1), art_ink.mean(),
            " ".join("%.2f" % s for s in share)))


SHAPES = {
    "snow": [[(0, 0)], [(0, 0)], [(0, 0), (1, 0)]],
    "flakes": [[(0, 0), (1, 0), (0, 1), (1, 1)], [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)], [(0, 0)]],
    "leaves": [[(0, 0), (1, 0), (1, 1), (2, 1)], [(1, 0), (0, 1), (1, 1), (0, 2)], [(0, 0), (1, 1), (2, 1), (1, 0)],
        [(0, 1), (1, 1), (1, 0), (2, 0), (3, 0)]],
    "birds": [[(0, 0), (1, 1), (2, 1), (3, 0)], [(0, 1), (1, 0), (2, 1), (3, 1), (4, 0)],
        [(0, 0), (1, 1), (2, 0)]],
    "petals": [[(0, 0), (1, 0)], [(0, 0), (0, 1)], [(0, 0), (1, 1)]],
    "embers": [[(0, 0)], [(0, 0), (0, 1)]],
    "wind": [[(i, 0) for i in range(7)] + [(7, 1), (8, 1)], [(i, 0) for i in range(5)],
        [(i, 1) for i in range(4)] + [(i, 0) for i in range(4, 10)]],
}


def motes(out: str, kind: str, count: int, seed: int) -> None:
    rng = np.random.default_rng(seed)
    w, h = CANVAS
    layer = np.zeros((h, w, 4), dtype=np.uint8)
    taken = np.zeros((h, w), dtype=bool)
    placed = 0
    tries = 0
    while placed < count and tries < count * 50:
        tries += 1
        shape = SHAPES[kind][rng.integers(len(SHAPES[kind]))]
        x, y = int(rng.integers(w)), int(rng.integers(h))
        cells = [((y + dy) % h, (x + dx) % w) for dx, dy in shape]
        # Keep 3 art px between motes so the layer reads as separate flecks.
        near = [(cy + j) % h for cy, _ in cells for j in range(-3, 4)], [(cx + i) % w for _, cx in cells for i in range(-3, 4)]
        if taken[np.ix_(sorted(set(near[0])), sorted(set(near[1])))].any():
            continue
        for cy, cx in cells:
            layer[cy, cx] = (*KEY, 255)
            taken[cy, cx] = True
        placed += 1
    Image.fromarray(layer, "RGBA").save(out)
    print("%s: %d %s" % (out, placed, kind))


def tube(raw: str, out: str, box: list[int], width: int, height: int, colors: int) -> None:
    rgb, solid = keyed(raw)
    rgb, solid = rgb[box[1]:box[3], box[0]:box[2]], solid[box[1]:box[3], box[0]:box[2]]
    labels, n = ndimage.label(solid)
    sizes = ndimage.sum(solid, labels, range(1, n + 1))
    subject = np.isin(labels, [i + 1 for i, s in enumerate(sizes) if s >= sizes.max() * 0.02])
    ys, xs = np.nonzero(subject)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    scale = min(width / (x1 - x0), height / (y1 - y0))
    aw, ah = max(1, round((x1 - x0) * scale)), max(1, round((y1 - y0) * scale))
    art = reduce(rgb[y0:y1, x0:x1], subject[y0:y1, x0:x1], aw, ah)
    flatten(art, colors)
    art = trim(art)
    sheet = np.zeros((height, width, 4), dtype=np.uint8)
    ox, oy = (width - art.shape[1]) // 2, (height - art.shape[0]) // 2
    sheet[oy:oy + art.shape[0], ox:ox + art.shape[1]] = art
    Image.fromarray(sheet, "RGBA").save(out)
    print("%s: %dx%d (subject %dx%d)" % (out, width, height, art.shape[1], art.shape[0]))


def _options(args: list[str]) -> dict:
    return dict(a[2:].split("=", 1) for a in args if a.startswith("--"))


if __name__ == "__main__":
    mode, rest = sys.argv[1], sys.argv[2:]
    positional = [a for a in rest if not a.startswith("--")]
    opts = _options(rest)
    if mode == "board":
        hexa = opts["ink"].lstrip("#")
        ink = tuple(int(hexa[i:i + 2], 16) for i in (0, 2, 4))
        order = [int(v) for v in opts.get("order", "1,2,3,4").split(",")]
        shifts = {}
        for item in filter(None, opts.get("shift", "").split(";")):
            n, d = item.split(":")
            dx, dy = d.split(",")
            shifts[int(n)] = (int(dx), int(dy))
        board(positional[0], positional[1], ink, order, shifts, float(opts.get("chroma", "0.16")))
    elif mode == "motes":
        motes(positional[0], positional[1], int(opts.get("count", "60")), int(opts.get("seed", "1")))
    elif mode == "tube":
        tube(positional[0], positional[1], [int(v) for v in opts["box"].split(",")], int(opts["width"]),
            int(opts["height"]), int(opts.get("colors", "8")))
    else:
        sys.exit("mode must be board, motes or tube")
