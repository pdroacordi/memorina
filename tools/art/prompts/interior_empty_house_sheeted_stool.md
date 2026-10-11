---
id: interior_empty_house_sheeted_stool
command: generate
target: res://assets/sprites/world/props/interiors/empty_house/sheeted_stool.png
size: 38x32
frames: 1
view: side
source: codex
---
The sheeted stool, a prop of the empty house: a family that left in a hurry, the table still set, the furniture under sheets (`village_empty_house`, scene `scenes/world/environment/props/interiors/empty_house/sheeted_stool.tscn`). Seen straight on from the side, standing on its own ground line or hanging, minimalist 16-bit, no outlines. The sheet asked for: an armchair under a dusty white sheet; a stool under a sheet; a dusty bookshelf with jars and cobwebs; the cold stone fireplace with its chimney breast rising to the top edge and a sheet over its mantel; the crooked empty picture frame; the boarded-up window; the dining table under a torn dusty cloth, set with three empty plates and a jug; two wooden chairs; one fallen chair on its side; the child's small wooden toy horse on wheels; a cabinet under a sheet with candlesticks; two corner cobwebs.
Redrawn 2026-10-11 after "The interior props are not looking nice, not combining with the game style" (user): Codex drew the objects of the approved room board tools/art/sources/interiors/empty_house_board_codex.png in the flat style of our tiles and the approved Ivo's house redraw (chunky shapes, at most 4 or 5 flat colours per object, no outlines or speckle, a darker bottom row), beside our Ivo still as the scale figure; our own art is the only reference. Kept in tools/art/sources/interiors/empty_house_props_codex.png, cut by `python -I tools/art/cut_props.py tools/art/sources/interiors/empty_house_props_codex.png <dir> --merge=8 --ref-height=29 --flat=7 --base-shade --colors=32 --names=dusty_bookshelf,cold_fireplace,empty_frame,sheeted_armchair,sheeted_stool,boarded_window,set_table,chair_old_a,-,fallen_chair,toy_horse,sheeted_cabinet,-,-`: scaled so Ivo is 29 art px, 2x density, 7 colours per object with specks repainted, one 32-colour palette, the bottom row shaded. Approved in game: "Redraw, board first (Recommended)", then the Ivo's house board "Approve (Recommended)" (user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, dithering, texture, grain lines, gradients, perspective, floor, walls, background, shadows on the ground, blur, text, letters, people
