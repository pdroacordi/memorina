---
id: guardian_autumn_effect_leaf_blade
command: generate
target: res://assets/sprites/characters/guardians/autumn_guardian/effects/autumn_leaf_blade.png
size: 20x20
frames: 4
view: side
direction: west
no_background: true
source: procedural: tools/art/draw_guardian_effects.py
---
The Leaf Guardian's thrown leaf blade (`scenes/characters/guardians/autumn_guardian/spawns/leaf_blade.tscn`, a `Boomerang`; GRD-18): one dry amber leaf, pointed, with a rust midrib, a pale lit edge and a 1 art px dark rim, so it reads against the grey sky and the ground at memory 0 (the GRD-15 feel pass: grey on grey). Four spin frames, one asymmetric leaf turned a quarter a frame (`np.rot90`), looped from the throw (`SpawnArt.loop_frame`) and mirrored for a westward throw. Measured: the blade's hit is 16x12; its placeholder drew it with a 2 px rim, so one frame is 20x20 (10x10 art px, square so a quarter turn keeps the frame), drawn centred on the hit; `_drawn_rect` grows by the art's overhang. Colours are the scarecrow's own (sampled from `tools/art/sources/guardians/scarecrow_still.png`). `Boomerang` gets the optional `art` (SpawnArt) Bloom gave FloorRunner, Lob and FloorPatch.
Drawn by `python -I tools/art/draw_guardian_effects.py autumn`.
Negative: black outline, speckle, scenery, text
