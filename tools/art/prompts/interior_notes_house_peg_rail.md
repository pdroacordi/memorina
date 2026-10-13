---
id: interior_notes_house_peg_rail
command: generate
target: res://assets/sprites/world/props/interiors/notes_house/peg_rail.png
size: 40x28
frames: 1
view: side
source: codex
---
The peg rail, a prop of the house of notes: a family that has begun to forget small things and pins picture notes everywhere (village_notes_house; "A: House of notes (Recommended)", user, 2026-10-13). Seen straight on from the side, minimalist 16-bit, no outlines. Codex drew the objects of the approved room board (tools/art/sources/interiors/notes_house_board_codex.png) flat, beside our Ivo still; cut by `python -I tools/art/cut_props.py tools/art/sources/interiors/notes_house_props2_codex.png <dir> --merge=8 --ref-height=29 --flat=7 --base-shade --colors=32 --names=bed,coat_stand,side_table,broom,chest,peg_rail,blankets,yarn_basket,plant,mirror,rug --size=bed:w32,coat_stand:h30,side_table:h14,broom:h22,chest:h10,peg_rail:w20,blankets:h10,yarn_basket:h7,plant:h12,mirror:h10,rug:w26`, each object sized against Ivo's 29 art px by tools/art/interior_prop_sizes.json.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
