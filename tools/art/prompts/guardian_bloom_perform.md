---
id: guardian_bloom_perform
command: animate3
target: res://assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_perform.png
size: 128x96
frames: 8
keep: 0-7
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/bloom_play_f0_2x.png
action: playing the flute deeply: the tree-stag plays the wooden flute at its mouth deeply with its whole body, leaning into the music, rising and bowing in time, the pink blossoms on its antlers opening wider, seen from the side facing left the whole time
source: pixellab
---
Deep, full-bodied playing of the flute during the lesson itself ("Dentro da própria lição", user, 2026-10-30), 1.6 s at 0.2 s a frame, a seamless loop (GRD-08); the guardian's `AnimationTree` is ALWAYS for the lesson's freeze. The Bloom guardian (GRD-07), a tall slender tree-stag standing on two legs: pale wood body, a deer-skull face, branch antlers with pink blossoms, a mossy green mantle, seen from the side facing west, body centred in the frame, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2. The flute: "Uma flauta da sua estação" (user, 2026-10-30): each guardian holds a pipe of its season's material, echoing the Memorina's flute (Bloom blossoming wood, Frost ice). The reference is the playing still tools/art/sources/guardians/bloom_play_f0_2x.png: frame 8 of the flute raise (`guardian_bloom_perform_end`), with two blossom pixels painted on the flute (213,120,163; the stag's own pink) by hand, saved as tools/art/sources/guardians/bloom_play_f0.png and doubled, nearest. The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_bloom_perform -Name guardian_bloom_perform -Out tools/art/sources/guardians`; returned frames in tools/art/sources/guardians/guardian_bloom_perform/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_bloom_perform guardian_bloom_perform tools/art/sources/guardians/bloom_palette.png tools/art/sources/guardians/guardian_bloom_perform_cut.png --write=1 --floor=191 --centre=80-140 --drop=45 --keep=0-8` and composed by `python -I tools/art/compose_strip.py assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_perform.png 128 tools/art/sources/guardians/guardian_bloom_perform_cut.png@0 tools/art/sources/guardians/guardian_bloom_perform_cut.png@1 tools/art/sources/guardians/guardian_bloom_perform_cut.png@2 tools/art/sources/guardians/guardian_bloom_perform_cut.png@3 tools/art/sources/guardians/guardian_bloom_perform_cut.png@4 tools/art/sources/guardians/guardian_bloom_perform_cut.png@5 tools/art/sources/guardians/guardian_bloom_perform_cut.png@6 tools/art/sources/guardians/guardian_bloom_perform_cut.png@7 --grow=3,4,5:#d578a3 --grow-above=52`: returned frames 0-7, a closed loop; it leans back with the flute raised on 3-5, where --grow spreads each antler blossom pixel one px left, right and up (above game row 52, so the mantle's flowers stay), so the blossoms open on the beat. No pack art was shown to any generator; every reference is our own GRD-07 strip.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, text, ground, scenery
