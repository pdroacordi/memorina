---
id: drawbridge_plank
command: generate
target: res://assets/sprites/world/props/drawbridge/drawbridge_plank.png
size: 128x12
frames: 1
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_puzzle_strips.py
---
Two courses of village oak planks seen from the side, staggered plank ends, an iron strap with a rivet every 64 px (WORLD-42). The drawbridge (orchard_mill_town) and the lowering platform (orchard_well) share it, both in the Wind Orchards, whose wood is the village planks (region board), so one look. Measured: 128x12; both scenes set region_rect to their length and repeat it, so the strip's period is its width; the deck's top row is the standing surface. Drawn at 64x6 art px and scaled 2x. Drawn by `python -I tools/art/draw_puzzle_strips.py drawbridge_plank assets/sprites/world/props/drawbridge/drawbridge_plank.png`. Orchestrator call, 2026-11-11: a seamless strip reads crisper drawn than cut, as with draw_street_grate.py; the user kept these two mechanical ("Keep them mechanical (Recommended)", 2026-11-11).
Approved: "está ok" (user, 2026-11-11).
Negative: outlines, black contour, moss, speckle, scenery, text
