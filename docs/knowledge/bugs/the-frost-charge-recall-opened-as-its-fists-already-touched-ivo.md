---
id: bugs/the-frost-charge-recall-opened-as-its-fists-already-touched-ivo
type: bug
title: The Frost charge's roll recall opened on the frame its fists already touched Ivo, so a charge thrown from afar hit before he could press
status: resolved
severity: medium
tags: [guardians, frost, recall, roll, charge, grd-14]
related: [systems/guardians, bugs/recall-move-range-exceeds-hitbox-reach]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - resources/characters/guardians/frost_guardian/recall_roll.tres
  - resources/characters/guardians/frost_guardian/frost_charge.tres
  - scenes/characters/ivo/player.gd
---

## Symptom

GRD-14 dodging run (`guardian_fight_player_driver.gd`, `PL_GOD=1`, Frost). The charge was thrown from 116.7 px. `recall_started` came at 8.105 s with the charge box already open at 109 px, and Ivo was hit at 8.155 s, before the driver's first press. The press at 8.238 s still taught the roll, so the recall's guarantee held, but the hit cost a life note the recall was meant to spare.

## Root cause

`AbilityRecallStats.trigger_distance` (110) waits for the body throwing the move to come that close, centre to centre (`Player` checks `global_position.distance_to`). The charge's fist box (x 56..104 from the golem's centre, GRD-07) touches Ivo's hurtbox (half width 8) out to 112 px. A charge thrown from beyond 112 opened its box at 0.5 s and touched Ivo on the frame the lunge crossed 110: the cue and the hit were the same frame. Before GRD-14 the same held for any charge thrown from 112..300 px; the bot fights threw it from about 63 px, inside the cue, so the recall armed at the strike's start.

## Fix

First `recall_roll.trigger_distance` 110 -> 220. The GRD-14 review found that this armed close throws 0.5 s before the lunge, so a prompt roll's grace ran out before the fists arrived (`bugs/a-prompt-roll-on-a-frost-charge-thrown-from-170-220-px-runs-out-of-grace-before-the-fists-arrive`). Final fix: the charge's recall is timed by its lunge (`GuardianAttack.recall_lead` 0.25 s before the fists reach 112 px), and `trigger_distance` is back at 110, unread for the charge.

## Rule

A recall on a lunge opens a set time before the box reaches Ivo, long enough to react and short enough that a press's grace covers every later entry; a distance cue cannot be both for every throw distance.
