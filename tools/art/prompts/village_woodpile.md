---
id: village_woodpile
command: generate
target: res://assets/sprites/world/props/village/woodpile.png
size: 64x30
frames: 1
view: side
source: codex
---
A pile of split logs. A village street prop, seen straight on from the side, minimalist 16-bit, no outlines. Cut from one Codex sheet of the street's props drawn beside our Ivo still in the flat style of our Ivo's house props and the village fronts (our own art the only references), by `python -I tools/art/cut_props.py tools/art/sources/village/street_small_codex.png <dir> --merge=8 --ref-height=29 --flat=9 --base-shade --colors=64 --names=-,-,barrel_stack,-,sacks,woodpile,-,fence_wood_a,fence_wood_b,flower_box,flower_pot_a,flower_pot_b,flower_pot_c,bush --size=barrel_stack:h26,sacks:h11,woodpile:h15,fence_wood_a:h16,fence_wood_b:h16,flower_box:w16,flower_pot_a:h10,flower_pot_b:h10,flower_pot_c:h8,bush:h15`. Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
