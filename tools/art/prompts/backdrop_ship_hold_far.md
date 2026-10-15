---
id: backdrop_ship_hold_far
command: generate
target: res://assets/sprites/world/background/ship_hold/far.png
size: 512x512
frames: 1
source: codex
---
The backdrop wall of `resources/world/backdrops/ship_hold.tres`: the inside of the wrecked ship's hold, frost_wreck_hold (WORLD-35 step 6): horizontal hull planks with dark seams crossed by thick, slightly bowed vertical ribs with iron rivets. Opaque, repeats on both axes, one band (no seasons indoors), drawn at 2x, one value step darker than the plank floor in front of it (architecture/backdrop-seams, "Art contracts"). Codex drew a square seamless texture (prompt: minimal 16-bit, large flat shapes, 3 or 4 close values, low contrast; our heartwood wall the only reference), kept in tools/art/sources/backdrop_ship_hold_codex.png; cut by `python -I tools/art/cut_wall.py tools/art/sources/backdrop_ship_hold_codex.png assets/sprites/world/background/ship_hold/far.png --colors=#211b17,#2b231e,#362c25`.
Negative: outlines, perspective, light source, glow, vignette, border, objects, creatures, text, speckle, high contrast, windows, portholes
