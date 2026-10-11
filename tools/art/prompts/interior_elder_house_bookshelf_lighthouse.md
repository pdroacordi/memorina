---
id: interior_elder_house_bookshelf_lighthouse
command: generate
target: res://assets/sprites/world/props/interiors/elder_house/bookshelf_lighthouse.png
size: 38x58
frames: 1
view: side
source: codex
---
The bookshelf lighthouse, a prop of the elder's house: an old keeper of the village's memory, the lighthouse painted, mapped and shelved (`village_elder`, scene `scenes/world/environment/props/interiors/elder_house/bookshelf_lighthouse.tscn`). Seen straight on from the side, standing on its own ground line or hanging, minimalist 16-bit, no outlines. The sheet asked for: the stone fireplace with a small fire and its chimney breast rising to the top edge, with candles, a lantern and a vase on its mantel; the worn red armchair with a cream blanket and a wooden pipe on its arm; the walking stick; the writing desk with candles, an open book and a quill; a wooden stool; a small globe; the iron-bound chest; the tall bookshelf full of old books with a small lighthouse model on top; the framed painting of a white lighthouse on a cliff; the hanging hand-drawn map (lines and shapes only, no letters); a hanging bunch of dried flowers; a small pile of books.
Cut from tools/art/sources/interiors/elder_house_props_codex.png (Codex drew the objects of the approved room board tools/art/sources/interiors/elder_house_board_codex.png, beside our approved Ivo still as the scale figure; our own art is the only reference) by `python -I tools/art/cut_props.py tools/art/sources/interiors/elder_house_props_codex.png <dir> --merge=8 --ref-height=20 --names=fireplace_lit,armchair,walking_stick,desk,stool,globe,chest,bookshelf_lighthouse,lighthouse_painting,map,dried_flowers,book_pile`: scaled so Ivo is 20 art px (the sheet draws objects about 1.45 times too big for his 29), 2x density, one 24-colour palette. Board approved: "Approve as shown (Recommended)" (user, 2026-10-11), after "The house interiors tiles could be improved as well as their design. Thei could tell stories with their props" (2026-10-10).
Negative: perspective, floor, walls, background, shadows, outlines, blur, anti-aliasing, text, letters, people, animals
