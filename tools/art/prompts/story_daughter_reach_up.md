---
id: story_daughter_reach_up
command: animate3
target: res://assets/sprites/world/story/daughter/reach_up.png
size: 64x64
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/daughter_standing_2x.png
action: reaches up with both arms to take something down from a hook on the wall above her, then holds it against her chest
keep: 0-5
generate: 6
source: pixellab
---
The daughter taking the guitar down from its hook, a one-shot ending held at her chest (05, Ato 1, cena 5; STORY-16). PixelLab animate-with-text-v3 from her standing still (frames in tools/art/sources/story/daughter_reach_up/; frame 6 turns her face to the viewer, so 0-5 are kept), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/daughter_reach_up daughter_reach_up tools/art/sources/story/daughter_standing_2x.png <out> --keep=0-5 --floor=61 --centre=30-62`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
