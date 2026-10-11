---
id: ivo_death
command: animate3
target: res://assets/sprites/characters/ivo/ivo_death.png
size: 128x128
frames: 10
keep: 6-15
generate: 16
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_ref_96.png
action: death: the same man, always in right-facing profile, is struck down: he staggers back, drops to his knees, falls onto his back on the ground and lies still for a long time, staying in the middle of the frame; his short hair and the ends of his blue scarf fall with him and come to rest on the ground
source: pixellab
---
Ivo's `death` sheet (serves death (death_shown at its end)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_ref_96.png` (96 px canvas), 16 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_death`; the returned frames are kept in tools/art/sources/ivo/death/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/death ivo_death tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_death.png --keep=6-15 --frame=128 --at=16,2`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys and a white (`ivo_palette.png`), each frame placed at 16,2 in the 128 px frame. 16 frames on a 96 px canvas so the fall ends lying still; frames 6-15 keep the stagger, the fall and the rest.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
