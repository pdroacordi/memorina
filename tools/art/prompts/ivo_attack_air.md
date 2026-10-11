---
id: ivo_attack_air
command: generate
target: res://assets/sprites/characters/ivo/ivo_attack_air.png
size: 128x128
frames: 4
view: side
direction: east
no_background: true
source: codex
---
Ivo's `attack_air` sheet: 128x128 frames at the 2x density, facing east (Character flips it). attack_jump and attack_fall: the wind-up, the strike with the arm and blade straight out, its smear, the follow-through. Built by `python -I tools/art/build_ivo_attacks.py` from key-pose stills in tools/art/sources/ivo/attack_poses/, cut by `cut_props.py --ref-height=29 --colors=48 --merge=8` from two Codex sheets drawn beside the approved still (`ivo_attack_poses_ground_codex.png`, `ivo_attack_poses_air_codex.png`) and snapped to `ivo_palette.png`. Each pose sits with its feet on row 95 and its body on the flip axis. A smear frame is the strike pose with the blade erased and a crescent of pale steel and white along the swing's path, drawn by the tool. Timing is by holds within the clip's existing frames at 1/12 s, and the Hitbox window covers the strike and smear frames. Rebuilt after "The attack animation still very strange. Not good, not fluid, doesn't even seem like an attack. The running attack is weird too, because the character is moving, but it's legs aren't" (user, 2026-10-11).
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, motion lines, pipes on his back
