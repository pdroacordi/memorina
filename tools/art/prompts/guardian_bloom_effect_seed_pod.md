---
id: guardian_bloom_effect_seed_pod
command: generate
target: res://assets/sprites/characters/guardians/bloom_guardian/effects/bloom_seed_pod.png
size: 16x16
frames: 4
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
The Bloom Guardian's seed pod in flight (`scenes/characters/guardians/bloom_guardian/spawns/seed_pod.tscn`, a `Lob`; GRD-18): a round brown pod with a pale lit side, a dark rim, a moss stem and a pink bud. Four spin frames, one asymmetric pod turned a quarter clockwise a frame, looped at 10 frames per scaled s from the throw (`SpawnArt.loop_frame`) and mirrored for a westward throw. Measured: the pod's hit is 12x12; its placeholder drew 16x16 with its rim, so one frame is 16x16 (8x8 art px), drawn centred on the hit. Colours are the stag's own (`tools/art/sources/guardians/bloom_palette.png`).
Drawn by `python -I tools/art/draw_guardian_effects.py bloom`. Approved: "Approve and wire" (user, 2026-11-19, the Bloom GRD-18 sheet).
Negative: black outline, speckle, scenery, text
