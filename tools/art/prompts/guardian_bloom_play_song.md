---
id: guardian_bloom_play_song
command: animate3
target: res://assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_play_song.png
size: 128x96
frames: 6
keep: 0-5
generate: 6
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/bloom_play_f0_2x.png
action: playing the flute: the tree-stag keeps the flute at its mouth and plays a short tune, rocking softly forward and back from the hips; antlers, blossoms and mantle unchanged; seen from the side facing left the whole time
source: pixellab
---
Playing the flute briefly, the fight's call, 0.9 s at 0.15 s a frame, a seamless loop (GRD-08): it plays from the call's first note to its end. The Bloom guardian (GRD-07), a tall slender tree-stag standing on two legs: pale wood body, a deer-skull face, branch antlers with pink blossoms, a mossy green mantle, seen from the side facing west, body centred in the frame, feet on art row 95, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2. The flute: "Uma flauta da sua estação" (user, 2026-10-30): each guardian holds a pipe of its season's material, echoing the Memorina's flute (Bloom blossoming wood, Frost ice). The reference is the playing still tools/art/sources/guardians/bloom_play_f0_2x.png: frame 8 of the flute raise (`guardian_bloom_perform_end`), with two blossom pixels painted on the flute (213,120,163; the stag's own pink) by hand, saved as tools/art/sources/guardians/bloom_play_f0.png and doubled, nearest. The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_bloom_play_song -Name guardian_bloom_play_song_r2 -Out tools/art/sources/guardians`; returned frames in tools/art/sources/guardians/guardian_bloom_play_song_r2/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_bloom_play_song_r2 guardian_bloom_play_song_r2 tools/art/sources/guardians/bloom_palette.png tools/art/sources/guardians/guardian_bloom_play_song_r2_cut.png --write=1 --floor=191 --centre=80-140 --drop=45 --keep=0-6` and composed by `python -I tools/art/compose_strip.py assets/sprites/characters/guardians/bloom_guardian/bloom_guardian_play_song.png 128 tools/art/sources/guardians/guardian_bloom_play_song_r2_cut.png@0 tools/art/sources/guardians/guardian_bloom_play_song_r2_cut.png@1 tools/art/sources/guardians/guardian_bloom_play_song_r2_cut.png@2 tools/art/sources/guardians/guardian_bloom_play_song_r2_cut.png@3 tools/art/sources/guardians/guardian_bloom_play_song_r2_cut.png@4 tools/art/sources/guardians/guardian_bloom_play_song_r2_cut.png@5`: returned frames 0-5, a closed loop (frame 6 repeats 0). The first try (tools/art/sources/guardians/guardian_bloom_play_song/, with the action "the tree-stag plays the flute held at its mouth, swaying gently in time with the music") and a second wording (tools/art/sources/guardians/guardian_bloom_play_song_r1/) dropped the antler blossoms on 3 of 6 frames; this action kept them. No pack art was shown to any generator; every reference is our own GRD-07 strip.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, text, ground, scenery
