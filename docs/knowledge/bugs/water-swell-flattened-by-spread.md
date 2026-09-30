---
id: bugs/water-swell-flattened-by-spread
type: bug
title: At default WaterProfile values the ambient swell almost never moves the stepped waterline, because neighbour coupling fights the swell
status: fixed
severity: medium
tags: [water, springs, tuning, memory]
related: [bugs/ice-front-leaps-dead-columns]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/world/environment/water/water_surface_field.gd
  - resources/world/water/water_profile.gd
---

## Summary

`WaterSurfaceField._substep` pulls each column toward `swell()` with `stiffness`, but
applies `spread` to the ABSOLUTE heights. The swell's own curvature therefore counts as a
ripple to be smoothed away. At the defaults (`stiffness` 25, `spread` 2000), a
`wave_amplitude` of 1 px comes out at about 0.6 px. The shader rounds heights, so the
waterline is almost always flat.

## Symptom

Found in review (commit 37c9c62) and measured headless with the real class: 96 columns,
default `WaterProfile`, all columns at rate 1, 30 s at 60 fps, sampling after 10 s. The
target swell peaks at 1.00 px and the realised surface peaks at **0.61 px**. Only **~1.2%**
of column-frames round to a non-zero height. `test_the_swell_moves_living_water` does not
catch this because it uses `wave_amplitude` 2.0 and asserts only `> 0.3`.

## Root cause

`water_surface_field.gd:152`: the term `spread * (left + right - 2h)` treats the swell's
shape as a disturbance. For the swell's shorter components the Laplacian stiffness
(`spread * (2 - 2cos k)`) is larger than `stiffness`, so those components are suppressed
most. `WaterProfile.wave_amplitude`, documented as "Height of the ambient swell in world
pixels", is not the height the water reaches.

## Fix

Not fixed yet. Suggested fix: couple the neighbours on the deviation from the swell, not on
the raw height. Compute `target[i]` once per substep into a member buffer, then use:

`spread * ((left - target_l) + (right - target_r) - 2.0 * (height - target))`

The springs then model only the disturbance around the swell. The swell comes through at
its authored amplitude, and splashes and scars still relax as before, because the target
is on the shared body clock.

## Prevention

Add a test at the DEFAULT profile: after a warm-up, the peak height must be within ~15% of
`wave_amplitude`. Any test of an authored amplitude should check that amplitude, not a
loose lower bound.

## Fix

Fixed in c45784b (2026-09-22): the springs couple on each column's distance from the swell (`h - target`), not on raw height. `test_the_swell_reaches_its_amplitude_at_the_default_profile` asserts the peak exceeds 0.85 of `wave_amplitude` at the default profile.
