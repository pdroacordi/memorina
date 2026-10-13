---
id: interior_notes_house_fireplace
command: generate
target: res://assets/sprites/world/props/interiors/notes_house/fireplace.png
size: 60x256
frames: 1
view: side
source: codex
---
The fireplace, a prop of the house of notes: a family that has begun to forget small things and pins picture notes everywhere (village_notes_house; "A: House of notes (Recommended)", user, 2026-10-13). Seen straight on from the side, minimalist 16-bit, no outlines. Codex drew the objects of the approved room board (tools/art/sources/interiors/notes_house_board_codex.png) flat, beside our Ivo still; cut by `python -I tools/art/cut_props.py tools/art/sources/interiors/notes_house_props_codex.png <dir> --merge=8 --ref-height=29 --flat=7 --base-shade --colors=32 --names=fireplace,cupboard_notes,table,chair_a,chair_b,firewood,note_dog,recipe,tally_calendar,wall_shelf,window,dog_bowl,dog_lead --size=fireplace:w30,cupboard_notes:h32,table:h14,chair_a:h17,chair_b:h17,firewood:h7,note_dog:h10,recipe:w32,tally_calendar:h16,wall_shelf:w30,window:h17,dog_bowl:w7,dog_lead:h11`, each object sized against Ivo's 29 art px by tools/art/interior_prop_sizes.json. Then `python -I tools/art/stretch_prop.py <cut> assets/sprites/world/props/interiors/notes_house/fireplace.png 256 --band=6:30 --bricks`: the chimney rises to the ceiling.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
