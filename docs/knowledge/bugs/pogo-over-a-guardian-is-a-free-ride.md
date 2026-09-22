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
- The guardian ANSWERS the situation rather than the QTE doing it for them. The first
  attempt let the Bloom burst reach 160 px up so a pogo triggered the double-jump recall;
  the correction was that the boss should be smart enough to leave, not that the QTE
  should rescue it. A player overhead is lunged out from under at `step_out_speed` and
  punished on the landing (the cooldown is zeroed the frame they come down), and the
  guardian never walks under a player it cannot reach.
- While a cooldown runs it holds spacing (`GuardianStats.comfort_distance`) instead of
  standing there: gives ground to a player who closes in, drifts back toward one who
  backs off, paces when neither.
- **Every decision taken from a distance is held with HYSTERESIS**, and it took three
  passes to get right because each fix moved the flip-flop to the next threshold:
  1. `sign(dx)` with no dead band - flipped every frame with the player directly above.
  2. The spacing re-decided from the raw distance - 47 flips in 10 s next to a
     stationary player at the boundary.
  3. `_is_above_reach` re-decided from the raw height - a pogo crosses it three times a
     second, so a player bouncing 70 px to one side gave 32 flips in 6 s. Fixed by
     making "out of reach overhead" a sticky state in BOTH axes (`_update_reach`), and
     giving the escape a minimum dwell and an exit band wider than its entry.
- **The move is CHOSEN, then kept.** `_situational_pick` answers an overhead player with
  a move that reaches up (if the guardian owns one) and a distant one with its longest,
  otherwise a weighted roll - but re-picking every frame let whichever move happened to
  be in range win every race, and the Bloom lash stopped appearing entirely. The choice
  now survives until it is thrown or a strong opinion replaces it (`_refresh_next`).
- **Three moves each** (the fight was two): Bloom gained a pounce - `leap_impulse` plus
  `lunge_speed`, 48 px up and 192 px across, landing past the player - and Frost a slam,
  whose clip keys a tall hitbox and whose `attack_height` is 150, so the golem swats a
  player bouncing just above it. Not every boss jumps: the asymmetry is the design.

Measured after the fix (throwaway harness, both guardians, 14 s per situation): all three
moves used at close range; the long move at range; Bloom silent and steady (0 facing
flips) while a player bounces on it, Frost answering with two slams; a bouncing player at
0/30/70 px to one side now gives 3/1/0 facing flips (was 12/11/32); an ordinary fight
still reaches the recall in 0.2-0.8 s and opens lucidity.

## Prevention

Four rules worth carrying. Reach is a box, not a radius, whenever a character's moves
are authored in a side view. Any AI decision taken from a raw distance - a `sign()`, a
threshold, a mode - needs hysteresis, because the one place the player WILL stand is
exactly on the boundary. And when an exploit shows up, ask what the AI should DO about
it before reaching for the mechanic that would paper over it. Finally: a choice re-made
every frame is not a choice - either commit to it, or watch the option with the widest
window win every time.
