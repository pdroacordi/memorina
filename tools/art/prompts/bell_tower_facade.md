---
id: bell_tower_facade
command: generate
target: res://assets/sprites/world/props/village/bell_tower_facade.png
size: 100x266
frames: 1
view: side
source: codex
---
A village building front seen straight on (no perspective, no side wall), roof seen from the front, half-timbered cream plaster with dark brown beams over grey stone, warm red-brown tiles, dark unlit panes, one empty dark doorway at ground level 1 unit wide and 2 tall; the bottom edge is the street line. The bell tower: a tall narrow stone tower, an open belfry arch near the top with a bronze bell, a small pointed roof, the doorway centred at the base. The cross Codex drew on the finial is cut away (--crop-top=bell_tower:8).
Cut from tools/art/sources/village_facades_codex.png (one Codex sheet of all six, the approved concept and the village tile sheets as references) by `python -I tools/art/cut_facades.py facades tools/art/sources/village_facades_codex.png assets/sprites/world/props/village ivo_house,bell_tower,tavern,elder_house,bakery,empty_house --crop-top=bell_tower:8`: each building scaled so its doorway is 32 art px (64 px) tall, 2x density, one 20-colour palette, a flat 16x32 art px doorway recess the Door entity sprite covers. Anchor (the doorway's sill centre, the scene's -offset): 50,266. Approved in the running game: "Approve as shown (Recommended)" (user, 2026-10-10).
Negative: outlines, black contour, perspective, side wall, lit windows, glow, text, letters, people, animals, trees, ground, scenery
