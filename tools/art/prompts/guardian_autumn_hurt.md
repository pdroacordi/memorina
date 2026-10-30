---
id: guardian_autumn_hurt
command: generate
target: res://assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_hurt.png
size: 128x112
frames: 7
view: side
direction: west
no_background: true
source: procedural: tools/art/lean_frames.py
---
A stagger, 0.583 s at 1/12 s a frame. The autumn guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), a hunched scarecrow of hollow bone and dry leaves: a round cracked bone mask with a stitched mouth facing the viewer, a hood of dry rust and amber leaves, long thin bone arms reaching the ground with twig claws, a long skirt of dry leaves trailing behind, withered apples; seen from the side facing west, the skirt and torso (not the reaching arms) on the flip axis, feet on art row 111, the frame's bottom row. Sheets are 1 px per art px (128x112), shown at Sprite2D scale 2. The still is our own: scarecrow_still.png (72x78 art px) and scarecrow_still_2x.png, cut from the Codex concept tools/art/sources/guardians/scarecrow_concept_codex_r1.png (user, 2026-10-30: "B, curvado, mais assustador", the face redrawn as a round cracked bone mask with a stitched mouth and a hood of dry leaves; "Aprovar"). The reference is the 2x still padded onto a 2x frame (`python -I tools/art/pad_reference.py tools/art/sources/guardians/scarecrow_still_2x.png tools/art/sources/guardians/scarecrow_ref.png 256x224 --at=bottom`), then moved 12 px left (`numpy.roll(ref, -12, axis=1)`) so still column 41 (the torso and the stilt foot) lands on the flip axis; PixelLab draws the slender scarecrow at 2x and the cut halves it (systems/art-pipeline, Guardians). The reference at 1x (scarecrow_ref.png halved, nearest: tools/art/sources/guardians/scarecrow_ref_1x.png) is leaned back above the hips by `python -I tools/art/lean_frames.py tools/art/sources/guardians/scarecrow_ref_1x.png assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_hurt.png --pivot=74 --lean=0,6,10,9,7,4,1`: the mask, hood and shoulders are thrown 6, 10, 9, 7, 4 and 1 art px away from the facing (toward +x) and recover; the skirt, legs and the hands on the floor stay planted. Procedural, as Frost's hurt, because generated recoils paint effects in the body's colours (systems/art-pipeline). No generation. No pack art was shown to any generator; every reference is our own still or our own strip of this guardian.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery
