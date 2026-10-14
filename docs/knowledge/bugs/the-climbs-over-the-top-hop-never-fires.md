---
id: bugs/the-climbs-over-the-top-hop-never-fires
type: bug
title: The climb's over-the-top hop never fires - the sensor leaves the climbable 16 px before the feet pass its top, so up held at the top of a root pole or shaft bobs instead of hopping
status: resolved
severity: low
tags: [climb, root, enraizar, player, world-35]
related: [systems/roots-and-climbing, bugs/the-root-caves-roots-end-short-of-woods-deep-without-the-row-0-ledge, playtests/2026-10-14-world35-step2]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/characters/components/climb_component.gd
  - scenes/characters/ivo/ivo.tscn
  - tests/scenes/characters/components/climb_component_test.gd
  - tools/playtest/scripts/world35s2_b_root_climb.json
---

## Summary

`ClimbComponent.update` returns `Exit.OVER_THE_TOP` only when the hands come off with up held and
`_above_the_top()` is true. It tested the sensor node's position (Ivo's origin, his feet) against the top of what is
held. The `ClimbSensor` shape is 12x28 at y -30, so it spans feet -44 to feet -16 and stops overlapping while the feet
are still 16 px below the top. At 80 px/s the feet are 15 px below the top on that frame, so the exit was always
`LET_GO`, and the 44 px hop (`top_hop_height`) never ran.

## Symptom

WORLD-35 step 2, `woods_hollow_tree` (uncommitted, on 743aa53), Enraizar only, a root pillar from the floor (feet 288) to
the underside of a one-way knot (y 128):
- With up held, Ivo climbed at -80 px/s to feet 147.9, fell back, regrabbed after 0.3 s and climbed again: a bob between
  feet 137 and 148 for as long as up was held (first run of `world35s2_b_root_climb.json`, t 8.7-10.4). He never landed
  on the knot (top 96).
- The same bob is the 2026-10-11 root caves symptom (feet ~426 under a top near 410).

## Impact

- The only way off a root pole or shaft was a jump while still holding (a ground jump, 143 px). Pressed during the
  bob's airborne half it was an air jump, which a player without the double jump does not have, so the press did nothing.
- `systems/roots-and-climbing` described the hop as working.

## Fix

2026-10-14, WORLD-35 step 2 (orchestrator call):
- `ClimbComponent.cleared_top(sensor_bottom, top)` (static, pure): the hands came off over the top when the sensor's
  bottom is at or above the top, and never when nothing of the climbable is left (`top` INF). `_above_the_top()` passes
  `_sensor_bottom()`, the lowest edge of the sensor's shapes, instead of the node position.
- `top_hop_height` 44 -> 54 px. From feet 16 px under the pole's top, the hop peaks 37.4 px over it (`JumpReach.heights`,
  the apex softening included), clearing the 32 px one-way cell lying on a root pole's top by 5.4 px in the model. In the
  game Ivo lands on each woods_hollow_tree knot with 12.2 px of apex to spare.
- `tests/scenes/characters/components/climb_component_test.gd`: `cleared_top` cases, a body and sensor climbing a real
  pole `Climbable` until it leaves (OVER_THE_TOP; it returned LET_GO before the fix), a slide off the side (LET_GO), and
  Ivo's hop from `ivo.tscn` against the sensor offset and one cell (it measured 29.2 px over the top against 36 needed
  before the fix).
- Re-run: `world35s2_b_root_climb.json` with up held and no jump. Eight songs, Ivo hops onto all eight knots, then the
  street. The root caves well's row-0 one-way (cols 28-29) was not re-run: its timelines climb under the open half.
