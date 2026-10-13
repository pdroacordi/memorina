---
id: village_cart
command: generate
target: res://assets/sprites/world/props/village/cart.png
size: 94x50
frames: 1
view: side
source: pixellab
---
The farmer's hand cart: one spoked wheel, a bed of hay, the shafts resting on the road. On the east road it leaves with the farmer at 0.6 (a RegionPresence on that instance). Redrawn at its exact art size by PixelLab pixflux (`tools/pixellab/pixellab.ps1 generate -Width .. -Height .. -NoBackground -Reference <the board's cut at 1x>`, the raw kept as tools/art/sources/village/pixellab/cart.png): the Codex cut shrunk to mush. Cleaned by `python -I tools/art/clean_prop.py tools/art/sources/village/pixellab/cart.png assets/sprites/world/props/village/cart.png --flat=9 --base-shade`. Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
