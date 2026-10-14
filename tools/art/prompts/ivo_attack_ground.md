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
Ivo's `attack_ground` sheet: 128x128 frames at the 2x density, facing east (Character flips it). attack_idle_1 (0-4): wind-up, a thin rising smear over his head, the slash with a leading smear, the follow-through with the trailing sweep, the guard; attack_idle_2 (5-8): the chop's wind-up, the chop with a leading smear, the follow-through with the trailing sweep down to the floor, the guard. Smears are pivoted on each pose's shoulder. Built by `python -I tools/art/build_ivo_attacks.py` from key-pose stills in tools/art/sources/ivo/attack_poses/, cut by `cut_props.py --ref-height=29 --colors=48 --merge=8` from two Codex sheets drawn beside the approved still (`ivo_attack_poses_ground_codex.png`, `ivo_attack_poses_air_codex.png`) and snapped to `ivo_palette.png`. Each pose sits with its feet on row 95 and its body on the flip axis. A smear frame is the strike pose with the blade erased and a crescent of pale steel and white along the swing's path, drawn by the tool. Timing is by holds within the clip's existing frames at 1/12 s, and the Hitbox window covers the strike and smear frames. Smoothed after "The attacks are mostly fine, just need to improve the swish from the standing attack the flowness." (user, 2026-10-11). Rebuilt after "The attack animation still very strange. Not good, not fluid, doesn't even seem like an attack. The running attack is weird too, because the character is moving, but it's legs aren't" (user, 2026-10-11). Reach lengthened after "can we make the attack range a bit bigger? Altering a bit the sprite" (user, 2026-10-14), then "About +25% (Recommended)": "The swing's smear and blade arc drawn about 12-14 px longer, and the hitbox follows the drawn steel. Enemy and guardian spacing retuned so fights stay fair (the earlier tuning matched Ivo's drawn reach)." Only the hit-window smears change; poses, faces and timing stay. Measured on the drawn steel, body px from the body centre: the slash's hit frames (2-3) reach 48 -> 60 px forward at y -66..-14, the chop's (6-7) 40 -> 52 at y -62..0; each smear widens forward into an ellipse (`reach` 1.6 lead and 1.33 trail on the slash, 1.36 and 1.39 on the chop) and never passes below the floor row.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, motion lines, pipes on his back
