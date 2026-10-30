---
id: guardian_frost_play_song
command: animate3
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_play_song.png
size: 192x128
frames: 6
keep: 0-5
generate: 6
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/frost_play_f0.png
action: playing the flute: the ice golem plays the flute held at its mouth, swaying gently in time with the music; its body stays in place
source: pixellab
---
Playing the flute briefly, the fight's call, 0.9 s at 0.15 s a frame, a seamless loop (GRD-08): it plays from the call's first note to its end. The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, seen from the side facing west, body centred in the frame, feet on art row 127, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2. The flute: "Uma flauta da sua estação" (user, 2026-10-30): each guardian holds a pipe of its season's material, echoing the Memorina's flute (Bloom blossoming wood, Frost ice). The reference is the playing still tools/art/sources/guardians/frost_play_f0.png: frame 8 of the flute raise (`guardian_frost_perform_end`), saved as tools/art/sources/guardians/frost_play_f0.png. The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_frost_play_song -Name guardian_frost_play_song -Out tools/art/sources/guardians`; returned frames in tools/art/sources/guardians/guardian_frost_play_song/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_frost_play_song guardian_frost_play_song tools/art/sources/guardians/frost_still.png tools/art/sources/guardians/guardian_frost_play_song_cut.png --scale=1 --floor=127 --centre=43-78 --keep=0-6` and composed by `python -I tools/art/compose_strip.py assets/sprites/characters/guardians/frost_guardian/frost_guardian_play_song.png 192 tools/art/sources/guardians/guardian_frost_play_song_cut.png@0 tools/art/sources/guardians/guardian_frost_play_song_cut.png@1 tools/art/sources/guardians/guardian_frost_play_song_cut.png@2 tools/art/sources/guardians/guardian_frost_play_song_cut.png@3 tools/art/sources/guardians/guardian_frost_play_song_cut.png@4 tools/art/sources/guardians/guardian_frost_play_song_cut.png@5`: returned frames 0-5, a closed loop (frame 6 repeats 0). No pack art was shown to any generator; every reference is our own GRD-07 strip.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, text, ground, scenery
