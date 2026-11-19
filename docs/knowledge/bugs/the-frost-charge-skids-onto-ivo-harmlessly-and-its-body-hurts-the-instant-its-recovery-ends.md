---
id: bugs/the-frost-charge-skids-onto-ivo-harmlessly-and-its-body-hurts-the-instant-its-recovery-ends
type: bug
title: After a Frost charge, the golem's recovery skid carries its body onto a rolled or wall-pinned Ivo while it is harmless, and its contact hurts him one frame after the recovery ends
status: resolved
severity: medium
tags: [guardians, frost, grd-14, charge, contact, recall, roll, wall, fairness, playtest]
related: [playtests/2026-11-18-grd14-frost-feel, bugs/the-frost-charge-back-after-a-far-charge-hits-ivo-as-he-lands-from-jumping-it, systems/guardians]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/characters/guardians/guardian.gd
  - resources/characters/guardians/frost_guardian/frost_charge.tres
---

## Summary

The charge has `body_contact` false, so the golem's body is harmless through its strike and its 0.6 s recovery. The
recovery is a skid: about 90 px at up to 437 px/s. `Guardian.body_hurts()` turns true again on the first idle frame,
wherever Ivo is. Two cases end with the golem standing on him:
- an Ivo who rolled in the charge's direction (the teaching charge included);
- an Ivo against a wall who jumped the fists.

He is then hit 17 ms after the recovery ends, with no attack and no warning. The design says "a pressed roll is never
hit by that charge" (GRD-14 task) and "jump the fists, then walk out of the body before the recovery"
(`systems/guardians`, pinned at a wall).

## Symptom

- **Teaching charge, passive run** (`PL_PASSIVE=1`, the driver presses the recall at once):
  - The charge is thrown from 194 px. The recall opens at 8.600 and the roll is pressed at 8.600.
  - Ivo rolls away, 4967 -> 4805. The recovery starts at 9.355 with dx 50.4 and gvx -437.9.
  - The idle starts at 9.955 with dx -39.7: the golem has skidded onto him.
  - He is hit at 9.972 (`atk=` empty, `hb=false`): his last note, so he dies.
- **Pinned at the west wall** (`pinw`, wall face x 4512, Ivo at 4523):
  - 8 hits, all `atk=` empty, dx 23.1, 0.017 s after `PRESSURE|||` (idle) begins, e.g. t 16.848.
  - The charge stopped 23 px from Ivo. He had jumped its fists at strike s 0.54-0.56, so he landed at about the end of
    the recovery.
  - In `pinw2`/`pinsweep` the driver jumps at strike s 0.15-0.17 and walks through the body during the recovery: 0
    contact hits in 13 charges. The dodge exists, but only with an early jump and a walk through the golem.
- **Roll owned** (`rollroll`, `PL_CHARGE=roll`): 2 contact hits in 3 stage-0 charges (t 11.411, 34.266), after two rolls
  in the charge's direction.

## Root cause

- `guardian.gd` `body_hurts()` returns `_ai.current_attack == null or current_attack.body_contact`. The charge's
  recovery still has the charge as `current_attack`, so the body is harmless during the skid.
- On the first idle frame the body hurts, even if the skid has just carried it over Ivo.
- Ivo and the golem do not collide (Ivo masks layers 1, 2, 4 and 5; the golem is on 17), so nothing pushes him out.

## Fix

Fixed in GRD-14 (2026-11-18), two rules in `GuardianBodyContact` (pure) used by `Guardian`:
- **The skid stops short of Ivo.** In a recovery, a skid heading at Ivo stops once the two bodies are within
  `overhead_band` (half of both widths, 45 px for Frost) plus 4 px (`skid_stops`).
- **A body a no-contact move carried onto Ivo spares him.** When a string with a `body_contact` false move ends (after its
  recovery), the contact box stays off while Ivo is still inside the golem's body, for at most `GRACE` (0.6 s, the time
  to walk out of a 68 px body). It ends the moment he is out; walking back in hurts.
- The wall-pinned case (the charge running into the wall over a jumping Ivo) is covered by the second rule: he lands
  inside the body and walks out unhurt.
Tests: `guardian_body_contact_test`, `guardian_contact_test.test_a_body_carried_onto_ivo_spares_him_until_he_is_out_of_it`.

## Prevention

Add a test: after any `body_contact` false move, an Ivo who stood still, or rolled in either direction, and whose body
the golem's skid overlaps is not hurt on the first idle frame.
