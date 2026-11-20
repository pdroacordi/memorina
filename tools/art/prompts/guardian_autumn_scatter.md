---
id: guardian_autumn_scatter
command: animate3
target: res://assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_scatter.png
size: 128x112
frames: 8
keep: 1-8
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/scarecrow_ref.png
action: come apart: the hunched bone scarecrow spreads its long bone arms wide, its dry leaf hood and skirt lift and swirl up around it, then its whole body breaks apart into a whirl of loose dry rust and amber leaves that spreads out and thins until only a few leaves are left; side view facing left
source: pixellab
---
The scatter (`autumn_scatter.tres`, clip_index 7, windup_index 6, recovery_index 6; stage 2): wind-up 0.4 s (frames 0-2: arms out, the leaves lift), strike 0.7 s (frames 3-7 played forward 0-0.15 as the body comes apart, the sprite hidden 0.15-0.45 as the `BlinkMotion` moves it 64 px behind Ivo, then frames 7-3 played backward 0.45-0.7 as it reforms there), recovery 0.4 s (frames 2-0 backward, then the idle). The sweep from behind follows as a link with its own wind-up. The leaves are the body's own colours, so PixelLab drawing them is wanted here. The autumn guardian (GRD-04, `architecture/grd-04-autumn-and-summer-guardians`), a hunched scarecrow of hollow bone and dry leaves: a round cracked bone mask with a stitched mouth facing the viewer, a hood of dry rust and amber leaves, long thin bone arms reaching the ground with twig claws, a long skirt of dry leaves trailing behind, withered apples; seen from the side facing west, the skirt and torso on the flip axis, feet on art row 111, the frame's bottom row. Sheets are 1 px per art px (128x112), shown at Sprite2D scale 2; the reference is our own 2x still padded to the frame (guardian_autumn_leap says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Leaf Guardian's fight); `keep:` is set after the look. animate-with-text-v3 returned at most 8+1 frames for this 256x224 reference (GRD-04), so `generate` is 8. Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_autumn_scatter -Name guardian_autumn_scatter_g18 -Out tools/art/sources/guardians` (a new `_g18` name: the GRD-04 raws are tracked); cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_autumn_scatter_g18 guardian_autumn_scatter_g18 tools/art/sources/guardians/scarecrow_still.png assets/sprites/characters/guardians/autumn_guardian/autumn_guardian_scatter.png --write=1 --keep=<keep> --floor=223 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=3`. No pack art is shown to any generator.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, motion lines, text, ground, scenery
