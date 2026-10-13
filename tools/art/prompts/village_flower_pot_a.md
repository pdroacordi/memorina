---
id: village_flower_pot_a
command: generate
target: res://assets/sprites/world/props/village/flower_pot_a.png
size: 10x20
frames: 1
bands: 3
view: side
source: codex
---
A clay flower pot. Three season bands; spring cut by `python -I tools/art/cut_props.py tools/art/sources/village/street_small_codex.png <dir> --merge=8 --ref-height=29 --flat=9 --base-shade --colors=64 --names=-,-,barrel_stack,-,sacks,woodpile,-,fence_wood_a,fence_wood_b,flower_box,flower_pot_a,flower_pot_b,flower_pot_c,bush --size=barrel_stack:h26,sacks:h11,woodpile:h15,fence_wood_a:h16,fence_wood_b:h16,flower_box:w16,flower_pot_a:h10,flower_pot_b:h10,flower_pot_c:h8,bush:h15`, autumn and winter recoloured by `python -I tools/art/season_bands.py`. Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
