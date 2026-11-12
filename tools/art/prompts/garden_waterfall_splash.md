---
id: garden_waterfall_splash
command: generate
target: res://assets/sprites/world/props/garden/waterfall_splash.png
size: 60x24
frames: 4
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_garden_props.py
---
The waterfall's foot: a white foam mound over a pale skirt, spray thrown out on both sides, changing over 4 frames (memory clock, like the fall). Its bottom row is the pool's surface: origin the bottom centre, on the water's top under the fall's centre (water draws over props at z 50, so nothing of it lies below). No pool painted. Drawn at 30x12 art px per frame by `python -I tools/art/draw_garden_props.py waterfall_splash assets/sprites/world/props/garden/waterfall_splash.png`.
The garden concept `tools/art/references/regions/garden_concept.png` is approved for look and mood only: "Isso é apenas o conceito, certo? Se sim, aprovada. Na implementação real, a água tem que ser das nossas, gerada automaticamente, com reflexo. E deve ser mais perto dos personagens para que fique um cenário bem bonito" (user, 2026-11-12). Not yet seen by the user in the room.
Negative: outlines, pool, rocks, scenery, text
