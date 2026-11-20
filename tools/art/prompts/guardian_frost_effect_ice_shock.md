---
id: guardian_frost_effect_ice_shock
command: generate
target: res://assets/sprites/characters/guardians/frost_guardian/effects/frost_ice_shock.png
size: 12x20
frames: 3
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
The body drop's landing shock (`ice_shock.tscn`, a `FloorRunner`): two ice shards splayed apart on a stone base, so it reads apart from the slam's wave. Three rise stages of 16, 18 and 20 px (8, 9, 10 art px). Measured: the shock's hit is 20x20, so one frame is 12x20 (6x10 art px), the bottom row the floor line; planted and staged as the wave. Colours are the golem's own, sampled from `tools/art/sources/guardians/frost_still.png` (the darkest stone as the rim). GRD-18.
Drawn by `python -I tools/art/draw_guardian_effects.py frost`. Approved: "Approve and wire (Recommended)" (user, 2026-11-20, the Frost GRD-18 sheet).
Negative: black outline, speckle, scenery, text
