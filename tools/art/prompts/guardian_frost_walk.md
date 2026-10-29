---
id: guardian_frost_walk
command: animate3
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_walk.png
size: 192x128
frames: 10
keep: 0-2,2-0,11-12,12-11
generate: 12
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/frost_ref.png
action: walk: the ice golem walks forward to the left with slow heavy striding steps, knees lifting, body leaning slightly forward, a looping walk cycle in place, keeping the same angle as the first frame in every frame
source: pixellab
---
A walk loop, 0.833 s at 1/12 s a frame. The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, seen from the side facing west, body centred in the frame, feet on art row 127, the frame's bottom row (today's pack sheets stand on row 109, so wiring moves the Sprite2D from y -92 to -128; the 18 rows freed above hold the raised fists). Sheets are 1 px per art px, shown at Sprite2D scale 2. The still is cut from our own Codex concept tools/art/sources/guardians/guardians_concept_codex.png (approved by the user 2026-10-29: "A, the tree-stag" and "A, the ice golem"; "Scale to today's"): `python -I tools/art/cut_creatures.py tools/art/sources/guardians/guardians_concept_codex.png tools/art/sources/guardians --names=-,bloom_cut,-,frost --pitch=4-12 --colors=16 --size=bloom_cut:h44,frost:h92` cut it at 60x92 art px, the height of today's Frost body (92 art px): frost_still.png. The reference is the still padded onto the 192x128 frame (`python -I tools/art/pad_reference.py tools/art/sources/guardians/frost_still.png tools/art/sources/guardians/frost_ref.png 192x128 --at=bottom`). Round 2 (2026-10-29, the playtest's "walk twists": frames 4-9 turned into profile): PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_frost_walk -Name guardian_frost_walk_r2b -Out tools/art/sources/guardians`; the returned frames kept in tools/art/sources/guardians/guardian_frost_walk_r2b/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_frost_walk_r2b guardian_frost_walk_r2b tools/art/sources/guardians/frost_still.png assets/sprites/characters/guardians/frost_guardian/frost_guardian_walk.png --scale=1 --keep=0-2,2-0,11-12,12-11 --floor=127 --centre=43-78`. Kept from retry 2 of 2, flagged: every run (round 1, guardian_frost_walk_r2a and r2b) turns into profile mid-cycle (r2b frames 3-10), so the loop is composed from the three-quarter frames only: one stomp (0-2, back 2-0) and the other (11-12, back 12-11). Every frame keeps the still's three-quarter view; the step is a stomp in place more than a stride. No pack art was shown to any generator; today's pack sheets were only measured (frame size, frame count, body bounds).
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery
