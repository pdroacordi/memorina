---
id: garden_ribbon_hand
command: generate
target: res://assets/sprites/world/props/garden/ribbon_hand.png
size: 24x22
frames: 1
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_garden_props.py
---
The ribbon in Ivo's hand after flashback 2: the same bow as `garden_ribbon_branch` (Alba's blue 118,152,199 and its two shades) at a hand's size, 12x11 art px: the knot at art (5-7, 1-3), two filled loops either side, two ends hanging 7 and 9 art px. Redrawn 2026-11-12 larger and readable at his hand (the first was 8x6 art px). `python -I tools/art/draw_garden_props.py ivo_ribbon tools/art/sources/story/ivo_ribbon_clean.png assets/sprites/characters/ivo/ivo_ribbon.png` lays it at 2x on each frame of `story_ivo_ribbon`, its knot on his hand. Drawn by `python -I tools/art/draw_garden_props.py ribbon_hand assets/sprites/world/props/garden/ribbon_hand.png`.
The garden concept `tools/art/references/regions/garden_concept.png` is approved for look and mood only: "Isso é apenas o conceito, certo? Se sim, aprovada. Na implementação real, a água tem que ser das nossas, gerada automaticamente, com reflexo. E deve ser mais perto dos personagens para que fique um cenário bem bonito" (user, 2026-11-12). Not yet seen by the user in the room.
Negative: outlines, black contour, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, people
