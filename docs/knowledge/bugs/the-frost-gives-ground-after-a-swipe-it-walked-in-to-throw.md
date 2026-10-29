---
id: bugs/the-frost-gives-ground-after-a-swipe-it-walked-in-to-throw
type: bug
title: The Frost golem stops inside its give-ground distance when it walks in to swipe, so it backs off after the swipe
status: resolved
severity: low
tags: [guardians, ai, spacing, tuning, grd-07]
related: [systems/guardians, bugs/the-frost-swipe-passes-over-ivo-standing-close-to-the-golem]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - resources/characters/guardians/frost_guardian/frost_swipe.tres
  - resources/characters/guardians/frost_guardian/frost_guardian_stats.tres
  - resources/characters/guardians/frost_guardian/frost_guardian_locomotion_stats.tres
  - scenes/characters/guardians/guardian_ai.gd
  - tests/scenes/combat/combat_reach_test.gd
---

## Summary

GRD-07 cut `frost_swipe.attack_range` from 110 to 104 and left `give_ground_distance` at 101.5.
That 2.5 px margin is smaller than the golem's stopping slide (2.97 px). A swipe thrown after
walking in therefore starts at about 101 px, and the golem gives ground once the swipe ends.

## Symptom

Expected from the code, not yet seen in play. Ivo stands still at the golem's comfort point
(165 px). The cooldown ends and the golem walks in at full speed. It telegraphs and swipes. Ivo
jumps the swipe straight up, or the swipe misses for another reason, and lands where he was. As
the next cooldown starts, the golem walks back toward 165 px. `systems/guardians` ("Comfort
distances follow Ivo's reach") says a guardian never backs off from where it just threw its
main move.

## Root cause

- `GuardianAI._select_state` starts the telegraph on the first frame `_in_range(_next)` holds,
  so the golem is at most 104 px away, and at least 104 - 78/60 = 102.7.
- `_telegraph_tick` sets `_current_direction = 0`, and `LocomotionComponent.ground_update`
  brakes at `deceleration` 1024 px/s^2 from `move_speed` 78 px/s. That slides another
  78^2 / (2 x 1024) = 2.97 px, so the swipe starts at 99.7..101.0 px.
- After the swing, `_hold_spacing` -> `_update_spacing_mode` compares that distance with
  `give_ground_distance` 101.5 and switches to GIVE_GROUND.

Before GRD-07 the margin was 110 - 101.5 = 8.5 px, more than the slide. The Bloom's new margin
(lash 52, give-ground 46) is 6 px against a 4.1 px slide (112^2 / (2 x 1536)), so it is
unaffected.

## Fix

Not fixed yet. Keep the margin larger than the slide: either `give_ground_distance` about 98
for Frost (still above its 42 px contact reach), or a swipe range the box still supports
(it touches out to 105, so 104 is already the limit).

## Prevention

`combat_reach_test.test_every_guardian_keeps_its_comfort_point_outside_ivos_reach_and_gives_ground_only_close_in`
compares `give_ground_distance` with the raw `attack_range`. Compare it with
`attack_range - move_speed^2 / (2 x deceleration)` from the guardian's `LocomotionStats`: that
is the farthest distance a move thrown after walking in can start from.

## Resolution (2026-10-29)

Frost `give_ground_distance` 101.5 -> 98: the swipe (range 104) thrown after a walk-in starts at 99.7-101.0 px, outside 98 and still above the 42 px contact reach.

## Revision (2026-10-29)

Fixed in the same GRD-07 change: `frost_guardian_stats.give_ground_distance` 101.5 -> 98, below the ~101 px an approach swipe starts from. The Fix section above was not updated when `status` became resolved. `combat_reach_test` also asserts give-ground < comfort.
