---
id: guardian_autumn_effect_swirl_leaf
command: generate
target: res://assets/sprites/characters/guardians/autumn_guardian/effects/autumn_swirl_leaf.png
size: 8x6
frames: 2
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
One leaf of the scatter's swirl (`scenes/characters/guardians/autumn_guardian/spawns/scatter_swirl.tscn`, a `LeafSwirl`; GRD-18): the swirl marks where the scarecrow reforms, 48x156 px, 18 leaves turning on its column for 0.45 s with the shared floor warning under it. The column's motion stays procedural (each leaf moves on its own path), so only the leaf is drawn: a small dry leaf, light with a dark rim, two tumble frames (flat, edge-on) swapped every quarter turn, mirrored on the far side (`LeafSwirl.leaf`). Measured: the placeholder leaf is a light rect in a 1 px dark rim; one frame is 8x6 (4x3 art px). Colours are the scarecrow's own (`tools/art/sources/guardians/scarecrow_still.png`); the light/dark pair the scene sets today stays for the floor warning.
Drawn by `python -I tools/art/draw_guardian_effects.py autumn`.
Negative: black outline, speckle, scenery, text
