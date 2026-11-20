---
id: guardian_bloom_seed_lob
command: animate3
target: res://assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_seed_lob.png
size: 128x96
frames: 9
keep: 3-9,10-10,0-0
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/bloom_ref_2x.png
action: overhand throw: the tree-stag reaches one long arm back behind its shoulder, then flings it up and forward in a high overhand throw, the hand open at the top, then lowers the arm, side view facing left the whole time
source: pixellab
---
The seed lob (`bloom_seed_lob.tres`, no strike box; stage 1): wind-up 0.5 s (frames 0-2: the arm back), strike 0.5 s (frames 3-6; the pods leave at 0.1, 0.2 and 0.3 s), recovery 0.3 s (frames 7-8). Hand-drawn pods are not part of the body: the spawn draws them. The Bloom guardian (GRD-07), a tall slender tree-stag standing on two legs: pale wood body, a deer-skull face, branch antlers with pink blossoms, a mossy green mantle, seen from the side facing west, body centred in the frame, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2; the reference is our own 2x still (guardian_bloom_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Bloom Guardian's fight); `keep:` was set after the look. Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_bloom_seed_lob -Name guardian_bloom_seed_lob_r1 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_bloom_seed_lob_r1 guardian_bloom_seed_lob_r1 tools/art/sources/guardians/bloom_palette.png assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_seed_lob.png --write=1 --keep=<keep> --floor=191 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=4`. Round 1 (2026-11-19): kept the arm back (0-2), the overhand throw (3-6), the lowered arm (7-8). PixelLab put a pale rod with a pod in the hand on the throw frames; it was cleared by hand on the target: frames 4-5 above the antler tips (row 34), and the rod pixels at x 45-48 rows 34-41 (frame 4), x 46-47 rows 34-49 (frame 5), x 46 rows 61-65 (frame 6).
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery
