"""Cut a Codex sheet of separate props, drawn beside our Ivo as the scale figure, into 2x-density prop PNGs.

python -I tools/art/cut_props.py <sheet.png> <out dir> [--names=a,b,...] [--ref-height=29] [--merge=24] [--colors=24]
    [--flat=N] [--base-shade]
    Objects are the magenta-keyed sheet's connected parts, merged when closer than --merge source px. The leftmost
    object at least 1.6 times taller than wide is Ivo: every object is scaled by the factor that makes him --ref-height
    art px (his approved still, tools/art/sources/ivo/ivo_still_2x.png), reduced by each block's most common colour, snapped to one shared
    palette and written at 2x. Objects are numbered in reading order (rows by their centres, then left to right); with
    --names they are written as <name>.png in that order (`-` skips one), else as prop_<nn>.png, and a contact sheet
    `_index.png` labels them for naming.
    --flat=N reduces each object to N colours of its own and repaints every speck (a pixel no 8-neighbour shares) with
    its neighbours' most common colour, so a reduced drawing keeps flat areas. --base-shade darkens each object's
    bottom row by a fifth, a contact line where it meets the floor.
"""
import os
import sys
from collections import Counter

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

# `python -I` leaves the script's own folder off the path.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cut_facades import keyed, reduce, snap, save_2x  # noqa: E402


def objects(solid: np.ndarray, merge: int) -> list[tuple[slice, slice, np.ndarray]]:
    grown = ndimage.binary_dilation(solid, iterations=max(1, merge // 2))
    labels, _count = ndimage.label(grown)
    found = []
    for index, box in enumerate(ndimage.find_objects(labels)):
        mask = (labels[box] == index + 1) & solid[box]
        if mask.sum() >= 200:
            found.append((box[0], box[1], mask))
    return found


def flatten(art: np.ndarray, colors: int) -> None:
    opaque = art[..., 3] > 0
    px = art[..., :3][opaque]
    if len(px) > colors:
        quant = Image.fromarray(px.reshape(-1, 1, 3)).quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
        palette = np.array(quant.getpalette()[: 3 * colors]).reshape(-1, 3)
        art[..., :3][opaque] = palette[((px[:, None].astype(int) - palette[None]) ** 2).sum(-1).argmin(1)]
    for _pass in range(2):
        despeckle(art)


def despeckle(art: np.ndarray) -> None:
    h, w = art.shape[:2]
    source = art.copy()
    for y in range(h):
        for x in range(w):
            if source[y, x, 3] == 0:
                continue
            own = tuple(source[y, x, :3])
            neighbours = [tuple(source[j, i, :3]) for j in range(max(0, y - 1), min(h, y + 2))
                for i in range(max(0, x - 1), min(w, x + 2)) if (j, i) != (y, x) and source[j, i, 3] > 0]
            if neighbours and own not in neighbours:
                art[y, x, :3] = Counter(neighbours).most_common(1)[0][0]


def shade_base(art: np.ndarray) -> None:
    bottom = art[-1]
    opaque = bottom[:, 3] > 0
    bottom[opaque, :3] = (bottom[opaque, :3].astype(int) * 4 // 5).astype(np.uint8)


def reading_order(found: list, row_gap: float) -> list:
    rows: list[list] = []
    for item in sorted(found, key=lambda o: (o[0].start + o[0].stop) / 2):
        centre = (item[0].start + item[0].stop) / 2
        if rows and centre - rows[-1][0] <= row_gap:
            rows[-1][1].append(item)
        else:
            rows.append((centre, [item]))
    return [o for _centre, row in rows for o in sorted(row, key=lambda o: o[1].start)]


def main(sheet: str, out_dir: str, options: dict) -> None:
    rgb, solid = keyed(sheet)
    found = objects(solid, int(options.get("merge", 24)))
    # Ivo stands tall and narrow; a table or a bench may start further left.
    standing = [o for o in found if (o[0].stop - o[0].start) >= 1.6 * (o[1].stop - o[1].start)]
    figure = min(standing, key=lambda o: o[1].start)
    scale = int(options.get("ref-height", 29)) / (figure[0].stop - figure[0].start)
    ordered = reading_order([o for o in found if o is not figure], rgb.shape[0] * 0.12)
    arts = []
    for ys, xs, mask in ordered:
        part = rgb[ys, xs]
        art = reduce(part, mask, max(1, round(part.shape[1] * scale)), max(1, round(part.shape[0] * scale)))
        if "flat" in options:
            flatten(art, int(options["flat"]))
        arts.append(art)
    snap(arts, int(options.get("colors", 24)))
    for art in arts:
        if "flat" in options:
            despeckle(art)
        if "base-shade" in options:
            shade_base(art)
    names = options["names"].split(",") if "names" in options else [f"prop_{i:02d}" for i in range(len(arts))]
    for i, art in enumerate(arts):
        if i < len(names) and names[i] != "-":
            image = save_2x(art, f"{out_dir}/{names[i]}.png")
            print(f"{i:02d} {names[i]} {image.width}x{image.height}")
    index = Image.open(sheet).convert("RGB")
    draw = ImageDraw.Draw(index)
    for i, (ys, xs, _mask) in enumerate(ordered):
        draw.rectangle((xs.start, ys.start, xs.stop, ys.stop), outline=(0, 255, 0), width=3)
        draw.text((xs.start + 6, ys.start + 4), str(i), fill=(0, 0, 0))
    index.save(f"{out_dir}/_index.png")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(args[0], args[1], opts)
