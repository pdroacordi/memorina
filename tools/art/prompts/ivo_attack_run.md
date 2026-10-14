---
id: ivo_attack_run
command: generate
target: res://assets/sprites/characters/ivo/ivo_attack_run.png
size: 128x128
frames: 9
view: side
direction: east
no_background: true
source: codex
---
Ivo's `attack_run` sheet: 128x128 frames at the 2x density, facing east (Character flips it). The same two swings above the hips, over the legs of run frames 0-7 then 0, so his legs keep running while the attack carries him forward (Player keeps velocity in a running attack). Built by `python -I tools/art/build_ivo_attacks.py` from key-pose stills in tools/art/sources/ivo/attack_poses/, cut by `cut_props.py --ref-height=29 --colors=48 --merge=8` from two Codex sheets drawn beside the approved still (`ivo_attack_poses_ground_codex.png`, `ivo_attack_poses_air_codex.png`) and snapped to `ivo_palette.png`. Each pose sits with its feet on row 95 and its body on the flip axis. A smear frame is the strike pose with the blade erased and a crescent of pale steel and white along the swing's path, drawn by the tool. Timing is by holds within the clip's existing frames at 1/12 s, and the Hitbox window covers the strike and smear frames. Rebuilt after "The attack animation still very strange. Not good, not fluid, doesn't even seem like an attack. The running attack is weird too, because the character is moving, but it's legs aren't" (user, 2026-10-11). Reach lengthened after "can we make the attack range a bit bigger? Altering a bit the sprite" (user, 2026-10-14), then "About +25% (Recommended)": "The swing's smear and blade arc drawn about 12-14 px longer, and the hitbox follows the drawn steel. Enemy and guardian spacing retuned so fights stay fair (the earlier tuning matched Ivo's drawn reach)." Only the hit-window smears change; poses, faces and timing stay. Measured on the drawn steel, body px from the body centre: swing 1's hit frames (2-3) reach 40 -> 52 px forward at y -76..-38, swing 2's (6-7) 40 -> 52 at y -66..-14; the crescents widen forward into ellipses (`reach` 1.5 and 1.36) at the same height.
Negative: outlines, black contour, front view, facing left, glow, text, ground, scenery, motion lines, pipes on his back
