---
id: stone_gate_orchard
command: generate
target: res://assets/sprites/world/props/stone_gate/stone_gate_orchard.png
size: 24x96
frames: 1
view: side
direction: west
no_background: true
source: codex
---
A tall slab of pale ochre limestone in dry-laid blocks with a carved windmill-sail cross in the middle, a band of weathered wood top and bottom. The sliding gate a pressure plate opens (Mechanism, `scenes/world/interactables/gate/gate.tscn`), in the Wind Orchards look (WORLD-42; "Per-region variants", user, 2026-11-11). Measured: 24x96, the whole collision box (24x96, centred at 0,-48); the scene's origin is the bottom centre, on the floor; travel 96 px up into the ceiling. Drawn at 12x48 art px and scaled 2x.
Drawn by Codex (one call, 2026-11-11; the region's approved board the only reference: tools/art/references/regions/board_wind_orchards.png), one board with the gate and the plate's two states, kept as tools/art/sources/puzzles/gate_plate_orchard_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/puzzles/gate_plate_orchard_codex.png assets/sprites/world/props/stone_gate/stone_gate_orchard.png --width=12 --height=48 --box=194,242,386,802 --palette= --flat=4`: the drawing is about 1:3, stretched to the 1:4 box. Approved: "Approve all (Recommended)" (user, 2026-11-11).
Negative: outlines, black contour, door frame, wall, handle, hinges, scenery, text
