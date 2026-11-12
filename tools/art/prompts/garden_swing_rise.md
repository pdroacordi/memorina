---
id: garden_swing_rise
command: generate
target: res://assets/sprites/world/props/garden/swing_rise.png
size: 36x98
frames: 3
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_garden_props.py
---
The fallen swing raised by a held Up in flashback 3 (design drafts/camada_pessoal.md section 2, flashback 3's Cinema line): frame k is step k + 1 of 4, between `garden_swing_fallen` on the ground and `garden_swing` hanging. Measured (game px from the frame's top left, the ground under row 97, the hanging swing's rows 0-85 in the same frame): the 36 px plank seat's top is at y 88, 84 and 82 over the three frames (the hanging seat's is 78, the fallen one lies on the ground); the two hemp ropes (game x 4-5 and 30-31, as the hanging swing's) climb from the seat to y 68, 44 and 24, each loose end bent outward 2 px and frayed. Same rope and plank colours as `garden_swing`. Drawn at 18x49 art px per frame by `python -I tools/art/draw_garden_props.py swing_rise assets/sprites/world/props/garden/swing_rise.png`.
Negative: outlines, black contour, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, people
