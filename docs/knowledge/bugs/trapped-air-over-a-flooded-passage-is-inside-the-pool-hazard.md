---
id: bugs/trapped-air-over-a-flooded-passage-is-inside-the-pool-hazard
type: bug
title: The pool's Hazard and Volume rectangles span covered columns from the rest line down, so the sealed chamber's air over the bell column hurts and splashes
status: resolved
severity: medium
tags: [water, hazard, covered-column, diving-bell, redoma, safe-ground]
related: [bugs/well-water-stands-in-the-air-at-a-passage-mouth, systems/water, architecture/hazard-respawn-on-safe-ground]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/environment/water/water_body.gd
  - scenes/world/environment/water/water_layer.gd
---

## Summary

Covered columns (`WaterBasins.Basin.tops`) widen a pool body under the ground. `WaterBody.fit_area()` and
`_wet_outlines()` still cover the whole width from `rest_y + hazard_depth` down. Where a column lies under a sealed
pocket (a bell column), the pocket's air between the rest line and the bell waterline is inside Hazard and Volume.

## Symptom

Found in review (2026-10-10) and confirmed headless on `lake_well`. The body spans x 448-608 and its hazard rect
starts at y 204. Point (452, 260) is chamber air (`map.is_solid` false), well above the bell waterline at y 288,
and `intersect_point` returns `Hazard`.

- Ivo stands on the chamber floor at the lip of the hole (lake_well col 13, cistern col 10, winter_trial col 16).
  His 22 px capsule overlaps the bell column, so he takes 1 HP and sinks while standing on firm ground.
- Ivo falls into the hole. He is taken about 84 px (lake_well) or 52 px (cistern) above the drawn waterline, so the
  fall does not visibly go in (`systems/water`: the hazard starts `hazard_depth` below the surface).
- As the shell contracts, the lower outline band (`_wet_outlines`, `cut.y` up to `top`) climbs into the chamber air
  above the bell line before the shell lets go.
- The Volume rect has the same span. A body jumping in the chamber over the hole splashes and wakes the field, and the
  ripple reaches the open well.

## Root cause

- `water_body.gd:269-276` `fit_area`: one rectangle `size.x` wide from `top` below the rest line. It knows nothing of
  `_ceilings`.
- `water_body.gd:502-526` `_wet_outlines`: `top = surface_rest_y() + hazard_depth` for every sample, also in covered
  columns.
- Over a roof-covered column this only covers rock, which is harmless. Over a bell column (`_bells`) it covers the
  trapped air.

## Fix

Open. Clip the hazard per column to `max(rest_y, rest_y + _ceilings[column]) + hazard_depth` (the volume to the same
without `hazard_depth`). For example, build the hazard as outlines whenever any `_ceilings` value is non-zero, with
`_wet_outlines` taking per-sample tops from the ceilings. Re-run the three chamber playtests with Ivo parked at the
lip of the hole after the water returns.

## Prevention

Anything sized by `fit_area()` assumes the water fills the body's rectangle from the rest line down. When a body
gains a shape that is not a rectangle (a floor, a ceiling, a held disc), audit every `fit_area` caller and the
outlines along with the shaders.

## Fix (2026-10-10)

`WaterBody._refit_hazard` builds outlines whenever a column is covered (`_any_covered`), and `_wet_outlines` starts each sample `hazard_depth` under its column's ceiling. `_ready` refits through it. Splash and wake skip covered columns. Test: `water_hold_out_test.test_the_hazard_stays_under_a_covered_columns_ceiling`. The four chamber playtests still end at 3 HP.
