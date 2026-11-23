---
id: story_ivo_memorina_reach
command: animate3
target: res://assets/sprites/characters/ivo/ivo_memorina_reach.png
size: 128x128
frames: 5
view: side
direction: east
reference: res://tools/art/sources/story/ivo_idle_f0_2x.png
action: looks up and slowly lifts his right arm forward to shoulder height, his open palm turned up, as if to receive something handed down to him by someone much taller standing in front of him; feet stay planted; always in right-facing profile
keep: 0-3,5-5
generate: 6
source: pixellab
---
Ivo reaching for the Memorina (STORY-35, `docs/knowledge/architecture/story35-memorina-hand-over.md`; pose `RECEIVE`). "Keeper lowers it (Recommended)" (user, 2026-11-22): Ivo does not reach overhead; he takes it from where he stands. 5 frames, 8 fps once (0.625 s), held on 4. No flute drawn.

Measured by script (2026-11-23). Ivo's frame: 128x128, floor row 96 (feet on 95), body on column 63.5; at `ivo_near` (776, 672) facing west, world x = 839 - file column, y = 576 + file row. `ivo_idle.png` frame 0 spans file (52..75, 38..95): 58 px tall, nose at world x 764, head top y 614. Frame 4's open palm is file column 89, rows 50..53 (world x 750, y 626..629), under the foot of `give.png` frame 3's flute (world y 625). Every frame: feet row 95, whole-frame centroid 61.9..64.1.

Approved reference: `ivo_idle.png` frame 0 (`tools/art/sources/story/ivo_idle_f0_2x.png`, identical). Frames in `tools/art/sources/story/ivo_memorina_reach/`. Built by `python -I tools/art/build_story35_hand_over.py`: frame 0 is idle frame 0 exactly; frames 1-4 are the generation's 1, 2, 3, 5, cut by `cut_inhabitant.py ... tools/art/sources/ivo/ivo_palette.png --keep=0-6 --floor=95 --centre=36-56` and not locked, like every Ivo sheet (`lock_to_still.py` doubled his head). Colours: `tools/art/sources/ivo/ivo_palette.png` only.
Negative: outlines, black contour, front view, glow, text, ground, scenery, flute, jumping
