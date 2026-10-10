---
id: backdrop_earth_caves_far
command: generate
target: res://assets/sprites/world/background/earth_caves/far.png
size: 512x512
frames: 1
source: procedural: tools/art/draw_backdrop_placeholder.gd
---
Placeholder backdrop wall for `resources/world/backdrops/earth_caves.tres` until its Codex art (architecture/backdrop-seams, "Art contracts"): opaque, repeats on both axes, one band (no seasons underground or indoors), drawn at 2x, one value step darker than the ground in front of it.
Drawn by tools/art/draw_backdrop_placeholder.gd --kind=rock --colors=#211a15,#2a211b,#342a22 --seed=4 (512 px at --scale=2).
