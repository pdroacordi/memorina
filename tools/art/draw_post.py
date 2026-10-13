"""Draw a squared wooden post: the mill bridge's pile, or the pole the square's bunting is tied to.

python -I tools/art/draw_post.py <out.png> [--height=24] [--cap]
    6 art px wide and `--height` tall, written at 2x: a lit left edge, a shaded right edge, a dark band near the top
    where a beam or a string rests on it; `--cap` adds a one-row cap an art px wider each side. The colours are the
    village fences' timber.
"""
import sys

from PIL import Image

LIGHT, BODY, DARK, BAND = (156, 89, 41), (124, 71, 32), (90, 48, 25), (80, 43, 22)
W = 6


def main(out: str, height: int, cap: bool) -> None:
    pad = 1 if cap else 0
    art = Image.new("RGBA", (W + pad * 2, height))
    for y in range(height):
        for x in range(W):
            colour = LIGHT if x == 0 else DARK if x == W - 1 else BODY
            if y in (1 + pad, 2 + pad):
                colour = BAND
            art.putpixel((x + pad, y), (*colour, 255))
    if cap:
        for x in range(W + 2):
            art.putpixel((x, 0), (*BAND, 255))
    art.resize((art.width * 2, height * 2), Image.NEAREST).save(out)
    print(out, art.width * 2, height * 2)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(args[0], int(opts.get("height", 24)), "cap" in opts)
