---
id: ivo_air_spin
command: animate3
target: res://assets/sprites/characters/ivo/ivo_air_spin.png
size: 128x128
frames: 6
keep: 0-5
generate: 6
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_jump_top_80.png
action: mid-air somersault: the same man, in right-facing profile, high in the air, curls into a tight ball and flips forward head over heels in one full turn, then opens back out into this airborne pose, staying in the middle of the frame; his short hair and the ends of his blue scarf whip round with the spin
source: pixellab
---
Ivo's `air_spin` sheet (serves air_spin): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_jump_top_80.png` (80 px canvas), 6 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_air_spin`; the returned frames are kept in tools/art/sources/ivo/air_spin/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/air_spin ivo_air_spin tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_air_spin.png --keep=0-5 --frame=128 --at=26,26`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 26,26 in the 128 px frame. The first frame is the jump's top (generated frame 3 of ivo_jump) on an 80 px canvas. Generated frame 4 came back on a flat brown box, keyed out of the kept source.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
