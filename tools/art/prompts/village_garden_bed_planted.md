---
id: village_garden_bed_planted
command: generate
target: res://assets/sprites/world/props/village/garden_bed_planted.png
size: 48x18
frames: 1
bands: 3
view: side
source: procedural: tools/art/draw_seed_art.py
---
A village garden bed (LIFE-04, `systems/seeds-and-the-seller`), one per street room, the lane-west one in view of the apple stall (user, "Accept all (Recommended)", 2026-10-28: "four garden beds, one by the stall, procedural art"). 24 art px wide, drawn at 2x: a low plank frame with a darker contact row and soil inside. `garden_bed_bare` is the bed alone, its soil furrowed and empty. `garden_bed_planted` is the same bed with four leaf clumps and yellow flowers between them, 9 art px tall, after the seller's replanting (`village_replanted.tres`). The planted bed is a nature prop: three season bands (spring, autumn, winter) recoloured from spring by `tools/art/season_bands.py`, worn with `prop_seasonal_material.tres`; the bare bed is built, one band. Flat clumps, no high-frequency texture in the grey (`systems/seasonal-art`); its bottom row is opaque and is its base (`prop_grounding_test`).
Negative: outlines, black contours, speckle, noise, dithering, gradients, perspective, background, shadows, blur, text, fence, tools, vegetables in rows of single pixels
