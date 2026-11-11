---
id: seesaw_plank
command: generate
target: res://assets/sprites/world/props/seesaw/seesaw_plank.png
size: 160x8
frames: 1
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_puzzle_strips.py
---
A long village oak plank seen from the side, a few grain marks, a dark band in its middle where it rests on the pivot (WORLD-42). Placed only in the Summer Caldera (caldera_seesaw) and the trials, so one look; the Caldera reuses the village planks (region board). Measured: 160x8; seesaw.gd centres its region on the texture's middle and repeats it, so the band sits on the pivot at any pivot_at. Drawn at 80x4 art px and scaled 2x. Drawn by `python -I tools/art/draw_puzzle_strips.py seesaw_plank assets/sprites/world/props/seesaw/seesaw_plank.png`. Orchestrator call, 2026-11-11: a seamless strip reads crisper drawn than cut.
Approved: "está ok" (user, 2026-11-11).
Negative: outlines, black contour, moss, speckle, scenery, text
