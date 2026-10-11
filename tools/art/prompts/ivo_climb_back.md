---
id: ivo_climb_back
command: animate3
target: res://assets/sprites/characters/ivo/ivo_climb_back.png
size: 128x128
frames: 4
keep: 0-3
generate: 4
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_back_view_80.png
action: climbing a pole: the same man, always seen from directly behind, climbs up a vertical pole that is not drawn, hand over hand, one arm reaching high while the other pulls down, knees gripping and stepping up in turn, staying in the same place in the frame; his short hair and the knot of his blue scarf sway with each pull
source: pixellab
---
Ivo's `climb_back` sheet (serves climb_back, climb_back_hold (0)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_back_view_80.png` (80 px canvas), 4 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_climb_back`; the returned frames are kept in tools/art/sources/ivo/climb_back/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/climb_back ivo_climb_back tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_climb_back.png --keep=0-3 --frame=128 --at=26,22`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys and a white (`ivo_palette.png`), each frame placed at 26,22 in the 128 px frame. The first frame is the back view of the Codex pose sheet on an 80 px canvas.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
