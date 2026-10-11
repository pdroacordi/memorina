---
id: interior_bakery_kneading_table
command: generate
target: res://assets/sprites/world/props/interiors/bakery/kneading_table.png
size: 94x56
frames: 1
view: side
source: codex
---
The kneading table, a prop of the bakery: a working room of racks, flour and the oven (`village_bakery`, scene `scenes/world/environment/props/interiors/bakery/kneading_table.tscn`). Seen straight on from the side, standing on its own ground line or hanging, minimalist 16-bit, no outlines. The sheet asked for: the domed brick bread oven with loaves in its mouth, a firewood store below and a dark iron chimney pipe on top; the long wooden bread peel; two tall wooden racks full of round loaves, long loaves and rolls; the long kneading table with a dough ball, a rolling pin and a cloth; a stack of three flour sacks; one open flour sack; a basket of bread rolls; a stack of firewood; the small blank chalkboard; a rail of hanging dried herbs and garlic; a wall shelf with bowls, jugs and a potted plant.
Cut from tools/art/sources/interiors/bakery_props_codex.png (Codex drew the objects of the approved room board tools/art/sources/interiors/bakery_board_codex.png, beside our approved Ivo still as the scale figure; our own art is the only reference) by `python -I tools/art/cut_props.py tools/art/sources/interiors/bakery_props_codex.png <dir> --merge=8 --ref-height=20 --names=bread_oven,bread_rack_a,bread_rack_b,bread_peel,kneading_table,flour_sacks,-,firewood_stack,chalkboard,herb_rail,wall_shelf_bowls`: scaled so Ivo is 20 art px (the sheet draws objects about 1.45 times too big for his 29), 2x density, one 24-colour palette. Board approved: "Approve as shown (Recommended)" (user, 2026-10-11), after "The house interiors tiles could be improved as well as their design. Thei could tell stories with their props" (2026-10-10).
Negative: perspective, floor, walls, background, shadows, outlines, blur, anti-aliasing, text, letters, people, animals
