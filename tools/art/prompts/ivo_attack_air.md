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
reference: res://tools/art/sources/ivo/ivo_first_air_guard_long_96.png
action: air slash in exact beats: the same man, always in right-facing profile, in mid-air with his knees tucked, staying in the same place in the frame: frame 1 the short sword sweeping from above his head forward and down with a bright white slash arc in front of him; frame 2 the hit, sword arm fully extended straight forward, the long steel blade horizontal in front of his chest and clearly visible; frame 3 the follow-through, blade pointing down in front of him; then back to this raised guard; his short hair and the ends of his blue scarf lift up
source: pixellab
---
Ivo's `attack_air` sheet (serves attack_jump, attack_fall): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_air_guard_long_96.png` (96 px canvas), 4 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_attack_air`; the returned frames are kept in tools/art/sources/ivo/attack_air/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/attack_air ivo_attack_air tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_attack_air.png --keep=1-4 --frame=128 --at=18,32 --centre=40-70`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys and a white (`ivo_palette.png`), each frame placed at 18,32 in the 128 px frame. Redone after "The jumping and falling animation could be improved. The attacking animation is weird as well. ... Many things on the game seem to just be flaoting. ivo while running doesn't touch the ground." (user, 2026-10-11; on the attack: "The swing itself", "Too short/weak", "Sliding or popping"). The arc sweeps in front of, under and behind him. Centred on the axis by the head and torso.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
