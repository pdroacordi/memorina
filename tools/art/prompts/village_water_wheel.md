---
id: village_water_wheel
command: generate
target: res://assets/sprites/world/props/village/water_wheel.png
size: 116x116
frames: 12
view: side
source: codex
---
The mill's water wheel, eight spokes and paddles, standing in the river east of the mill house. The still is cut by `python -I tools/art/cut_props.py tools/art/sources/village/street_big_codex.png <dir> --merge=8 --ref-height=29 --flat=7 --base-shade --colors=32 --names=-,water_wheel,-,market_stall_bread,market_stall_apples,village_tree --size=water_wheel:w55,market_stall_bread:h46,market_stall_apples:h46,village_tree:h84`, then baked into 12 frames over one 45 degree period, read through one 45 degree sector so the loop closes, by `"<godot>" --headless --path . -s res://tools/art/bake_rotation.gd -- --in=<water_wheel still> --out=assets/sprites/world/props/village/water_wheel.png --frames=12 --period=45` ("Baked pixel frames", user, 2026-10-09). Played at 9.6 fps (0.1 turn/s). Anchor: the hub, the frame's centre. Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
