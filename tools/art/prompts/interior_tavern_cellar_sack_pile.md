---
id: interior_tavern_cellar_sack_pile
command: generate
target: res://assets/sprites/world/props/interiors/tavern_cellar/sack_pile.png
size: 36x30
frames: 1
view: side
source: codex
---
The sack pile, a prop of the tavern cellar: stores, a lantern and the roots breaking through the stone (`village_tavern_cellar`, scene `scenes/world/environment/props/interiors/tavern_cellar/sack_pile.tscn`). Seen straight on from the side, standing on its own ground line or hanging, minimalist 16-bit, no outlines. The sheet asked for: a stack of five big barrels on wooden cradles (two on three); two single big barrels on cradles; one small standing barrel; a tall wooden shelf of dusty wine bottles and jars; a small wall shelf with bottles and a basket; a short wall shelf with jars and a crate; a wooden rail with three hanging cured hams; a pile of three sacks; a wooden crate; a wall lantern; a small barred vent; thick tree roots spreading from the top edge (a separate wall decoration).
Cut from tools/art/sources/interiors/tavern_cellar_props_codex.png (Codex drew the objects of the approved room board tools/art/sources/interiors/tavern_cellar_board_codex.png, beside our approved Ivo still as the scale figure; our own art is the only reference) by `python -I tools/art/cut_props.py tools/art/sources/interiors/tavern_cellar_props_codex.png <dir> --merge=8 --ref-height=20 --names=barrel_stack,-,-,wine_shelf,-,-,ham_rail,sack_pile,crate,lantern,vent,wall_roots`: scaled so Ivo is 20 art px (the sheet draws objects about 1.45 times too big for his 29), 2x density, one 24-colour palette. Board approved: "Approve as shown (Recommended)" (user, 2026-10-11), after "The house interiors tiles could be improved as well as their design. Thei could tell stories with their props" (2026-10-10).
Negative: perspective, floor, walls, background, shadows, outlines, blur, anti-aliasing, text, letters, people, animals
