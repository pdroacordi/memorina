---
id: ivo_attack_run
command: animate3
target: res://assets/sprites/characters/ivo/ivo_attack_run.png
size: 128x128
frames: 9
keep: 2-10
generate: 10
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_guard_long_96.png
action: two lunging sword slashes in exact beats: the same man, always in right-facing profile, in a deep lunge with the front knee bent and the back leg stretched, boots fixed on the ground and never sliding: frame 1 a big wind-up, the short sword pulled back over his shoulder; frame 2 a flat sweep forward with a bright white slash arc; frame 3 the hit, sword arm fully extended straight forward at waist height, the long steel blade horizontal and clearly visible; frame 4 the follow-through across his body; frame 5 the sword drawn back across his chest for the second cut; frame 6 a flat backhand sweep forward with a bright white slash arc; frame 7 the hit, sword arm fully extended forward at chest height, blade clearly visible; frame 8 the follow-through; frame 9 recovering; then back to this guard; his short hair and the ends of his blue scarf stream back with each lunge
source: pixellab
---
Ivo's `attack_run` sheet (serves attack_run_1 (0-4), attack_run_2 (5-8)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_guard_long_96.png` (96 px canvas), 10 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_attack_run`; the returned frames are kept in tools/art/sources/ivo/attack_run/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/attack_run ivo_attack_run tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_attack_run.png --keep=2-10 --frame=128 --at=32,2 --floor=95 --centre=80-96`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys and a white (`ivo_palette.png`), each frame placed at 32,2 in the 128 px frame. Redone after "The jumping and falling animation could be improved. The attacking animation is weird as well. ... Many things on the game seem to just be flaoting. ivo while running doesn't touch the ground." (user, 2026-10-11; on the attack: "The swing itself", "Too short/weak", "Sliding or popping"). Swing 1 winds the sword back and thrusts (generated 2-6), swing 2 is the white backhand slash (7-10). Settled on the floor line and on the axis by the feet.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
