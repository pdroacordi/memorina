---
id: bugs/a-pinned-ivo-jumps-the-roaring-lion-only-in-a-frame-tight-window
type: bug
title: A pinned Ivo can single-jump over the roaring Sun Guardian only inside a ~0.07 s window, because its body hurts through the roar's wind-up
status: fixed
severity: medium
tags: [guardians, summer, fairness, body-contact, grd-16]
related: [systems/guardians, playtests/2026-11-19-grd16-sun-fight, bugs/the-sun-guardians-roar-never-fires]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - resources/characters/guardians/summer_guardian/summer_roar.tres
  - scenes/characters/guardians/guardian.gd
  - tests/resources/characters/guardians/summer_guardian/summer_guardian_kit_test.gd
---

## Summary

`systems/guardians` ("The Sun Guardian's fight", "Pinned at a wall") gives a pinned Ivo with no roll and no double jump
one answer to the roar: jump over the lion during its 0.6 s wind-up. With the roar's `body_contact` true, the 132x72
contact box hurts through that wind-up, so the jump works only if it is pressed by 0.42 s into the wind-up and the
direction is held 0.03-0.14 s after the press. Pressing both together is always hit.

## Symptom

GRD-16 review, 2026-11-19. In `pl4` the dodging driver jumped over the roar while holding toward the lion, and 9 of its
30 body-contact hits came during a roar wind-up, at 70-74 px, on the floor or just off it ("roar over" in the log).

## Root cause

The roar is thrown at 88 px or less, and the walk-in carries the lion about 7 px further, so Ivo stands 81-88 px from
its centre. The contact edge is at 74 px (66 half body plus Ivo's 8 px hurtbox half). Ivo's feet reach 66 px (hurtbox
foot over the 72 px box) 0.155 s after take-off. His air acceleration (2048 x 0.8 px/s²) covers about 18 px in that
time, more than the 7-14 px he has. He must also be past the rear's high box (x 30..80, 110-190 px up, strike
0.25-0.33 s, so 0.85-0.93 s into the wind-up) and land behind the body. A sweep of jump times and direction delays on the kit test's `JUMP` trace, in 1/240 s steps,
finds:

| Ivo at | Latest jump into the wind-up | Delay of the direction after the press, jump at 0.35 s |
|---|---|---|
| 81 px | 0.42 s | 0.07-0.14 s |
| 84 px | 0.42 s | 0.05-0.12 s |
| 88 px | 0.43 s | 0.03-0.10 s |

With the kit test's `REACT` (0.35 s to read a tell), that leaves 0.07 s to jump, and no delay of 0 works. The doc's "a
jump carries Ivo about 160 px across in the 0.85 s before the rear" counts the travel but not the contact box during the
climb. `test_the_arena_leaves_room_to_jump` checks only the ceiling.

Each kit still has another answer: the Lake kit's roll (128 px plus the recovery slide, about 165 px, invulnerable,
ends past the body), and the Orchard kit's double jump straight up over the 190 px box. So no move needs a kit Ivo may
lack. The defect is that the single-jump answer the contract promises to every kit is not a fair one.

## Fix

Fixed 2026-11-19 (GRD-16 review): `summer_roar.tres` has `body_contact` false. Its boxes (the rear's high box and the
slam) are its hit; the body is harmless from its wind-up to the end of its recovery, and the GRD-10 grace
(`GuardianBodyContact`) covers an Ivo still inside the body after it. The telegraph is unchanged.

Test: `summer_guardian_kit_test.test_a_pinned_ivo_jumps_over_the_roar` replays the pinned jump from 81, 84 and 88 px:
Ivo's traced jump with the direction held toward the lion from the press (his air acceleration and speed read from
`ivo_locomotion_stats.tres`), against the roar's keyed boxes every 1/60 s, landing behind the body. Each start has a
take-off window of at least 0.25 s, and a press at `REACT` (0.35 s into the wind-up) clears it.

## Prevention

A "jump over the guardian" answer has to be checked against the body's contact box during the climb, from the
distance the move is actually thrown at, with the direction held from the press.
