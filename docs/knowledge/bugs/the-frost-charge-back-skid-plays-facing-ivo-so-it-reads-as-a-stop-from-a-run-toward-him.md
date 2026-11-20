---
id: bugs/the-frost-charge-back-skid-plays-facing-ivo-so-it-reads-as-a-stop-from-a-run-toward-him
type: bug
title: The Frost charge-back's drawn skid plays already turned toward Ivo, so it reads as braking from a run at him
status: fixed
severity: low
tags: [grd-18, guardians, frost, animation, facing, charge-back]
related: [systems/guardians, bugs/the-frost-charge-back-after-a-far-charge-hits-ivo-as-he-lands-from-jumping-it]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/guardian_ai.gd
  - scenes/characters/guardians/frost_guardian/frost_guardian.tscn
  - tools/art/prompts/guardian_frost_charge_skid.md
---

## Symptom

Found in the GRD-18 Frost review (2026-11-20) by reading the code. Not seen in a run.
`windup_7` now plays `frost_guardian_charge_skid.png`: the golem digs in its heels, leans back
and throws its arms back, drawn facing its slide. The charge carried it past Ivo, so its slide
points away from him. The sprite turns toward Ivo on the wind-up's first frame. The skid then
plays facing Ivo, which is the opposite way to the slide. The wind-up also zeroes the body's x
speed, so the golem looks like it is braking from a run toward Ivo that it never made. The
contract asks for the opposite order: "The turn itself is the sprite's flip at the end; today it
flips on the first frame."

## Root cause

During a telegraph, `GuardianAI.facing_intent()` (`guardian_ai.gd:149-154`) returns
`_look_direction`, the side Ivo is on. It returns 0 only in a swing, in a recovery or in a
`turns_from_wall` wind-up. `Guardian._process_motion` (`guardian.gd:207-208`) applies that
facing on every attacking frame. So the flip happens as the charge-back's telegraph begins,
before any frame of the skid has played.

## Fix

Applied 2026-11-20: the skid strip is stored mirrored (each 192 px frame flipped), so with the guardian already turned to Ivo the golem on screen still faces its slide while it digs in; the turn reads as the charge-back starts. Data only; `facing_intent` is unchanged. Recorded in `tools/art/prompts/guardian_frost_charge_skid.md`.

## Options considered

Hold the facing through this wind-up and turn on its last frame. One option is a
`GuardianAttack` flag, for example "turns at the wind-up's end", that makes `facing_intent()`
return 0 until the telegraph's last 0.1 s. The other is to redraw the skid as seen from the
side it turns to. Either way, record the user's choice in `systems/guardians`.

## Prevention

When a wind-up's art shows a turn or a stop, check which way the guardian faces on that
wind-up's first frame (`facing_intent` during TELEGRAPH), not only the frame timings.
