---
id: ivo_attack_down
command: animate3
target: res://assets/sprites/characters/ivo/ivo_attack_down.png
size: 128x128
frames: 6
keep: 6-6,0-4
generate: 6
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_air_guard_96.png
action: downward stab: the same man, always in right-facing profile, in mid-air, pulls his knees up and stabs his short sword straight down below his boots with both hands, the blade pointing at the ground, then lifts it back to this raised guard; the stab leaves a pale slash trail below him; his short hair and the ends of his blue scarf fly up
source: pixellab
---
Ivo's `attack_down` sheet (serves attack_pogo): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_air_guard_96.png` (96 px canvas), 6 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_attack_down`; the returned frames are kept in tools/art/sources/ivo/attack_down/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/attack_down ivo_attack_down tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_attack_down.png --keep=6-6,0-4 --frame=128 --at=18,32`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 18,32 in the 128 px frame. Kept 6, 0-4 so the stab (generated 2-3) lands on the clip's hit window, frames 3-4.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
