---
id: lift_platform
command: generate
target: res://assets/sprites/world/props/lift_platform/lift_platform.png
size: 64x12
frames: 1
view: side
direction: west
no_background: true
source: codex
---
A thick deck of weathered wooden planks seen from the side, an iron band near each end. The lift (Mechanism, `scenes/world/interactables/lift/lift.tscn`), placed only in the Wind Orchards (orchard_counterweights) and the song trials, so it has one look (WORLD-42). Measured: 64x12, the whole collision box (64x12 at 0,-6); its top edge is the standing surface. Drawn at 32x6 art px and scaled 2x.
Drawn by Codex (one call, 2026-11-11, with the orchard cocoon; tools/art/references/regions/board_wind_orchards.png and our orchard gate the only references), kept as tools/art/sources/puzzles/lift_cocoon_orchard_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/puzzles/lift_cocoon_orchard_codex.png assets/sprites/world/props/lift_platform/lift_platform.png --width=32 --height=6 --box=135,448,903,533 --palette=`: the box starts at the deck's top, below the two rope rings Codex drew, so the art's top is the collision's top.
Approved: "está ok" (user, 2026-11-11).
Negative: outlines, black contour, chain, rope, pulley, wall, scenery, text
