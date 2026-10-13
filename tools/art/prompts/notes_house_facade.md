---
id: notes_house_facade
command: generate
target: res://assets/sprites/world/props/village/notes_house_facade.png
size: 152x206
frames: 1
view: side
source: codex
---
The house of notes: a narrow two-storey townhouse between Ivo's house and the bell tower, a stone ground floor, a half-timbered upper storey with two flower boxes, a steep gable and one chimney; its door is village_square col 15. Cut from tools/art/sources/village/notes_house_front_codex.png (the Codex picture cropped to the front, box (540, 80, 1200, 930) of notes_house_sheet_codex.png) by `python -I tools/art/cut_facades.py facades tools/art/sources/village/notes_house_front_codex.png assets/sprites/world/props/village notes_house --grid=1x1 --palette=<the five village fronts' PNGs>`: scaled so its doorway is 32 art px (64 px) tall, snapped to the colours the built village fronts use (the board's stone came out lighter), a flat 16x32 art px doorway recess the Door sprite fills exactly. Anchor (the doorway's sill centre, the scene's -offset): 56,206. Middle house "A: House of notes (Recommended)", mill "A: Working mill (Recommended)" (user, 2026-10-13). Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
