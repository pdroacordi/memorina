---
id: ivo_push
command: animate3
target: res://assets/sprites/characters/ivo/ivo_push.png
size: 128x128
frames: 10
keep: 3-10,9-8
generate: 10
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_push_lean_64.png
action: pushing hard: the same man, always in right-facing profile, pushes with all his weight against a heavy wall on his right that is not drawn: his whole body leans forward at about thirty degrees in one straight line from head to back heel, both arms straight out in front with both hands flat on the wall at chest height, back straight, head down; his legs drive one after the other, each boot digging into the ground and pushing back, staying in the same place in the frame; his short hair and the ends of his blue scarf are blown back behind him
source: pixellab
---
Ivo's `push` sheet (serves brace (walking into a wind that pushes back, Player.is_bracing)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_push_lean_64.png` (64 px canvas), 10 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_push`; the returned frames are kept in tools/art/sources/ivo/push/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/push ivo_push tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_push.png --keep=3-10,9-8 --frame=128 --at=30,34`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys and a white (`ivo_palette.png`), each frame placed at 30,34 in the 128 px frame. Redone after the user's note on his pushing (2026-10-11). The first frame is the first take's lean (its generated frame 10); frames 0-2 straighten up from it, so the loop plays the lean and the leg drive, 3-10, then back 9-8.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
