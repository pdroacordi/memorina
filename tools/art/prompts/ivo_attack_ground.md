---
id: ivo_attack_ground
command: generate
target: res://assets/sprites/characters/ivo/ivo_attack_ground.png
size: 128x128
frames: 9
view: side
direction: east
no_background: true
source: codex
---
Ivo's `attack_ground` sheet: 128x128 frames at the 2x density, facing east (Character flips it). attack_idle_1 (0-4): wind-up, a thin rising smear over his head, the slash with a leading smear, the follow-through with the trailing sweep, the guard; attack_idle_2 (5-8): the chop's wind-up, the chop with a leading smear, the follow-through with the trailing sweep down to the floor, the guard. Smears are pivoted on each pose's shoulder. Built by `python -I tools/art/build_ivo_attacks.py` from key-pose stills in tools/art/sources/ivo/attack_poses/, cut by `cut_props.py --ref-height=29 --colors=48 --merge=8` from two Codex sheets drawn beside the approved still (`ivo_attack_poses_ground_codex.png`, `ivo_attack_poses_air_codex.png`) and snapped to `ivo_palette.png`. Each pose sits with its feet on row 95 and its body on the flip axis. A smear frame is the strike pose with the blade erased and a crescent of pale steel and white along the swing's path, drawn by the tool. Timing is by holds within the clip's existing frames at 1/12 s, and the Hitbox window covers the strike and smear frames. Smoothed after "The attacks are mostly fine, just need to improve the swish from the standing attack the flowness." (user, 2026-10-11). Rebuilt after "The attack animation still very strange. Not good, not fluid, doesn't even seem like an attack. The running attack is weird too, because the character is moving, but it's legs aren't" (user, 2026-10-11).
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, motion lines, pipes on his back
