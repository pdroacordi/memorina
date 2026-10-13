---
id: interior_mill_house_gear
command: generate
target: res://assets/sprites/world/props/interiors/mill_house/gear.png
size: 68x68
frames: 12
view: side
source: codex
---
The big wooden gear on the water wheel's shaft through the east wall, a prop of the working mill: millstones, the gear on the wheel's shaft, flour sacks marked for the bakery (village_mill_house; "A: Working mill (Recommended)", user, 2026-10-13). Cut by `python -I tools/art/cut_props.py tools/art/sources/interiors/mill_house_props_codex.png <dir> --merge=8 --ref-height=29 --flat=7 --base-shade --colors=32 --names=millstones,gear,hook_rope,axle,flour_sack_a,flour_sack_b,grain_sack,barrel,flour_bin,wheat_sheaf,lantern --size=millstones:h32,gear:h30,axle:w30,hook_rope:h20,flour_sack_a:h15,flour_sack_b:h14,grain_sack:h10,barrel:h11,flour_bin:h9,wheat_sheaf:h14,lantern:h14`, baked into 12 frames over one 45 degree period (read through one sector, so the loop closes) by `"<godot>" --headless --path . -s res://tools/art/bake_rotation.gd -- --in=<gear still> --out=assets/sprites/world/props/interiors/mill_house/gear.png --frames=12 --period=45`, turning with the wheel outside (9.6 fps). Anchor: the hub.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
