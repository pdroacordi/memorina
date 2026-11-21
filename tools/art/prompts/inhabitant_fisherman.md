---
id: inhabitant_fisherman
command: animate3
target: res://assets/sprites/world/inhabitants/fisherman.png
size: 64x64
frames: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/inhabitants/fisherman_still_2x.png
action: idle: an old fisherman standing in strict side profile facing left the whole time, a net over his arm, breathing slowly, his free hand tugging a knot; he never turns his head or body toward the viewer; feet stay planted
source: pixellab
---
An idle loop of the old fisherman in his hut (lake_fisher_hut; design 04 section 5, pescador), seen from the side facing west, feet on the frame's bottom row, body centred, no talk ("yes", user, 2026-11-20). The still is cut from one Codex sheet of the three regions' people (tools/art/sources/inhabitants/region_people_codex.png; tools/art/references/village_concept.png the reference) by `cut_props.py --figure=none --size=<name>:h26`, mirrored to face west on a 64x64 2x frame. An adult, 26 art px tall in a 32 art px frame. The loop is PixelLab animate-with-text-v3 from that still, cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/inhabitants fisherman_idle tools/art/sources/inhabitants/fisherman_still.png assets/sprites/world/inhabitants/fisherman.png`. The first loop turned to the viewer in frames 3-6 and was redone with "strict side profile".
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery
