---
id: guardian_summer_effect_ember
command: generate
target: res://assets/sprites/characters/guardians/summer_guardian/effects/summer_ember.png
size: 16x16
frames: 4
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
The Sun Guardian's ember in flight (`scenes/characters/guardians/summer_guardian/spawns/ember.tscn`, a `Lob`; GRD-18): a lump of glowing volcanic stone with a pale-gold core and an orange skin cracked with charcoal. Four spin frames, one asymmetric lump turned a quarter a frame (`np.rot90`), looped from the throw (`SpawnArt.loop_frame`). Measured: its hit is 12x12 and its placeholder drew a 2 px rim, so one frame is 16x16 (8x8 art px), centred on the hit. Colours are the lion's own (sampled from `tools/art/sources/guardians/sun_lion_still.png`): the pale-gold and orange of its pores and mane for the fire, the charcoal stone for the rim; every stage keeps a dark rim so it reads at memory 0 and over the grass, and every floor stage stands 16 px or more (`spawned_attack_test.test_every_runner_stage_stands_above_the_grass`).
Drawn by `python -I tools/art/draw_guardian_effects.py summer`.
Negative: black outline, speckle, scenery, text
