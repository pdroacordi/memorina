---
id: inhabitant_child_a
command: animate3
target: res://assets/sprites/world/inhabitants/child_a.png
size: 48x48
frames: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/inhabitants/child_a_still_2x.png
action: idle: a child rolling a wooden hoop forward a little with a stick and pulling it back, in place
source: pixellab
---
An idle loop of a child playing with a wooden hoop and stick, seen from the side facing west, feet on the frame's bottom row, body centred. The still is cut from one Codex sheet of the village's people and animals (tools/art/sources/village_people_codex.png; the approved concept and the village fronts as references), A child, two thirds of an adult, in a 24 art px frame. The loop is PixelLab animate-with-text-v3 from that still (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/inhabitants/child_a_still_2x.png -Frames 8 -Action "<action>"`; the frames kept in tools/art/sources/inhabitants/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/inhabitants child_a_idle tools/art/sources/inhabitants/child_a_still.png assets/sprites/world/inhabitants/child_a.png`: each 2x2 block to its most common colour, every pixel snapped to the still's colours.
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery
