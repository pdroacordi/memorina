---
id: guardian_frost_perform
command: animate3
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_perform.png
size: 192x128
frames: 8
keep: 0-4,3-1
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/frost_play_f0.png
action: playing the flute deeply: the ice golem plays the ice flute at its mouth deeply with its whole body, swaying its heavy shoulders slowly in time, rising and sinking; its feet stay planted
source: pixellab
---
Deep, full-bodied playing of the flute during the lesson itself ("Dentro da própria lição", user, 2026-10-30), 1.6 s at 0.2 s a frame, a seamless loop (GRD-08); the guardian's `AnimationTree` is ALWAYS for the lesson's freeze. The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, seen from the side facing west, body centred in the frame, feet on art row 127, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2. The flute: "Uma flauta da sua estação" (user, 2026-10-30): each guardian holds a pipe of its season's material, echoing the Memorina's flute (Bloom blossoming wood, Frost ice). The reference is the playing still tools/art/sources/guardians/frost_play_f0.png: frame 8 of the flute raise (`guardian_frost_perform_end`), saved as tools/art/sources/guardians/frost_play_f0.png. The clip is PixelLab animate-with-text-v3 (`tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_frost_perform -Name guardian_frost_perform -Out tools/art/sources/guardians`; returned frames in tools/art/sources/guardians/guardian_frost_perform/), cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_frost_perform guardian_frost_perform tools/art/sources/guardians/frost_still.png tools/art/sources/guardians/guardian_frost_perform_cut.png --scale=1 --floor=127 --centre=43-78 --keep=0-8` and composed by `python -I tools/art/compose_strip.py assets/sprites/characters/guardians/frost_guardian/frost_guardian_perform.png 192 tools/art/sources/guardians/guardian_frost_perform_cut.png@0 tools/art/sources/guardians/guardian_frost_perform_cut.png@1 tools/art/sources/guardians/guardian_frost_perform_cut.png@2 tools/art/sources/guardians/guardian_frost_perform_cut.png@3 tools/art/sources/guardians/guardian_frost_perform_cut.png@4 tools/art/sources/guardians/guardian_frost_perform_cut.png@3 tools/art/sources/guardians/guardian_frost_perform_cut.png@2 tools/art/sources/guardians/guardian_frost_perform_cut.png@1 --lift=3,4,5:1 --ramp=#4ca0f6,#78bef2,#88d5fb,#d0effc`: a ping-pong of returned frames 0-4 (the crystals on its back rise to a peak and settle; returned frame 8 does not close the loop and 5-7 hold the peak), and --lift moves every crystal colour one step up the still's own ice ramp on the peak frames, so the crystals brighten on the beat without a new colour. No pack art was shown to any generator; every reference is our own GRD-07 strip.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, text, ground, scenery
