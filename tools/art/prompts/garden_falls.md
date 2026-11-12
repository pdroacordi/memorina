---
id: garden_falls
command: generate
target: res://assets/sprites/world/props/garden/falls.png
size: 104x192
frames: 6
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_garden_props.py
---
The garden's big waterfall (STORY-05), replacing `waterfall_fall`: a falling sheet 52 art px wide over a 96 art px vertical period, pale water in the game water's colours (world/water) with broad tongues and deeper cores pointing down, a few foam streaks and ragged sides. Every frame repeats vertically with a 192 px period; frame f is frame 0 moved down 32 px, so the 6 frames loop as falling water. One `Sprite2D` with `region_enabled`, `texture_repeat` and a `region_rect` as tall as the fall (250-350 px) draws the whole column; it plays only on the memory clock (`AmbientMotion`, `systems/props`). Its centre stands on the cliff's channel (`garden_falls_cliff`: channel x 126-169, centre x 148 from the cliff's left edge); it ends at the pool's surface, where `garden_falls_foam` sits. Drawn by `python -I tools/art/draw_garden_props.py falls assets/sprites/world/props/garden/falls.png`.
Board: `tools/art/references/regions/garden_concept_v2.png`, "Aprovar a prancha" (user, 2026-11-12). The user's notes with it, as relayed: the place is the foot of the waterfall that is the source of the village river; one pool only, in front of the characters, full width at the bottom of the screen, drawn by the game's own water with reflections, never painted; the waterfall tall, close, at the right, falling straight into that front pool beside the bank; the lantern's light is code; sky and light per flashback: 1 morning, 2 day, 3 late afternoon, 4 moonlit night, 5 darkening twilight, the epilogue late afternoon.
Negative: outlines, pool, rocks, scenery, text
