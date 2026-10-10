---
id: backdrop_earth_caves_far
command: generate
target: res://assets/sprites/world/background/earth_caves/far.png
size: 512x512
frames: 1
source: codex
---
The backdrop wall of `resources/world/backdrops/earth_caves.tres`: the back wall of an earth cave: packed brown earth in big soft rounded masses and strata, a few embedded stones. Opaque, repeats on both axes, one band (no seasons underground or indoors), drawn at 2x, one value step darker than the ground in front of it (architecture/backdrop-seams, "Art contracts"). Codex drew a square seamless texture (prompt: minimal 16-bit, large flat shapes, 3 or 4 close values, low contrast), kept in tools/art/sources/backdrop_earth_caves_codex.png; cut by `python -I tools/art/cut_wall.py tools/art/sources/backdrop_earth_caves_codex.png assets/sprites/world/background/earth_caves/far.png --colors=#211a15,#2a211b,#342a22`: reduced to 256 art px, 5 colours, each wrap stitched along the cut of least difference, values mapped onto these colours.
Negative: outlines, perspective, light source, glow, vignette, border, objects, creatures, text, speckle, high contrast
