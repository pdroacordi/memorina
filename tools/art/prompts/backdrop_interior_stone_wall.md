---
id: backdrop_interior_stone_wall
command: generate
target: res://assets/sprites/world/background/interior_stone/wall.png
size: 512x512
frames: 1
source: codex
---
The backdrop wall of `resources/world/backdrops/interior_stone.tres`: the inside wall of a stone building: big rough grey blocks in irregular courses with thin mortar joints. Opaque, repeats on both axes, one band (no seasons underground or indoors), drawn at 2x, one value step darker than the ground in front of it (architecture/backdrop-seams, "Art contracts"). Codex drew a square seamless texture (prompt: minimal 16-bit, large flat shapes, 3 or 4 close values, low contrast), kept in tools/art/sources/backdrop_interior_stone_codex.png; cut by `python -I tools/art/cut_wall.py tools/art/sources/backdrop_interior_stone_codex.png assets/sprites/world/background/interior_stone/wall.png --colors=#3f3b39,#4a4643,#55504c,#2a2725 --tile=256`: reduced to 128 art px and repeated (half the caves' scale, nearer the 32 px tiles indoors), 5 colours, each wrap stitched along the cut of least difference, values mapped onto these colours.
Negative: outlines, perspective, light source, glow, vignette, border, objects, creatures, text, speckle, high contrast
