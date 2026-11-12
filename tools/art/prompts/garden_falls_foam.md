---
id: garden_falls_foam
command: generate
target: res://assets/sprites/world/props/garden/falls_foam.png
size: 168x60
frames: 6
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_garden_props.py
---
The big waterfall's foot, replacing `waterfall_splash`: a foam mound 84x30 art px churning on the pool's surface, every puff swelling and settling once per 6-frame loop, a skirt of churned water on the bottom rows, mist rounds drifting up and spray on arcs to both sides. Its bottom row is the pool's surface: origin the bottom centre, on the water's top under the fall's centre (water draws over props at z 50, so nothing of it lies below). Memory clock, at the fall's fps. Drawn by `python -I tools/art/draw_garden_props.py falls_foam assets/sprites/world/props/garden/falls_foam.png`.
Board: `tools/art/references/regions/garden_concept_v2.png`, "Aprovar a prancha" (user, 2026-11-12). The user's notes with it, as relayed: the place is the foot of the waterfall that is the source of the village river; one pool only, in front of the characters, full width at the bottom of the screen, drawn by the game's own water with reflections, never painted; the waterfall tall, close, at the right, falling straight into that front pool beside the bank; the lantern's light is code; sky and light per flashback: 1 morning, 2 day, 3 late afternoon, 4 moonlit night, 5 darkening twilight, the epilogue late afternoon.
Negative: outlines, pool, rocks, scenery, text
