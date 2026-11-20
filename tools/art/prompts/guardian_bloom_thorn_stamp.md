---
id: guardian_bloom_thorn_stamp
command: animate3
target: res://assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_thorn_stamp.png
size: 128x96
frames: 9
keep: 2-4,6-8,8-8,9-10
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/bloom_ref_2x.png
action: stamp: the tree-stag rears up tall on its two hind legs with its arms raised, then slams one hoof down hard on the ground leaning forward, then stands back upright, side view facing left the whole time
source: pixellab
---
The thorn row (`bloom_thorn_row.tres`, no strike box): wind-up 0.45 s (frames 0-2: the rear), strike 0.5 s (frames 3-6: the stamp; the thorns leave at 0.2 s, frame 5), recovery 0.3 s (frames 7-8). Today it reuses the leap's crouch and the burst's rear. The Bloom guardian (GRD-07), a tall slender tree-stag standing on two legs: pale wood body, a deer-skull face, branch antlers with pink blossoms, a mossy green mantle, seen from the side facing west, body centred in the frame, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2; the reference is our own 2x still (guardian_bloom_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Bloom Guardian's fight); `keep:` was set after the look. Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_bloom_thorn_stamp -Name guardian_bloom_thorn_stamp_r1 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_bloom_thorn_stamp_r1 guardian_bloom_thorn_stamp_r1 tools/art/sources/guardians/bloom_palette.png assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_thorn_stamp.png --write=1 --keep=<keep> --floor=191 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=4`. Round 1 (2026-11-19): PixelLab did not rear; it raised an arm (0-2) and dropped to all fours (3-6, the known Bloom stamp habit, art-pipeline Round 2), which reads as the slam that sends the thorns; the rise is 7-8.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery
