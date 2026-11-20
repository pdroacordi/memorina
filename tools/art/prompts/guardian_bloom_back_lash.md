---
id: guardian_bloom_back_lash
command: animate3
target: res://assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_back_lash.png
size: 128x96
frames: 8
keep: 1-2,4-4,6-8,9-9,0-0
generate: 10
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/bloom_ref_2x.png
action: backhand whip: the tree-stag swings its long arm back across its chest, then lashes it out low and forward the other way like a backhand whip, the arm stretched out at knee height, then draws it back to its side, side view facing left the whole time
source: pixellab
---
The back-lash (`bloom_back_lash.tres`, link after the lash): wind-up 0.25 s (frames 0-1: the arm across the chest), strike 0.4 s at 0.1 s a frame with the low box live 0.1-0.3 (frames 2-5), recovery 0.35 s (frames 6-7). It must not read as idle (the GRD-13 playtest). The Bloom guardian (GRD-07), a tall slender tree-stag standing on two legs: pale wood body, a deer-skull face, branch antlers with pink blossoms, a mossy green mantle, seen from the side facing west, body centred in the frame, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2; the reference is our own 2x still (guardian_bloom_attack_1 says how it was made). One strip holds the move's wind-up, strike and recovery (GRD-18; timings from docs/knowledge/systems/guardians.md, The Bloom Guardian's fight); `keep:` was set after the look. Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_bloom_back_lash -Name guardian_bloom_back_lash_r1 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_bloom_back_lash_r1 guardian_bloom_back_lash_r1 tools/art/sources/guardians/bloom_palette.png assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_back_lash.png --write=1 --keep=<keep> --floor=191 --drop=45`, then `python -I tools/art/despeckle.py <target> 128 --min=4`. Round 1 (2026-11-19): PixelLab drew the vine white, which `--drop` clears, so the frames were first copied to the scratchpad with every pixel paler than 215 recoloured to the palette's second-darkest brown (70,42,35), then cut from there. Kept: arm back with the vine trailing (0-1), the swing (2), the vine out at waist height (3-4, the hit), the snap back (5), the stand (6-7). The generation drew the vine at 60-74 px, over Ivo's 50 px hurtbox, and no frame drew it lower and long, so the two hit frames were bent down from the hand to his chest (tip 36-38 px up, 84-86 px out; GRD-18 re-fit, 2026-11-19): `python -I tools/art/bend_strike.py <target> 128 3 18 0 droop 0.75`, then `python -I tools/art/bend_strike.py <target> 128 4 18 0 droop 0.5`, after the despeckle.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, text, ground, scenery
