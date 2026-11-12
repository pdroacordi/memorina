---
id: garden_swing
command: generate
target: res://assets/sprites/world/props/garden/swing.png
size: 36x86
frames: 1
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_garden_props.py
---
Alba's rope swing hanging still: two hemp ropes 26 px apart (game x 4-5 and 30-31), each looped round the branch at the top (y 0-5 overlap the branch's underside), a village-oak plank seat 36 px wide. Measured (game px from the sprite's top left): the rope runs from y 6 to the seat's top at y 78, the seat is 6 px thick, a knot under each end reaches y 86. Hung from the old tree with its top 6 px above the branch's underside (92 over the floor), the seat's top is 20 px over the floor: Alba (26 art px) sits on it with room under the branch, and Ivo pushes it. One still; a cutscene moves it. Drawn at 18x43 art px by `python -I tools/art/draw_garden_props.py swing assets/sprites/world/props/garden/swing.png`: a 1 art px rope is drawn by script, as every part at 6 art px or less (systems/art-pipeline, Puzzle parts).
The garden concept `tools/art/references/regions/garden_concept.png` is approved for look and mood only: "Isso é apenas o conceito, certo? Se sim, aprovada. Na implementação real, a água tem que ser das nossas, gerada automaticamente, com reflexo. E deve ser mais perto dos personagens para que fique um cenário bem bonito" (user, 2026-11-12). Not yet seen by the user in the room.
Negative: outlines, black contour, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, people
