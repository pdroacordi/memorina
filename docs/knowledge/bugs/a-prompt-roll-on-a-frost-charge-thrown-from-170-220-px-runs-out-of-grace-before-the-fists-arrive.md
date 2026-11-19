---
id: bugs/a-prompt-roll-on-a-frost-charge-thrown-from-170-220-px-runs-out-of-grace-before-the-fists-arrive
type: bug
title: With the roll cue at 220 px, a Frost charge thrown from 170-220 px arms the recall at the strike's start, and a prompt roll's 0.9 s grace ends before the fists reach the rolled-away Ivo
status: resolved
severity: medium
tags: [guardians, frost, recall, roll, charge, grace, grd-14]
related: [bugs/the-frost-charge-recall-opened-as-its-fists-already-touched-ivo, systems/guardians]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - resources/characters/guardians/frost_guardian/recall_roll.tres
  - resources/characters/guardians/frost_guardian/frost_charge.tres
  - scenes/characters/guardians/frost_guardian/frost_guardian.tscn
  - scenes/characters/ivo/player.gd
  - scenes/characters/guardians/guardian.gd
  - resources/characters/guardians/guardian_attack.gd
  - tests/resources/characters/guardians/frost_guardian/frost_charge_recall_test.gd
---

## Summary

GRD-14 raised `recall_roll.trigger_distance` from 110 to 220. A charge thrown from inside 220 px now opens the recall when its strike starts, 0.5 s before the lunge. A roll pressed in the first 0.6-0.9 s real of the 2.0 s window takes Ivo 128 px away, and its 0.9 s grace (strike time) ends before the fist box reaches him. The charge that taught the roll still costs a life note.

## Symptom

Found in the GRD-14 review by computation, not seen in play. Probe: `charge_grace_probe.py` in the review session's scratchpad. It uses the `attack_2` Hitbox keys, a 455 px/s lunge from 0.5 s, the 128 px / 0.37 s roll away and grace 0.9 from the press. It reports the first box entry outside grace, in strike seconds, by throw distance and press time `p` (strike s; p 0.15 is about 0.57 s real into the slow-down):

| thrown from | p 0.05 | p 0.10 | p 0.15 | p 0.20 | p 0.25 |
|---|---|---|---|---|---|
| 150-160 | safe | safe | safe | safe | safe |
| 170 | hit 0.967 | hit 1.017 | safe | safe | safe |
| 190 | hit 1.067 | hit 1.067 | hit 1.067 | safe | safe |
| 210-220 | hit 1.1 | hit 1.1 | hit 1.1 | hit 1.1 | safe |

This distance band is common. During a cooldown the golem holds Ivo between `give_ground_distance` 98 and `comfort_distance * 1.3` (214.5). When the cadence picks the charge, `_select_state` telegraphs it at once from where they stand, because 260 already reaches. With cue 110 no charge armed at the start from beyond 110, so a close throw's box entry came by about 0.8 s, inside any press's grace.

## Root cause

The cue is a distance, and it now also decides when a close throw arms (the strike's start). Arming 0.5 s before the lunge lets the press, and its grace, come up to about 1.1 s before the box can enter a rolled-away Ivo. `Hitbox` hits only on `area_entered` (`continuous` false), so the grace must cover the entry frame. The `attack_2` position keys at 0.917, 1.0 and 1.083 pull the box back and push it forward again, and the forward key makes a new entry at 1.083 s.

## Fix

Fixed in GRD-14 (2026-11-18). The recall is timed by the lunge, not by a distance. `GuardianAttack.recall_lead` (s) and `recall_reach` (px where the box first touches Ivo) give `seconds_to_blow(elapsed, distance)`: the lunge delay left plus the distance past the reach over the lunge speed. `Guardian._open_due_recall()` opens the recall when that falls to the lead, through `Player.begin_recall(..., wait_for_cue = false)`; a recall move without a lead still opens at its strike's start and waits for its cue. The Frost charge: lead 0.25, reach 112, so the fists arrive 0.25 strike s (about 1 s real) after the recall opens from any throw, and a roll pressed from then to the window's end has its 0.9 s grace over every later box entry, the forward key at 1.083 included. `recall_roll.trigger_distance` is back at 110 and no longer read for the charge.

Opening "no earlier than the lunge" (the first option) was tried and is not enough: a charge thrown from 106-150 px touches Ivo within 0.02-0.1 strike s of the lunge's start, too soon to react. The test failed at 110 px.

Test: `frost_charge_recall_test` sweeps throws from 42 to 260 px every 8 px and presses every 0.025 strike s through the window: the fists arrive at least 0.1 strike s after the recall opens, and no box entry lands on a pressed roll outside its grace.

## Prevention

A recall's grace must cover its move's last possible box entry on an Ivo who performed the taught escape from the earliest press. Check it over the full throw range, from `attack_range` down to the contact distance. A `combat_reach_test`-style probe per recall move would pin it.
