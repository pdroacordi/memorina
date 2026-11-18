---
id: bugs/a-guardian-motion-left-undriven-mid-strike-keeps-gravity-off-and-the-world-passed-through
type: bug
title: A guardian whose AI stops ticking mid-strike keeps its MotionPath's last frame, so gravity stays off, the collision mask can stay 0 and the body drifts at its last path velocity
status: fixed
severity: medium
tags: [grd-12, guardian, motion, mover, gravity, collision-mask, latent]
related: [systems/guardians, architecture/grd-12-guardian-fight-engine]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/guardian_mover.gd
---

## Summary

Latent until a shipped move has a `motion` (GRD-13..17). If the strike is frozen without `attack_finished` (Ivo leaves the arena rect mid-strike), `GuardianMover` keeps its path and its last `_elapsed`, and `Guardian` keeps reading it every frame.

## Symptom

Found in the GRD-12 review (code reading). Expected repro on `engine_guardian`: a `LeapMotion` (`through_ceiling = true`) or `DiveMotion` strike; Ivo leaves `Arena.bounds()` while the path holds the vertical. The guardian floats at its last `velocity.y`, gravity off. With `through_ceiling` it also passes through the world, until Ivo comes back.

## Root cause

- `guardian.gd:177-187`: `_ai.tick` and `_mover.drive` run only while `PRESSURE and _player_in_arena()`. Otherwise the clock stays in STRIKE and `_mover._elapsed` stops changing.
- `guardian.gd:192-197` reads `_mover.passes_through()` and `_mover.owns_vertical()` every frame whatever the branch. Both are `_path.holds_vertical(_elapsed)` (`guardian_mover.gd:81-90`), so they stay true. `velocity.y` keeps the last `step.y` written by `drive` (`guardian_mover.gd:66-67`), with no gravity, and the mask stays 0 above the take-off line.
- Legacy moves are not affected: `_path` is null, so both queries return false. The old swing froze the same way, but nothing in it suspended gravity.

## Fix

Fixed in GRD-12 (2026-11-18). A path holds the body only on a physics frame it was driven: `GuardianMover.drive` stamps `Engine.get_physics_frames()`, and `owns_vertical()`, `passes_through()` and `is_intangible()` answer false on any other frame (`_holds()`). The hit flush of the same frame still reads it. An undriven strike falls under gravity and takes `_solid_mask` back on the next frame. Tests: `guardian_engine_test.test_a_hang_left_undriven_falls`, `test_a_leap_through_the_ceiling_left_undriven_takes_the_world_back`.

Not fixed. Options:
- the mover answers `owns_vertical`/`passes_through` only on a frame it was driven (a `_driven` flag cleared in `after_move`);
- or `Guardian` calls `_mover.end()` (and cancels the string) when the AI stops being ticked mid-strike.

## Prevention

A `guardian_engine_test` case: start a vertical motion, move Ivo out of the arena, step 30 frames, and assert gravity applies and `collision_mask` is restored.
