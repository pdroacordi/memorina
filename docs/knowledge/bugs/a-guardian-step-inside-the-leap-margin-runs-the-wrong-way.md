---
id: bugs/a-guardian-step-inside-the-leap-margin-runs-the-wrong-way
type: bug
title: A backstep or a step planned within 96 px of an arena wall is clamped to the lucidity leap's margin, so it runs the wrong way (the antler dash lurches forward, the antler thrust recoils)
status: fixed
severity: low
tags: [grd-13, guardian, bloom, motion, dash, step, arena, wall]
related: [systems/guardians, bugs/the-bloom-antler-dash-strands-it-beyond-every-other-move-and-it-dashes-back-from-off-screen]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - resources/characters/guardians/motion/dash_motion.gd
  - resources/characters/guardians/motion/step_motion.gd
  - resources/characters/guardians/motion/motion_context.gd
  - scenes/characters/guardians/guardian.gd
---

## Summary

Found (GRD-13 fix-round review, 2026-11-18). `MotionContext.clamp_x` clamps an x into `[arena.position.x + margin,
arena.end.x - margin]`, and `Guardian._motion_context` sets `margin` to `lucidity_leap_margin` (96). That margin is
meant for leap landings. A guardian on foot can stand closer to a wall than 96 px. Its walking stops at the wall, and
the dash itself ends 48 px from it. A step whose end is clamped into that band then moves toward the arena's middle,
whatever its authored direction.

## Symptom

Measured with a headless probe of the shipped `.tres` (arena 0..1200, margin 96, facing +1):

| Move | Feet from the wall | Authored | Planned |
|---|---|---|---|
| Antler dash backstep (`DashMotion.backstep` 48, away from Ivo) | 30 behind | -48 | +66 (forward, toward Ivo) |
| Antler dash backstep | 60 behind | -48 | +36 |
| Antler thrust (`StepMotion` +32, toward Ivo) | 50 ahead | +32 | -46 (a recoil) |
| Antler thrust | 80 ahead | +32 | -16 |

- The dash: the backstep pose plays while the stag slides up to ~66 px toward Ivo in 0.2 s, and the hit window opens
  that much nearer him. Reachable after any dash that ended near a wall (it ends 48 px from it), or after the stag gave
  ground into a corner.
- The thrust ends the lash string, which is what a player pinned at a wall faces (`systems/guardians`, "The lash
  string"). The stag is then 40-100 px from that wall, and its thrust steps back.

## Root cause

`clamp_x` limits the end of the step to the margin band but never limits it by the guardian's current feet. Once the
feet are already outside the band, the clamp turns the step around. `DashMotion.plan` (new `backstep`) and
`StepMotion.plan` both call it. `guardian_motions_test`'s cornered case starts at 110 px, outside the margin.

## Fix

Not fixed. Options:
- Clamp a floor step only in its own direction and never past the feet:
  `clampf(x, minf(low, feet.x), maxf(high, feet.x))`. It may stop short, but it never reverses. The dash's backstep
  could also use its own `margin` (48), not the leap's.
- Add a `guardian_motions_test` case: feet inside the margin, for a backstep toward the near wall and a forward step
  toward it. The sign of the planned offset is never the opposite of the authored one.

## Prevention

A floor motion's planned offset keeps the authored sign or is zero. Assert this for every `GuardianMotion` at feet 0,
30 and 60 px from each wall.

## Fix (2026-11-18, GRD-13)

`MotionContext.clamp_step(from, x)` holds a floor step inside the margins but returns `from` when the clamp would reverse it, so a step from inside a margin stops short and never runs the wrong way. `StepMotion` and the `DashMotion` backstep use it. Test: `guardian_motions_test.test_a_step_from_inside_the_margin_never_runs_the_wrong_way`.
