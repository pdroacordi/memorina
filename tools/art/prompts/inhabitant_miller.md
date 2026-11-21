---
id: inhabitant_miller
command: animate3
target: res://assets/sprites/world/inhabitants/miller.png
size: 64x64
frames: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/inhabitants/miller_still_2x.png
action: idle: a miller shifting the flour sack on his shoulder, breathing; feet stay planted
source: pixellab
---
An idle loop of a miller on the mill town's lower street, by the small windmill, seen from the side facing west, feet on the frame's bottom row, body centred, no talk ("yes", user, 2026-11-20). The still is cut from one Codex sheet of the three regions' people (tools/art/sources/inhabitants/region_people_codex.png; tools/art/references/village_concept.png the reference) by `cut_props.py --figure=none --size=<name>:h26`, mirrored to face west on a 64x64 2x frame. An adult, 26 art px tall in a 32 art px frame. The loop is PixelLab animate-with-text-v3 from that still, cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/inhabitants miller_idle tools/art/sources/inhabitants/miller_still.png assets/sprites/world/inhabitants/miller.png`.
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery
