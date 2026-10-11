---
id: interior_bakery_wall_shelf_bowls
command: generate
target: res://assets/sprites/world/props/interiors/bakery/wall_shelf_bowls.png
size: 140x42
frames: 1
view: side
source: codex
---
The wall shelf bowls, a prop of the bakery: a working room of racks, flour and the oven (`village_bakery`, scene `scenes/world/environment/props/interiors/bakery/wall_shelf_bowls.tscn`). Seen straight on from the side, standing on its own ground line or hanging, minimalist 16-bit, no outlines. The sheet asked for: the domed brick bread oven with loaves in its mouth, a firewood store below and a dark iron chimney pipe on top; the long wooden bread peel; two tall wooden racks full of round loaves, long loaves and rolls; the long kneading table with a dough ball, a rolling pin and a cloth; a stack of three flour sacks; one open flour sack; a basket of bread rolls; a stack of firewood; the small blank chalkboard; a rail of hanging dried herbs and garlic; a wall shelf with bowls, jugs and a potted plant.
Redrawn 2026-10-11 after "The interior props are not looking nice, not combining with the game style" (user): Codex drew the objects of the approved room board tools/art/sources/interiors/bakery_board_codex.png in the flat style of our tiles and the approved Ivo's house redraw (chunky shapes, at most 4 or 5 flat colours per object, no outlines or speckle, a darker bottom row), beside our Ivo still as the scale figure; our own art is the only reference. Kept in tools/art/sources/interiors/bakery_props_codex.png, cut by `python -I tools/art/cut_props.py tools/art/sources/interiors/bakery_props_codex.png <dir> --merge=8 --ref-height=29 --flat=7 --base-shade --colors=32 --names=bread_oven,bread_peel,bread_rack_a,bread_rack_b,kneading_table,flour_sacks,-,-,firewood_stack,chalkboard,herb_rail,wall_shelf_bowls`: scaled so Ivo is 29 art px, 2x density, 7 colours per object with specks repainted, one 32-colour palette, the bottom row shaded. Approved in game: "Redraw, board first (Recommended)", then the Ivo's house board "Approve (Recommended)" (user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, dithering, texture, grain lines, gradients, perspective, floor, walls, background, shadows on the ground, blur, text, letters, people
