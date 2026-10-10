---
id: backdrop_village_strata_far
command: generate
target: res://assets/sprites/world/background/village_strata/far.png
size: 512x512
frames: 1
source: codex
---
The backdrop wall of `resources/world/backdrops/village_strata.tres`: the earth under the village: layered horizontal strata of earth and clay with a few flat stones. Opaque, repeats on both axes, one band (no seasons underground or indoors), drawn at 2x, one value step darker than the ground in front of it (architecture/backdrop-seams, "Art contracts"). Codex drew a square seamless texture (prompt: minimal 16-bit, large flat shapes, 3 or 4 close values, low contrast), kept in tools/art/sources/backdrop_village_strata_codex.png; cut by `python -I tools/art/cut_wall.py tools/art/sources/backdrop_village_strata_codex.png assets/sprites/world/background/village_strata/far.png --colors=#2c241e,#352b23,#3e3229,#30271f`: reduced to 256 art px, 5 colours, each wrap stitched along the cut of least difference, values mapped onto these colours.
Negative: outlines, perspective, light source, glow, vignette, border, objects, creatures, text, speckle, high contrast
