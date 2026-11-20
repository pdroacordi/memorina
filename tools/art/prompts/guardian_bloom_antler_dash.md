---
id: guardian_bloom_antler_dash
command: animate3
target: res://assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_antler_dash.png
size: 128x96
frames: 12
keep: 2-6,7-9,8-8,10-10,1-1,0-0
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/bloom_ref_2x.png
action: charge: the tree-stag crouches low with its antlers lowered forward, takes one step back, then charges forward in a fast low run with its head down and antlers pointing ahead, then skids to a stop and straightens up, side view facing left the whole time
source: pixellab
---
The antler dash (`bloom_antler_dash.tres`, `repeats` false; stage 1): wind-up 0.55 s (frames 0-2: the low crouch), strike 0.9 s (frames 3-4: the 48 px backstep in 0.2 s; frames 5-8: the run, looped at 0.1 s from 0.35 s, the low box live 0.35-0.9), recovery 0.5 s (frames 9-11: the skid and the stand). The run's body stays on the flip axis (`--centre`); the motion is the guardian's. The Bloom guardian (GRD-07), a tall slender tree-stag standing on two legs: pale wood body, a deer-skull face, branch antlers with pink blossoms, a mossy green mantle, seen from the side facing west, body centred in the frame, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2; the reference is our own 2x still (guardian_bloom_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Bloom Guardian's fight); `keep:` was set after the look. Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_bloom_antler_dash -Name guardian_bloom_antler_dash_r1 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_bloom_antler_dash_r1 guardian_bloom_antler_dash_r1 tools/art/sources/guardians/bloom_palette.png assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_antler_dash.png --write=1 --keep=<keep> --floor=191 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=4`. Round 1 (2026-11-19): kept the crouch (0-2), the backstep (3-4), the head-down run on all fours (5-8, looped), the skid and the stand (9-11); cut with `--centre=120-170` so the run stays on the flip axis.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery
