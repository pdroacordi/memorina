---
id: garden_lantern
command: generate
target: res://assets/sprites/world/props/garden/lantern.png
size: 32x68
frames: 4
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_garden_props.py
---
The garden lantern: a small square iron lantern hung by a ring from a crook-topped wrought-iron post with a flared foot, 16x34 art px. Frame 0 unlit (smoky glass, a candle); frames 1-3 lit (warm panes, the flame's tip one row higher or lower per frame: a flicker on the memory clock, 3 fps like the village lanterns). Nothing glows outside the panes: the light is a `Light2D` set by code. The post stands at x 4-7 game px from the frame's left, the lantern's centre at x 21, its panes at y 24-35. Codex drew the design (2026-11-12, both states side by side), but cut to 16 art px it lost the bars and the hook (systems/art-pipeline, Puzzle parts), so it is drawn pixel by pixel in that design's shape by `python -I tools/art/draw_garden_props.py lantern assets/sprites/world/props/garden/lantern.png`.
Board: `tools/art/references/regions/garden_concept_v2.png`, "Aprovar a prancha" (user, 2026-11-12). The user's notes with it, as relayed: the place is the foot of the waterfall that is the source of the village river; one pool only, in front of the characters, full width at the bottom of the screen, drawn by the game's own water with reflections, never painted; the waterfall tall, close, at the right, falling straight into that front pool beside the bank; the lantern's light is code; sky and light per flashback: 1 morning, 2 day, 3 late afternoon, 4 moonlit night, 5 darkening twilight, the epilogue late afternoon.
Negative: outlines, glow, halo, light rays, ground, scenery, text
