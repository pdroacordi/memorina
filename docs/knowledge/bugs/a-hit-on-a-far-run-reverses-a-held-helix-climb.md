---
id: bugs/a-hit-on-a-far-run-reverses-a-held-helix-climb
type: bug
title: A hit while climbing a far run with a side held resets the steer latch, and the held side then descends
status: resolved
severity: low
tags: [helix, stair, steering, knockback, latch, player]
related: [systems/helix-stair, architecture/walkable-helix-stair]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/world/interactables/helix_stair/helix_steer.gd
---

## Summary

While Ivo is knocked back, `Player._stair_axis()` returns `Vector2.ZERO` (player.gd:524-526).
The rider passes it to `HelixSteer.step` (helix_rider_component.gd:75), which treats x 0 as a
release and clears the latch (helix_steer.gd:22-24). When the knockback ends, the still-held
side is read again from the run's screen direction.

## Symptom

Found in review of WORLD-26 (2026-10-11). Reasoned from the code. Latent: nothing can hit Ivo in
the bell tower today, but `lighthouse_interior` reuses the stair.

With hand 1, a far run rises toward screen-left. Ivo climbs holding right, latched upward through
the turns. A hit lands on a far run. 0.18 s later right is re-read as "move right on screen",
which on that run is down. He walks back down the stair while the player still holds the key
that was climbing it.

## Root cause

"Knockback zeroes the stair input" was built by zeroing the axis, and the steer cannot tell that
from a release.

## Fix

Hold the rider still without touching the steer. For example, give
`HelixRiderComponent.update(delta, axis, speed, held)` a flag that skips the step while `held`,
or pass the real axis with a speed of 0 during knockback.

## Prevention

When a controller carries a latch, pausing its input is not a release.

## Resolution

Fixed 2026-10-11 (WORLD-26). `HelixRiderComponent.update` takes `held`; `Player._stair_motion` passes `is_in_knockback()` and no longer zeroes the axis. While held the rider keeps the feet where they are and never steps the steer, so the latch survives. Test: `helix_rider_component_test.test_a_hit_on_a_far_run_keeps_the_held_climb`.

Revision (2026-10-11): the latch is gone (the run never changes direction at the front); `held` still keeps the feet still through a hit; `test_a_hold_keeps_the_feet_still_and_the_climb_resumes`.
