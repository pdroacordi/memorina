---
id: bugs/an-outward-press-at-the-helix-foot-does-not-step-off
type: bug
title: Standing on a helix stair's foot, a press away from the stair does nothing; only Down steps him off
status: resolved
severity: medium
tags: [helix, stair, steering, stuck, player]
related: [systems/helix-stair, architecture/walkable-helix-stair]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/interactables/helix_stair/helix_steer.gd
  - scenes/characters/components/helix_rider_component.gd
---

## Summary

At u 0 the foot is a side. `HelixSteer._direction_for` returns 0 for a press away from the axis
(helix_steer.gd:40-42), and `helix_steer_test.test_at_a_side_a_press_away_from_the_axis_moves_nothing`
pins that at u 0. `HelixRiderComponent.update` steps off at the foot only when
`_u <= 0.0 and direction < 0` (helix_rider_component.gd:87). The head steps off on a fresh
outward press; the foot does not.

## Symptom

Found in review of WORLD-26 (2026-10-11). Reasoned from the code.

Ivo walks right across the bell floor into the foot's 12 px end zone and boards at once. The
player lets go and presses left to walk back to the door, and nothing moves: the idle clip plays
on the bottom step. He stays there until the player presses Down (which also means sit and peek
elsewhere) or climbs.

## Root cause

Leaving at the foot was built only as "descending past u 0". The side rule "a press away moves
nothing" also applies at u 0, where away is the floor.

## Fix

Mirror the head: at `_u <= 0.0`, a fresh press equal to `-_stair.into(false)` calls `_leave(x)`
and returns `OFF_FOOT`. `_held_at_leave` already stops that press from boarding again. Add a
rider test: board with RIGHT, release, press LEFT, expect `OFF_FOOT`.

## Prevention

Give both ends the same exit gestures, and test the walk back from each end.

## Resolution

Fixed 2026-10-11 (WORLD-26). The foot mirrors the head: at u 0 with the steer still, a fresh press away from the stair (`-into(false)`) steps off (`OFF_FOOT`); a press held since boarding or arriving waits for a fresh one (`_outward_held`, set per end in `board`). The steer still answers 0 for that press; the rider owns the exit. Tests: `helix_rider_component_test` `test_a_fresh_press_away_from_the_foot_steps_off` and `test_a_press_away_held_since_boarding_waits_for_a_fresh_one`; `helix_steer_test` notes that the rider steps off at the ends.

Revision (2026-10-11): at the foot the other side descends past u 0 and walks onto the floor (`HelixSteer.direction`), so the exit holds without `_outward_held`; `test_the_other_side_walks_off_the_foot`.
