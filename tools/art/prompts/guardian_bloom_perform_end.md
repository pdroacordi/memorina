---
id: guardian_bloom_perform_end
command: animate3
target: res://assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_perform_end.png
size: 128x96
frames: 4
keep: 8-8,5-5,3-3,0-0
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/bloom_restored_f0_2x.png
action: raising the flute: the tree-stag slowly lifts a slender flute of pale blossoming wood with small pink blossoms on it in both hands up to its mouth and holds it there sideways, ready to play, seen from the side facing left the whole time
source: pixellab
---
Lowering the flute after the lesson, 0.8 s at 0.2 s a frame, one-shot (GRD-08); the last frame is frame 0 of `bloom_guardian_restored.png`, so the clip settles into `restored`. Generated forwards as the RAISE of the flute from the restored still (its last frame is the playing still `play_song` and `perform` animate from) and kept backwards. The Bloom guardian (GRD-07), a tall slender tree-stag standing on two legs: pale wood body, a deer-skull face, branch antlers with pink blossoms, a mossy green mantle, seen from the side facing west, body centred in the frame, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2. The flute: "Uma flauta da sua estação" (user, 2026-10-30): each guardian holds a pipe of its season's material, echoing the Memorina's flute (Bloom blossoming wood, Frost ice). The raise is PixelLab animate-with-text-v3 from tools/art/sources/guardians/bloom_restored_f0_2x.png (bloom_guardian_restored.png frame 0, the strip's frame 0 at 2x (nearest), so PixelLab draws the slender stag at 2x and the cut halves it (systems/art-pipeline, Guardians)): `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_bloom_perform_end -Name guardian_bloom_raise -Out tools/art/sources/guardians`, returned frames in tools/art/sources/guardians/guardian_bloom_raise/; cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_bloom_raise guardian_bloom_raise tools/art/sources/guardians/bloom_palette.png tools/art/sources/guardians/bloom_raise_cut.png --write=1 --floor=191 --centre=80-140 --drop=45 --keep=0-8`. The sheet runs backwards and is composed by `python -I tools/art/compose_strip.py assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_perform_end.png 128 tools/art/sources/guardians/bloom_play_f0.png tools/art/sources/guardians/bloom_raise_cut.png@5 tools/art/sources/guardians/bloom_raise_cut.png@3 tools/art/sources/guardians/bloom_restored_f0.png`: the playing still, two lowering frames, and bloom_guardian_restored.png frame 0 itself, so the clip lands exactly on `restored`. The flute vanishes on that last frame, since `restored` holds none. No pack art was shown to any generator; every reference is our own GRD-07 strip.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, text, ground, scenery
