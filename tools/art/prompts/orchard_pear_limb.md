---
id: orchard_pear_limb
command: generate
target: res://assets/sprites/world/props/wind_orchards/pear_limb.png
size: 500x192
frames: 1
bands: 3
view: side
direction: west
no_background: true
source: codex
---
An old pear tree in the lift shaft: roots on the floor, a slim trunk up the west wall, one long limb across the shaft with leaf clumps on top and a bare underside. The context of the two hanging pears in orchard_counterweights (WORLD-42): "as frutas não podem ser simplesmente penduradas no teto. Devem ter contexto. Uma árvore ou algo assim.", then "e na segunda imagem, o galho está flutuando" and "Trunk rooted on the floor (Recommended)" (user, 2026-11-11). Measured: the shaft is 480 px wide (x 32-512) from its floor (y 672) to the rock over it (y 480), 192 px; the pears hang 48 px and 16 px from the walls (x 80, 496), too close for a standing tree's crown. Its origin is the roots' base (offset -34,-192), placed at 46,672 on the shaft floor, so its left 20 px run behind the west wall's tiles and the trunk clears the west pear; the limb's underside is 75 px under its top over the west pear and 67 over the east one, so `rope_length` is 8 and 16 (the stalk starts at the 44 px collision top, 2 px under the sprite's). Drawn at 250x96 art px and scaled 2x (a 4% stretch of the drawing's 2.5:1); three season bands (a few bark-coloured flecks stay warm in the spring and winter crowns, where the leaves share the bark's highlight).
Drawn by Codex (one call, 2026-11-11; our pear tree the only reference), kept as tools/art/sources/puzzles/pear_limb_orchard_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/puzzles/pear_limb_orchard_codex.png <cut> --width=250 --height=96 --parts --palette= --flat=8`, then `python -I tools/art/season_bands.py <cut> assets/sprites/world/props/wind_orchards/pear_limb.png --autumn`. Approved: "Approve (Recommended)" (user, 2026-11-11).
Negative: outlines, black contour, fruit, pears, hanging things, rock, ground line, scenery, text
