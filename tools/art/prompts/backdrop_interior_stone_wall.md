---
id: backdrop_interior_stone_wall
command: generate
target: res://assets/sprites/world/background/interior_stone/wall.png
size: 512x512
frames: 1
source: procedural: tools/art/draw_backdrop_placeholder.gd
---
Placeholder backdrop wall for `resources/world/backdrops/interior_stone.tres` until its Codex art (architecture/backdrop-seams, "Art contracts"): opaque, repeats on both axes, one band (no seasons underground or indoors), drawn at 2x, one value step darker than the ground in front of it.
Drawn by tools/art/draw_backdrop_placeholder.gd --kind=stone --colors=#3f3b39,#4a4643,#55504c --accent=#2a2725 --seed=8 (512 px at --scale=2).
