---
id: orchard_pear_tree
command: generate
target: res://assets/sprites/world/props/wind_orchards/pear_tree.png
size: 176x156
frames: 1
bands: 3
view: side
direction: west
no_background: true
source: codex
---
A small old pear tree in autumn: a short thick trunk, a rounded crown, one long bough reaching right whose leafy tip holds the pear's stalk. The context the hanging load needs in orchard_windy_gap (WORLD-42): "as frutas não podem ser simplesmente penduradas no teto. Devem ter contexto. Uma árvore ou algo assim." (user, 2026-11-11). Measured: the bough's underside is 76 px over the trunk's base at x 159, so on the shelf (y 160) with the pear at col 6 (x 208) the tree stands at 89,160; its origin is the trunk's base (offset -40,-156) and the stalk reaches it at `rope_length` 16 (measured from the 44 px collision top, where `HangingLoad` starts the stalk, `hang_height` 16). The room's top is 160 px over the shelf. Drawn at 88x78 art px and scaled 2x; a nature prop with three season bands (`prop_seasonal_material.tres`).
Drawn by Codex (one call, 2026-11-11; tools/art/references/regions/board_wind_orchards.png and our pear the only references), kept as tools/art/sources/puzzles/pear_tree_orchard_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/puzzles/pear_tree_orchard_codex.png <cut> --width=88 --parts --palette= --flat=8`, then `python -I tools/art/season_bands.py <cut> assets/sprites/world/props/wind_orchards/pear_tree.png --autumn` (drawn in autumn; spring is its foliage mapped onto the village tree's greens, winter a recolour of spring).
Shown in the room on 2026-11-11 with the other two trees; the user's answer, "qual o sentido de uma fruta dentro de casa? e na segunda imagem, o galho está flutuando", objected only to the house and the shaft.
Negative: outlines, black contour, fruit, pears, second tree, ground, grass, scenery, text
