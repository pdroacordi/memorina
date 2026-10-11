---
id: interior_tavern_notice_board
command: generate
target: res://assets/sprites/world/props/interiors/tavern/notice_board.png
size: 62x42
frames: 1
view: side
source: codex
---
The notice board, a prop of the tavern: the bar, the hearth, the long tables and the rooms upstairs (`village_tavern`, scene `scenes/world/environment/props/interiors/tavern/notice_board.tscn`). Seen straight on from the side, standing on its own ground line or hanging, minimalist 16-bit, no outlines. The sheet asked for: the long wooden bar counter; three round bar stools; the barrel rack with six barrels on its shelves (to stand behind the bar); a wall shelf with jugs and bottles; a wall shelf with mugs; the stone fireplace with its chimney breast rising to the top edge and a pot hanging inside; the notice board with blank pinned papers; the wagon-wheel candle chandelier on its chain; two sturdy tables, each with two pewter mugs and a jug; four benches; two loose barrels; a small stack of firewood.
Cut from tools/art/sources/interiors/tavern_props_codex.png (Codex drew the objects of the approved room board tools/art/sources/interiors/tavern_board_codex.png, beside our approved Ivo still as the scale figure; our own art is the only reference) by `python -I tools/art/cut_props.py tools/art/sources/interiors/tavern_props_codex.png <dir> --merge=8 --ref-height=20 --names=chandelier,shelf_jugs,shelf_mugs,tavern_fireplace,notice_board,bar_counter,barrel_rack,tavern_table_a,tavern_table_b,bench_a,bench_b,-,-,barrel,keg,firewood_tavern`: scaled so Ivo is 20 art px (the sheet draws objects about 1.45 times too big for his 29), 2x density, one 24-colour palette. Board approved: "Approve as shown (Recommended)" (user, 2026-10-11), after "The house interiors tiles could be improved as well as their design. Thei could tell stories with their props" (2026-10-10).
Negative: perspective, floor, walls, background, shadows, outlines, blur, anti-aliasing, text, letters, people, animals
