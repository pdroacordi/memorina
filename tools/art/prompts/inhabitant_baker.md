---
id: inhabitant_baker
command: animate3
target: res://assets/sprites/world/inhabitants/baker.png
size: 64x64
frames: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/inhabitants/baker_still_2x.png
action: idle: a baker turning a loaf of bread in his hands, looking at it, breathing; feet stay planted
source: pixellab
---
An idle loop of the baker woman (design 04 section 3.1, the Padeira), in a white cap and a flour-dusted apron, holding a round loaf, seen from the side facing west, feet on the frame's bottom row, body centred. The still is cut from one Codex sheet of the village's people and animals (tools/art/sources/village_people_codex.png; the approved concept and the village fronts as references), An adult, 26 art px tall in a 32 art px frame. The baker's still is its own Codex picture (tools/art/sources/village_baker_codex.png, the people sheet as its reference). The loop is PixelLab animate-with-text-v3 from that still (`tools/pixellab/pixellab.ps1 animate3 -Reference tools/art/sources/inhabitants/baker_still_2x.png -Frames 8 -Action "<action>"`; the frames kept in tools/art/sources/inhabitants/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/inhabitants baker_idle tools/art/sources/inhabitants/baker_still.png assets/sprites/world/inhabitants/baker.png`: each 2x2 block to its most common colour, every pixel snapped to the still's colours.
Negative: outlines, black contour, front view, facing right, glow, text, ground, scenery
