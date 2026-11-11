---
id: root_strand
command: generate
target: res://assets/sprites/world/props/roots/root_strand.png
size: 32x10
frames: 1
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_puzzle_strips.py
---
One thick living root, 3 art px, with a thin root winding round it (behind it on the way down), one small green shoot (WORLD-42). Enraizar's root span (root_span_view.gd, root_catch.gd) repeats it along any span between earth walls; roots are the song's, not a region's, so one look in the root wall's colours. Measured: 32x10 (STRAND_THICKNESS 10), period 32 px; drawn at 16x5 art px and scaled 2x. Drawn by `python -I tools/art/draw_puzzle_strips.py root_strand assets/sprites/world/props/roots/root_strand.png`. Orchestrator call, 2026-11-11: a seamless braid is drawn, not cut.
Approved: "está ok" (user, 2026-11-11).
Negative: outlines, black contour, moss, speckle, scenery, text
