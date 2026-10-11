---
id: ivo_roll
command: animate3
target: res://assets/sprites/characters/ivo/ivo_roll.png
size: 128x128
frames: 7
keep: 1-7
generate: 8
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_crouch_96.png
action: somersault roll: the same man, always in right-facing profile, tucks his head and curls into a tight ball and tumbles forward head over heels in one full somersault along the ground, his back touching the ground, his boots passing over his head, then comes back up into this crouch, staying in the middle of the frame; his short hair and the ends of his blue scarf whip round with the roll
source: pixellab
---
Ivo's `roll` sheet (serves roll (0.583 s = roll_time + roll_recovery_time)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_crouch_96.png` (96 px canvas), 8 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_roll`; the returned frames are kept in tools/art/sources/ivo/roll/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/roll ivo_roll tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_roll.png --keep=1-7 --frame=128 --at=14,2 --floor=95`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys and a white (`ivo_palette.png`), each frame placed at 14,2 in the 128 px frame. Re-rolled once: from the standing still the roll came back as a lunge; the first frame is now the land clip's deep crouch (generated frame 5 of ivo_land) on a 96 px canvas.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
