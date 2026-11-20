---
id: guardian_bloom_effect_thorn_tuft
command: generate
target: res://assets/sprites/characters/guardians/bloom_guardian/effects/bloom_thorn_tuft.png
size: 16x22
frames: 3
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
A tuft of three wooden thorns on a moss base, the middle one tallest with a pink blossom when whole, the side ones leaning out: the patch a Bloom seed pod leaves (`scenes/characters/guardians/bloom_guardian/spawns/thorn_patch.tscn`, a `FloorPatch`; GRD-18). Three rise stages: sprout (the warning), half, full (live). Measured: the patch is 48x22, so one frame is 16x22 (8x11 art px), three tufts across, mirrored every other, its bottom row the floor line; `FloorPatch` picks the stage by its rise (`SpawnArt.stage`). Colours are the stag's own (`tools/art/sources/guardians/bloom_palette.png`).
Drawn by `python -I tools/art/draw_guardian_effects.py bloom`. Approved: "Approve and wire" (user, 2026-11-19, the Bloom GRD-18 sheet).
Negative: black outline, speckle, scenery, text
