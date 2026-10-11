---
id: ivo_wall_slide
command: cut
cut_from: ivo_wall_land
target: res://assets/sprites/characters/ivo/ivo_wall_slide.png
size: 128x128
frames: 1
keep: 6-6
view: side
direction: east
no_background: true
source: pixellab
---
Ivo's `wall_slide` sheet (serves wall_slide): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). No generation of its own: the last frame of the `ivo_wall_land` generation (`cut_from`). Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/wall_land ivo_wall_land tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_wall_slide.png --keep=6-6 --frame=128 --at=26,24`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 26,24 in the 128 px frame. Cut from ivo_wall_land's last frame, so the slide continues the landing without a pop. No call of its own.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
