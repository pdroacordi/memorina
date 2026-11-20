---
id: guardian_frost_walk
command: animate3
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_walk.png
size: 192x128
frames: 8
keep: 0-4,3-1
generate: 4
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/frost_ref.png
action: stepping in place: the ice golem lifts its left foot and stomps it down, then lifts its right foot and stomps it down, a heavy step in place, the body and head staying at exactly the same three-quarter angle as the reference in every frame, never turning
source: pixellab
---
GRD-11 ("a animação de caminhada do guardião do gelo tá estranha", user, 2026-11-16): a walk loop, 0.667 s at 1/12 s a frame, stepping in place at the still's three-quarter angle. The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, facing west, body centred, feet on art row 127. Sheets are 1 px per art px, shown at Sprite2D scale 2; the reference is our own still padded to the frame (guardian_frost_attack_1 says how it was made). Longer walk generations turn the golem to profile mid-cycle (the GRD-07 walk and round 1 of 2026-11-20, 8 frames, both did; round 1's raws were written over the GRD-07 `guardian_frost_walk_r1/` and that folder was restored, so they are not kept); 4 frames held the angle. Round 2 ("One more short retry (Recommended)", user, 2026-11-20): `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_frost_walk -Name guardian_frost_walk_r2 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_frost_walk_r2 guardian_frost_walk_r2 tools/art/sources/guardians/frost_still.png assets/sprites/characters/guardians/frost_guardian/frost_guardian_walk.png --scale=1 --keep=0-4,3-1 --floor=127 --drop=45`, then `python -I tools/art/despeckle.py <target> 192`. Frames 3-4 are the stride with the fists swinging; the loop runs 0-4 and back 3-1.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, ice bursts, motion lines, text, ground, scenery
