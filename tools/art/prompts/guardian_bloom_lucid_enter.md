---
id: guardian_bloom_lucid_enter
command: animate3
target: res://assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_lucid_enter.png
size: 128x96
frames: 4
keep: 1-1,3-3,7-7,8-8
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/bloom_idle_f0_2x.png
action: coming to its senses: the tree-stag shakes its head hard as if shaking off a daze, shudders once, then straightens up tall and stands still, calm, seen from the side facing left the whole time
source: pixellab
---
The madness leaving, 0.6 s at 0.15 s a frame, one-shot (GRD-08, `architecture/guardian-performance-and-talks`; must stay under `lucidity_delay - leap_crouch`): shaking off, straightening; the last frame is frame 0 of `bloom_guardian_lucid.png`, so the clip settles into `lucid` without a jump. The Bloom guardian (GRD-07), a tall slender tree-stag standing on two legs: pale wood body, a deer-skull face, branch antlers with pink blossoms, a mossy green mantle, seen from the side facing west, body centred in the frame, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2. The reference is tools/art/sources/guardians/bloom_idle_f0_2x.png (bloom_guardian_idle.png frame 0, the strip's frame 0 at 2x (nearest), so PixelLab draws the slender stag at 2x and the cut halves it (systems/art-pipeline, Guardians)). The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_bloom_lucid_enter -Name guardian_bloom_lucid_enter -Out tools/art/sources/guardians`; returned frames in tools/art/sources/guardians/guardian_bloom_lucid_enter/), cut whole by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_bloom_lucid_enter guardian_bloom_lucid_enter tools/art/sources/guardians/bloom_palette.png tools/art/sources/guardians/guardian_bloom_lucid_enter_cut.png --write=1 --floor=191 --centre=80-140 --drop=45 --keep=0-8` and composed by `python -I tools/art/compose_strip.py assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_lucid_enter.png 128 tools/art/sources/guardians/guardian_bloom_lucid_enter_cut.png@1 tools/art/sources/guardians/guardian_bloom_lucid_enter_cut.png@3 tools/art/sources/guardians/guardian_bloom_lucid_enter_cut.png@7 tools/art/sources/guardians/bloom_lucid_f0.png`: the head thrown back, straightening, upright, then bloom_guardian_lucid.png frame 0 itself. `keep` names the returned frames; its last is replaced by that continuity frame. No pack art was shown to any generator; every reference is our own GRD-07 strip.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, text, ground, scenery
