---
id: story_ribbon_flight
command: generate
target: res://assets/sprites/world/story/ribbon/ribbon_flight.png
size: 64x192
frames: 12
view: side
direction: east
no_background: true
source: procedural: tools/art/draw_garden_props.py
---
Alba's ribbon let go in flashback 2's crossing (design drafts/camada_pessoal.md section 2, flashback 2): the free bow of `garden_ribbon_branch` (no twig) at the hand's size, rising from the frame's bottom left up and away to its top right over 10 frames, its two ends trailing and waving; frames 10-11 are empty (it has gone into the white). Same blue, 118,152,199, and its two shades. Played once at 5 fps by `ribbon_flight.tscn` (offset -8,-188 from Ivo's hand). Drawn at 32x96 art px per frame by `python -I tools/art/draw_garden_props.py ribbon_flight assets/sprites/world/story/ribbon/ribbon_flight.png`.
Negative: outlines, black contour, speckle, noise, gradients, background, glow, blur, text, people
