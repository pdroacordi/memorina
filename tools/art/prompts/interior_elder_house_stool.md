---
id: interior_elder_house_stool
command: generate
target: res://assets/sprites/world/props/interiors/elder_house/stool.png
size: 22x26
frames: 1
view: side
source: codex
---
The stool, a prop of the elder's house: an old keeper of the village's memory, the lighthouse painted, mapped and shelved (`village_elder`, scene `scenes/world/environment/props/interiors/elder_house/stool.tscn`). Seen straight on from the side, standing on its own ground line or hanging, minimalist 16-bit, no outlines. The sheet asked for: the stone fireplace with a small fire and its chimney breast rising to the top edge, with candles, a lantern and a vase on its mantel; the worn red armchair with a cream blanket and a wooden pipe on its arm; the walking stick; the writing desk with candles, an open book and a quill; a wooden stool; a small globe; the iron-bound chest; the tall bookshelf full of old books with a small lighthouse model on top; the framed painting of a white lighthouse on a cliff; the hanging hand-drawn map (lines and shapes only, no letters); a hanging bunch of dried flowers; a small pile of books.
Redrawn 2026-10-11 after "The interior props are not looking nice, not combining with the game style" (user): Codex drew the objects of the approved room board tools/art/sources/interiors/elder_house_board_codex.png in the flat style of our tiles and the approved Ivo's house redraw (chunky shapes, at most 4 or 5 flat colours per object, no outlines or speckle, a darker bottom row), beside our Ivo still as the scale figure; our own art is the only reference. Kept in tools/art/sources/interiors/elder_house_props_codex.png, cut by `python -I tools/art/cut_props.py tools/art/sources/interiors/elder_house_props_codex.png <dir> --merge=8 --ref-height=29 --flat=7 --base-shade --colors=32 --names=fireplace_lit,bookshelf_lighthouse,lighthouse_painting,map,dried_flowers,armchair,walking_stick,desk,stool,globe,chest,book_pile`: scaled so Ivo is 29 art px, 2x density, 7 colours per object with specks repainted, one 32-colour palette, the bottom row shaded. Approved in game: "Redraw, board first (Recommended)", then the Ivo's house board "Approve (Recommended)" (user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, dithering, texture, grain lines, gradients, perspective, floor, walls, background, shadows on the ground, blur, text, letters, people
