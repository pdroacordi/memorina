---
id: interior_farmhouse_turnip_basket
command: generate
target: res://assets/sprites/world/props/interiors/farmhouse/turnip_basket.png
size: 22x18
frames: 1
view: side
source: codex
---
The turnip basket, a prop of the farmhouse on the Threshold, a meal stopped mid-bite (`threshold_farmhouse`, scene `scenes/world/environment/props/interiors/farmhouse/turnip_basket.tscn`): a woven basket of grey turnips. Seen straight on from the side, standing on its own ground line, minimalist 16-bit, no outlines. Codex drew the farmhouse's objects in the flat style of the approved Ivo's house props (tools/art/sources/interiors/ivo_house_props_codex.png the only reference, beside its scale figure); kept in tools/art/sources/interiors/farmhouse_props_codex.png and cut by `python -I tools/art/cut_props.py tools/art/sources/interiors/farmhouse_props_codex.png <dir> --merge=8 --ref-height=29 --flat=7 --base-shade --colors=32 --names=meal_table,chair_pushed,stool,sword,wall_shelf,window,broom,turnip_basket,bucket --size=meal_table:w52,chair_pushed:h17,stool:h9,sword:w22,wall_shelf:w30,window:h17,broom:h22,turnip_basket:h9,bucket:h10`, each sized against Ivo's 29 art px by tools/art/interior_prop_sizes.json. Script draft 2, approved ("Approve draft 2 (Recommended)", user, 2026-10-15): "The farmhouse: a meal stopped mid-bite, a chair pushed back, and the sword on the table, where someone set it down to eat."
Negative: outlines, black contours, speckle, noise, dithering, texture, grain lines, gradients, perspective, floor, walls, background, shadows on the ground, blur, text, letters, people
