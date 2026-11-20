---
id: guardian_autumn_overhead_claw
command: animate3
target: res://assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_overhead_claw.png
size: 128x112
frames: 8
keep: 1-8
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/scarecrow_ref.png
action: overhead claw: the hunched bone scarecrow rears up and lifts one long bone arm high above its leaf hood with the twig claws spread, then brings the arm down in a fast chop in front of it from above its head to the floor, the claws ending on the ground far ahead, then pulls the arm back to its hunched stance; side view facing left the whole time
source: pixellab
---
The overhead claw (`autumn_overhead_claw.tres`, clip_index 4, windup_index 2, recovery_index 1; stage 0): wind-up 0.4 s (frames 0-1: it rears and the arm goes up over the hood), strike 0.5 s with the box live 0.17-0.33 (frames 2-5: the chop from over the head down to the floor; its box reaches 140 px up, so the claws must be drawn from above Ivo's head down through his height), recovery 0.5 s (frames 6-7). Its raised pose must differ from the sweep's arm swung back low (the feel pass: the placeholder read as a third low swipe). The autumn guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), a hunched scarecrow of hollow bone and dry leaves: a round cracked bone mask with a stitched mouth facing the viewer, a hood of dry rust and amber leaves, long thin bone arms reaching the ground with twig claws, a long skirt of dry leaves trailing behind, withered apples; seen from the side facing west, the skirt and torso on the flip axis, feet on art row 111, the frame's bottom row. Sheets are 1 px per art px (128x112), shown at Sprite2D scale 2; the reference is our own 2x still padded to the frame (guardian_autumn_leap says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Leaf Guardian's fight); `keep:` is set after the look. animate-with-text-v3 returned at most 8+1 frames for this 256x224 reference (GRD-04), so `generate` is 8. Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_autumn_overhead_claw -Name guardian_autumn_overhead_claw_g18 -Out tools/art/sources/guardians` (a new `_g18` name: the GRD-04 raws are tracked); cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_autumn_overhead_claw_g18 guardian_autumn_overhead_claw_g18 tools/art/sources/guardians/scarecrow_still.png assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_overhead_claw.png --write=1 --keep=<keep> --floor=223 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=3`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, motion lines, text, ground, scenery, particles
