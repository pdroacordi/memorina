---
id: bugs/ice-grows-on-stale-rates-off-screen
type: bug
title: FREEZE ice grows on stale memory when the pool is off-screen, because WaterBody stops reading the field there
status: fixed
severity: medium
tags: [water, freeze, ice, memory-field, visibility-notifier]
related: [bugs/ice-front-leaps-dead-columns]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/environment/water/water_body.gd
  - scenes/world/interactables/freezable_water/freezable_water.gd
---

## Summary

`WaterBody` skips its whole `_physics_process` when its `Notifier` is off-screen, and
that includes refreshing the per-column memory rates. `FreezableWater` is not gated. It
keeps advancing `IceFront` with `_water.column_rates()`, which are frozen at whatever
the field read the last time the pool was on screen, or at `_ready`. Ice growth, which
is gameplay, is then decided by stale memory.

## Symptom

Found by code review of 224d721. Not reproduced in the engine. The trigger is realistic:
`default_pulse_stats.tres` has `max_radius = 600`, and the screen is 640 px wide. A
FREEZE played about 400 px from the pool reaches the pool's `SongReceiver` while the
pool is off-screen.
- If the stale rates are about 0 (the pool was last seen in grey water), the fronts do
  not move. After `thaw_delay` the thaw front marks the columns thawed, and a thawed
  column never regrows (`ice_front.gd` `_grow_fronts` skips `_thawed == 1`). By the time
  the player walks over, the crossing never formed.
- If the stale rates are high (the pool was last seen inside an old pulse), ice grows
  over water that is dead now. That breaks "growth needs living water" (design 03 §6.3).

## Root cause

- `water_body.gd:87-91`: the `is_on_screen()` early return comes before the
  `_frames_until_rates` countdown, so `_refresh_rates()` stops along with the field
  step and the upload.
- `freezable_water.gd:35`: `_front.advance(delta, _water.column_rates())` reads that
  cached array every frame, whether or not the pool is visible.

## Fix

Not fixed yet. Move the rate refresh above the visibility gate in
`WaterBody._physics_process`. It costs about `columns / RATE_STRIDE` field samples
every `RATE_REFRESH_FRAMES`, which is cheap. Gate only the field step, `_time` and
`_upload()` on visibility. That keeps the rule "rates are always current; drawing is
what visibility saves".

## Prevention

Any value that gameplay consumes must not sit behind a render-visibility gate. When a
`VisibleOnScreenNotifier2D` skips work, check every public getter of that node for
readers outside the drawing path.

## Fix

Fixed in 3f64f90 (2026-09-23): `WaterBody._physics_process` refreshes the rates before the `is_on_screen()` gate; only the surface sim, clock and upload are gated.
