---
id: garden_waterfall_ledge
command: generate
target: res://assets/sprites/world/props/garden/waterfall_ledge.png
size: 96x48
frames: 1
view: side
direction: west
no_background: true
source: codex
---
The mossy rock ledge the garden's waterfall pours from: a block of warm grey stone jutting left from the cliff (its right edge straight, to tuck behind the room's `S` tiles, which draw over props), a thick moss cap with fern tufts, a smooth lip with a worn notch, moss strands hanging under it. Measured (game px from the top left): the notch's lowest point is x 20-22, y 16, where the fall's centre starts; the right edge x 95 is opaque from y 8 to 47. Drawn at 48x24 art px. Drawn by Codex (one call, 2026-11-12; the village stone and a crop of the garden concept's waterfall rocks the references), kept as tools/art/sources/props/garden/waterfall_ledge_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/props/garden/waterfall_ledge_codex.png assets/sprites/world/props/garden/waterfall_ledge.png --width=48 --parts --palette=tools/art/sources/props/garden/garden_stone_palette.png,tools/art/sources/props/garden/garden_tree_palette.png`.
The garden concept `tools/art/references/regions/garden_concept.png` is approved for look and mood only: "Isso é apenas o conceito, certo? Se sim, aprovada. Na implementação real, a água tem que ser das nossas, gerada automaticamente, com reflexo. E deve ser mais perto dos personagens para que fique um cenário bem bonito" (user, 2026-11-12). Not yet seen by the user in the room.
Negative: outlines, black contour, water, waterfall, sky, scenery, text
