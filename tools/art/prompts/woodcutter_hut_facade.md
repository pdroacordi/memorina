---
id: woodcutter_hut_facade
command: generate
target: res://assets/sprites/world/props/spring_woods/woodcutter_hut_facade.png
size: 242x180
frames: 1
view: side
source: codex
---
A building front seen straight on, its long side facing the viewer (no perspective, no side wall), so the roof's ridge is a straight horizontal line the player walks on; one empty dark doorway at ground level 1 unit wide and 2 tall; the bottom edge is the ground line. The woodcutter's hut (spring forest): a log cabin of round horizontal logs, a thick mossy turf roof with a few small flowers, a stone chimney at one end, one small window; the turf ridge is flat, 9 units long at height 5.
Cut from tools/art/sources/region_facades_codex.png (one Codex sheet of all five; our approved village concept and tools/art/sources/village_facades_codex.png as the only references) by `python -I tools/art/cut_facades.py facades tools/art/sources/region_facades_codex.png <dir> woodcutter_hut,farmhouse,fisher_hut,inn,lighthouse --grid=5x1 --colors=24 --dark=fisher_hut:36 --rows=woodcutter_hut:34:6,fisher_hut:40:6,inn:41:-7 --crop-top=lighthouse:14`, each written to its region's folder: scaled so the doorway is 32 art px (64 px) tall, 2x density, one 24-colour palette, wall rows repeated or dropped so every walkable roof lands on the 32 px grid. Anchor (the doorway's sill centre): 124,180. Placed in woods_edge (door col 12; roof cells 11-14 at 160 px); its roof is `^` cells (facade_doors_test). Approved in the running game: "Approve (Recommended)" (user, 2026-10-10), after "The cistern one is the only one that still looks kind of weird".
Negative: outlines, black contour, perspective, side wall, gable end, pointed roof peak, lit windows, glow, text, letters, people, animals, trees, ground, scenery
