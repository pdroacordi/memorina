---
id: guardian_frost_effect_icicle_shatter
command: generate
target: res://assets/sprites/characters/guardians/frost_guardian/effects/frost_icicle_shatter.png
size: 20x18
frames: 2
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
The icicle bursting where it struck (`icicle.tscn`'s `shatter`), drawn through the fade: shards splaying up from a stone lump, then sinking. Two stages, 10 and 18 px tall (5 and 9 art px). Measured: the placeholder drew a 16 px wide lump; the burst is 20x18 (10x9 art px) so it shows over the 16 px front grass, inside the shard's drawn rect (size.x + 6 either side). Colours are the golem's own, sampled from `tools/art/sources/guardians/frost_still.png` (the darkest stone as the rim). GRD-18.
Drawn by `python -I tools/art/draw_guardian_effects.py frost`. Approved: "Approve and wire (Recommended)" (user, 2026-11-20, the Frost GRD-18 sheet).
Negative: black outline, speckle, scenery, text
