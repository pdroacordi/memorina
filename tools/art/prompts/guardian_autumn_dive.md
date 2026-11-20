---
id: guardian_autumn_dive
command: animate3
target: res://assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_dive.png
size: 128x112
frames: 8
keep: 1-8
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/scarecrow_ref.png
action: dive: the hunched bone scarecrow crouches and wraps its long bone arms around its knees, springs straight up into the air curled in a ball, then hangs upside down head first and plunges straight down with both bone arms stretched straight below its mask, the twig claws stab into the ground, it lands in a deep upright crouch with the claws dug in, then rises to its hunched upright stance; side view facing left the whole time, upright when it lands, never lying flat, never crawling
source: pixellab
---
The dive (`autumn_dive.tres`, clip_index 6, windup_index 5, recovery_index 3; stage 1): wind-up 0.45 s (frames 0-1: the curl, which must differ from the hop's standing crouch), strike 1.2 s (frame 2 the rise to 0.35, frame 3 the hang to 0.75, frames 4-5 the plunge claws first, the box live from 0.85 on the landing, frame 5 the landing), recovery 0.6 s (frames 6-7: the claws dug in, the rise; the punish window). Feet on the floor row on every frame: `DiveMotion` carries the arc. The autumn guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), a hunched scarecrow of hollow bone and dry leaves: a round cracked bone mask with a stitched mouth facing the viewer, a hood of dry rust and amber leaves, long thin bone arms reaching the ground with twig claws, a long skirt of dry leaves trailing behind, withered apples; seen from the side facing west, the skirt and torso on the flip axis, feet on art row 111, the frame's bottom row. Sheets are 1 px per art px (128x112), shown at Sprite2D scale 2; the reference is our own 2x still padded to the frame (guardian_autumn_leap says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Leaf Guardian's fight); `keep:` is set after the look. animate-with-text-v3 returned at most 8+1 frames for this 256x224 reference (GRD-04), so `generate` is 8. Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_autumn_dive -Name guardian_autumn_dive_g18r2 -Out tools/art/sources/guardians` (a new `_g18` name: the GRD-04 raws are tracked); cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_autumn_dive_g18r2 guardian_autumn_dive_g18r2 tools/art/sources/guardians/scarecrow_still.png assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_dive.png --write=1 --keep=<keep> --floor=223 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=3`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, motion lines, text, ground, scenery, particles
