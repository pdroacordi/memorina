---
id: ivo_attack_ground
command: animate3
target: res://assets/sprites/characters/ivo/ivo_attack_ground.png
size: 128x128
frames: 9
keep: 0-4,7-10
generate: 10
view: side
direction: east
no_background: true
reference: res://tools/art/sources/ivo/ivo_first_guard_long_96.png
action: two strong sword cuts in exact beats: the same man, always in right-facing profile, boots planted on the ground and never sliding: frame 1 he draws the short sword back behind his shoulder; frame 2 a flat slash forward with a bright white slash arc in front of his chest; frame 3 the hit, sword arm fully extended straight forward, the long steel blade horizontal and clearly visible; frame 4 the follow-through, blade swept across to his other side; frame 5 he lifts the sword high above his head with both hands; frame 6 an overhead chop coming down in front of him with a bright white slash arc; frame 7 the hit, arms fully extended forward and down, the long blade pointing down in front of him, clearly visible; frame 8 the follow-through, blade low near his front boot; frame 9 recovering; then back to this guard; his short hair and the ends of his blue scarf swing with each cut
source: pixellab
---
Ivo's `attack_ground` sheet (serves attack_idle_1 (0-4), attack_idle_2 (5-8)): 128x128 frames at the 2x density, the floor line on row 96 and his body on the flip axis (between columns 63 and 64), facing east (Character flips it). PixelLab animate-with-text-v3 from `ivo_first_guard_long_96.png` (96 px canvas), 10 frames (`generate:`): `tools/pixellab/pixellab.ps1 animate3 -Prompt ivo_attack_ground`; the returned frames are kept in tools/art/sources/ivo/attack_ground/. Cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/ivo/attack_ground ivo_attack_ground tools/art/sources/ivo/ivo_palette.png assets/sprites/characters/ivo/ivo_attack_ground.png --keep=0-4,7-10 --frame=128 --at=32,2 --floor=95 --centre=80-96`: each 2x2 block to its most common colour, every pixel snapped to the still's colours plus three steel greys and a white (`ivo_palette.png`), each frame placed at 32,2 in the 128 px frame. Redone after "The jumping and falling animation could be improved. The attacking animation is weird as well. ... Many things on the game seem to just be flaoting. ivo while running doesn't touch the ground." (user, 2026-10-11; on the attack: "The swing itself", "Too short/weak", "Sliding or popping"). The first frame is the Codex guard with its sword repainted as a long two-pixel steel blade (`ivo_first_guard_long_96.png`). Swing 1 is the thrust (generated 1-4, arm extended through the hit window), swing 2 the overhead chop (7-10). One retake: the first took the second swing as a held blade. Settled on the floor line and on the axis by the feet.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, pipes on his back
