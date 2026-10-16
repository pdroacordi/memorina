---
id: ivo_stand_up
command: animate3
target: res://assets/sprites/characters/ivo/ivo_stand_up.png
size: 128x128
frames: 6
view: side
direction: east
reference: res://tools/art/sources/story/ivo_sit_f0_2x.png
action: slowly stands up from sitting, tired, hands pushing on his knees, ending standing upright and relaxed; he stays in place
keep: 0-5
generate: 6
source: pixellab
---
Ivo getting up from his bed's edge, a one-shot ending standing (05, Ato 1, cena 1; STORY-16: "Ivo stands up with a cut", the seated loop has no rise). PixelLab animate-with-text-v3 from his seated frame 0 (tools/art/sources/story/ivo_sit_f0_2x.png; frames in tools/art/sources/story/ivo_stand_up/; frame 6 throws an arm out, so 0-5 are kept), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/story/ivo_stand_up ivo_stand_up tools/art/sources/story/ivo_sit_f0_2x.png <out> --keep=0-5 --floor=95`.
Negative: outlines, black contour, front view, glow, text, ground, scenery
