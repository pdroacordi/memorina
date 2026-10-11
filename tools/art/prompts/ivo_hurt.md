---
id: ivo_hurt
command: animate3
target: res://assets/sprites/characters/ivo/ivo_hurt.png
size: 128x128
frames: 4
keep: 1-4
generate: 4
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_ref_64.png
action: hurt: the same man, always in right-facing profile, is struck from the front: he recoils backward with his head snapping back and his arms flung out, then recovers into his standing pose; his short hair and the ends of his blue scarf snap forward with the jolt; his boots stay on the ground
source: pixellab
---
Ivo's `hurt` sheet (serves hurt): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_ref_64.png` (64 px canvas), 4 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_hurt`; the returned frames are kept in tools/art/sources/ivo/hurt/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/hurt ivo_hurt tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_hurt.png --keep=1-4 --frame=128 --at=32,34`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 32,34 in the 128 px frame. The flinch turns him three-quarters to the camera for two frames.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
