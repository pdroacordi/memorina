---
id: ivo_jump
command: animate3
target: res://assets/sprites/characters/ivo/ivo_jump.png
size: 128x128
frames: 6
keep: 1-6
generate: 8
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_ref_64.png
action: jump: the same man, always in right-facing profile, jumps without moving across the frame: he crouches, springs up with his arms swinging up, tucks his knees high at the top, then stretches his legs down as he falls and lands back in his standing pose; his short hair and the ends of his blue scarf lift and trail with the motion, flying up as he falls; his sword stays in its scabbard at his hip
source: pixellab
---
Ivo's `jump` sheet (serves jump_start (0-2), jump_idle (2), fall_start (3-5), fall_idle (5)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_ref_64.png` (64 px canvas), 8 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_jump`; the returned frames are kept in tools/art/sources/ivo/jump/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/jump ivo_jump tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_jump.png --keep=1-6 --frame=128 --at=32,34`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys (`ivo_palette.png`), each frame placed at 32,34 in the 128 px frame.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
