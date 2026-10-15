---
id: ivo_memorina_lower
command: animate3
target: res://assets/sprites/characters/ivo/ivo_memorina_lower.png
size: 128x128
frames: 4
view: side
direction: east
reference: res://tools/art/sources/story/ivo_memorina_play/ivo_memorina_play_3.png
action: lowers the small pan flute from his lips and tucks it away at his belt, his arms coming down to rest at his sides, ending standing relaxed; feet stay planted
keep: 1-4
generate: 6
source: pixellab
---
Ivo lowering the Memorina: played forward it puts the instrument away, played backward it is the draw (`memorina_draw`). "Should have an animation for when playing memorina too." (user, 2026-10-15; STORY-11). PixelLab animate-with-text-v3 from a frame of the playing loop (frames in tools/art/sources/story/ivo_memorina_lower/; 0 repeats the pose and 5-6 change his stance, so 1-4 are kept), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/ivo_memorina_lower ivo_memorina_lower tools/art/sources/story/ivo_memorina_still_2x.png <out> --keep=1-4 --floor=95 --centre=36-56`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
