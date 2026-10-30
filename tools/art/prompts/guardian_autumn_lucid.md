---
id: guardian_autumn_lucid
command: animate3
target: res://assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_lucid.png
size: 128x112
frames: 6
keep: 4-6,6-4
generate: 6
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/scarecrow_ref.png
action: calm: the bone scarecrow straightens up a little and stands still, quiet, its round bone mask tilted up, one dry leaf trembling at its fingertips; seen from the side facing left the whole time
source: pixellab
---
The lucid loop, 0.9 s at 0.15 s a frame: straighter, the mask tilted up, a leaf trembling at its fingers. The autumn guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), a hunched scarecrow of hollow bone and dry leaves: a round cracked bone mask with a stitched mouth facing the viewer, a hood of dry rust and amber leaves, long thin bone arms reaching the ground with twig claws, a long skirt of dry leaves trailing behind, withered apples; seen from the side facing west, the skirt and torso (not the reaching arms) on the flip axis, feet on art row 111, the frame's bottom row. Sheets are 1 px per art px (128x112), shown at Sprite2D scale 2. The still is our own: scarecrow_still.png (72x78 art px) and scarecrow_still_2x.png, cut from the Codex concept tools/art/sources/guardians/scarecrow_concept_codex_r1.png (user, 2026-10-30: "B, curvado, mais assustador", the face redrawn as a round cracked bone mask with a stitched mouth and a hood of dry leaves; "Aprovar"). The reference is the 2x still padded onto a 2x frame (`python -I tools/art/pad_reference.py tools/art/sources/guardians/scarecrow_still_2x.png tools/art/sources/guardians/scarecrow_ref.png 256x224 --at=bottom`), then moved 12 px left (`numpy.roll(ref, -12, axis=1)`) so still column 41 (the torso and the stilt foot) lands on the flip axis; PixelLab draws the slender scarecrow at 2x and the cut halves it (systems/art-pipeline, Guardians). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_autumn_lucid -Name guardian_autumn_lucid -Out tools/art/sources/guardians`; the returned frames kept in tools/art/sources/guardians/guardian_autumn_lucid/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_autumn_lucid guardian_autumn_lucid tools/art/sources/guardians/scarecrow_still.png assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_lucid.png --write=1 --floor=223 --drop=45 --keep=4-6,6-4` then `python -I tools/art/despeckle.py assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_lucid.png 128 --min=3`: every pixel snapped to the still's 16 colours (--drop=45 clears the white flashes PixelLab paints; the still's palest bone is 82 away from white), feet on art row 111. The run straightens from the hunch over its frames, so the loop is a ping-pong of its upright frames 4-6 (6-4 back). Returned frame 6 (the most upright) is also the reference of `restored` (autumn_lucid_upright.png, doubled to autumn_lucid_upright_2x.png). No pack art was shown to any generator; every reference is our own still or our own strip of this guardian.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery
