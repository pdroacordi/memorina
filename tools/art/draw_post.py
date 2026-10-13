"""Draw a squared wooden post: the mill bridge's pile, the pole the square's bunting is tied to, or a pier post's foot.

python -I tools/art/draw_post.py <out.png> [--height=24] [--cap] [--foot]
    6 art px wide and `--height` tall, written at 2x: a lit left edge, a shaded right edge, a dark band near the top
    where a beam or a string rests on it; `--cap` adds a one-row cap an art px wider each side. The colours are the
    village fences' timber.
    `--foot` draws instead the part of a pier post in a lake (WORLD-29): a pale ripple row an art px wider each side,
    then the post pulled toward the lake's dark blue in two flat steps.
"""
import sys

from PIL import Image

LIGHT, BODY, DARK, BAND = (156, 89, 41), (124, 71, 32), (90, 48, 25), (80, 43, 22)
RIPPLE = (196, 206, 214)
LAKE = (60, 72, 96)
W = 6


def _toward(colour: tuple[int, int, int], target: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
    return tuple(round(c + (t - c) * amount) for c, t in zip(colour, target))


def post(height: int, cap: bool) -> Image.Image:
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
    return art


def foot(height: int) -> Image.Image:
    art = Image.new("RGBA", (W + 2, height))
    for x in range(W + 2):
        art.putpixel((x, 0), (*RIPPLE, 255))
    for y in range(1, height):
        amount = 0.5 if y <= height // 2 else 0.75
        for x in range(W):
            colour = LIGHT if x == 0 else DARK if x == W - 1 else BODY
            art.putpixel((x + 1, y), (*_toward(colour, LAKE, amount), 255))
    return art


def main(out: str, height: int, cap: bool, is_foot: bool) -> None:
    art = foot(height) if is_foot else post(height, cap)
    art.resize((art.width * 2, height * 2), Image.NEAREST).save(out)
    print(out, art.width * 2, height * 2)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(args[0], int(opts.get("height", 24)), "cap" in opts, "foot" in opts)
