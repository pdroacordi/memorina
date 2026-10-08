---
id: bugs/a-crest-built-off-screen-springs-in-overshooting
type: bug
title: A wind crest built off screen is not followed by the field, which springs to it 50% too high on screen and freezes stale
status: fixed
severity: medium
tags: [water, wind, crest, freeze, visibility-notifier, pzl-03]
related: [bugs/ice-grows-on-stale-rates-off-screen, bugs/wind-piles-water-above-its-own-bank, architecture/wind-piles-a-bounded-crest, playtests/2026-10-08-frozen-wave]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/environment/water/water_body.gd
  - scenes/world/environment/water/water_surface_field.gd
  - scenes/world/interactables/freezable_water/freezable_water.gd
---

## Summary

`WaterBody._physics_process` steps the `WindCrest` above the `Notifier` gate but
`_field.step(..., _offsets)` below it. Off screen, the crest moves and the surface does not.
The surface heights are gameplay now: Congelar pins them into a ramp. This repeats the
pattern of `bugs/ice-grows-on-stale-rates-off-screen`.

## Symptom

Found in review of the PZL-03 diff (2026-10-08). A scratch headless simulation of
`WaterSurfaceField` with the default `WaterProfile` (192 columns of 2 px, a 384 px pool) measured
both cases:
- On screen throughout, the last column follows the rising crest to 158.3 px (target 159.4).
- The crest built off screen to full, then the pool comes on screen: the last column overshoots
  to **240 px** (damping 2/s against stiffness 25/s², zeta 0.2). The quad's headroom is
  `cap + 4` = 164 px, so the top is cut flat for about a second.
- The reverse case behaves the same way. A crest that settles while off screen leaves the
  surface high, and it drops past the rest line when the pool is seen again.
- `FreezableWater` is not gated. A Congelar reaching an off-screen pool (pulse radius 600,
  screen 640 px) pins `height - swell` from the stale heights, so it freezes flat or old water
  where the crest says a ramp stands.

## Root cause

`water_body.gd:135-137` steps the crest before the `is_on_screen()` return at `:137`.
`water_body.gd:152` (`_field.step`) is after it. `WaterSurfaceField.set_hold` pins
`_heights`, never the target.

## Fix

Fixed before commit (2026-10-08): `WaterBody` keeps stepping its surface off screen while its crest is not flat, so the surface follows the crest wherever it is built.

Not exercised in the engine (playtest `2026-10-08-frozen-wave`): from every spot where Ivo can play Vendaval in the water trial, part of the pool stays on screen. From the wall top, the peek showed only the pool's flat downwind end.

Not fixed. Step the field above the gate while the crest is not flat or is changing, and keep
only `_time`, the swell clock and `_upload()` behind it. The cheaper alternative: while off
screen, set each unheld column to its target (`swell + offset`) with zero velocity, so it
comes on screen at rest.

## Prevention

The prevention rule of `ice-grows-on-stale-rates-off-screen` covers this case: any value
gameplay reads must not sit behind a render-visibility gate. The surface heights became such
a value when the pin started reading them for ice.
