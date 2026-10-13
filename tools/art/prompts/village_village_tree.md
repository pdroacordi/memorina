---
id: village_village_tree
command: generate
target: res://assets/sprites/world/props/village/village_tree.png
size: 244x164
frames: 1
bands: 3
view: side
source: codex
---
A broad village tree, three season bands (spring, autumn, winter). Spring cut by `python -I tools/art/cut_props.py tools/art/sources/village/street_big_codex.png <dir> --merge=8 --ref-height=29 --flat=7 --base-shade --colors=32 --names=-,water_wheel,-,market_stall_bread,market_stall_apples,village_tree --size=water_wheel:w55,market_stall_bread:h46,market_stall_apples:h46,village_tree:h84`; the autumn and winter bands are recolours of it by `python -I tools/art/season_bands.py <spring> assets/sprites/world/props/village/village_tree.png` (foliage only, the silhouette held). Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
