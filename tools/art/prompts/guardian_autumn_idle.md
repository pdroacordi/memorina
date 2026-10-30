---
id: guardian_autumn_idle
command: animate3
target: res://assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_idle.png
size: 128x112
frames: 6
keep: 0-5
generate: 6
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/scarecrow_ref.png
action: idle: the hunched bone scarecrow stands in place swaying slowly, its long bone arms hanging to the ground, its leaf skirt rustling a little and one leaf on its hood lifting as if about to fall; its round bone mask keeps facing the same way; seen from the side facing left the whole time
source: pixellab
---
An idle loop, 0.9 s at 0.15 s a frame: a hunched sway, the skirt rustling, one leaf caught back as it starts to fall. The autumn guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), a hunched scarecrow of hollow bone and dry leaves: a round cracked bone mask with a stitched mouth facing the viewer, a hood of dry rust and amber leaves, long thin bone arms reaching the ground with twig claws, a long skirt of dry leaves trailing behind, withered apples; seen from the side facing west, the skirt and torso (not the reaching arms) on the flip axis, feet on art row 111, the frame's bottom row. Sheets are 1 px per art px (128x112), shown at Sprite2D scale 2. The still is our own: scarecrow_still.png (72x78 art px) and scarecrow_still_2x.png, cut from the Codex concept tools/art/sources/guardians/scarecrow_concept_codex_r1.png (user, 2026-10-30: "B, curvado, mais assustador", the face redrawn as a round cracked bone mask with a stitched mouth and a hood of dry leaves; "Aprovar"). The reference is the 2x still padded onto a 2x frame (`python -I tools/art/pad_reference.py tools/art/sources/guardians/scarecrow_still_2x.png tools/art/sources/guardians/scarecrow_ref.png 256x224 --at=bottom`), then moved 12 px left (`numpy.roll(ref, -12, axis=1)`) so still column 41 (the torso and the stilt foot) lands on the flip axis; PixelLab draws the slender scarecrow at 2x and the cut halves it (systems/art-pipeline, Guardians). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_autumn_idle -Name guardian_autumn_idle -Out tools/art/sources/guardians`; the returned frames kept in tools/art/sources/guardians/guardian_autumn_idle/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_autumn_idle guardian_autumn_idle tools/art/sources/guardians/scarecrow_still.png assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_idle.png --write=1 --floor=223 --drop=45 --keep=0-5 --ceiling=60` then `python -I tools/art/despeckle.py assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_idle.png 128 --min=3`: every pixel snapped to the still's 16 colours (--drop=45 clears the white flashes PixelLab paints; the still's palest bone is 82 away from white), feet on art row 111. Returned frames 0-5, a closed loop (frame 6 repeats 0). --ceiling=60 clears the loose leaf PixelLab lifted off the hood and flew upward on frames 3-5, so the loop does not pop a leaf in and out; the hood's own leaves still rustle. No pack art was shown to any generator; every reference is our own still or our own strip of this guardian.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery
