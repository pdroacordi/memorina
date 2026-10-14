---
id: orchard_bramble_barrier
command: generate
target: res://assets/sprites/world/props/wind_orchards/bramble_barrier.png
size: 32x96
frames: 1
view: side
source: codex
---
A tall barrier of dry autumn brambles and twisted thorny branches grown across a narrow mouth, seen from the side: dark woody stems woven from the ground up, thorns, a few clinging orange and rust leaves, a ragged top. The `art` of the `FactBarrier` in orchard_arena (col 1, row 8) that holds the cliff chimney's mouth until the save holds wall climb, which the autumn guardian gives in this arena (design 04 section 3.6); the growth goes when the guardian is restored. It replaces the placeholder the user asked about ("what is this rectangle?", 2026-10-14; WORLD-36).
Drawn by Codex (one call, 2026-10-14; our Wind Orchards earth tiles and orchard near backdrop the only references), kept as tools/art/sources/wind_orchards/bramble_barrier_codex.png and cut by `python -I tools/art/cut_single_prop.py tools/art/sources/wind_orchards/bramble_barrier_codex.png assets/sprites/world/props/wind_orchards/bramble_barrier.png --width=16 --height=48 --parts --colors=5 --palette=assets/sprites/world/background/wind_orchards/near.png,assets/sprites/world/tilesets/wind_orchards/earth.png,assets/sprites/world/wind/wind_leaf.png,assets/sprites/world/props/wind_orchards/inn_facade.png`: 16x48 art px at 2x, reduced to five colours so the tangle does not read as speckle.
Negative: outlines, black contour, perspective, flowers, berries, green leaves, rocks, ground, sky, scenery, text
