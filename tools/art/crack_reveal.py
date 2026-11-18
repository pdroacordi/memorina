"""Grow cracks across one still and show another through them, frame by frame (STORY-38's waking keeper).

python -I tools/art/crack_reveal.py <top.png> <top_at_x,y> <under.png> <under_at_x,y> <out.png> <frame WxH> <frames>
    [--seed=N] [--flip-under] [--start=x,y]
<top.png> (the stasis still) is drawn at top_at on each frame; <under.png> (the body's first frame, already at game
size) at under_at. Cracks are seeded random walks on the 2x art grid from --start (the mask) downward; frame k shows
<under.png> through the first k/(frames-1) of each walk, two art px wide, and pale flakes from the cracks' edges fall
two art px a frame. Frame 0 is <top.png> exactly. Our own art only.
"""
import random
import sys

from PIL import Image, ImageOps


def walks(seed: int, start: tuple, height: int, count: int) -> list:
    rng = random.Random(seed)
    paths = []
    for i in range(count):
        x, y = start[0] + rng.choice((-4, -2, 0, 2, 4)), start[1] + rng.choice((0, 2, 4))
        path = [(x, y)]
        while y < height - 4:
            y += 2
            x += rng.choice((-2, 0, 0, 2)) + (2 if i % 2 else -2) * (rng.random() < 0.15)
            path.append((x, y))
        paths.append(path)
    return paths


def main(argv: list) -> None:
    args = [a for a in argv if not a.startswith("--")]
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in argv if a.startswith("--"))
    top = Image.open(args[0]).convert("RGBA")
    top_at = tuple(int(v) for v in args[1].split(","))
    under = Image.open(args[2]).convert("RGBA")
    if "flip-under" in opts:
        under = ImageOps.mirror(under)
    under_at = tuple(int(v) for v in args[3].split(","))
    out_path = args[4]
    width, height = (int(v) for v in args[5].split("x"))
    frames = int(args[6])
    start = tuple(int(v) for v in opts.get("start", f"{top_at[0] + top.width // 2},{top_at[1] + 8}").split(","))
    paths = walks(int(opts.get("seed", "7")), start, height, 5)

    base = Image.new("RGBA", (width, height))
    base.alpha_composite(top, top_at)
    below = Image.new("RGBA", (width, height))
    below.alpha_composite(under, under_at)
    strip = Image.new("RGBA", (width * frames, height))
    for k in range(frames):
        frame = base.copy()
        share = k / (frames - 1)
        flakes = []
        for path in paths:
            for x, y in path[: int(len(path) * share)]:
                for dx in (0, 1):
                    for dy in (0, 1):
                        px, py = x + dx, y + dy
                        if not (0 <= px < width and 0 <= py < height) or base.getpixel((px, py))[3] == 0:
                            continue
                        shown = below.getpixel((px, py))
                        frame.putpixel((px, py), shown if shown[3] > 0 else (0, 0, 0, 0))
                if (x + y) % 22 == 0:
                    flakes.append((x + 2, y))
        for x, y in flakes:
            fy = y + 2 * k
            colour = base.getpixel((min(x, width - 1), min(y, height - 1)))
            if colour[3] == 0 or fy + 1 >= height:
                continue
            for dx in (0, 1):
                for dy in (0, 1):
                    if 0 <= x + dx < width:
                        frame.putpixel((x + dx, fy + dy), colour)
        strip.alpha_composite(frame, (k * width, 0))
    strip.save(out_path)
    print(f"{out_path}: {frames} frames of {width}x{height}")


if __name__ == "__main__":
    main(sys.argv[1:])
