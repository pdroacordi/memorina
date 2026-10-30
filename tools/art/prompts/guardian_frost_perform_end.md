---
id: guardian_frost_perform_end
command: animate3
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_perform_end.png
size: 192x128
frames: 4
keep: 8-8,5-5,2-2,0-0
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/frost_restored_f0.png
action: raising the flute: the ice golem slowly lifts a short thick flute of pale blue ice in both hands up to its mouth and holds it there sideways, ready to play; its body stays in place
source: pixellab
---
Lowering the flute after the lesson, 0.8 s at 0.2 s a frame, one-shot (GRD-08); the last frame is frame 0 of `frost_guardian_restored.png`, so the clip settles into `restored`. Generated forwards as the RAISE of the flute from the restored still (its last frame is the playing still `play_song` and `perform` animate from) and kept backwards. The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, seen from the side facing west, body centred in the frame, feet on art row 127, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2. The flute: "Uma flauta da sua estação" (user, 2026-10-30): each guardian holds a pipe of its season's material, echoing the Memorina's flute (Bloom blossoming wood, Frost ice). The raise is PixelLab animate-with-text-v3 from tools/art/sources/guardians/frost_restored_f0.png (frost_guardian_restored.png frame 0, the strip's frame 0 at 1x): `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_frost_perform_end -Name guardian_frost_raise -Out tools/art/sources/guardians`, returned frames in tools/art/sources/guardians/guardian_frost_raise/; cut by `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_frost_raise guardian_frost_raise tools/art/sources/guardians/frost_still.png tools/art/sources/guardians/frost_raise_cut.png --scale=1 --floor=127 --centre=43-78 --keep=0-8`. The sheet runs backwards and is composed by `python -I tools/art/compose_strip.py assets/sprites/characters/guardians/frost_guardian/frost_guardian_perform_end.png 192 tools/art/sources/guardians/frost_play_f0.png tools/art/sources/guardians/frost_raise_cut.png@5 tools/art/sources/guardians/frost_raise_cut.png@2 tools/art/sources/guardians/frost_restored_f0.png`: the playing still, two lowering frames, and frost_guardian_restored.png frame 0 itself, so the clip lands exactly on `restored`. The flute vanishes on that last frame, since `restored` holds none. No pack art was shown to any generator; every reference is our own GRD-07 strip.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, motion lines, music notes, text, ground, scenery
