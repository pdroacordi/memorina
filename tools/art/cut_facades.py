"""Cut Codex building fronts (and the door) into 2x-density prop sheets.

Facades: python -I tools/art/cut_facades.py facades <sheet.png> <out dir> <name,name,...> [--grid=3x2] [--colors=20]
    [--crop-top=name:rows] [--dark=name:luma] [--rows=name:at:delta] [--doorway=name:x0:y0:x1:y1]. Each building is scaled so its
    doorway (the dark opening that reaches the ground line) is
    32 art px tall, reduced by each block's most common colour, snapped to one shared palette, given a flat 16x32 art px
    doorway recess and written at 2x as <name>_facade.png. Prints each sheet's size and its anchor (the doorway's
    sill centre, game px): the prop scene's offset is minus the anchor (architecture/props-and-ambient-life).
    --rows repeats (delta > 0) or drops (delta < 0) |delta| art rows of plain wall starting `at` art px above the ground,
    so a walkable roof lands on the 32 px room grid. --doorway gives the doorway's box in sheet px (x1, y1 exclusive) for a
    front drawn with its door shut; the front is cut at the box's bottom, its sill, which becomes the ground line.
    A name `-` skips that grid cell. --write=name,... writes only those fronts; the palette still comes from every cell.
    --palette=a.png,b.png,... snaps every front to the colours those built fronts use instead of a palette of its own,
    so a front cut from a later sheet shares the street's colours.
Door: python -I tools/art/cut_facades.py door <sheet.png> <out.png> [--colors=10]: two doors side by side, each cut
    to its plank body and reduced to 16x32 art px, written at 2x as a 64x64 two-frame strip.
Doorways: python -I tools/art/cut_facades.py doorways <sheet.png> <out dir> <name:art_width,...> [--colors=16]: a 3x2
    sheet, open pieces on top and their sealed versions below; each column is scaled so its open piece is art_width art
    px wide and written at 2x as <name>.png, two bottom-aligned frames (open, sealed) of one size. --side reads one piece
    drawn open on the left and sealed on the right; --opening=px scales by the open piece's dark opening width instead;
    --keep-x=l:r keeps only art columns l..r of each frame.
"""
import sys
from collections import Counter

import numpy as np
from PIL import Image
from scipy import ndimage

ART_SCALE = 2
DOOR_ART = (16, 32)
LUMA = np.array([0.299, 0.587, 0.114])


def keyed(path: str) -> tuple[np.ndarray, np.ndarray]:
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(int)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    # Codex's magenta wanders around #ff00ff; nothing in a subject is that hue.
    return rgb, ~((r > 150) & (b > 150) & (g < 110) & (abs(r - b) < 90))


def reduce(rgb: np.ndarray, mask: np.ndarray, aw: int, ah: int) -> np.ndarray:
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


def snap(arts: list[np.ndarray], colors: int) -> np.ndarray:
    stack = np.concatenate([a[a[..., 3] > 0][:, :3] for a in arts]).astype(np.uint8)
    quant = Image.fromarray(stack.reshape(-1, 1, 3)).quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
    palette = np.array(quant.getpalette()[: 3 * colors]).reshape(-1, 3)
    for a in arts:
        opaque = a[..., 3] > 0
        px = a[..., :3][opaque].astype(int)
        a[..., :3][opaque] = palette[((px[:, None] - palette[None]) ** 2).sum(-1).argmin(1)]
    return palette


def palette_of(paths: list[str]) -> np.ndarray:
    colours = set()
    for path in paths:
        a = np.asarray(Image.open(path).convert("RGBA"))
        colours |= set(map(tuple, a[a[..., 3] > 0][:, :3]))
    return np.array(sorted(colours))


def snap_to(arts: list[np.ndarray], palette: np.ndarray) -> np.ndarray:
    for a in arts:
        opaque = a[..., 3] > 0
        px = a[..., :3][opaque].astype(int)
        a[..., :3][opaque] = palette[((px[:, None] - palette[None]) ** 2).sum(-1).argmin(1)]
    return palette


def save_2x(art: np.ndarray, path: str) -> Image.Image:
    image = Image.fromarray(art, "RGBA")
    image = image.resize((image.width * ART_SCALE, image.height * ART_SCALE), Image.NEAREST)
    image.save(path)
    return image


def facades(sheet: str, out_dir: str, names: list[str], options: dict) -> None:
    rgb, solid = keyed(sheet)
    cols, rows = map(int, options.get("grid", "3x2").split("x"))
    crop_top = dict((k, int(v)) for k, v in (c.split(":") for c in options.get("crop-top", "").split(",") if c))
    # A wall nearly as dark as its doorway merges with it at the default threshold (the fisher hut's tarred planks).
    dark_luma = dict((k, int(v)) for k, v in (c.split(":") for c in options.get("dark", "").split(",") if c))
    rows_at = dict((k, (int(a), int(d))) for k, a, d in (c.split(":") for c in options.get("rows", "").split(",") if c))
    boxes = dict((k, tuple(int(v) for v in rest)) for k, *rest in (c.split(":") for c in options.get("doorway", "").split(",") if c))
    labels, count = ndimage.label(solid)
    sizes = ndimage.sum(solid, labels, range(1, count + 1))
    centres = ndimage.center_of_mass(solid, labels, range(1, count + 1))
    cells = [np.zeros_like(solid) for _ in names]
    h, w = solid.shape
    for i, (cy, cx) in enumerate(centres):
        if sizes[i] < 30:
            continue
        cell = min(rows - 1, int(cy / (h / rows))) * cols + min(cols - 1, int(cx / (w / cols)))
        if cell < len(cells):
            cells[cell] |= labels == i + 1
    arts, centres_x, kept = [], [], []
    for name, mask in zip(names, cells):
        if name == "-":
            continue
        ys, xs = np.nonzero(mask)
        part, inside = rgb[ys.min():ys.max() + 1, xs.min():xs.max() + 1], mask[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        if name in boxes:
            x0, y0, x1, y1 = boxes[name]
            part, inside = part[:y1 - ys.min()], inside[:y1 - ys.min()]
            best = (0, y0 - ys.min(), x0 - xs.min(), x1 - 1 - xs.min())
        else:
            best = _dark_doorway(part, inside, dark_luma.get(name, 48))
        assert best is not None, f"{name}: no doorway reaches the ground line"
        scale = DOOR_ART[1] / (part.shape[0] - best[1])
        art = reduce(part, inside, round(part.shape[1] * scale), round(part.shape[0] * scale))
        if name in rows_at:
            art = resized_rows(art, *rows_at[name])
        arts.append(art[crop_top.get(name, 0):])
        centres_x.append(int(round((best[2] + best[3] + 1) / 2 * scale)))
        kept.append(name)
    if "palette" in options:
        palette = snap_to(arts, palette_of(options["palette"].split(",")))
    else:
        palette = snap(arts, int(options.get("colors", 20)))
    darkest = palette[(palette @ LUMA).argmin()]
    written = [n for n in options.get("write", "").split(",") if n]
    for name, art, cx in zip(kept, arts, centres_x):
        if written and name not in written:
            continue
        half = DOOR_ART[0] // 2
        art[-DOOR_ART[1]:, cx - half:cx + half] = (*darkest, 255)
        image = save_2x(art, f"{out_dir}/{name}_facade.png")
        print(f"{name}_facade {image.width}x{image.height} anchor {cx * ART_SCALE},{image.height}")


def _dark_doorway(part: np.ndarray, inside: np.ndarray, luma: int) -> tuple | None:
    """The largest dark opening that reaches the ground line: (size, top, left, right) in part px."""
    dark = (part @ LUMA < luma) & inside
    dark_labels, dark_count = ndimage.label(dark)
    best = None
    for d in range(1, dark_count + 1):
        dy, dx = np.nonzero(dark_labels == d)
        if dy.max() >= part.shape[0] - 12 and (best is None or dy.size > best[0]):
            best = (dy.size, dy.min(), dx.min(), dx.max())
    return best


def resized_rows(art: np.ndarray, at: int, delta: int) -> np.ndarray:
    top = art.shape[0] - at - abs(delta)
    band = art[top:art.shape[0] - at]
    if delta > 0:
        return np.concatenate([art[:top], band, band, art[art.shape[0] - at:]])
    return np.concatenate([art[:top], art[art.shape[0] - at:]])


def door(sheet: str, out: str, options: dict) -> None:
    rgb, solid = keyed(sheet)
    w = solid.shape[1]
    arts = []
    for half in (slice(0, w // 2), slice(w // 2, w)):
        mask = solid[:, half]
        labels, count = ndimage.label(mask)
        body = labels == np.argmax(ndimage.sum(mask, labels, range(1, count + 1))) + 1
        # The plank body: columns that are mostly solid (the sealed door's bar overhangs it).
        fill = body.sum(0)
        xs, ys = np.nonzero(fill > 0.8 * fill.max())[0], np.nonzero(body.any(1))[0]
        part = rgb[ys.min():ys.max() + 1, half][:, xs.min():xs.max() + 1]
        arts.append(reduce(part, np.ones(part.shape[:2], bool), *DOOR_ART))
    snap(arts, int(options.get("colors", 10)))
    image = save_2x(np.concatenate(arts, axis=1), out)
    print(f"door {image.width}x{image.height}")


def doorways(sheet: str, out_dir: str, specs: list[str], options: dict) -> None:
    rgb, solid = keyed(sheet)
    labels, count = ndimage.label(solid)
    sizes = ndimage.sum(solid, labels, range(1, count + 1))
    centres = ndimage.center_of_mass(solid, labels, range(1, count + 1))
    h, w = solid.shape
    side = "side" in options
    cells = [np.zeros_like(solid) for _ in range(6)]
    for i, (cy, cx) in enumerate(centres):
        if sizes[i] < 30:
            continue
        # --side: the open piece is cell 0 and the sealed one cell 3, as in the grid layout's first column.
        cell = (3 if cx > w / 2 else 0) if side else min(1, int(cy / (h / 2))) * 3 + min(2, int(cx / (w / 3)))
        cells[cell] |= labels == i + 1
    arts, names = [], []
    for column, spec in enumerate(specs):
        name, art_width = spec.split(":")
        open_mask = cells[column]
        if "opening" in options:
            # The widest run of dark pixels inside the open piece's bounds: its opening.
            ys, xs = np.nonzero(open_mask)
            part = rgb[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
            dark = (part @ LUMA < 48).sum(0) > 0.3 * part.shape[0]
            runs = np.diff(np.concatenate([[0], dark.astype(int), [0]]))
            widths = np.nonzero(runs == -1)[0] - np.nonzero(runs == 1)[0]
            scale = int(options["opening"]) / ART_SCALE / widths.max()
        else:
            xs_open = np.nonzero(open_mask.any(0))[0]
            scale = int(art_width) / (xs_open.max() - xs_open.min() + 1)
        pair = []
        for mask in (open_mask, cells[3 + column]):
            ys, xs = np.nonzero(mask)
            part, inside = rgb[ys.min():ys.max() + 1, xs.min():xs.max() + 1], mask[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
            pair.append(reduce(part, inside, max(1, round(part.shape[1] * scale)), max(1, round(part.shape[0] * scale))))
        if "keep-x" in options:
            left, right = map(int, options["keep-x"].split(":"))
            pair = [a[:, left:right] for a in pair]
        fw, fh = max(a.shape[1] for a in pair), max(a.shape[0] for a in pair)
        fw += fw % 2
        strip = np.zeros((fh, fw * 2, 4), dtype=np.uint8)
        for i, a in enumerate(pair):
            x0 = i * fw + (fw - a.shape[1]) // 2
            strip[fh - a.shape[0]:, x0:x0 + a.shape[1]] = a
        arts.append(strip)
        names.append(name)
    snap(arts, int(options.get("colors", 16)))
    for name, art in zip(names, arts):
        image = save_2x(art, f"{out_dir}/{name}.png")
        print(f"{name} {image.width}x{image.height} frame {image.width // 2}x{image.height}")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    if args[0] == "facades":
        facades(args[1], args[2], args[3].split(","), opts)
    elif args[0] == "doorways":
        doorways(args[1], args[2], args[3].split(","), opts)
    else:
        door(args[1], args[2], opts)
