---
id: guardian_frost_body_drop
command: animate3
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_body_drop.png
size: 192x128
frames: 10
keep: 0-9
generate: 12
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/frost_ref.png
action: body slam: the ice golem crouches low on bent knees, leaps up with its knees tucked and fists raised, then crashes down onto both feet in a deep heavy squat with both fists hitting the ground, then stands back up, side view facing left the whole time
source: pixellab
---
The body drop (`frost_body_drop.tres`; stage 2): wind-up 0.6 s (frames 0-1: the crouch), strike 1.0 s (frames 2-6: launch and the tucked flight while `LeapMotion` carries it 0.1-0.85 s, then the crash at 0.85, the box live 0.85-1.0), recovery 0.8 s (frames 7-9: the squat and the rise). Feet on the floor row on every frame: the arc is the guardian's own motion. The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, seen from the side facing west, body centred in the frame, feet on art row 127, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2; the reference is our own still padded to the frame (guardian_frost_attack_1 says how it was made). GRD-18: timings from docs/knowledge/systems/guardians.md, The Frost Guardian's fight; `keep:` was set after the look. Round 1 (2026-11-20): kept the crouch (gen 1-2), launch (3), tucked flight (4-5), the lunge down (6), the squat with the fists on the ground (7, 9) and the rise (12, 0). Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_frost_body_drop -Name guardian_frost_body_drop_r1 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_frost_body_drop_r1 guardian_frost_body_drop_r1 tools/art/sources/guardians/frost_still.png assets/sprites/characters/guardians/frost_guardian/frost_guardian_body_drop.png --scale=1 --keep=<keep> --floor=127 --drop=45`, then `python -I tools/art/despeckle.py <target> 192`.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, ice bursts, motion lines, text, ground, scenery
