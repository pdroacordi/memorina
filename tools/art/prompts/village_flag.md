---
id: village_flag
command: animate3
target: res://assets/sprites/world/props/village/flag.png
size: 22x30
frames: 5
view: side
reference: res://tools/art/sources/village/pixellab/flag_ref.png
action: the red and white cloth flag waves gently in the wind, rippling; the wooden pole stays perfectly still
keep: 0-3,5-5
generate: 6
source: pixellab
---
A small red and cream pennant on a short pole, waving. The still is cut by `python -I tools/art/cut_props.py tools/art/sources/village/street_cloth_codex.png <dir> --merge=8 --ref-height=29 --flat=10 --base-shade --colors=64 --names=-,laundry_line,-,-,flag,bunting --size=laundry_line:h34,flag:h16,bunting:w64`; the loop is PixelLab animate-with-text-v3 from it (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/village/pixellab/flag_ref.png -Frames 6 -Action "<action>"`, frames kept in tools/art/sources/village/pixellab/flag/), cut by `python -I tools/art/cut_inhabitant.py <frames> flag <ref> <strip> --frames=5 --keep=0-3,5-5` and trimmed by `python -I tools/art/trim_strip.py`. Approved on the WORLD-11 board: props "Approve (Recommended)" (user, 2026-10-13: approve the look and sizes; the small props that turned to mush redrawn at exact size with PixelLab, the well head redrawn wider and lower). Sized against Ivo's 29 art px ("some of the props are way too big. They are bigger than Ivo", user, 2026-10-11) and trimmed so the bottom row is the base ("Many things on the game seem to just be flaoting", user, 2026-10-11).
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
