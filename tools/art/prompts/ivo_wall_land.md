---
id: ivo_wall_land
command: animate3
target: res://assets/sprites/characters/ivo/ivo_wall_land.png
size: 128x128
frames: 6
keep: 1-6
generate: 6
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_wall_cling_80.png
action: catching a wall: the same man, always in right-facing profile, clinging to a wall on his right that is not drawn, absorbs the impact of landing against it: his body sinks and his knees bend as his hands slide down the wall, then he settles back into his clinging pose; his short hair and the ends of his blue scarf flick up with the impact and settle
source: pixellab
---
Ivo's `wall_land` sheet (serves wall_landing): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_wall_cling_80.png` (80 px canvas), 6 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_wall_land`; the returned frames are kept in tools/art/sources/ivo/wall_land/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/wall_land ivo_wall_land tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_wall_land.png --keep=1-6 --frame=128 --at=26,24`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 26,24 in the 128 px frame. Wall clips face the wall (a slide starts while pushing into it); the front edge sits on the capsule's edge, x 75 of the frame.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
