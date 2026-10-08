---
id: bugs/stepping-from-a-bank-onto-ice-is-an-8-px-fall
type: bug
title: Walking off a bank onto Congelar's ice is an 8 px fall, which the 8 px floor snap does not catch, so the fall pose flashes
status: fixed
severity: low
tags: [ice, freeze, floor-snap, water, locomotion, animation, pzl-03]
related: [playtests/2026-10-08-frozen-wave, architecture/wind-piles-a-bounded-crest, architecture/ice-is-its-own-sheet, bugs/a-lowered-drawbridge-is-a-10-px-curb-on-its-own-bank]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/characters/character.gd
  - scenes/world/environment/water/water_layer.gd
  - scenes/world/interactables/freezable_water/ice_collider.gd
---

## Summary

A pool's water, and the ice Congelar lays on it, sits `WaterLayer.surface_inset` (8 px) below the
bank. Ivo walking off the bank onto the ice leaves the floor for about 0.15 s and plays
`fall_start` (arms out). `Character.FLOOR_SNAP`, raised to 8 px for the PZL-03 ramp, does not
catch the drop.

## Symptom

Measured in the water trial, section 2, on every run that walked onto the ice (playtest
`2026-10-08-frozen-wave`). From the `[playtest] log` at 0.05 s:

```
walk_07.00 pos=(15875.0,6000.2) floor=true  state=run
walk_07.05 pos=(15884.6,6001.4) floor=false state=fall_start
walk_07.10 pos=(15894.2,6002.6) floor=false state=fall_start
walk_07.15 pos=(15903.8,6005.1) floor=false state=fall_start
walk_07.20 pos=(15913.4,6007.9) floor=true  state=run
```

Bank top y 6000, flat ice top y 6008. Screenshot:
`playtests/screenshots/2026-10-08-frozen-wave/fall_pose_stepping_onto_ice.png`. It happens the
same way with and without a wind crest, and on the control run with Congelar alone. A walk off a
96 px ledge (section 1's tank wall) is unaffected: one 2 px dip over the corner, then a normal fall.

## Root cause

Not confirmed in code. The drop (6000 to 6008) equals the snap length exactly. Most likely the
collision safe margin puts the floor just past 8 px, so `apply_floor_snap` finds nothing. The
other candidate is the one-way `SegmentShape2D` chain under the snap test. Either way, the gap is
`surface_inset` meeting `FLOOR_SNAP`.

## Fix

Fixed before commit (2026-10-08): `Character.FLOOR_SNAP` is 12 px, so an 8 px step down onto ice stays grounded.

Not fixed. Options:
- A snap a few px longer than `surface_inset` (for example 10 px). Check that slopes and the
  ledge still behave.
- Or lay the ice's top at the bank's height when it meets a bank. That changes the ice sheet's
  shape, so `ice-is-its-own-sheet` owns the decision.

## Prevention

When a constant is chosen to absorb a step (`FLOOR_SNAP`), test it against the largest step the
game paints, which is `surface_inset` between every bank and its water or ice, and not only
against the slope it was made for.
