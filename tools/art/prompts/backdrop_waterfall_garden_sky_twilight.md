---
id: backdrop_waterfall_garden_sky_twilight
command: generate
target: res://assets/sprites/world/background/waterfall_garden/sky_twilight.png
size: 1024x1152
frames: 1
source: procedural: tools/art/cut_backdrop.py
---
The waterfall garden's sky at twilight (flashback 5), layer 0 of its twilight `BackdropSet`: 1024x384 per band at 2x, spring, autumn and winter stacked, stepped bands from zenith to horizon (through a middle colour at afternoon and twilight) and flat clouds in the time's colours (`TIMES` in the tool), 24 dim stars in the top rows and no sun. The sun and moon stand in art columns 440..511 or 0..264, the span both garden rooms show (x 3200..4480 and its twin) at scroll 0.05 (texture x = camera x * 0.05 - 320 at the screen's left, mod 1024). Scroll 0.05, 0 and horizon row 229 like every surface sky. Drawn by `python -I tools/art/cut_backdrop.py sky assets/sprites/world/background/waterfall_garden/sky_twilight.png --time=twilight`.
Board: `tools/art/references/regions/garden_concept_v2.png`, "Aprovar a prancha" (user, 2026-11-12). The user's notes with it, as relayed: the place is the foot of the waterfall that is the source of the village river; one pool only, in front of the characters, full width at the bottom of the screen, drawn by the game's own water with reflections, never painted; the waterfall tall, close, at the right, falling straight into that front pool beside the bank; the lantern's light is code; sky and light per flashback: 1 morning, 2 day, 3 late afternoon, 4 moonlit night, 5 darkening twilight, the epilogue late afternoon.
Negative: outlines, birds, text, frame, speckle, busy texture
