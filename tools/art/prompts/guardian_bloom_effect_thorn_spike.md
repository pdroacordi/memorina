---
id: guardian_bloom_effect_thorn_spike
command: generate
target: res://assets/sprites/characters/guardians/bloom_guardian/effects/bloom_thorn_spike.png
size: 12x28
frames: 4
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
One wooden thorn of the Bloom Guardian's thorn row (`scenes/characters/guardians/bloom_guardian/spawns/thorn_row.tscn`, a `FloorRunner`; GRD-18), rising out of a moss tuft on the floor line: pale wood with a dark brown rim, a pink blossom on its tip when whole. Four rise stages: tip, bud, half, full (frame 3, in blossom). Measured: the runner's hit is 20x28 at its head and its placeholder spikes rose to 28 px, so one frame is 12x28 (6x14 art px), its bottom row the floor line. `FloorRunner` plants one every frame width (12 px) from its root, mirrored every other, and picks the stage by the spike's rise (`SpawnArt.stage`): full at the head, sinking behind it and in the fade. Colours are the stag's own (`tools/art/sources/guardians/bloom_palette.png`).
Drawn by `python -I tools/art/draw_guardian_effects.py bloom`. Approved: "Approve and wire" (user, 2026-11-19, the Bloom GRD-18 sheet).
Negative: black outline, speckle, scenery, text
