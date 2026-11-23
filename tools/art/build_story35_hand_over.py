"""Build STORY-35's five hand-over strips from their PixelLab frames, with every seam frame pasted exactly.

python -I tools/art/build_story35_hand_over.py [--out=<dir>]
Writes give.png and let_go.png (assets/sprites/world/story/mentor/) and ivo_memorina_reach/take/hold.png
(assets/sprites/characters/ivo/), or all five into --out. Plan and measurements:
docs/knowledge/architecture/story35-memorina-hand-over.md; contracts tools/art/prompts/story_*_give.md and the rest.
- give: hold_out frame 3, then the generation's frames 4, 5, 6 locked to it (lock_to_still.py --mirror), each with its
  drawn flute replaced by hold_out frame 3's flute at the arm's tip, kept 22 px or more from the frame's left edge.
- let_go: give 3; give 3 without the flute, fingers open; lower.png frames 2 and 1 without the flute; empty_hand_breathe 0.
- reach: ivo_idle 0, then the generation's frames 1, 2, 3, 5 (cut_inhabitant.py, Ivo's palette).
- take: reach 4 with give 3's flute moved by FLUTE_TO_IVO and closed fingers; the generation's frames 1 and 2; frame 2
  with its torso 2 px longer and its head 1 px higher (GROWN), its flute at GROWN_FLUTE; the raise generation's frames 4, 3, 2, 1 (played
  backward) with their back arm from ivo_memorina_lower 1 and their flute replaced by the keeper's scaled to FLUTE_STEPS;
  ivo_memorina_lower 1 with the hand 2 px higher; ivo_memorina_lower 1. The flute shrinks and the figure grows over
  frames 3-8, not in one frame.
- hold: ivo_memorina_lower 1; the head 2 px up; everything over row 70 2 px up; that with the flute hand back down.
"""
import os
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image, ImageOps
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "tools/art/sources/story")
MENTOR = os.path.join(ROOT, "assets/sprites/world/story/mentor")
IVO = os.path.join(ROOT, "assets/sprites/characters/ivo")
F = 128
# The keeper's flute: hold_out frame 3's colours that his body never uses.
FLUTE = [(142, 92, 57), (157, 127, 91), (227, 211, 170), (100, 66, 51)]
# Mentor file (col, row) -> Ivo file at ivo_near (776, 672) facing west: world x = 786 - col = 839 - ivo col,
# world y = 546 + row = 576 + ivo row.
FLUTE_TO_IVO = (53, -30)
ARM = (218, 207, 189, 255)
SKIN = (247, 175, 112, 255)
OPEN_FINGERS = [(30, 62), (28, 60), (30, 66), (28, 68)]
CLOSED_FINGERS = [(86, 46), (88, 46), (88, 44), (80, 46), (80, 48)]
# Ivo file rows (head top, shoulders, waist, feet) of take frame 2 and where frame 3 draws them.
GROWN = ([34, 50, 62, 95], [33, 50, 64, 95])
# (height, width) of the keeper's flute in that frame, which the row stretch would lengthen.
GROWN_FLUTE = (14, 12)
# (height, width) of the keeper's flute in the raise generation's frames 4, 3, 2, 1, from 16x14 down toward the 4 px
# Memorina of ivo_memorina_lower.
FLUTE_STEPS = [(11, 10), (9, 8), (7, 6), (5, 4)]
# Ivo file rows and columns the raise generation's back arm swings through; ivo_memorina_lower 1's arm replaces it.
BACK_ARM = (slice(50, 80), slice(0, 58))


def load(path):
    return np.array(Image.open(path).convert("RGBA"))


def frame(strip, k):
    return strip[:, F * k:F * k + F].copy()


def flute_mask(a, right=40):
    m = np.zeros(a.shape[:2], bool)
    for c in FLUTE:
        m |= (a[..., :3] == c).all(-1) & (a[..., 3] > 0)
    m[:, right:] = False
    return m


def despeckled(a, least=16):
    labels, n = ndimage.label(a[..., 3] > 0, structure=np.ones((3, 3)))
    for i in range(1, n + 1):
        if (labels == i).sum() < least:
            a[labels == i] = 0
    return a


def colour_mask(a, colours, left=0):
    m = np.zeros(a.shape[:2], bool)
    for c in colours:
        m |= (a[..., :3] == c).all(-1) & (a[..., 3] > 0)
    m[:, :left] = False
    return m


def remapped(a, src, dst):
    """Each row inside dst's span drawn from the source row at the same fraction of src's span (nearest)."""
    b = a.copy()
    for y in range(dst[0], dst[-1] + 1):
        b[y] = a[int(round(np.interp(y, dst, src)))]
    return b


def holding(a, patch, size, ivo_colours):
    """`a` with every colour outside Ivo's palette right of column 70 (the flute it holds) replaced by `patch` at
    `size`, centred where that flute was."""
    b = a.copy()
    m = colour_mask(b, {tuple(c[:3]) for c in b[b[..., 3] > 0]} - ivo_colours, left=70)
    ys, xs = np.nonzero(m)
    cy, cx = (ys.min() + ys.max()) // 2, (xs.min() + xs.max()) // 2
    b[m] = 0
    h, w = size
    p = np.array(Image.fromarray(patch).resize((w, h), Image.NEAREST))
    pm = p[..., 3] > 0
    b[cy - h // 2:cy - h // 2 + h, cx - w // 2:cx - w // 2 + w][pm] = p[pm]
    return b


def run(*args):
    subprocess.run([sys.executable, "-I", *args], check=True, cwd=ROOT, stdout=subprocess.DEVNULL)


def stretched(a, row, d=2):
    """Everything above game row `row` moves up d px; the d rows under the cut repeat."""
    b = a.copy()
    b[:row - d] = a[d:row]
    return b


def main(out_dir):
    tmp = tempfile.mkdtemp()
    hold_out3 = frame(load(f"{MENTOR}/hold_out.png"), 3)
    # give
    run("tools/art/cut_inhabitant.py", f"{SRC}/mentor_give", "give", f"{SRC}/mentor_hold_out_f3_2x.png",
        f"{tmp}/give_cut.png", "--keep=0-6", "--frame=128", "--at=0,0", "--floor=125")
    Image.fromarray(hold_out3).save(f"{tmp}/still.png")
    run("tools/art/lock_to_still.py", f"{tmp}/give_cut.png", f"{tmp}/still.png", f"{tmp}/give_lock.png",
        "--keep=0,1,2,3,4,5,6", "--mirror")
    lock = load(f"{tmp}/give_lock.png")
    patch = hold_out3[34:50, 18:32].copy()
    patch[~flute_mask(patch, 14)] = 0
    give = [hold_out3]
    for k in (4, 5, 6):
        f = frame(lock, k)
        drawn = flute_mask(f)
        drawn[:30] = False
        f[drawn] = 0
        arm = np.zeros(f.shape[:2], bool)
        arm[50:76, :40] = True
        ys, xs = np.nonzero(arm & (f[..., 3] > 0))
        tip = xs.min()
        x, y = max(tip - 8, 22), ys[xs <= tip + 3].min()
        m = patch[..., 3] > 0
        f[y:y + 16, x:x + 14][m] = patch[m]
        give.append(f)
    empty = frame(lock, 6)
    gone = flute_mask(empty)
    gone[:30] = False
    empty[gone] = 0
    empty = despeckled(empty)
    ImageOps.mirror(Image.fromarray(empty)).save(f"{SRC}/mentor_give_f3_empty_2x.png")
    # let_go
    opened = empty.copy()
    for x, y in OPEN_FINGERS:
        opened[y:y + 2, x:x + 2] = ARM
    lower = load(f"{MENTOR}/lower.png")
    breathe = load(f"{MENTOR}/empty_hand_breathe.png")
    body = {tuple(c[:3]) for c in breathe.reshape(-1, 4) if c[3] > 0}
    withdraw = []
    for k in (2, 1):
        f = frame(lower, k)
        m = np.zeros(f.shape[:2], bool)
        for c in {tuple(c[:3]) for c in f[:, :40].reshape(-1, 4) if c[3] > 0} - body:
            m |= (f[..., :3] == c).all(-1) & (f[..., 3] > 0)
        m[:, 44:] = False
        f[m] = 0
        withdraw.append(despeckled(f))
    let_go = [give[3], opened, *withdraw, frame(breathe, 0)]
    # reach
    idle0 = frame(load(f"{IVO}/ivo_idle.png"), 0)
    run("tools/art/cut_inhabitant.py", f"{SRC}/ivo_memorina_reach", "reach", "tools/art/sources/ivo/ivo_palette.png",
        f"{tmp}/reach_cut.png", "--keep=0-6", "--floor=95", "--centre=36-56")
    reach_cut = load(f"{tmp}/reach_cut.png")
    reach = [idle0] + [frame(reach_cut, k) for k in (1, 2, 3, 5)]
    # take
    lower1 = frame(load(f"{IVO}/ivo_memorina_lower.png"), 1)
    take0 = np.zeros_like(lower1)
    ys, xs = np.nonzero(flute_mask(give[3]))
    take0[ys + FLUTE_TO_IVO[1], xs + FLUTE_TO_IVO[0]] = give[3][ys, xs]
    hand = reach[4][..., 3] > 0
    take0[hand] = reach[4][hand]
    for x, y in CLOSED_FINGERS:
        take0[y:y + 2, x:x + 2] = SKIN
    palette = set()
    for path in ("tools/art/sources/ivo/ivo_palette.png", f"{SRC}/ivo_memorina_still_2x.png"):
        palette |= {tuple(c[:3]) for c in load(path).reshape(-1, 4) if c[3] > 0}
    palette |= {tuple(c[:3]) for c in take0.reshape(-1, 4) if c[3] > 0}
    strip = np.zeros((1, len(palette), 4), np.uint8)
    strip[0, :, :3] = sorted(palette)
    strip[0, :, 3] = 255
    Image.fromarray(strip).save(f"{SRC}/ivo_memorina_take_palette.png")
    run("tools/art/cut_inhabitant.py", f"{SRC}/ivo_memorina_take", "take", f"{SRC}/ivo_memorina_take_palette.png",
        f"{tmp}/take_cut.png", "--keep=0-8", "--floor=95", "--centre=80-96")
    run("tools/art/cut_inhabitant.py", f"{SRC}/ivo_memorina_take", "raise_rev", f"{SRC}/ivo_memorina_still_2x.png",
        f"{tmp}/raise_cut.png", "--keep=0-6", "--floor=95", "--centre=80-96")
    take_cut, raise_cut = load(f"{tmp}/take_cut.png"), load(f"{tmp}/raise_cut.png")
    # Frame 1 two px back, so its legs stand where take 0's stand.
    lifted = lower1.copy()
    block = lower1[46:74, 72:].copy()
    lifted[46:74, 72:] = 0
    by, bx = np.nonzero(block[..., 3] > 0)
    lifted[by + 44, bx + 72] = block[by, bx]
    ys, xs = np.nonzero(flute_mask(take0, F))
    box = (slice(ys.min(), ys.max() + 1), slice(xs.min(), xs.max() + 1))
    patch = take0[box].copy()
    patch[~flute_mask(take0, F)[box]] = 0
    ivo_colours = {tuple(c[:3]) for c in load("tools/art/sources/ivo/ivo_palette.png").reshape(-1, 4) if c[3] > 0}
    shrinking = []
    for k, size in zip((4, 3, 2, 1), FLUTE_STEPS):
        f = frame(raise_cut, k)
        f[BACK_ARM] = 0
        arm = np.zeros(f.shape[:2], bool)
        arm[BACK_ARM] = True
        arm &= lower1[..., 3] > 0
        f[arm] = lower1[arm]
        shrinking.append(holding(f, patch, size, ivo_colours))
    take2 = frame(take_cut, 2)
    grown = holding(remapped(take2, *GROWN), patch, GROWN_FLUTE, ivo_colours)
    take = [take0, np.roll(frame(take_cut, 1), -2, axis=1), take2, grown, *shrinking, lifted, lower1]
    # hold
    risen = stretched(lower1, 70)
    settled = risen.copy()
    keep = np.zeros(lower1.shape[:2], bool)
    keep[50:72, 76:] = True
    settled[keep] = 0
    m = keep & (lower1[..., 3] > 0)
    settled[m] = lower1[m]
    hold = [lower1, stretched(lower1, 52), risen, settled]
    for name, frames, where in (("give", give, MENTOR), ("let_go", let_go, MENTOR),
                                ("ivo_memorina_reach", reach, IVO), ("ivo_memorina_take", take, IVO),
                                ("ivo_memorina_hold", hold, IVO)):
        path = os.path.join(out_dir or where, f"{name}.png")
        Image.fromarray(np.concatenate(frames, axis=1), "RGBA").save(path)
        print(f"{path}: {len(frames)} frames")


if __name__ == "__main__":
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(opts.get("out", ""))
