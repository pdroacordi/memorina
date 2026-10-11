---
id: ivo_jump
command: animate3
target: res://assets/sprites/characters/ivo/ivo_jump.png
size: 128x128
frames: 6
keep: 2-6,5-5
generate: 8
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_ref_80.png
action: jump in exact beats: the same man, always in right-facing profile, staying in the same place in the frame and never sliding sideways: frame 1 a deep anticipation crouch, knees bent low, arms swung back; frame 2 the take-off, both legs fully extended and pushing off, arms flung up; frames 3 and 4 rising with both knees tucked up to his chest; frames 5 and 6 falling with arms and legs spread wide open, his short hair and the ends of his blue scarf lifted up above him by the fall; frame 7 the landing crouch; his sword stays in its scabbard at his hip
source: pixellab
---
Ivo's `jump` sheet (serves jump_start (0-2), jump_idle (2), fall_start (3-5), fall_idle (5)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_ref_80.png` (80 px canvas), 8 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_jump`; the returned frames are kept in tools/art/sources/ivo/jump/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/jump ivo_jump tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_jump.png --keep=2-6,5-5 --frame=128 --at=24,18 --floor=95 --centre=0-128`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys and a white (`ivo_palette.png`), each frame placed at 24,18 in the 128 px frame. Redone after "The jumping and falling animation could be improved. The attacking animation is weird as well. ... Many things on the game seem to just be flaoting. ivo while running doesn't touch the ground." (user, 2026-10-11; on the attack: "The swing itself", "Too short/weak", "Sliding or popping"). The crouch, take-off and rise are generated 2-4, the open fall 5-6; fall_idle holds 5, the highest-flung arms. Every frame is settled with its lowest pixel on the floor line and its body on the axis (`--floor --centre`), so the art meets the capsule's bottom and never slides.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
