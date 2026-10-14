"""Build Ivo's attack sheets from key-pose stills, smear frames and, for the running attack, the run cycle's legs.

python -I tools/art/build_ivo_attacks.py [--preview=<dir>]
Each pose in tools/art/sources/ivo/attack_poses/ (cut from the Codex key-pose sheets by cut_props.py) is placed in a
128 px frame with its lowest non-steel pixel on the floor line (row 95) and its body centroid on the flip axis (column
63.5): the feet for ground poses, head and torso for air poses. A smear frame is its pose with the blade erased and a
crescent of pale steel along the swing's path. A running frame keeps the pose above the hips and takes the legs of a
run frame. The timing is in SHEETS, one frame per 1/12 s step, so every clip keeps its length
(architecture/ivo-at-2x). --preview also writes each sheet as an animated GIF at game speed.
"""
import math
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
POSES = os.path.join(ROOT, "tools/art/sources/ivo/attack_poses")
PALETTE = os.path.join(ROOT, "tools/art/sources/ivo/ivo_palette.png")
RUN = os.path.join(ROOT, "assets/sprites/characters/ivo/ivo_run.png")
OUT = os.path.join(ROOT, "assets/sprites/characters/ivo")
SIDE = 64  # art px: a 128 game px frame
FLOOR = 47  # art row of the feet
AXIS = (SIDE - 1) / 2
WHITE, LIGHT, MID = (234, 240, 240), (200, 208, 210), (150, 160, 166)
TROUSERS = {(139, 116, 62), (141, 115, 63), (126, 101, 60)}  # olive only: the darker browns are hair too
GROUND_BAND, AIR_BAND = (40, 48), (20, 35)  # art rows the body is centred by
LEAN = 1.7  # > 1 moves a smear's thickest point late in the swing (t ** LEAN peaks at t = 0.66)

# A smear: an arc of `thick` art px at most, from `start` to `end` degrees (0 forward, 90 down), `inner` art px from
# `pivot` (art px in the frame, the shoulder of the pose it is drawn on); or a vertical streak from `pivot` down
# `length` art px. Style "plain" erases the blade and paints over the pose; "lead" (thin and bright, the blade arriving)
# and "trail" (the whole sweep fading behind the blade) keep the blade and paint only behind the body. An arc never
# passes below the floor row. `reach` widens an arc in front of its pivot into an ellipse; the Hitbox keys must follow
# the drawn steel (ivo_sheet_test).
SMEARS = {
    "slash": {"kind": "arc", "pivot": (36, 29), "inner": 9, "thick": 11, "start": -150, "end": 12, "style": "plain",
              "reach": 1.5},
    "chop": {"kind": "arc", "pivot": (35, 30), "inner": 8, "thick": 10, "start": -100, "end": 80, "style": "plain",
             "reach": 1.36},
    "air": {"kind": "arc", "pivot": (35, 32), "inner": 8, "thick": 10, "start": -150, "end": 25, "style": "plain",
            "reach": 1.32},
    "pogo": {"kind": "streak", "pivot": (33, 44), "length": 19, "thick": 5.2, "style": "plain"},
    "slash_rise": {"kind": "arc", "pivot": (36, 24), "inner": 8, "thick": 4, "start": -165, "end": -75,
                   "style": "lead", "erase": True},
    "slash_lead": {"kind": "arc", "pivot": (36, 29), "inner": 13, "thick": 5, "start": -85, "end": -4, "style": "lead",
                   "reach": 1.6},
    "slash_trail": {"kind": "arc", "pivot": (35, 32), "inner": 8, "thick": 10, "start": -150, "end": 40,
                    "style": "trail", "reach": 1.33},
    "chop_lead": {"kind": "arc", "pivot": (35, 30), "inner": 12, "thick": 5, "start": -110, "end": 38, "style": "lead",
                  "reach": 1.36},
    "chop_trail": {"kind": "arc", "pivot": (36, 35), "inner": 7, "thick": 9, "start": -150, "end": 72, "style": "trail",
                   "reach": 1.39},
}
# One entry per frame: (pose, smear or None, run frame for the legs or None).
SWING_1 = [("windup_slash", None), ("windup_slash", None), ("strike_slash", None), ("strike_slash", "slash"),
           ("follow_slash", None)]
SWING_2 = [("windup_chop", None), ("strike_chop", None), ("strike_chop", "chop"), ("follow_chop", None)]
# The standing combo: the blade rises, arrives with a leading smear, sweeps on with a trailing one and eases back to
# guard, where the chop's wind-up begins.
STANDING_1 = [("windup_slash", None), ("windup_slash", "slash_rise"), ("strike_slash", "slash_lead"),
              ("follow_slash", "slash_trail"), ("guard", None)]
STANDING_2 = [("windup_chop", None), ("strike_chop", "chop_lead"), ("follow_chop", "chop_trail"), ("guard", None)]
SHEETS = {
    "ivo_attack_ground": [(p, s, None) for p, s in STANDING_1 + STANDING_2],
    "ivo_attack_run": [(p, s, legs) for (p, s), legs in zip(SWING_1 + SWING_2, [0, 1, 2, 3, 4, 5, 6, 7, 0])],
    "ivo_attack_air": [("air_windup", None, None), ("air_strike", None, None), ("air_strike", "air", None),
                       ("air_follow", None, None)],
    "ivo_attack_down": [("pogo_raise", None, None), ("pogo_raise", None, None), ("pogo_stab", None, None),
                        ("pogo_stab", "pogo", None), ("pogo_stab", None, None), ("pogo_raise", None, None)],
}
AIR_POSES = {"air_windup", "air_strike", "air_follow", "pogo_raise", "pogo_stab"}


def load_art(path):
    image = np.asarray(Image.open(path).convert("RGBA"))
    return image[::2, ::2].copy()


def is_steel(art):
    rgb = art[..., :3].astype(int)
    return (art[..., 3] > 0) & (rgb.max(-1) - rgb.min(-1) < 20)


def placed(name):
    """The pose on a SIDE x SIDE canvas: lowest body pixel on FLOOR, body centroid on AXIS."""
    pose = load_art(os.path.join(POSES, name + ".png"))
    canvas = np.zeros((SIDE, SIDE, 4), np.uint8)
    body = (pose[..., 3] > 0) & ~is_steel(pose)
    ys, _ = np.nonzero(body)
    top = FLOOR - ys.max()
    left = (SIDE - pose.shape[1]) // 2
    canvas[top:top + pose.shape[0], left:left + pose.shape[1]] = pose
    band = AIR_BAND if name in AIR_POSES else GROUND_BAND
    rows = canvas[band[0]:band[1]]
    xs = np.nonzero((rows[..., 3] > 0) & ~is_steel(rows))[1]
    return np.roll(canvas, int(round(AXIS - xs.mean())), axis=1)


def paint_smear(art, smear):
    style = smear["style"]
    art = art.copy()
    if style == "plain" or smear.get("erase"):
        art[is_steel(art)] = 0
    body = art[..., 3] > 0
    px, py = smear["pivot"]
    for y in range(SIDE):
        for x in range(SIDE):
            if style != "plain" and body[y, x]:
                continue
            if smear["kind"] == "streak":
                t = (y - py) / smear["length"]
                width = smear["thick"] * math.sin(math.pi * t) if 0 <= t <= 1 else 0
                d = abs(x + 0.5 - px)
                if d <= width / 2:
                    art[y, x] = WHITE + (255,) if d <= width / 4 else LIGHT + (255,)
                continue
            if y > FLOOR:
                continue
            dx, dy = x + 0.5 - px, y + 0.5 - py
            if dx > 0:
                # In front of the pivot the arc is an ellipse `reach` times as wide: the sweep reaches further forward
                # without rising higher over his head.
                dx /= smear.get("reach", 1.0)
            angle = math.degrees(math.atan2(dy, dx))
            t = (angle - smear["start"]) / (smear["end"] - smear["start"])
            if not 0 <= t <= 1:
                continue
            # Thickest late in the swing, where the blade moves fastest, tapering to a point at both ends.
            thick = max(1.0, smear["thick"] * math.sin(math.pi * t ** LEAN))
            r = math.hypot(dx, dy) - smear["inner"]
            if not 0 <= r <= thick:
                continue
            if style == "lead":
                colour = WHITE if r >= thick / 3 else LIGHT
            elif style == "trail":
                # White near the blade, pale steel further back, a darker inner edge against light walls.
                colour = MID if r < 1 else (WHITE if t > 0.55 and r >= thick / 2 else LIGHT)
            else:
                colour = WHITE if r >= thick / 2 else LIGHT
            art[y, x] = colour + (255,)
    return art


def hips(art):
    """The first row with at least three trouser pixels."""
    for y in range(SIDE):
        if sum(1 for x in range(SIDE) if art[y, x, 3] and tuple(art[y, x, :3]) in TROUSERS) >= 3:
            return y
    sys.exit("no trousers found")


def torso_x(art, cut):
    rows = art[cut - 12:cut]
    return np.nonzero((rows[..., 3] > 0) & ~is_steel(rows))[1].mean()


def on_running_legs(art, run_frame):
    """The pose above its hips, moved onto the run frame's hips, over the run frame's legs."""
    legs = run_frame.copy()
    cut = hips(legs)
    shift = cut - hips(art)
    upper = np.roll(art, shift, axis=0)
    upper[:max(shift, 0)] = 0
    # The torso goes where the run frame's torso is, so the upper body rides the stride instead of lunging off it.
    upper = np.roll(upper, int(round(torso_x(legs, cut) - torso_x(upper, cut))), axis=1)
    out = legs.copy()
    out[:cut] = 0
    above = np.arange(SIDE)[:, None] < cut
    keep = (upper[..., 3] > 0) & (above | is_steel(upper))
    out[keep] = upper[keep]
    return out


def main(preview):
    run = np.asarray(Image.open(RUN).convert("RGBA"))[::2, ::2]
    run_frames = [run[:, i * SIDE:(i + 1) * SIDE] for i in range(run.shape[1] // SIDE)]
    palette = np.asarray(Image.open(PALETTE).convert("RGBA"))
    colours = {tuple(c) for c in palette[palette[..., 3] > 0][:, :3]}
    for sheet, frames in SHEETS.items():
        arts = []
        for pose, smear, legs in frames:
            art = placed(pose)
            if smear:
                art = paint_smear(art, SMEARS[smear])
            if legs is not None:
                art = on_running_legs(art, run_frames[legs])
            stray = {tuple(c) for c in art[art[..., 3] > 0][:, :3]} - colours
            if stray:
                sys.exit(f"{sheet}: colours outside the palette {sorted(stray)[:4]}")
            arts.append(art)
        strip = Image.fromarray(np.concatenate(arts, axis=1), "RGBA")
        strip = strip.resize((strip.width * 2, strip.height * 2), Image.NEAREST)
        strip.save(os.path.join(OUT, sheet + ".png"))
        print(f"{sheet}: {len(arts)} frames")
        if preview:
            gif = []
            for i in range(len(arts)):
                frame = Image.new("RGBA", (128, 128), (58, 66, 74, 255))
                frame.alpha_composite(strip.crop((i * 128, 0, (i + 1) * 128, 128)))
                gif.append(frame.resize((384, 384), Image.NEAREST).convert("RGB"))
            gif[0].save(os.path.join(preview, sheet + ".gif"), save_all=True, append_images=gif[1:],
                        duration=83, loop=0)


if __name__ == "__main__":
    opts = dict((a[2:].split("=", 1) + [""])[:2] for a in sys.argv[1:] if a.startswith("--"))
    main(opts.get("preview", ""))
