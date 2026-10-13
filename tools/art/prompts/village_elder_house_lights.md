---
id: village_elder_house_lights
command: generate
target: res://assets/sprites/world/props/village/elder_house_lights.png
size: 246x220
frames: 3
view: side
source: procedural: tools/art/draw_ambient_frames.py
---
The lit window panes of the elder house front: an overlay the front's size, each dark pane filled with three flat warm tones that flicker over three frames (architecture/props-and-ambient-life section 5: the light is painted pixels, greyed by the greyhush with the wall). Drawn by `python -I tools/art/draw_ambient_frames.py lights assets/sprites/world/props/village/elder_house_facade.png assets/sprites/world/props/village/elder_house_lights.png`.
Negative: outlines, black contours, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, letters, numbers, people
