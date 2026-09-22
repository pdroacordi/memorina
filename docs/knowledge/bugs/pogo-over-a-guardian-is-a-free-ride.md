---
id: bugs/pogo-over-a-guardian-is-a-free-ride
type: bug
title: Pogoing on a guardian was endless - it could not swing upward and shuffled left and right under the player's feet
status: fixed
severity: high
tags: [guardians, ai, pogo, qte, recall, exploit]
related: [architecture/guardian-fight-phase-machine, bugs/recall-move-range-exceeds-hitbox-reach]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/characters/guardians/guardian_ai.gd
  - resources/characters/guardians/guardian_attack.gd
  - resources/characters/guardians/bloom_guardian/bloom_burst.tres
---

## Summary

The air attack's pogo bounce (`PogoComponent`) refreshes on every hit, and a guardian's
hurtbox accepts one every `invulnerability_time` (0.2 s), so a player parked above a
guardian could bounce for ever. Two AI bugs made it completely safe and completely
stuck: `_in_range` measured a RADIUS (`distance_to`), so a player 100 px overhead was
never in range of any move - including the one carrying the recall, which the fight was
waiting on - and `_approach_tick` took `signf(player.x - body.x)` every frame, which
flips sign every frame when that difference sits on zero.

## Symptom

User, round 7: "POGO nos bosses. No momento eu posso infinitamente no POGO, pq nao
dispara o QTE e o boss nao sai de baixo (ele buga ali trocando de direcao
infinitamente)." Measured before the fix: the guardian's facing flipped on most physics
frames; hits saturated at the threshold, `request_recall()` was honoured, and the recall
move still never fired because it could not reach.

## Root cause

- `GuardianAI._in_range`: `_body.global_position.distance_to(player)` - a circle. An
  overhead player is outside every guardian's circle but inside nothing it can answer.
- `GuardianAI._approach_tick`: `signf(dx)` with no dead band, and `Guardian` faced
  `_ai.direction`, so the flip-flop was visible as well as pointless.

## Fix

- A move now reaches inside a BOX: `attack_range` horizontally, new
  `GuardianAttack.attack_height` (default 96) vertically.
- `TURN_BAND` (10 px) dead band on both the chase and the facing; `Guardian` faces
  `GuardianAI.facing_intent()` - where it walks, or where the player is when it stands
  still - so a guardian that has backed away keeps watching.
- A player overhead and out of the move's box is answered, not chased: the guardian
  walks out from under for `STEP_OUT_TIME` and then stands off (`_step_out`).
- The Bloom burst is given `attack_height = 160`: it is a harmless launcher whose recall
  wants Ivo airborne, so pogoing the flower now triggers the double-jump QTE instead of
  being free. Frost's moves stay low, and that guardian steps out instead.

Measured after the fix: Bloom opens the recall 1.9 s into a pogo chain with one facing
flip; Frost steps out 213 px, holds, and charges 0.7 s after the player lands.

## Prevention

Two rules worth carrying: reach is a box, not a radius, whenever a character's moves are
authored in a side view; and any AI that takes `sign()` of a distance needs a dead band,
because the one place the player WILL stand is exactly on top of it.
