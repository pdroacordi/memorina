---
id: story_mentor_play
command: animate3
target: res://assets/sprites/world/story/mentor/play.png
size: 128x128
frames: 6
view: side
direction: west
reference: res://tools/art/sources/story/mentor_holding_2x.png
action: a tall ancient guardian of wood and frost slowly raises the small pan flute in its hand to its pale wooden mask and plays it, swaying gently, its mantle of lichen barely moving; it stays in place
keep: 4-7,6-5
generate: 8
source: pixellab
---
The mentor playing his phrase, the flute at his mask, a loop (05, Act 3). "Should have an animation for when playing memorina too." (user, 2026-10-15; STORY-11). The same generation as `story_mentor_raise`, frames 4-7 kept back and forth, cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/mentor_play mentor_play tools/art/sources/story/mentor_holding_2x.png <out> --keep=4-7,6-5 --floor=125 --centre=60-124`, mirrored to face west.
Negative: outlines, black contour, front view, glow, text, ground, scenery
