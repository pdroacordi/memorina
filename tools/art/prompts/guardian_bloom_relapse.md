---
id: guardian_bloom_relapse
command: animate3
target: res://assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_relapse.png
size: 128x96
frames: 5
keep: 1-1,4-5,7-7,8-8
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/bloom_lucid_f0_2x.png
action: falling back into madness: the tree-stag shudders violently, clutches itself and hunches over, falling back into a dazed, twitching stance, seen from the side facing left the whole time
source: pixellab
---
Falling back into madness, 0.75 s at 0.15 s a frame, one-shot (GRD-08; must stay under `relapse_time * FAILED_RELAPSE_SCALE`, 0.84 s): a shudder, hunching; the last frame is frame 0 of `bloom_guardian_idle.png`, so the clip settles into `idle` without a jump. The Bloom guardian (GRD-07), a tall slender tree-stag standing on two legs: pale wood body, a deer-skull face, branch antlers with pink blossoms, a mossy green mantle, seen from the side facing west, body centred in the frame, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2. The reference is tools/art/sources/guardians/bloom_lucid_f0_2x.png (bloom_guardian_lucid.png frame 0, the strip's frame 0 at 2x (nearest), so PixelLab draws the slender stag at 2x and the cut halves it (systems/art-pipeline, Guardians)). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_bloom_relapse -Name guardian_bloom_relapse -Out tools/art/sources/guardians`; returned frames in tools/art/sources/guardians/guardian_bloom_relapse/), cut whole by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_bloom_relapse guardian_bloom_relapse tools/art/sources/guardians/bloom_palette.png tools/art/sources/guardians/guardian_bloom_relapse_cut.png --write=1 --floor=191 --centre=80-140 --drop=45 --keep=0-8` and composed by `python -I tools/art/compose_strip.py assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_relapse.png 128 tools/art/sources/guardians/guardian_bloom_relapse_cut.png@1 tools/art/sources/guardians/guardian_bloom_relapse_cut.png@4 tools/art/sources/guardians/guardian_bloom_relapse_cut.png@5 tools/art/sources/guardians/guardian_bloom_relapse_cut.png@7 tools/art/sources/guardians/bloom_idle_f0.png`: the shudder, the hunch, half up, then bloom_guardian_idle.png frame 0 itself. `keep` names the returned frames; its last is replaced by that continuity frame. No pack art was shown to any generator; every reference is our own GRD-07 strip.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, text, ground, scenery
