---
id: door
command: generate
target: res://assets/sprites/world/props/door/door.png
size: 32x64
frames: 2
view: side
direction: west
no_background: true
source: codex
---
A plain wooden house door seen straight on, exactly twice as tall as wide, square top: three or four wide vertical planks, two dark iron strap hinges, a small iron ring handle. Two states side by side: first the door shut and usable; second the same door sealed - a heavy dark iron bar across it and a pale grey-blue crust of frost. No outline, matching the village facades (the codex prompt attached tools/art/sources/village_facades_codex.png). Cut by `python -I tools/art/cut_facades.py door tools/art/sources/door_codex.png assets/sprites/world/props/door/door.png`: each door's plank body reduced to 16x32 art px, 10 colours, 2x.
Negative: outlines, black contour, house, wall, window, arch, rounded top, person, text, open door
