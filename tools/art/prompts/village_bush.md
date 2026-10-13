---
id: village_bush
command: animate3
target: res://assets/sprites/world/props/village/bush.png
size: 54x28
frames: 4
bands: 3
view: side
reference: res://tools/art/sources/village/pixellab/bush_ref.png
action: the leaves of the round bush sway gently in a light breeze; the base of the bush stays planted on the ground
source: pixellab
---
A round bush swaying in a light breeze, 4 frames, three season bands. The still is cut by `python -I tools/art/cut_props.py tools/art/sources/village/street_small_codex.png <dir> --merge=8 --ref-height=29 --flat=9 --base-shade --colors=64 --names=-,-,barrel_stack,-,sacks,woodpile,-,fence_wood_a,fence_wood_b,flower_box,flower_pot_a,flower_pot_b,flower_pot_c,bush --size=barrel_stack:h26,sacks:h11,woodpile:h15,fence_wood_a:h16,fence_wood_b:h16,flower_box:w16,flower_pot_a:h10,flower_pot_b:h10,flower_pot_c:h8,bush:h15`; the loop is PixelLab animate-with-text-v3 from it (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/village/pixellab/bush_ref.png -Frames 4 -Action "<action>"`, frames kept in tools/art/sources/village/pixellab/bush/), cut by `python -I tools/art/cut_inhabitant.py <frames> bush <ref> <strip> --frames=4`, trimmed by `python -I tools/art/trim_strip.py <strip> <out> --frames=4` and stacked into season bands by `python -I tools/art/season_bands.py`. Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
