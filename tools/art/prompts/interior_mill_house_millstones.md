---
id: interior_mill_house_millstones
command: generate
target: res://assets/sprites/world/props/interiors/mill_house/millstones.png
size: 76x64
frames: 1
view: side
source: codex
---
The millstones, a prop of the working mill: millstones, the gear on the wheel's shaft, flour sacks marked for the bakery (village_mill_house; "A: Working mill (Recommended)", user, 2026-10-13). Seen straight on from the side, minimalist 16-bit, no outlines. Codex drew the objects of the approved room board (tools/art/sources/interiors/mill_house_board_codex.png) flat, beside our Ivo still; cut by `python -I tools/art/cut_props.py tools/art/sources/interiors/mill_house_props_codex.png <dir> --merge=8 --ref-height=29 --flat=7 --base-shade --colors=32 --names=millstones,gear,hook_rope,axle,flour_sack_a,flour_sack_b,grain_sack,barrel,flour_bin,wheat_sheaf,lantern --size=millstones:h32,gear:h30,axle:w30,hook_rope:h20,flour_sack_a:h15,flour_sack_b:h14,grain_sack:h10,barrel:h11,flour_bin:h9,wheat_sheaf:h14,lantern:h14`, each object sized against Ivo's 29 art px by tools/art/interior_prop_sizes.json.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
