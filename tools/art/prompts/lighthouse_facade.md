---
id: lighthouse_facade
command: generate
target: res://assets/sprites/world/props/frost_edge/lighthouse_facade.png
size: 160x288
frames: 1
view: side
source: codex
---
A building front seen straight on, its long side facing the viewer (no perspective, no side wall), so the roof's ridge is a straight horizontal line the player walks on; one empty dark doorway at ground level 1 unit wide and 2 tall; the bottom edge is the ground line. The lighthouse base (icy sea cliffs): the bottom of a tall round tower of white stone with one broad dark red band, slightly tapering, dark slit windows, a heavy stone doorway frame, cut flat at the top.
Cut from tools/art/sources/region_facades_codex.png (one Codex sheet of all five; our approved village concept and tools/art/sources/village_facades_codex.png as the only references) by `python -I tools/art/cut_facades.py facades tools/art/sources/region_facades_codex.png <dir> woodcutter_hut,farmhouse,fisher_hut,inn,lighthouse --grid=5x1 --colors=24 --dark=fisher_hut:36 --rows=woodcutter_hut:34:6,fisher_hut:40:6,inn:41:-7 --crop-top=lighthouse:14`, each written to its region's folder: scaled so the doorway is 32 art px (64 px) tall, 2x density, one 24-colour palette, wall rows repeated or dropped so every walkable roof lands on the 32 px grid. Anchor (the doorway's sill centre): 80,288. Placed in lighthouse_base (door col 20); it rises out of the room's top edge; its roof is `^` cells (facade_doors_test). Approved in the running game: "Approve (Recommended)" (user, 2026-10-10), after "The cistern one is the only one that still looks kind of weird".
Negative: outlines, black contour, perspective, side wall, gable end, pointed roof peak, lit windows, glow, text, letters, people, animals, trees, ground, scenery
