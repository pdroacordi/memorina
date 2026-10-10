---
id: backdrop_interior_timber_wall
command: generate
target: res://assets/sprites/world/background/interior_timber/wall.png
size: 512x512
frames: 1
source: procedural: tools/art/draw_backdrop_placeholder.gd
---
Placeholder backdrop wall for `resources/world/backdrops/interior_timber.tres` until its Codex art (architecture/backdrop-seams, "Art contracts"): opaque, repeats on both axes, one band (no seasons underground or indoors), drawn at 2x, one value step darker than the ground in front of it.
Drawn by tools/art/draw_backdrop_placeholder.gd --kind=plaster --colors=#7b6f61,#85796a,#8f8273 --accent=#3b2a1e --seed=7 (512 px at --scale=2).
