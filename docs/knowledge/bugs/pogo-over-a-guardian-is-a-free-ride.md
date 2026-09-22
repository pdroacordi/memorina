---
id: bugs/pogo-over-a-guardian-is-a-free-ride
type: bug
title: Pogoing on a guardian was endless - it could not reach upward and shuffled left and right under the player's feet
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
- The guardian ANSWERS the situation rather than the QTE doing it for them (the first
  attempt let the Bloom burst reach 160 px up so a pogo triggered the double-jump recall;
  the user's correction was that the boss should be smart enough to leave, not that the
  QTE should rescue it). A player overhead is lunged out from under at `step_out_speed`,
  and the landing is punished: the cooldown is zeroed the frame they stop being overhead.
- While a cooldown runs the guardian holds spacing (`GuardianStats.comfort_distance`)
  instead of standing there: gives ground to a player who closes in, drifts back toward
  one who backs off, paces when neither.
- Every one of those decisions is held with HYSTERESIS. The first spacing pass re-decided
  from the raw distance each frame and the guardian turned 47 times in 10 s standing next
  to a stationary player - the same bug as the `sign()` flip, one level up.

Measured after the fix (throwaway harness, both guardians): standing fight - moving 63-68%
of frames, ~500 px walked in 10 s, 9-10 facing flips; player on its head - moving 85-100%
of frames, 1-2 flips, no move thrown upward; landing punished by an attack within the
watch window in every run.

## Prevention

Three rules worth carrying. Reach is a box, not a radius, whenever a character's moves
are authored in a side view. Any AI decision taken from a raw distance - a `sign()`, a
threshold, a mode - needs hysteresis, because the one place the player WILL stand is
exactly on the boundary. And when an exploit shows up, ask what the AI should DO about
it before reaching for the mechanic that would paper over it.
