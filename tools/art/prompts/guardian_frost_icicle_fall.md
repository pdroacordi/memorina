---
id: guardian_frost_icicle_fall
command: animate3
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_icicle_fall.png
size: 192x128
frames: 11
keep: 0-10
generate: 12
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/frost_ref.png
action: ceiling punches: the ice golem plants its feet, raises both huge stone fists straight above its head and punches upward at the ceiling three times, arms fully stretched up on each punch, then lowers its arms to its sides, side view facing left the whole time
source: pixellab
---
The icicle fall (`frost_icicle_fall.tres`, no strike box; stage 1): wind-up 0.55 s (frames 0-2: the arms rise), strike 1.1 s (frames 3-8: a punch up at each shot, 0.15, 0.55 and 0.95 s), recovery 0.6 s (frames 9-10). Its pose must differ from the slam's raised fists, which say jump in place; this one says keep moving. The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, seen from the side facing west, body centred in the frame, feet on art row 127, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2; the reference is our own still padded to the frame (guardian_frost_attack_1 says how it was made). GRD-18: timings from docs/knowledge/systems/guardians.md, The Frost Guardian's fight; `keep:` was set after the look. Round 1 (2026-11-20): the arms rise (gen 0-2), then the fists thrust up, highest on gen 4, 9 and 10, which the clip shows at the shots. Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_frost_icicle_fall -Name guardian_frost_icicle_fall_r1 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_frost_icicle_fall_r1 guardian_frost_icicle_fall_r1 tools/art/sources/guardians/frost_still.png assets/sprites/characters/guardians/frost_guardian/frost_guardian_icicle_fall.png --scale=1 --keep=<keep> --floor=127 --drop=45`, then `python -I tools/art/despeckle.py <target> 192`.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, ice bursts, motion lines, text, ground, scenery
