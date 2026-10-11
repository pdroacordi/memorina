---
id: ivo_climb
command: animate3
target: res://assets/sprites/characters/ivo/ivo_climb.png
size: 128x128
frames: 4
keep: 0-3
generate: 4
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_climbing_80.png
action: climbing: the same man, always in right-facing profile, climbs up a wall of roots on his right that is not drawn, hand over hand, alternating arms reaching high and knees stepping up, staying in the same place in the frame; his short hair and the ends of his blue scarf sway with each pull
source: pixellab
---
Ivo's `climb` sheet (serves climb, climb_hold (0)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_climbing_80.png` (80 px canvas), 4 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_climb`; the returned frames are kept in tools/art/sources/ivo/climb/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/climb ivo_climb tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_climb.png --keep=0-3 --frame=128 --at=26,18`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 26,18 in the 128 px frame. The first frame is the climbing pose of the Codex pose sheet on an 80 px canvas.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
