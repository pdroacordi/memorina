---
id: ivo_attack_run
command: animate3
target: res://assets/sprites/characters/ivo/ivo_attack_run.png
size: 128x128
frames: 9
keep: 0-4,6-9
generate: 10
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_guard_left_96.png
action: running sword slashes: the same man, always in right-facing profile, lunges forward in a long running stride and slashes his short sword in a flat arc forward at waist height, then steps through and slashes back across in a second flat arc forward at chest height, then returns to his guard; each slash leaves a pale curved slash trail in front of him; his short hair and the ends of his blue scarf stream back with each lunge
source: pixellab
---
Ivo's `attack_run` sheet (serves attack_run_1 (0-4), attack_run_2 (5-8)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_guard_left_96.png` (96 px canvas), 10 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_attack_run`; the returned frames are kept in tools/art/sources/ivo/attack_run/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/attack_run ivo_attack_run tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_attack_run.png --keep=0-4,6-9 --frame=128 --at=34,2`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 34,2 in the 128 px frame. Re-rolled once (the first take thrust once and wound up during the first hit window).
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
