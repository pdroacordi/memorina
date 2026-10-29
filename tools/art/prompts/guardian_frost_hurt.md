---
id: guardian_frost_hurt
command: generate
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_hurt.png
size: 192x128
frames: 7
view: side
direction: west
no_background: true
source: procedural: tools/art/lean_frames.py
---
A stagger, 0.583 s at 1/12 s a frame. The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, seen from the side facing west, body centred in the frame, feet on art row 127, the frame's bottom row (today's pack sheets stand on row 109, so wiring moves the Sprite2D from y -92 to -128; the 18 rows freed above hold the raised fists). Sheets are 1 px per art px, shown at Sprite2D scale 2. The still is cut from our own Codex concept tools/art/sources/guardians/guardians_concept_codex.png (approved by the user 2026-10-29: "A, the tree-stag" and "A, the ice golem"; "Scale to today's"): `python -I tools/art/cut_creatures.py tools/art/sources/guardians/guardians_concept_codex.png tools/art/sources/guardians --names=-,bloom_cut,-,frost --pitch=4-12 --colors=16 --size=bloom_cut:h44,frost:h92` cut it at 60x92 art px, the height of today's Frost body (92 art px): frost_still.png. The reference is the still padded onto the 192x128 frame (`python -I tools/art/pad_reference.py tools/art/sources/guardians/frost_still.png tools/art/sources/guardians/frost_ref.png 192x128 --at=bottom`). Round 2 (2026-10-29, the playtest: the strip flung an arm forward, a reach more than a recoil): `python -I tools/art/lean_frames.py tools/art/sources/guardians/frost_ref.png assets/sprites/characters/guardians/frost_guardian/frost_guardian_hurt.png --pivot=98 --lean=0,8,13,12,9,5,2` leans the still back above the hips (art row 98): the head and shoulders are thrown 8, 13, 12, 9, 5 and 2 art px away from the facing (toward +x) and recover; the legs stay planted. Procedural, flagged: both PixelLab runs of round 2 (guardian_frost_hurt_r2a and r2b) painted ice bursts, white flashes and shards in the crystals' blues on every recoil frame, which neither --drop nor a composed clip could clear, and turned toward the viewer. No pack art was shown to any generator; today's pack sheets were only measured (frame size, frame count, body bounds).
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery
