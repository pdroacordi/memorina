---
id: bugs/wind-dragged-pool-water-upwind
type: bug
title: WaterBody._blow pushed the downwind half of a pool down, so wind piled water upwind
status: fixed
severity: low
tags: [water, wind, sign-convention, pzl-03]
related: [architecture/wind-piles-a-bounded-crest, systems/air]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/environment/water/water_body.gd
---

## Summary

`_blow` added `-wind * wind_stress * delta * (column - half) / half` to each column. With wind
positive to the right, the right half (column > half) got a negative displacement, so the water
rose at the upwind bank. Its comment and `systems/air` said downwind. The effect was about 1 px,
and no test covered it.

## Root cause

A world direction (wind x, + right) was multiplied by a column index measured from the middle
(+ right), and a minus sign was added. Nothing checked which end ended up higher.

## Fix

Removed in PZL-03 (2026-10-08) along with `WaterProfile.wind_stress`. `WindCrest` replaces it,
and `wind_crest_test.gd` `test_it_piles_at_the_end_the_wind_blows_to` covers both signs.

## Prevention

When a world direction drives a per-column quantity, write the test that says which end goes
up before tuning the magnitude.
