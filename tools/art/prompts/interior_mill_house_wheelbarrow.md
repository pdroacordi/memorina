---
id: interior_mill_house_wheelbarrow
command: generate
target: res://assets/sprites/world/props/interiors/mill_house/wheelbarrow.png
size: 58x32
frames: 1
view: side
source: codex
---
The wheelbarrow, a prop of the working mill: millstones, the gear on the wheel's shaft, flour sacks marked for the bakery (village_mill_house; "A: Working mill (Recommended)", user, 2026-10-13). Seen straight on from the side, minimalist 16-bit, no outlines. Codex drew the objects of the approved room board (tools/art/sources/interiors/mill_house_board_codex.png) flat, beside our Ivo still; cut by `python -I tools/art/cut_props.py tools/art/sources/interiors/mill_house_props2_codex.png <dir> --merge=8 --ref-height=29 --flat=7 --base-shade --colors=32 --names=shelf,workbench,peg_rail,spare_millstone,wheelbarrow,empty_sacks,scale,grain_crate,broom,bucket --size=shelf:h32,workbench:h15,peg_rail:w34,spare_millstone:h22,wheelbarrow:h16,empty_sacks:h8,scale:h14,grain_crate:h9,broom:h22,bucket:h9`, each object sized against Ivo's 29 art px by tools/art/interior_prop_sizes.json.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
