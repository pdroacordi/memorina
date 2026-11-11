---
id: interior_empty_house_pear_tree_indoor
command: generate
target: res://assets/sprites/world/props/interiors/empty_house/pear_tree_indoor.png
size: 188x148
frames: 1
view: side
direction: west
no_background: true
source: codex
---
A young pear tree grown up through the splintered floorboards of the abandoned house, its autumn crown pressed under the ceiling, one bough reaching left whose end holds the pear. The context of the Empty House's hanging load (WORLD-42): "qual o sentido de uma fruta dentro de casa?" and "A tree grown into the house (Recommended)" (user, 2026-11-11). Measured: the room's lower floor is 128 px tall (floor y 288, ceiling 160) and the pear's top hangs 16 px under the ceiling (`hang_height` 32 over the plate's cell), so the tree is cut 148 px tall and its crown runs 20 px up behind the ceiling's planks (ground tiles draw over props); the bough's underside meets the pear's top (`rope_length` 2, from the 44 px collision top). Origin the trunk's base (offset -132,-148), placed at 520,288; one band, autumn, like every interior prop. Drawn at 94x74 art px and scaled 2x.
Drawn by Codex (one call, 2026-11-11; our pear tree and tools/art/sources/interiors/empty_house_board_codex.png the only references), kept as tools/art/sources/puzzles/pear_tree_indoor_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/puzzles/pear_tree_indoor_codex.png assets/sprites/world/props/interiors/empty_house/pear_tree_indoor.png --width=0 --height=74 --box=0,0,1315,1034 --parts --palette= --flat=8` (the box drops the full floor strip Codex drew under the splinters). Approved: "Approve (Recommended)" (user, 2026-11-11).
Negative: outlines, black contour, fruit, pears, second tree, wall, ceiling, scenery, text
