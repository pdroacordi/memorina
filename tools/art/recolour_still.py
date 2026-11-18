"""Recolour a still (or a strip) through the colour map between two stills drawn on the same mask.

python -I tools/art/recolour_still.py <from.png> <to.png> <in.png> <out.png> [--drop=D] [--drop-colours=<png>]
    <from.png> and <to.png> share an alpha mask pixel for pixel (`stasis.png` is `empty_hand.png` greyed); every
    colour of <from.png> maps to the colour <to.png> has at the same pixels. Each opaque pixel of <in.png> snaps to the
    nearest <from.png> colour, then takes its mapped colour. --drop=D clears every pixel farther than D (RGB distance)
    from all <from.png> colours first: a colour the source still never had. --drop-colours=<png> clears every pixel
    nearer to a colour of that image than to any <from.png> colour (the flute in `turn.png`: `memorina_in_hand.png`).
"""
import sys

from PIL import Image


def colour_map(src: Image.Image, dst: Image.Image) -> dict:
    if src.size != dst.size:
        sys.exit(f"the two stills differ in size: {src.size} and {dst.size}")
    mapping: dict = {}
    for a, b in zip(src.getdata(), dst.getdata()):
        if (a[3] > 0) != (b[3] > 0):
            sys.exit("the two stills' alpha masks differ")
        if a[3] == 0:
            continue
        key = a[:3]
        if mapping.setdefault(key, b[:3]) != b[:3]:
            sys.exit(f"colour {key} maps to two colours")
    return mapping


def nearest(colour: tuple, palette: list) -> tuple:
    return min(palette, key=lambda p: sum((x - y) ** 2 for x, y in zip(colour, p)))


def main(src_path: str, dst_path: str, in_path: str, out_path: str, drop: float, drop_colours: str) -> None:
    mapping = colour_map(Image.open(src_path).convert("RGBA"), Image.open(dst_path).convert("RGBA"))
    palette = list(mapping)
    cut: list = []
    if drop_colours:
        cut = sorted({p[:3] for p in Image.open(drop_colours).convert("RGBA").getdata() if p[3] > 0} - set(palette))
    image = Image.open(in_path).convert("RGBA")
    out = []
    dropped = 0
    for pixel in image.getdata():
        if pixel[3] == 0:
            out.append(pixel)
            continue
        snapped = nearest(pixel[:3], palette)
        if cut and nearest(pixel[:3], palette + cut) in cut:
            out.append((0, 0, 0, 0))
            dropped += 1
            continue
        if drop > 0 and sum((x - y) ** 2 for x, y in zip(pixel[:3], snapped)) > drop * drop:
            out.append((0, 0, 0, 0))
            dropped += 1
            continue
        out.append(mapping[snapped] + (255,))
    image.putdata(out)
    image.save(out_path)
    print(f"{out_path}: {image.size[0]}x{image.size[1]}, {dropped} px dropped")


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(args[0], args[1], args[2], args[3], float(opts.get("drop", "0")), opts.get("drop-colours", ""))
