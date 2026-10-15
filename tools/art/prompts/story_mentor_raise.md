---
id: story_mentor_raise
command: animate3
target: res://assets/sprites/world/story/mentor/raise.png
size: 128x128
frames: 5
view: side
direction: west
reference: res://tools/art/sources/story/mentor_holding_2x.png
action: a tall ancient guardian of wood and frost slowly raises the small pan flute in its hand to its pale wooden mask and plays it, swaying gently, its mantle of lichen barely moving; it stays in place
keep: 0-4
generate: 8
source: pixellab
---
The mentor raising the Memorina to his mask before his phrase (05, Act 3). "Should have an animation for when playing memorina too." (user, 2026-10-15; STORY-11). The reference is his empty-handed still with the flute in hand, facing east (tools/art/sources/story/mentor_holding_2x.png); PixelLab animate-with-text-v3 (frames in tools/art/sources/story/mentor_play/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/mentor_play mentor_play tools/art/sources/story/mentor_holding_2x.png <out> --keep=0-4 --floor=125 --centre=60-124`, each frame mirrored back to face west like his stills.
Negative: outlines, black contour, front view, glow, text, ground, scenery
