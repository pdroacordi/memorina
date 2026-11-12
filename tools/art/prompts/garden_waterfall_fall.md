---
id: garden_waterfall_fall
command: generate
target: res://assets/sprites/world/props/garden/waterfall_fall.png
size: 28x64
frames: 4
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_garden_props.py
---
The garden's narrow waterfall: a falling-water strip 28 px wide in the game water's blues (world/water/water_cell.png, reflection_ramp.png), light streaks and a few foam flecks, ragged edges. Every frame repeats vertically with a 64 px period (a region taller than 64 with TEXTURE_REPEAT, or stacked sprites), and frame f is frame 0 moved down 16 px, so the 4 frames loop as falling water. It plays only on the memory clock (`AmbientMotion`: still in the grey, running in colour, design drafts/camada_pessoal.md section 1). The pool below is the room's `s` water, never painted. Drawn at 14x32 art px per frame by `python -I tools/art/draw_garden_props.py waterfall_fall assets/sprites/world/props/garden/waterfall_fall.png`.
The garden concept `tools/art/references/regions/garden_concept.png` is approved for look and mood only: "Isso é apenas o conceito, certo? Se sim, aprovada. Na implementação real, a água tem que ser das nossas, gerada automaticamente, com reflexo. E deve ser mais perto dos personagens para que fique um cenário bem bonito" (user, 2026-11-12). Not yet seen by the user in the room.
Negative: outlines, pool, rocks, scenery, text
