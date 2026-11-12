---
id: garden_flower_bed_mixed
command: generate
target: res://assets/sprites/world/props/garden/flower_bed_mixed.png
size: 48x20
frames: 4
bands: 3
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_garden_props.py
---
A wider clump of yellow and white wild flowers, as garden_flower_bed_yellow. Four frames: the mound holds still and the heads nod 1 art px on their stems (frame 0 the still), played on the memory clock (`AmbientMotion`), so the clump is still in the grey (2026-11-12, for the garden's "flowers move only on the memory clock"). Drawn at 24x10 art px by `python -I tools/art/draw_garden_props.py flower_bed_mixed <spring>`, then `python -I tools/art/season_bands.py <spring> assets/sprites/world/props/garden/flower_bed_mixed.png`.
The garden concept `tools/art/references/regions/garden_concept.png` is approved for look and mood only: "Isso é apenas o conceito, certo? Se sim, aprovada. Na implementação real, a água tem que ser das nossas, gerada automaticamente, com reflexo. E deve ser mais perto dos personagens para que fique um cenário bem bonito" (user, 2026-11-12). Not yet seen by the user in the room.
Negative: outlines, black contour, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, people
