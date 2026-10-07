---
id: architecture/the-water-level-moves
type: architecture
title: A body of water is painted at its highest level and moves its origin to sink
status: active
tags: [water, water-body, set-level, chuva, rain-basin, floater, freeze]
related: [architecture/water-two-projections, architecture/played-pulses-hold-in-a-pause, architecture/a-pool-rests-below-its-painted-reach, architecture/ice-is-its-own-sheet]
created: 2026-09-30
updated: 2026-10-07
source_files:
  - scenes/world/environment/water/water_body.gd
  - scenes/world/interactables/rain_basin/rain_basin.gd
  - scenes/world/interactables/floater/floater.gd
  - scenes/world/interactables/freezable_water/ice_collider.gd
---

## Summary

`surface_rest_y()` was always the body's own origin, so a moving level is a moving
origin: `WaterBody.set_level(y)` moves the node, shrinks `size.y`, keeps each column's
floor at its world height, re-fits the volume and hazard, keeps the mirror axis halfway
up the bank and re-pushes the shaders' `rest_y`. A Chuva basin is painted at its full
level and dried out at load.

## Details

- Painted at the HIGHEST level so every quad, floor and receiver is sized once; a lower
  level only shrinks. `level_range()` = (painted top, deepest floor).
- A column whose floor is above the level has depth 0 and the shaders clip it; a dry body
  hides its quads and disables its volume and hazard (deferred).
- `RainBasin` sizes its RAIN receiver to the full water, then dries the body DEFERRED,
  because the `FreezableWater` above it sizes its own receiver in its later `_ready`.
- Ice: `IceCollider.set_top()` puts the collider at the level when the freeze starts, and a
  basin holds its level while any ice is on it (`FreezableWater.is_frozen()`).

## Why

Design 03 section 6.5: levels are authored, never computed. Painting the full level makes
the authored level the painted one - readable in the room's text.

## Not yet

A pool rising above a painted rest level, and ice outliving the water draining under it
(an independent ice sheet, Phase 7).

## Revision (2026-10-07, planned, not built)

Both "Not yet" items are planned. Painting at the highest level stays.

- A basin's rest is no longer always dry: `r` cells above `~`/`f` water are the level Chuva
  brings it to, and the painted water below is the rest (`WaterBody.rest_depth`,
  `rest_level()`); a lone `r` group is still dry at rest
  (`architecture/a-pool-rests-below-its-painted-reach`).
- "A basin holds its level while any ice is on it" is replaced: ice is a lid, so a frozen
  basin may not RISE but keeps draining; the ice keeps its own world height in a sheet of
  its own, and `IceCollider.set_top()` goes (`architecture/ice-is-its-own-sheet`).
- `set_level()` becomes the commanded level; Redoma's held volume may raise the drawn level
  above it, up to the painted top (`architecture/the-shell-displaces-water-into-the-reach`).
