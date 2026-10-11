---
id: ivo_attack_ground
command: animate3
target: res://assets/sprites/characters/ivo/ivo_attack_ground.png
size: 128x128
frames: 9
keep: 0-4,6-9
generate: 10
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_guard_left_96.png
action: two sword slashes: the same man, always in right-facing profile, boots planted, swings his short sword in a wide flat arc in front of him at chest height from behind his shoulder forward, then swings it back in a second rising arc from his knee forward and up above his head, then returns to his guard; each swing leaves a pale curved slash trail in front of him; his short hair and the ends of his blue scarf swing with each cut
source: pixellab
---
Ivo's `attack_ground` sheet (serves attack_idle_1 (0-4), attack_idle_2 (5-8)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_guard_left_96.png` (96 px canvas), 10 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_attack_ground`; the returned frames are kept in tools/art/sources/ivo/attack_ground/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/attack_ground ivo_attack_ground tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_attack_ground.png --keep=0-4,6-9 --frame=128 --at=36,2`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 36,2 in the 128 px frame. Re-rolled twice (two swings that barely moved, then arcs only over his head). The first is a quick forward jab, the finisher the wide arc.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
