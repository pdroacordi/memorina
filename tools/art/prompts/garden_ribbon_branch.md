---
id: garden_ribbon_branch
command: generate
target: res://assets/sprites/world/props/garden/ribbon_branch.png
size: 48x48
frames: 4
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_garden_props.py
---
Alba's cornflower-blue cloth ribbon (118,152,199, the blue of story/alba/standing.png, with a darker shade 84,114,166 and a knot shade 62,86,134) tied in a bow round a twig end: the call of flashbacks 2 and 4 (design drafts/camada_pessoal.md section 1). Redrawn 2026-11-12 twice the first size, a clear bow and two long loose ends, after the user found the first "small and tangled"; then scaled down the same day to 48 px per frame, because at 72 px it read larger than Ivo's torso in play. Measured (game px from the frame's top left): the dead twig leaves the corner (0, 0) and roots there in rock or bark, two leaves on it; the 6x6 knot is at x 28-33, y 8-13; the two loops span x 14-47, y 6-15, filled, a small dark eye in each; the two ends hang from under the knot to y 47, 6 px wide then 4, their tips notched; a wave runs down them over the 4 frames (a loop). Drawn at 24x24 art px per frame by `python -I tools/art/draw_garden_props.py ribbon_branch assets/sprites/world/props/garden/ribbon_branch.png`.
The garden concept `tools/art/references/regions/garden_concept.png` is approved for look and mood only: "Isso é apenas o conceito, certo? Se sim, aprovada. Na implementação real, a água tem que ser das nossas, gerada automaticamente, com reflexo. E deve ser mais perto dos personagens para que fique um cenário bem bonito" (user, 2026-11-12). Not yet seen by the user in the room.
Negative: outlines, black contour, speckle, noise, gradients, perspective, floor, background, shadows on the ground, glow, blur, text, people
