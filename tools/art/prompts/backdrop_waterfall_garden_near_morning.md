---
id: backdrop_waterfall_garden_near_morning
command: generate
target: res://assets/sprites/world/background/waterfall_garden/near_morning.png
size: 1024x1152
frames: 1
source: codex
---
The near layer of the waterfall garden at morning (flashback 1): a meadow edge with three round broadleaf trees far apart, every crown closed inside the strip, bushes and flowering shrubs between them. Horizon row 229, scroll 0.55, 0.32 as in the region sets. 1024x384 per band at 2x, spring, autumn and winter stacked, recoloured from the spring drawing; the time's tint multiplies every colour and the aerial mix goes toward that time's horizon (`--time`). Raw kept in `tools/art/sources/waterfall_garden_near_codex.png` (Codex, one call, 2026-11-12; a crop of the board's landscape the reference); cut by `python -I tools/art/cut_backdrop.py layer tools/art/sources/waterfall_garden_near_codex.png assets/sprites/world/background/waterfall_garden/near_morning.png --kind=broadleaf --colors=8 --top=84 --aerial=0.3 --snow=2 --time=morning`. Seamless sideways; EDGE rows one colour per band (architecture/vertical-backdrops, "Art contract").
Board: `tools/art/references/regions/garden_concept_v2.png`, "Aprovar a prancha" (user, 2026-11-12). The user's notes with it, as relayed: the place is the foot of the waterfall that is the source of the village river; one pool only, in front of the characters, full width at the bottom of the screen, drawn by the game's own water with reflections, never painted; the waterfall tall, close, at the right, falling straight into that front pool beside the bank; the lantern's light is code; sky and light per flashback: 1 morning, 2 day, 3 late afternoon, 4 moonlit night, 5 darkening twilight, the epilogue late afternoon.
Negative: outlines, sky, clouds, sun, birds, snow, text, frame, speckle, busy texture, waterfall, river, buildings
