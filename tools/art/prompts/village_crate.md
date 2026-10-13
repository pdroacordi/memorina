---
id: village_crate
command: generate
target: res://assets/sprites/world/props/village/crate.png
size: 32x18
frames: 1
view: side
source: pixellab
---
A low plank crate. Redrawn at its exact art size by PixelLab pixflux (`tools/pixellab/pixellab.ps1 generate -Width .. -Height .. -NoBackground -Reference <the board's cut at 1x>`, the raw kept as tools/art/sources/village/pixellab/crate.png): the Codex cut shrunk to mush. Cleaned by `python -I tools/art/clean_prop.py tools/art/sources/village/pixellab/crate.png assets/sprites/world/props/village/crate.png --flat=7 --base-shade --replace=#edb31f:#9c6a3b,#e8a81c:#9c6a3b`. Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
