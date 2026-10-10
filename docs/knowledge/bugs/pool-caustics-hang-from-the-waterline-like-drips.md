---
id: bugs/pool-caustics-hang-from-the-waterline-like-drips
type: bug
title: A pool's caustics were 3 px vertical bands stippled 10 px down from the waterline, which read as drips hanging off the surface
status: resolved
severity: low
tags: [water, caustics, pool, shader, look]
related: [systems/water, playtests/2026-09-23-generated-water]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/environment/water/water_surface.gdshader
  - resources/world/water/water_look.gd
---

## Summary

The user (2026-10-10), on a screenshot of the village cistern: "the water (such as in the image) is beheaving sort of
weird, don't you think?" Under every pool's waterline hung light dotted columns. Turning the reflection off
(`reflection_strength = 0` in `pool_look.tres`) left the frame identical, so they were not the reflection: they
were the caustics. Each 3 px band chosen by the hash was lit from the surface down to `caustic_depth` (10 px) and
Bayer-stippled by depth, so a lit band became a short stippled column under the line.

## Fix

Caustics are now short 1 px glints (`caustic_band_px`, 4 px long) on every `caustic_row_px`-th row (3) under the
surface. The chance of a glint falls linearly to 0 at `caustic_depth`. They still re-roll on the water's clock and
wake with the reflection. There is no vertical stipple.

## Lesson

A light pattern that falls off with depth must not be stippled down a column, because that draws a drip. Thin it
out across rows instead.
