---
id: backdrop_heartwood_far
command: generate
target: res://assets/sprites/world/background/heartwood/far.png
size: 512x512
frames: 1
source: codex
---
The backdrop wall of `resources/world/backdrops/heartwood.tres`: the inside of the giant hollow tree woods_hollow_tree (WORLD-35, the Bloom Guardian's way on: "Hollow tree to the orchards (Recommended)", user, 2026-10-14): long vertical wood grain in broad flowing bands, a few curves around old knots, dark knot holes, cracks running with the grain. Opaque, repeats on both axes, one band (no seasons inside the trunk), drawn at 2x, one value step darker than the woods ground in front of it (architecture/backdrop-seams, "Art contracts"); the same values as `earth_caves` but warmer, so the trunk reads as wood, not earth. Codex drew a square seamless texture (prompt: minimal 16-bit, large flat shapes, 3 or 4 close values, low contrast; our earth_caves wall the only reference), kept in tools/art/sources/backdrop_heartwood_codex.png; cut by `python -I tools/art/cut_wall.py tools/art/sources/backdrop_heartwood_codex.png assets/sprites/world/background/heartwood/far.png --colors=#2a1a12,#35221a,#412b20`.
Negative: outlines, perspective, light source, glow, vignette, border, objects, creatures, text, speckle, high contrast, bark plates, leaves, moss
