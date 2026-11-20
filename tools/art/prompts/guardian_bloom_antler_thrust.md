---
id: guardian_bloom_antler_thrust
command: animate3
target: res://assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_antler_thrust.png
size: 128x96
frames: 9
keep: 1-3,6-8,9-10,0-0
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/bloom_ref_2x.png
action: antler thrust: the tree-stag lowers its head, then lunges a short step forward driving its branch antlers straight ahead at chest height, then lifts its head back up and stands, side view facing left the whole time
source: pixellab
---
The antler thrust (`bloom_antler_thrust.tres`, link after the back-lash): wind-up 0.2 s (frames 0-1: the head drops), strike 0.4 s with the box live 0.1-0.3 and a 32 px step (frames 2-5), recovery 0.45 s (frames 6-8). Its head-down pose must differ from the antler dash's crouch. The Bloom guardian (GRD-07), a tall slender tree-stag standing on two legs: pale wood body, a deer-skull face, branch antlers with pink blossoms, a mossy green mantle, seen from the side facing west, body centred in the frame, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2; the reference is our own 2x still (guardian_bloom_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Bloom Guardian's fight); `keep:` was set after the look. Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_bloom_antler_thrust -Name guardian_bloom_antler_thrust_r1 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_bloom_antler_thrust_r1 guardian_bloom_antler_thrust_r1 tools/art/sources/guardians/bloom_palette.png assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_antler_thrust.png --write=1 --keep=<keep> --floor=191 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=4`. Round 1 (2026-11-19): kept the head drop (0-1), the antlers lowered (2), the lunge (3-5), the rise (6-8); `--drop` cleared PixelLab's white sparks.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery
