---
id: bell_tower_facade
command: generate
target: res://assets/sprites/world/props/village/bell_tower_facade.png
size: 114x420
frames: 1
view: side
source: codex
---
The bell tower's front seen straight on (no perspective, no side wall), rising out of the frame: a wider stone base of rough ashlar with an arched wooden door at ground level, then a long ashlar shaft with dark timber bands every storey, two timber posts up its face and narrow arched slit windows, cut straight across at the top. The doorway is 1 unit wide and 2 tall; the bottom edge is the street line.
Cut from the RIGHT panel of the approved style board tools/art/sources/bell_tower_board_codex.png (Codex; our approved village concept, our placeholder stair and our short tower front as the only references; "Approve (Recommended)", user, 2026-10-11) by `python -I tools/art/cut_facades.py facades tools/art/sources/bell_tower_board_codex.png assets/sprites/world/props/village -,bell_tower --grid=2x1 --doorway=bell_tower:765:1124:858:1326`: the board draws the door shut, so `--doorway` gives its box in board px (the arch's top to the sill); the panel is cut at the sill and scaled so the doorway is 32 art px (64 px) tall, 2x density, 20 colours, a flat 16x32 art px doorway recess the Door entity sprite covers. Anchor (the doorway's sill centre, the scene's -offset): 56,420. Placed in village_square at the door's feet (656, 288), so its top stands 132 px above the room's top edge and the frame never shows it end.
Negative: outlines, black contour, perspective, side wall, lit windows, glow, text, letters, people, animals, trees, ground, scenery
