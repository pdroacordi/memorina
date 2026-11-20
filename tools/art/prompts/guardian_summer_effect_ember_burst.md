---
id: guardian_summer_effect_ember_burst
command: generate
target: res://assets/sprites/characters/guardians/summer_guardian/effects/summer_ember_burst.png
size: 24x18
frames: 3
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
The embers that run both ways from the pounce's landing (`ember_burst.tscn`, a `FloorRunner` 18 px tall, 128 px at 320 px/s; GRD-18): tongues of fire in three rise stages along its trail (`FloorRunner` grows them toward the head), feet on the bottom row, every other one mirrored. Measured: its hit is 18 tall; one frame is 24x18 (12x9 art px). Colours are the lion's own (sampled from `tools/art/sources/guardians/sun_lion_still.png`): the pale-gold and orange of its pores and mane for the fire, the charcoal stone for the rim; every stage keeps a dark rim so it reads at memory 0 and over the grass, and every floor stage stands 16 px or more (`spawned_attack_test.test_every_runner_stage_stands_above_the_grass`).
Drawn by `python -I tools/art/draw_guardian_effects.py summer`.
Negative: black outline, speckle, scenery, text
