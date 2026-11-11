---
id: fallen_log
command: generate
target: res://assets/sprites/world/props/fallen_log/fallen_log.png
size: 64x16
frames: 1
view: side
direction: west
no_background: true
source: codex
---
A thick fallen trunk lying on its side, medium brown bark with darker marks and soft green moss along its top, pale rings at both cut ends. The floater (`scenes/world/interactables/floater/floater.tscn`, legend `O`), placed only in the Spring Woods (woods_pond) and the song trials, so it has one look (WORLD-42). Measured: 64x16, its body over the 60x10 collision at 0,-8; drawn at 32x8 art px and scaled 2x.
Drawn by Codex (one call, 2026-11-11; tools/art/references/regions/board_spring_woods.png the only reference), kept as tools/art/sources/puzzles/floater_log_woods_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/puzzles/floater_log_woods_codex.png assets/sprites/world/props/fallen_log/fallen_log.png --width=32 --height=8 --parts --palette=`. Approved: "está ok" (user, 2026-11-11).
Negative: outlines, black contour, branches, roots, water, ripples, leaves, scenery, text
