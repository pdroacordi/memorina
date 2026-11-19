---
id: bugs/the-leaf-gust-blows-ivo-out-of-the-guardians-sight-and-the-fight-stops
type: bug
title: The Leaf gust carries Ivo more than 900 px from the scarecrow, its EnemySight loses him, and its AI holds mid-strike for good
status: resolved
severity: high
tags: [guardians, autumn, leaf, grd-15, gust, sight, softlock, playtest]
related: [playtests/2026-11-18-grd15-leaf-fight, systems/guardians]
created: 2026-11-18
updated: 2026-11-19
source_files:
  - scenes/characters/guardians/autumn_guardian/autumn_guardian.tscn
  - scenes/characters/components/enemy_sight.gd
  - scenes/characters/guardians/guardian_ai.gd
  - tests/resources/characters/guardians/autumn_guardian/autumn_guardian_kit_test.gd
---

## Summary

The gust pushes Ivo along the floor at 1700 px/s until a wall stops him. Thrown from the east half of the 1280 px
orchard arena, it left him 930 px from the scarecrow. Its `EnemySight` circle was 900 px, so `EnemySight.player` went
null. `GuardianAI._select_state` returns HOLD when it has no player, and HOLD does not tick the move clock. The gust's
strike never ended, the scarecrow stood on its last frame, and nothing else happened for the remaining 165 s of the run.

## Symptom

Dodging driver run `pl7` (GRD-15), stage 2: an owned gust thrown from 248 px at 90.7 s. At 92.75 s Ivo stopped at the
west FightWall, 929.8 px away; at 93.55 s the floor box hit him. The log then shows no state or sprite change until the
run ended at 259 s; the runner's last line reads `room=orchard_arena`, `hp=2`.

## Fix

Engine-wide (GRD-15 review, 2026-11-19): `Guardian._fit_sight_to_arena()` sets the `EnemySight` circle, at `_ready`, to
the diagonal of the guardian's own `Arena` (`Guardian.sight_radius_for`), never below the scene's 900 px; the shape is
duplicated first, so no other instance changes. Every guardian sees its whole arena from anywhere in it; the autumn
scene keeps 900. Tests: `guardian_sight_test` (all five guardians in their rooms; the radius rule).

## Not fixed here

A clock that stops whenever sight is lost mid-strike is still the engine's behaviour; with sight covering the arena,
and the AI ticking only while Ivo is inside it, it can no longer be reached.
