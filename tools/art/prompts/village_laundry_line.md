---
id: village_laundry_line
command: animate3
target: res://assets/sprites/world/props/village/laundry_line.png
size: 138x66
frames: 6
view: side
reference: res://tools/art/sources/village/pixellab/laundry_line_ref.png
action: the clothes hanging on the line sway gently in a light breeze; the two wooden posts and the line's ends stay still
keep: 0-5
generate: 6
source: pixellab
---
A washing line between two posts, the house of notes' clothes swaying on it. The still is cut by `python -I tools/art/cut_props.py tools/art/sources/village/street_cloth_codex.png <dir> --merge=8 --ref-height=29 --flat=10 --base-shade --colors=64 --names=-,laundry_line,-,-,flag,bunting --size=laundry_line:h34,flag:h16,bunting:w64`; the loop is PixelLab animate-with-text-v3 from it (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/village/pixellab/laundry_line_ref.png -Frames 6 -Action "<action>"`, frames kept in tools/art/sources/village/pixellab/laundry_line/), cut by `python -I tools/art/cut_inhabitant.py <frames> laundry_line <ref> <strip> --frames=6` and trimmed by `python -I tools/art/trim_strip.py`. Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
