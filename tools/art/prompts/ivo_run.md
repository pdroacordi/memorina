---
id: ivo_run
command: animate3
target: res://assets/sprites/characters/ivo/ivo_run.png
size: 128x128
frames: 8
keep: 2-3,5-8,0-1
generate: 8
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/run_v5/ivo_first_run_passing_64.png
action: sprint cycle, a run and never a walk: the same man, always in right-facing profile, sprints on the spot without moving across the frame; this first frame is the push-off, the back leg straightening behind him with its toe on the ground while the front knee swings forward and up; each stride he lands on the front foot a little ahead of his hips, sinks onto the bent knee, pushes off hard as the free knee drives forward and high, and leaps into a flight phase with both boots off the ground and his body at its highest, then lands on the other foot and repeats with the legs swapped; torso leaning forward, elbows bent, fists pumping hard opposite the legs; his hair bounces and the ends of his blue scarf fly out behind him; his sword stays in its scabbard at his hip
source: pixellab
---
Ivo's `run` sheet (serves run, and the legs of the running attack): 128x128 frames at the 2x density, facing east (Character flips it). Each stride is contact, down, push-off and flight: sheet frames 0-2, 5 and 6 stand on the floor line (row 96), frames 3, 4 and 7 are in the air, 2, 2 and 3 art px up, at PixelLab's own height. Rebuilt after "the run animation should still be worked on, it does not look natural as of now." (user, 2026-10-12); the user picked this PixelLab take over a key-pose build ("2: PixelLab", 2026-10-13), then kept it as first presented: "the new running animation changes too much of the Ivo style. The one you presented me before we removed the beard was far better (the pixel lab one)" and "Stubble pixels only (Recommended)", "The run exactly as first presented: same frames, timing and head. The only change is the few stubble pixels on the jaw recoloured to skin." (2026-10-13).

Start frame: `ivo_first_run_passing_64.png`, the push-off pose of a Codex key-pose sheet drawn beside the approved still (`tools/art/sources/ivo/run_keyposes/ivo_run_keyposes_codex.png`, cut by `python -I tools/art/cut_props.py tools/art/sources/ivo/run_keyposes/ivo_run_keyposes_codex.png <dir> --ref-height=29 --colors=48 --merge=8` into `passing_a.png`), standing on row 61 of a 64 px canvas. Generated with `tools/pixellab/pixellab.ps1 animate3 -Action "<action above>" -Reference tools/art/sources/ivo/run_v5/ivo_first_run_passing_64.png -Frames 8 -Name ivo_run_t2_passing` (the same call as `-Prompt ivo_run`); the returned frames are kept in tools/art/sources/ivo/run_v5/ivo_run_t2_passing/ (five takes were made, this one kept).

Built by `python -I tools/art/build_ivo_run.py`: the cut of `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/run_v5/ivo_run_t2_passing ivo_run_t2_passing tools/art/sources/ivo/ivo_palette.png <out> --keep=2-3,5-8,0-1 --frame=128 --at=32,34 --centre=0-128` (each 2x2 block to its most common colour, snapped to `ivo_palette.png`, placed at 32,34, centred on the flip axis); then the ground frames on row 95 and frames 3, 4 and 7 at PixelLab's own height above its ground level, limited to 1-3 art px; then the olive (141, 115, 63) in the top 10 rows of the figure recoloured to skin (191, 126, 74), the stubble on his jaw. Then `python -I tools/art/build_ivo_attacks.py` rebuilds `ivo_attack_run.png`, whose legs are these frames.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
