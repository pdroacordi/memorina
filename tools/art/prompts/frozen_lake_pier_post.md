---
id: frozen_lake_pier_post
command: generate
target: res://assets/sprites/world/props/frozen_lake/pier_post.png
size: 12x26
frames: 1
view: side
source: procedural: tools/art/draw_post.py
---
A squared wooden post under the fishing village's plank deck, from 2 px behind the plank's 8 px edge down to the lake's waterline (the row 10 cell top), so the deck stands on stilts (WORLD-29, "Stilt piers (Recommended)", "Continuous deck (Recommended)", user, 2026-10-13). Under `Props` (z -10), so the lake reflects it. Measured: plank 8 px at the top of row 9, waterline 24 px below it. Drawn by `python -I tools/art/draw_post.py assets/sprites/world/props/frozen_lake/pier_post.png --height=13`; the reference is our own `village_bridge_pile` (same tool, same timber).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
