---
id: woods_root_wall
command: generate
target: res://assets/sprites/world/props/spring_woods/root_wall.png
size: 32x96
frames: 1
view: side
source: codex
---
A wall of thick, gnarled tree roots grown down from a cave ceiling into the floor, closing a narrow underground passage, seen from the side: pale and dark brown woody roots twisted and knotted together, small clods of earth between them, no leaves. The `art` of the `FactBarrier` before the hole to woods_root_caves in woods_deep's pit, which opens once the save knows Enraizar (`knows_root.tres`), so Ivo cannot drop into the root caves without the song that brings him back ("Root wall that opens with Enraizar (Recommended)", user, 2026-10-14; TECH-08 found the trap: Redoma alone walks the pool the root bridge spans, design 04 section 3.4 "Enraizar (retorno)").
Drawn by Codex (one call, 2026-10-14; our Bloom Woods earth tiles, woods near backdrop and the orchard bramble barrier the only references), kept as tools/art/sources/spring_woods/root_wall_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/spring_woods/root_wall_codex.png assets/sprites/world/props/spring_woods/root_wall.png --width=16 --height=48 --parts --colors=4 --palette=assets/sprites/world/props/wind_orchards/bramble_barrier.png,assets/sprites/world/props/spring_woods/woodcutter_hut_facade.png`: 16x48 art px at 2x, four colours so the tangle does not read as speckle.
Negative: outlines, black contour, perspective, leaves, flowers, thorns, rocks, ground, sky, scenery, text
