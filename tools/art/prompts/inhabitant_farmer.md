---
id: inhabitant_farmer
command: animate3
target: res://assets/sprites/world/inhabitants/farmer.png
size: 64x64
frames: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/inhabitants/farmer_still_2x.png
action: idle: a farmer standing with a grain sack on his shoulder, shifting its weight a little and breathing; feet stay planted
source: pixellab
---
An idle loop of a farmer in a straw hat carrying a full grain sack on his shoulder, seen from the side facing west, feet on the frame's bottom row, body centred. The still is cut from one Codex sheet of the village's people and animals (tools/art/sources/village_people_codex.png; the approved concept and the village fronts as references), An adult, 26 art px tall in a 32 art px frame. The loop is PixelLab animate-with-text-v3 from that still (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/inhabitants/farmer_still_2x.png -Frames 8 -Action "<action>"`; the frames kept in tools/art/sources/inhabitants/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/inhabitants farmer_idle tools/art/sources/inhabitants/farmer_still.png assets/sprites/world/inhabitants/farmer.png`: each 2x2 block to its most common colour, every pixel snapped to the still's colours.
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery
