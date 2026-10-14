---
id: fact_barrier
command: generate
target: res://assets/sprites/world/props/fact_barrier/fact_barrier.png
size: 32x96
frames: 1
view: side
source: codex
---
A tall closed village gate seen straight on from the side, one cell wide and three cells tall: rough vertical planks lashed to two iron crossbars, a thick iron chain wound across the middle with a heavy padlock, the plank tops cut in uneven points. The `FactBarrier` scene's default art: it bars the village's west road to the woods (village_lane_west) and the river trail to the lake (village_mill) until Ivo owns the Memorina (design 04 section 2, "ter a Memorina"); a barrier elsewhere sets its own `art`. The bottom edge is the floor line.
Drawn by Codex (one call, 2026-10-14; our village fence_wood_a and gate_tower the only references), kept as tools/art/sources/village/village_gate_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/village/village_gate_codex.png assets/sprites/world/props/fact_barrier/fact_barrier.png --width=16 --height=48 --parts --palette=assets/sprites/world/props/village/fence_wood_a.png,assets/sprites/world/props/village/gate_tower.png`: 16x48 art px at 2x. It replaces the placeholder the user asked about ("what is this rectangle?", 2026-10-14; WORLD-36).
Negative: outlines, black contour, perspective, wall, house, door frame, person, text, open gate, fence posts beside it
