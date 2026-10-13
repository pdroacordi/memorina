---
id: mill_house_facade
command: generate
target: res://assets/sprites/world/props/village/mill_house_facade.png
size: 234x206
frames: 1
view: side
source: codex
---
The mill house: a half-timbered upper storey over grey stone, a terracotta roof and one stone chimney, the wheel's axle stub on its east wall; its doorway is the working mill's door (village_mill col 3). Cut from tools/art/sources/village/mill_house_front_codex.png (the Codex picture cropped to the front, box (205, 20, 775, 520) of street_big_codex.png) by `python -I tools/art/cut_facades.py facades tools/art/sources/village/mill_house_front_codex.png assets/sprites/world/props/village mill_house --grid=1x1 --palette=<the five village fronts' PNGs>`: scaled so its doorway is 32 art px (64 px) tall, snapped to the colours the built village fronts use (the board's stone came out lighter), a flat 16x32 art px doorway recess the Door sprite fills exactly. Anchor (the doorway's sill centre, the scene's -offset): 66,206. Middle house "A: House of notes (Recommended)", mill "A: Working mill (Recommended)" (user, 2026-10-13). Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
