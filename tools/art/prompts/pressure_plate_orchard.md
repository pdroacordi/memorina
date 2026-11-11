---
id: pressure_plate_orchard
command: generate
target: res://assets/sprites/world/props/pressure_plate/pressure_plate_orchard.png
size: 32x12
frames: 2
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_pressure_plate.py
---
A slab of pale ochre limestone with a carved inlay on its top face, on a weathered wood socket. A floor pressure plate (`scenes/world/interactables/pressure_plate/pressure_plate.tscn`) in the Wind Orchards look (WORLD-42; "Per-region variants", user, 2026-11-11). Two frames: raised (frame 0), a slab 3 art px tall on a 1 px socket; pressed (frame 1, `PressurePlate` sets it while the weight holds), the slab sunk to 1 art px. Measured: the frame is 32x12, its bottom row the floor line (Sprite2D at 0,-6); the sensor (28x20 at 0,-10) is unchanged. Drawn at 16x6 art px per frame and scaled 2x.
Drawn by `python -I tools/art/draw_pressure_plate.py orchard assets/sprites/world/props/pressure_plate/pressure_plate_orchard.png`, in the colours of the region's tiles and gate. Orchestrator call, 2026-11-11: Codex cuts of the plate (on the gate's board, tools/art/sources/puzzles/gate_plate_orchard_codex.png) turned to mush at 16x4 art px; precedent `draw_street_grate.py`. Approved: "Approve all (Recommended)" (user, 2026-11-11).
Negative: outlines, black contour, moss, speckle, scenery, text
