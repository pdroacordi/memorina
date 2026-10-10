---
id: backdrop_interior_timber_wall
command: generate
target: res://assets/sprites/world/background/interior_timber/wall.png
size: 512x512
frames: 1
source: codex
---
The backdrop wall of `resources/world/backdrops/interior_timber.tres`: the inside wall of a half-timbered house: beige-grey plaster crossed by dark brown timber beams. Opaque, repeats on both axes, one band (no seasons underground or indoors), drawn at 2x, one value step darker than the ground in front of it (architecture/backdrop-seams, "Art contracts"). Codex drew a square seamless texture (prompt: minimal 16-bit, large flat shapes, 3 or 4 close values, low contrast), kept in tools/art/sources/backdrop_interior_timber_codex.png; cut by `python -I tools/art/cut_wall.py tools/art/sources/backdrop_interior_timber_codex.png assets/sprites/world/background/interior_timber/wall.png --colors=#7b6f61,#85796a,#8f8273,#3b2a1e --tile=256`: reduced to 128 art px and repeated (half the caves' scale, nearer the 32 px tiles indoors), 5 colours, each wrap stitched along the cut of least difference, values mapped onto these colours.
Negative: outlines, perspective, light source, glow, vignette, border, objects, creatures, text, speckle, high contrast
