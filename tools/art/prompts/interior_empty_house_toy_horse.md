---
id: interior_empty_house_toy_horse
command: generate
target: res://assets/sprites/world/props/interiors/empty_house/toy_horse.png
size: 26x24
frames: 1
view: side
source: codex
---
The toy horse, a prop of the empty house: a family that left in a hurry, the table still set, the furniture under sheets (`village_empty_house`, scene `scenes/world/environment/props/interiors/empty_house/toy_horse.tscn`). Seen straight on from the side, standing on its own ground line or hanging, minimalist 16-bit, no outlines. The sheet asked for: an armchair under a dusty white sheet; a stool under a sheet; a dusty bookshelf with jars and cobwebs; the cold stone fireplace with its chimney breast rising to the top edge and a sheet over its mantel; the crooked empty picture frame; the boarded-up window; the dining table under a torn dusty cloth, set with three empty plates and a jug; two wooden chairs; one fallen chair on its side; the child's small wooden toy horse on wheels; a cabinet under a sheet with candlesticks; two corner cobwebs.
Cut from tools/art/sources/interiors/empty_house_props_codex.png (Codex drew the objects of the approved room board tools/art/sources/interiors/empty_house_board_codex.png, beside our approved Ivo still as the scale figure; our own art is the only reference) by `python -I tools/art/cut_props.py tools/art/sources/interiors/empty_house_props_codex.png <dir> --merge=8 --ref-height=20 --names=dusty_bookshelf,cold_fireplace,empty_frame,boarded_window,sheeted_armchair,sheeted_stool,set_table,chair_old_a,-,fallen_chair,toy_horse,sheeted_cabinet,cobweb_a`: scaled so Ivo is 20 art px (the sheet draws objects about 1.45 times too big for his 29), 2x density, one 24-colour palette. Board approved: "Approve as shown (Recommended)" (user, 2026-10-11), after "The house interiors tiles could be improved as well as their design. Thei could tell stories with their props" (2026-10-10).
Negative: perspective, floor, walls, background, shadows, outlines, blur, anti-aliasing, text, letters, people, animals
