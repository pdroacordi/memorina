---
id: bugs/a-roll-through-the-sun-charge-always-skips-its-stage-1-return
type: bug
title: An Ivo who rolls through the Sun Guardian's charge ends 280-380 px from it, past the return's 208 px range, so no stage-1 charge returns for a Lake-kit player
status: fixed
severity: medium
tags: [guardians, summer, sun, charge, return, roll, follow-up, grd-16]
related: [systems/guardians, playtests/2026-11-19-grd16-sun-feel, playtests/2026-11-19-grd16-sun-fight]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - resources/characters/guardians/summer_guardian/summer_charge.tres
  - resources/characters/guardians/summer_guardian/summer_charge_back.tres
  - scenes/characters/guardians/guardian_ai.gd
  - tests/resources/characters/guardians/summer_guardian/summer_guardian_kit_test.gd
---

## Summary

User, 2026-11-19: "Turn after passing Ivo (Recommended)". From stage 1, every Sun charge should turn and come back. The
return is a `GuardianFollowUp` that is taken only while Ivo is in its range (`GuardianAI._in_range`, 208 px). Rolling
through the charge, the Lake kit's answer, carries Ivo about 165 px one way while the lion runs about 267 px the other.
The charge then ends 278-381 px from Ivo, and the return is never thrown.

## Symptom

GRD-16 feel playtest, 2026-11-19 (`playtests/2026-11-19-grd16-sun-feel`). Runs `l1` and `l2` used the dodging driver
with the Lake kit (`"skills": [2]`), rolling through every charge toward the lion. Median frame time was 5-6 ms.

- Stage-1 charges returned 0 of 8. The `[st]` line at the charge's recovery shows the gap:

  | t | gap at recovery |
  |---|---|
  | 67.2 | 317 px |
  | 77.3 | -356 px |
  | 84.8 | 381 px |
  | 94.1 | -278 px |

  At 77.3 the lion's centre was 130 px off the left edge of the view (`gsx=-130`).
- In the same session, Orchard-kit runs (`o1`, `o2`), which jump the charge in place, got the return after 4 of 4 stage-1
  charges. The implementer's runs got it after 9 of 9.

## Root cause

`test_the_charge_ends_within_reach_of_its_return` assumes Ivo is still where the charge was aimed: the run ends at most
193 px past that spot, inside 208. A roll moves Ivo 128 px plus the recovery slide (about 165 px), toward the lion and
through it, so the two distances add. A jump carried away from the charge would add distance the same way (not measured).
The follow-up is checked in range when the strike ends (`GuardianRepertoire.next_link(..., _in_range,
...)`), so it is skipped and the string ends.

## Fix

Fixed 2026-11-19 (GRD-16 feel round): the charge stops 80 px beyond Ivo's live x (`GuardianAttack.lunge_past`,
`GuardianMover._ran_past_ivo`), so it ends within its return's 208 px whether he jumped it in place or rolled through it
toward the lion, and the return's wind-up stays on screen.

Tests: `summer_guardian_kit_test.test_the_charge_ends_within_reach_of_its_return_for_both_kits` (a jumped and a rolled
Ivo, the roll from `ivo_roll_stats.tres` pressed 0.12 s before the box arrives, every 8 px of throw),
`guardian_contact_test.test_a_lunge_stops_its_past_beyond_ivo`. In play: the return followed every stage-1 charge in the re-measure, 15 of 15 with the Lake kit rolling through (`lg1`, `ln1`, `lg2`, `ln2`) and 11 of 11 with the Orchard kit jumping (`og1`, `on1`, `og2`, `on2`), at 6 ms a frame.

## Prevention

A follow-up's range test should be run against each kit's dodge of the first move (stay, jump away, roll through), not
only against an Ivo standing where the move was aimed.
