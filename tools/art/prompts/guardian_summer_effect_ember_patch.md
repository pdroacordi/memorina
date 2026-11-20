---
id: guardian_summer_effect_ember_patch
command: generate
target: res://assets/sprites/characters/guardians/summer_guardian/effects/summer_ember_patch.png
size: 48x18
frames: 3
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
The burning patch an ember leaves (`ember_patch.tscn`, a `FloorPatch` 48x18, live 1.5 s; GRD-18): a low bed of cinders with short flat flames, three rise stages (`SpawnArt.stage`: a few low tongues through the warning, then fuller, then the whole bed while it burns, and back down as it fades), feet on the bottom row. Measured: its hit is 48x18, so one frame is 48x18 (24x9 art px). A 16 px floor is the minimum to read over the front grass; the flames stand 18. Colours are the lion's own (sampled from `tools/art/sources/guardians/sun_lion_still.png`): the pale-gold and orange of its pores and mane for the fire, the charcoal stone for the rim; every stage keeps a dark rim so it reads at memory 0 and over the grass, and every floor stage stands 16 px or more (`spawned_attack_test.test_every_runner_stage_stands_above_the_grass`).
Drawn by `python -I tools/art/draw_guardian_effects.py summer`.
Negative: black outline, speckle, scenery, text
