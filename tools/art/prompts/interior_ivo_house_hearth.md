---
id: interior_ivo_house_hearth
command: generate
target: res://assets/sprites/world/props/interiors/ivo_house/hearth.png
size: 56x256
frames: 1
view: side
source: codex
---
The hearth, a prop of Ivo's house: a father raising his daughter alone; her bed, her drawings and her late mother's shawl kept on a chair (`village_house`, scene `scenes/world/environment/props/interiors/ivo_house/hearth.tscn`). Seen straight on from the side, standing on its own ground line or hanging, minimalist 16-bit, no outlines. The sheet asked for: the stone hearth with its chimney breast rising to the top edge, a small pot on the grate, a jug and a vase of dried flowers on its mantel; a small stack of firewood; the acoustic guitar (standing); the wooden table; two wooden chairs, one of them with the woman's folded knitted blue shawl over its back; the adult bed with a blue blanket; the small child's bed with a patchwork quilt and a rag doll on the pillow; the wall shelf with two cups, a jug and a jar of dried flowers; the small window with dark panes; three small child's charcoal drawings on paper (a sun, a house, a heart; no letters).
Cut from tools/art/sources/interiors/ivo_house_props_codex.png (Codex drew the objects of the approved room board tools/art/sources/interiors/ivo_house_board_codex.png, beside our approved Ivo still as the scale figure; our own art is the only reference) by `python -I tools/art/cut_props.py tools/art/sources/interiors/ivo_house_props_codex.png <dir> --merge=8 --ref-height=20 --names=hearth,wall_shelf_cups,window,drawing_sun,drawing_house,drawing_heart,firewood,guitar,table,chair,chair_shawl,bed,child_bed`: scaled so Ivo is 20 art px (the sheet draws objects about 1.45 times too big for his 29), 2x density, one 24-colour palette. Then `python -I tools/art/stretch_prop.py <cut> assets/sprites/world/props/interiors/ivo_house/hearth.png 256`: the chimney breast rises to the ceiling. Board approved: "Approve as shown (Recommended)" (user, 2026-10-11), after "The house interiors tiles could be improved as well as their design. Thei could tell stories with their props" (2026-10-10).
Negative: perspective, floor, walls, background, shadows, outlines, blur, anti-aliasing, text, letters, people, animals
