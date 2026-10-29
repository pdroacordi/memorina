"""Pad a 2x still onto a transparent frame-sized canvas, the reference PixelLab animates in place.

python -I tools/art/pad_reference.py <still_2x.png> <out.png> <W>x<H> [--at=bottom|top|middle]
    The still keeps its pixels and lands centred across the frame on an even column (the 2x grid) with its bottom row on
    the frame's bottom row (a walker), its top row on the top row (a bat hanging) or centred on an even row (a flyer).
    animate-with-text-v3 returns frames the size of its reference, so the canvas is the room a clip can move in.
"""
import sys

from PIL import Image


def main(src: str, out: str, size: str, at: str) -> None:
    width, height = map(int, size.split("x"))
    still = Image.open(src).convert("RGBA")
    if still.width > width or still.height > height:
        sys.exit(f"{src}: {still.width}x{still.height} does not fit {size}")
    x = (width - still.width) // 2
    y = {"bottom": height - still.height, "top": 0, "middle": (height - still.height) // 2}[at]
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    canvas.alpha_composite(still, (x - x % 2, y - y % 2))
    canvas.save(out)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(args[0], args[1], args[2], opts.get("at", "bottom"))
