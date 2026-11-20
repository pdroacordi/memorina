---
id: guardian_frost_effect_ice_wave
command: generate
target: res://assets/sprites/characters/guardians/frost_guardian/effects/frost_ice_wave.png
size: 12x24
frames: 3
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
The slam's ice wave (`scenes/characters/guardians/frost_guardian/spawns/ice_wave.tscn`, a `FloorRunner`; also the mentor's frost wave): one ice shard on a blue-grey stone base, pale ice with a white ridge and a dark stone rim. Three rise stages of 16, 20 and 24 px (8, 10, 12 art px), so even the lowest stands above the 16 px front grass (the Bloom lesson). Measured: the wave's hit is 20x24 at its head and its placeholder spikes rose to 24 px, so one frame is 12x24 (6x12 art px), the bottom row the floor line. `FloorRunner` plants one every frame width, mirrored every other, the stage by its rise (`SpawnArt.stage`). Colours are the golem's own, sampled from `tools/art/sources/guardians/frost_still.png` (the darkest stone as the rim). GRD-18.
Drawn by `python -I tools/art/draw_guardian_effects.py frost`. Approved: "Approve and wire (Recommended)" (user, 2026-11-20, the Frost GRD-18 sheet).
Negative: black outline, speckle, scenery, text
