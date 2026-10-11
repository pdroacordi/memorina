---
id: ivo_attack_down
command: animate3
target: res://assets/sprites/characters/ivo/ivo_attack_down.png
size: 128x128
frames: 6
keep: 0-5
generate: 6
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_air_guard_long_96.png
action: downward stab in exact beats: the same man, always in right-facing profile, in mid-air, staying in the same place in the frame: frame 1 he grips the short sword with both hands above his head; frame 2 he drives it down past his chest, knees pulled up; frames 3 and 4 the hit, both arms extended straight down and the long steel blade pointing straight down below his boots, clearly visible, a bright white streak under it; frame 5 he pulls the sword back up; then back to this raised guard; his short hair and the ends of his blue scarf fly up
source: pixellab
---
Ivo's `attack_down` sheet (serves attack_pogo): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_air_guard_long_96.png` (96 px canvas), 6 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_attack_down`; the returned frames are kept in tools/art/sources/ivo/attack_down/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/attack_down ivo_attack_down tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_attack_down.png --keep=0-5 --frame=128 --at=18,32 --centre=40-70`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys and a white (`ivo_palette.png`), each frame placed at 18,32 in the 128 px frame. Redone after "The jumping and falling animation could be improved. The attacking animation is weird as well. ... Many things on the game seem to just be flaoting. ivo while running doesn't touch the ground." (user, 2026-10-11; on the attack: "The swing itself", "Too short/weak", "Sliding or popping"). The blade points down below his boots from generated 1 to 5; the clip's hit window, frames 3-4, falls on the stab. Centred on the axis by the head and torso.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
