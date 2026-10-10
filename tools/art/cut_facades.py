"""Cut Codex building fronts (and the door) into 2x-density prop sheets.

Facades: python -I tools/art/cut_facades.py facades <sheet.png> <out dir> <name,name,...> [--grid=3x2] [--colors=20]
    [--crop-top=name:rows]. Each building is scaled so its doorway (the dark opening that reaches the ground line) is
    32 art px tall, reduced by each block's most common colour, snapped to one shared palette, given a flat 16x32 art px
    doorway recess and written at 2x as <name>_facade.png. Prints each sheet's size and its anchor (the doorway's
    sill centre, game px): the prop scene's offset is minus the anchor (architecture/props-and-ambient-life).
Door: python -I tools/art/cut_facades.py door <sheet.png> <out.png> [--colors=10]: two doors side by side, each cut
    to its plank body and reduced to 16x32 art px, written at 2x as a 64x64 two-frame strip.
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


def save_2x(art: np.ndarray, path: str) -> Image.Image:
    image = Image.fromarray(art, "RGBA")
    image = image.resize((image.width * ART_SCALE, image.height * ART_SCALE), Image.NEAREST)
    image.save(path)
    return image


def facades(sheet: str, out_dir: str, names: list[str], options: dict) -> None:
    rgb, solid = keyed(sheet)
    cols, rows = map(int, options.get("grid", "3x2").split("x"))
    crop_top = dict((k, int(v)) for k, v in (c.split(":") for c in options.get("crop-top", "").split(",") if c))
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
    arts, centres_x = [], []
    for name, mask in zip(names, cells):
        ys, xs = np.nonzero(mask)
        part, inside = rgb[ys.min():ys.max() + 1, xs.min():xs.max() + 1], mask[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        dark = (part @ LUMA < 48) & inside
        dark_labels, dark_count = ndimage.label(dark)
        best = None
        for d in range(1, dark_count + 1):
            dy, dx = np.nonzero(dark_labels == d)
            if dy.max() >= part.shape[0] - 12 and (best is None or dy.size > best[0]):
                best = (dy.size, dy.min(), dx.min(), dx.max())
        assert best is not None, f"{name}: no doorway reaches the ground line"
        scale = DOOR_ART[1] / (part.shape[0] - best[1])
        art = reduce(part, inside, round(part.shape[1] * scale), round(part.shape[0] * scale))
        arts.append(art[crop_top.get(name, 0):])
        centres_x.append(int(round((best[2] + best[3] + 1) / 2 * scale)))
    palette = snap(arts, int(options.get("colors", 20)))
    darkest = palette[(palette @ LUMA).argmin()]
    for name, art, cx in zip(names, arts, centres_x):
        half = DOOR_ART[0] // 2
        art[-DOOR_ART[1]:, cx - half:cx + half] = (*darkest, 255)
        image = save_2x(art, f"{out_dir}/{name}_facade.png")
        print(f"{name}_facade {image.width}x{image.height} anchor {cx * ART_SCALE},{image.height}")


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


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    if args[0] == "facades":
        facades(args[1], args[2], args[3].split(","), opts)
    else:
        door(args[1], args[2], opts)
