---
id: guardian_frost_charge_skid
command: animate3
target: res://assets/sprites/characters/guardians/frost_guardian/frost_guardian_charge_skid.png
size: 192x128
frames: 4
keep: 0-3
generate: 8
view: side
direction: west
no_background: true
reference: res://tools/art/sources/guardians/frost_ref.png
action: skid: the ice golem, running forward fast, digs its heels into the ground and skids to a hard stop leaning back, sliding, arms thrown back for balance, then straightens up, side view facing left the whole time
source: pixellab
---
The charge-back's wind-up (`frost_charge_back.tres`, link after the charge; stage 1): 0.5 s, the body held still while the golem skids and turns (frames 0-3). The guardian turns to Ivo as the wind-up begins (`GuardianAI.facing_intent`), so the strip is stored mirrored: on screen the golem still faces its slide while it digs in, and the turn reads as the charge-back starts. The Frost guardian (GRD-07), a heavy ice golem: dark blue-grey stone body, pale blue ice crystals on its shoulders and back, huge stone fists, seen from the side facing west, body centred in the frame, feet on art row 127, the frame's bottom row. Sheets are 1 px per art px, shown at Sprite2D scale 2; the reference is our own still padded to the frame (guardian_frost_attack_1 says how it was made). GRD-18: timings from docs/knowledge/systems/guardians.md, The Frost Guardian's fight; `keep:` was set after the look. Round 1 (2026-11-20): kept the brace with the arms thrown out (gen 1-4); from gen 5 PixelLab drew a sliding dive with ice bursts in the body's colours. Flecks at the feet were cleared by removing 4-connected pieces under 30 px, then each frame was mirrored. Generate: `tools/pixellab/pixellab.ps1 animate3 -Prompt guardian_frost_charge_skid -Name guardian_frost_charge_skid_r1 -Out tools/art/sources/guardians`; cut: `python -I tools/art/cut_inhabitant.py tools/art/sources/guardians/guardian_frost_charge_skid_r1 guardian_frost_charge_skid_r1 tools/art/sources/guardians/frost_still.png assets/sprites/characters/guardians/frost_guardian/frost_guardian_charge_skid.png --scale=1 --keep=<keep> --floor=127 --drop=45`, then `python -I tools/art/despeckle.py <target> 192`.
Negative: outlines, black contour, front view, facing right, turning around, glow, flash, sparks, particles, ice bursts, motion lines, text, ground, scenery
