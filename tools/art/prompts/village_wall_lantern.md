---
id: village_wall_lantern
command: generate
target: res://assets/sprites/world/props/village/wall_lantern.png
size: 14x22
frames: 3
view: side
source: pixellab
---
A small iron lantern on a wall bracket. Redrawn at its exact art size by PixelLab pixflux (`tools/pixellab/pixellab.ps1 generate -NoBackground -Reference <the board's cut at 1x>`, raw in tools/art/sources/village/pixellab/wall_lantern.png), cleaned by `python -I tools/art/clean_prop.py <raw> <still> --flat=6`; its glass flickers over 3 frames by `python -I tools/art/draw_ambient_frames.py flame <still> assets/sprites/world/props/village/wall_lantern.png`. Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
