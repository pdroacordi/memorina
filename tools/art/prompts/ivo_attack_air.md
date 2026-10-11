---
id: ivo_attack_air
command: animate3
target: res://assets/sprites/characters/ivo/ivo_attack_air.png
size: 128x128
frames: 4
keep: 1-4
generate: 4
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_air_guard_96.png
action: air slash: the same man, always in right-facing profile, in mid-air with his knees tucked, swings his short sword from above his shoulder down in a big arc in front of him, then lifts it back to this raised guard; the swing leaves a pale curved slash trail in front of him; his short hair and the ends of his blue scarf stream up
source: pixellab
---
Ivo's `attack_air` sheet (serves attack_jump, attack_fall): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_air_guard_96.png` (96 px canvas), 4 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_attack_air`; the returned frames are kept in tools/art/sources/ivo/attack_air/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/attack_air ivo_attack_air tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_attack_air.png --keep=1-4 --frame=128 --at=18,32`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 18,32 in the 128 px frame. The arc sweeps in front of, under and behind him.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
