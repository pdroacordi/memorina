---
id: guardian_autumn_blade_throw
command: animate3
target: res://assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_blade_throw.png
size: 128x112
frames: 8
keep: 1-8
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/scarecrow_ref.png
action: leaf throw: the hunched bone scarecrow, facing left, reaches down to its dry leaf skirt and tears off a handful of leaves, cocks the long bone arm back behind its shoulder on its right side, then swings it forward and flings it out to the LEFT in front of its mask at chest height with the twig claws opening, the arm stretched out ahead of its face pointing left, then lowers the arm back to its hunched stance; side view facing left the whole time, the throwing arm always ends in front of the face, never behind the back
source: pixellab
---
The leaf blades (`autumn_leaf_blades.tres`, clip_index 5, windup_index 4, recovery_index 4; stage 0): wind-up 0.45 s (frames 0-2: the low reach to the skirt, then the arm cocked: stay down, then jump), strike 0.6 s with the throw at 0.2 (frames 3-5: the fling; the three blades are spawns drawn by `draw_guardian_effects.py autumn`, so the hand stays empty of drawn blades), recovery 0.4 s (frames 6-7). No hitbox on the body. The autumn guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), a hunched scarecrow of hollow bone and dry leaves: a round cracked bone mask with a stitched mouth facing the viewer, a hood of dry rust and amber leaves, long thin bone arms reaching the ground with twig claws, a long skirt of dry leaves trailing behind, withered apples; seen from the side facing west, the skirt and torso on the flip axis, feet on art row 111, the frame's bottom row. Sheets are 1 px per art px (128x112), shown at Sprite2D scale 2; the reference is our own 2x still padded to the frame (guardian_autumn_leap says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Leaf Guardian's fight); `keep:` is set after the look. animate-with-text-v3 returned at most 8+1 frames for this 256x224 reference (GRD-04), so `generate` is 8. Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_autumn_blade_throw -Name guardian_autumn_blade_throw_g18r2 -Out tools/art/sources/guardians` (a new `_g18` name: the GRD-04 raws are tracked); cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_autumn_blade_throw_g18r2 guardian_autumn_blade_throw_g18r2 tools/art/sources/guardians/scarecrow_still.png assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_blade_throw.png --write=1 --keep=<keep> --floor=223 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=3`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, motion lines, text, ground, scenery, particles, thrown objects
