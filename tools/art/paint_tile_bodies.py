"""Paint seamless 16 art px tile bodies from a spec, for a tile recipe (tools/art/tiles/<biome>_<look>.json).

python -I tools/art/paint_tile_bodies.py <spec.json> <out_stem>

A spec (tools/art/tiles/bodies/<biome>_<material>.json) names a kind and its colours, sampled from the approved Codex
sheet of the material (tools/art/tiles/sources/<biome>_tiles_codex_raw.png):
  soil      mottled earth (periodic value noise in "tones") with embedded "stones" and "roots"
  slabs     paving slabs in two courses (8 art px), offset by half, "joint" lines, rounded worn corners
  ashlar    dressed blocks in two courses ("block" art px wide), offset by half, thin joints
  drystone  flat irregular stones in rough courses (anisotropic periodic Voronoi), dark gaps
  basalt    big blocks with columnar cracks and round pores (a dark pixel over a lit rim pixel)
  scree     loose ash: mottled grey strewn with dark angular cinders and pale pumice chips
Every body repeats with a 16 art px period (all placement wraps), so it tiles by construction. "variants" lists one
detail each ("stone", "root", "pebbles", "twig", "crack", "groove", "chip", "stain", "carving", "wedge", "lichen",
"gap", "pores", "sulphur", "block", "pumice", "grit"), painted over the base only inside its outer 2 art px ring, so
every variant tiles with the base and with every other variant (systems/art-pipeline). Every detail is placed by its
variant's seed, and the tool refuses to write when two bodies differ by fewer than MIN_DIFFERENT art px. Writes
<out_stem>_0.png (the base) .. _N.png, 16x16 RGBA.
"""
import json
import math
import random
import sys

import numpy as np
from PIL import Image

N = 16
RING = 2
# Art px every two bodies of one material must differ by.
MIN_DIFFERENT = 6


def rgb(hexes):
    return [tuple(int(h.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4)) for h in hexes]


def value_noise(rng, cells):
    # Periodic smooth noise: a cells x cells lattice wrapped on the 16 px period, smoothstep-interpolated.
    lat = [[rng.random() for _ in range(cells)] for _ in range(cells)]
    out = np.zeros((N, N))
    step = N / cells
    for y in range(N):
        for x in range(N):
            gx, gy = x / step, y / step
            x0, y0 = int(gx) % cells, int(gy) % cells
            x1, y1 = (x0 + 1) % cells, (y0 + 1) % cells
            tx, ty = gx - int(gx), gy - int(gy)
            tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
            top = lat[y0][x0] * (1 - tx) + lat[y0][x1] * tx
            bottom = lat[y1][x0] * (1 - tx) + lat[y1][x1] * tx
            out[y, x] = top * (1 - ty) + bottom * ty
    return out


def mottle(rng, tones, cells=(4, 8), weights=(0.7, 0.3), cuts=None):
    # tones dark to light; the middle tone is the base, the noise picks darker or lighter patches.
    noise = sum(w * value_noise(rng, c) for c, w in zip(cells, weights))
    noise = (noise - noise.min()) / max(1e-6, noise.max() - noise.min())
    cuts = cuts or [i / len(tones) for i in range(1, len(tones))]
    img = np.zeros((N, N, 3), dtype=int)
    for y in range(N):
        for x in range(N):
            img[y, x] = tones[sum(noise[y, x] > c for c in cuts)]
    return img


def put(img, x, y, colour, clip=None):
    if clip is None:
        img[y % N, x % N] = colour
    elif clip[0] <= x <= clip[1] and clip[0] <= y <= clip[1]:
        img[y, x] = colour


def blob(img, cx, cy, rx, ry, body, light, shade, clip=None):
    # A rounded stone: body, its top row lit, its bottom row in shade.
    cells = [(x, y) for y in range(-ry, ry + 1) for x in range(-rx, rx + 1)
             if (x / (rx + 0.5)) ** 2 + (y / (ry + 0.5)) ** 2 <= 1.0]
    tops = {}
    bottoms = {}
    for x, y in cells:
        tops[x] = min(tops.get(x, y), y)
        bottoms[x] = max(bottoms.get(x, y), y)
    for x, y in cells:
        colour = light if y == tops[x] and light else shade if y == bottoms[x] and shade else body
        put(img, cx + x, cy + y, colour, clip)


def walk(img, rng, x, y, length, colour, clip=None, dirs=((1, 0), (1, 1), (1, -1), (1, 0))):
    for _ in range(length):
        put(img, x, y, colour, clip)
        dx, dy = rng.choice(dirs)
        x, y = x + dx, y + dy


def soil(spec, rng):
    c = spec["colors"]
    img = mottle(rng, rgb(c["tones"]), cuts=spec.get("cuts"))
    st = rgb(c["stone"])
    taken = []
    for _ in range(spec.get("stones", 3)):
        for _ in range(40):
            x, y = rng.randrange(N), rng.randrange(N)
            if all(min(abs(x - a), N - abs(x - a)) + min(abs(y - b), N - abs(y - b)) > 6 for a, b in taken):
                break
        taken.append((x, y))
        rx, ry = rng.choice(spec.get("stone_sizes", [[1, 1], [2, 1], [1, 0]]))
        blob(img, x, y, rx, ry, st[1], st[2], st[0])
    for _ in range(spec.get("roots", 1)):
        walk(img, rng, rng.randrange(N), rng.randrange(N), rng.randint(4, 7), rgb(c["root"])[0])
    return img


def courses(spec, rng, block, rounded):
    c = spec["colors"]
    faces, joint = rgb(c["faces"]), rgb(c["joint"])[0]
    light = rgb(c.get("light", c["faces"][-1:]))[0]
    img = np.zeros((N, N, 3), dtype=int)
    for course in range(2):
        y0 = course * 8
        offset = (block // 2) * course
        for b in range(N // block):
            x0 = b * block + offset
            face = rng.choice(faces)
            for y in range(8):
                for x in range(block):
                    px, py = (x0 + x) % N, y0 + y
                    if y == 7 or x == block - 1:
                        img[py, px] = joint
                    elif rounded and (x, y) in ((0, 0), (block - 2, 0), (0, 6), (block - 2, 6)):
                        img[py, px] = joint
                    elif y == 0 and spec.get("lit_top", True):
                        img[py, px] = light
                    else:
                        img[py, px] = face
            # A few worn patches per face, one tone off.
            for _ in range(spec.get("wear", 2)):
                px, py = (x0 + rng.randint(1, block - 3)) % N, y0 + rng.randint(1, 5)
                img[py, px] = rng.choice(faces)
    return img


def voronoi(sites, sx=1.0, sy=1.0):
    near = np.zeros((N, N), dtype=int)
    gap = np.zeros((N, N))
    for y in range(N):
        for x in range(N):
            d = []
            for i, (a, b) in enumerate(sites):
                dx = min(abs(x - a), N - abs(x - a)) * sx
                dy = min(abs(y - b), N - abs(y - b)) * sy
                d.append((math.hypot(dx, dy), i))
            d.sort()
            near[y, x] = d[0][1]
            gap[y, x] = d[1][0] - d[0][0]
    return near, gap


def drystone(spec, rng):
    # Two courses of flat stones of random widths (summing to the period), each with a random top inset so the gaps
    # wander; lit top row, shaded bottom row, cut corners.
    c = spec["colors"]
    faces, joint, light, shade = rgb(c["faces"]), rgb(c["joint"])[0], rgb(c["light"])[0], rgb(c["shade"])[0]
    img = np.zeros((N, N, 3), dtype=int)
    img[:, :] = joint
    for course in range(2):
        widths = []
        while sum(widths) < N:
            widths.append(rng.choice(spec.get("widths", [6, 7, 8, 9, 10])))
        widths[-1] -= sum(widths) - N
        if widths[-1] < 5:
            widths[-2] += widths.pop()
        x0 = rng.randrange(N)
        for w in widths:
            top = course * 8 + rng.choice([0, 0, 1])
            bottom = course * 8 + 6
            face = rng.choice(faces)
            for y in range(top, bottom + 1):
                for x in range(w - 1):
                    corner = (x in (0, w - 2)) and (y in (top, bottom))
                    if corner:
                        continue
                    colour = light if y == top else shade if y == bottom else face
                    img[y % N, (x0 + x) % N] = colour
            x0 += w
    return img


def basalt(spec, rng):
    c = spec["colors"]
    faces, crack, pore, rim = rgb(c["faces"]), rgb(c["crack"])[0], rgb(c["pore"])[0], rgb(c["rim"])[0]
    sites = [((k * N / 3 + rng.uniform(-1, 1)) % N, rng.uniform(0, N)) for k in range(3)]
    _, gap = voronoi(sites, sx=1.0, sy=0.35)
    img = mottle(rng, faces, cells=(4, 8))
    for y in range(N):
        for x in range(N):
            if gap[y, x] < 0.8:
                img[y, x] = crack
    pores(img, rng, spec.get("pores", 6), pore, rim)
    return img


def pores(img, rng, count, pore, rim, clip=None, spread=None):
    taken = []
    for _ in range(count):
        for _ in range(60):
            if spread:
                x, y = spread[0] + rng.randint(-2, 2), spread[1] + rng.randint(-2, 2)
            else:
                x, y = rng.randrange(N), rng.randrange(N)
            if all(min(abs(x - a), N - abs(x - a)) > 1 or min(abs(y - b), N - abs(y - b)) > 2 for a, b in taken):
                break
        taken.append((x, y))
        put(img, x, y, pore, clip)
        put(img, x, y + 1, rim, clip)


def scree(spec, rng):
    c = spec["colors"]
    img = mottle(rng, rgb(c["tones"]), cuts=spec.get("cuts", [0.3, 0.75]))
    cinder, cinder_lit, pumice, pumice_shade = (rgb(c[k])[0] for k in ("cinder", "cinder_lit", "pumice", "pumice_shade"))
    shapes = [[(0, 0), (1, 0)], [(0, 0), (0, 1)], [(0, 0), (1, 0), (0, 1)], [(0, 0), (1, 0), (1, 1)], [(0, 0)],
              [(0, 0), (1, 0), (0, 1), (1, 1)]]
    for _ in range(spec.get("cinders", 8)):
        x, y = rng.randrange(N), rng.randrange(N)
        shape = rng.choice(shapes)
        for i, (dx, dy) in enumerate(shape):
            put(img, x + dx, y + dy, cinder_lit if i == 0 and len(shape) > 2 else cinder)
    for _ in range(spec.get("pumice", 4)):
        x, y = rng.randrange(N), rng.randrange(N)
        put(img, x, y, pumice)
        put(img, x + 1, y, pumice)
        put(img, x, y + 1, pumice_shade)
    return img


KINDS = {"soil": soil, "drystone": drystone, "basalt": basalt, "scree": scree,
         "slabs": lambda s, r: courses(s, r, 8, True), "ashlar": lambda s, r: courses(s, r, s.get("block", 8), False)}


def detail(img, spec, kind, rng):
    # Every detail takes its place from the variant's seed, inside the base's outer ring.
    c = spec["colors"]
    clip = (RING, N - 1 - RING)
    x, y = rng.randint(RING + 1, N - 5 - RING), rng.randint(RING + 1, N - 5 - RING)
    if kind == "stone":
        st = rgb(c["stone"])
        blob(img, x + 2, y + 1, 2, 1, st[1], st[2], st[0], clip)
    elif kind == "pebbles":
        st = rgb(c["stone"])
        for dx, dy in ((0, 0), (3, 1), (1, 3)):
            px, py = x + dx + rng.randint(0, 1), y + dy + rng.randint(0, 1)
            put(img, px, py, st[2], clip)
            put(img, px + 1, py, st[1], clip)
    elif kind == "root":
        walk(img, rng, x - 1, y, 9, rgb(c["root"])[0], clip)
        walk(img, rng, x + 3, y, 5, rgb(c["root"])[0], clip, dirs=((1, 1), (0, 1), (1, 1)))
    elif kind == "twig":
        walk(img, rng, x, y + 2, 7, rgb(c.get("twig", c["root"]))[0], clip, dirs=((1, 0), (1, -1)))
    elif kind == "crack":
        colour = rgb(c.get("crack", c.get("joint", ["#000000"])))[0]
        walk(img, rng, x - 1, y - 1, 9, colour, clip, dirs=((1, 1), (1, 0), (0, 1)))
    elif kind == "groove":
        colour = rgb(c.get("groove", c["joint"]))[0]
        for gx in range(x - 1, x + 6):
            put(img, gx, y, colour, clip)
            if (gx - x) % 3:
                put(img, gx, y + 2, colour, clip)
    elif kind == "chip":
        colour, light = rgb(c["joint"])[0], rgb(c.get("light", c["joint"]))[0]
        for dx, dy in ((0, 0), (1, 0), (2, 0), (0, 1), (1, 1)):
            put(img, x + dx, y + dy, colour, clip)
        put(img, x + 2, y + 1, light, clip)
    elif kind == "stain":
        colour = rgb(c["stain"])[0]
        for sy in range(y - 1, y + rng.randint(5, 7)):
            put(img, x, sy, colour, clip)
            if sy > y + 1:
                put(img, x + 1, sy, colour, clip)
    elif kind == "carving":
        colour = rgb(c.get("carving", c["joint"]))[0]
        for gx in range(x - 1, x + 5):
            put(img, gx, y, colour, clip)
            put(img, gx, y + 2, colour, clip)
    elif kind == "wedge":
        st = rgb(c["faces"])
        for dx, dy in ((0, 0), (1, 0), (2, 0), (0, 1), (1, 1)):
            put(img, x + dx, y + dy, st[-1], clip)
        put(img, x + 2, y + 1, rgb(c["shade"])[0], clip)
    elif kind == "lichen":
        colour = rgb(c["lichen"])[0]
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1), (2, 0), (2, 1)):
            put(img, x + dx, y + dy, colour, clip)
    elif kind == "gap":
        colour = rgb(c["joint"])[0]
        for dx, dy in ((0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)):
            put(img, x + dx, y + dy, colour, clip)
    elif kind == "pores":
        pores(img, rng, 4, rgb(c["pore"])[0], rgb(c["rim"])[0], clip, spread=(x + 1, y + 1))
    elif kind == "sulphur":
        colour = rgb(c["sulphur"])
        for dx, dy, k in ((0, 0, 0), (1, 0, 1), (0, 1, 0), (1, 1, 1), (3, 2, 1), (3, 3, 0)):
            put(img, x + dx, y + dy, colour[k % len(colour)], clip)
    elif kind == "block":
        cinder, lit = rgb(c["cinder"])[0], rgb(c["cinder_lit"])[0]
        for dy in range(3):
            for dx in range(3 if dy else 2):
                put(img, x + dx, y + dy, lit if dy == 0 else cinder, clip)
    elif kind == "pumice":
        p, s = rgb(c["pumice"])[0], rgb(c["pumice_shade"])[0]
        for dx in range(3):
            put(img, x + dx, y, p, clip)
            put(img, x + dx, y + 1, s if dx else p, clip)
    elif kind == "grit":
        colour = rgb(c["cinder"])[0]
        for dx, dy in ((0, 0), (2, 0), (1, 1), (3, 1), (0, 2), (2, 3), (3, 3), (1, 3)):
            put(img, x + dx, y + dy, colour, clip)
    else:
        raise ValueError(f"unknown detail {kind}")


def differing(a, b):
    return int((a != b).any(-1).sum())


def main():
    spec = json.load(open(sys.argv[1], encoding="utf-8"))
    stem = sys.argv[2]
    base = KINDS[spec["kind"]](spec, random.Random(spec.get("seed", 1)))
    out = [base]
    for i, variant in enumerate(spec.get("variants", [])):
        rng = random.Random(variant.get("seed", 100 + i))
        for _ in range(40):
            # A spot where the detail mostly lands on colours it already has (a chip on a joint) is drawn again.
            img = base.copy()
            detail(img, spec, variant["detail"], rng)
            if differing(img, base) >= MIN_DIFFERENT and all(differing(img, other) >= MIN_DIFFERENT for other in out):
                break
        out.append(img)
    # A variant that is almost the base or another variant draws the same cell twice (bugs/painted-tile-variants-repeat-
    # because-fixed-position-details-ignore-their-seed).
    pairs = [(i, j, differing(out[i], out[j])) for i in range(len(out)) for j in range(i + 1, len(out))]
    close = [f"{i}-{j}: {n} px" for i, j, n in pairs if n < MIN_DIFFERENT]
    if close:
        sys.exit(f"{stem}: bodies differ by fewer than {MIN_DIFFERENT} art px: {', '.join(close)}")
    for i, img in enumerate(out):
        Image.fromarray(img.astype(np.uint8), "RGB").convert("RGBA").save(f"{stem}_{i}.png")
    least = min(n for _, _, n in pairs) if pairs else 0
    print(f"{stem}: {len(out)} bodies, {len({tuple(p) for img in out for p in img.reshape(-1, 3)})} colours, "
          f"the closest pair {least} px apart")


if __name__ == "__main__":
    main()
