---
id: bugs/calm-ice-top-steps-on-the-sign-of-a-hundredth-of-a-pixel
type: bug
title: Ice frozen on calm water draws a top that steps by one texel, and a half-texel top row, because the band's top is a fractional y the shader floors and the rect clips
status: fixed
severity: low
tags: [water, ice, ice-sheet, shader, pixel-grid, pzl-02]
related: [architecture/ice-is-its-own-sheet, systems/water, playtests/2026-10-07-ice-outlives-the-drain]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - scenes/world/interactables/freezable_water/ice_sheet.gdshader
  - scenes/world/interactables/freezable_water/ice_sheet.gd
  - scenes/world/interactables/freezable_water/freezable_water.gd
  - scenes/world/interactables/freezable_water/ice_sheet_shape.gd
  - scenes/world/environment/water/water_body.gd
---

## Summary

Ice on calm water should be flat. Its top steps by 1 world px in runs of columns instead, and
the highest row is drawn half a texel tall. The captured top is
`rest_y - pinned` (fractional, pinned about ±0.04 px on calm water). The sheet shader floors it,
the water shader and the collider round it, and the sheet's rect starts at the unrounded y.

## Symptom

PZL-02 review of the uncommitted ice sheet. In
`playtests/screenshots/2026-10-07-ice-outlives-the-drain/shelf_over_sinking_water_22.00.png`
(1280x720, 2 screen px per world px), the water's rows start on even screen rows (518, 520).
The ice's top-line colour starts on screen row 471 at x 1150 and on 472 at x 1170, with runs
of columns alternating between the two along the whole shelf. Row 471 is half of a world
texel, so it is a sub-texel row. The comb is also visible on the crossing frame
(`crossing_on_the_sheet_16.20.png`).

Measured with `WaterSurfaceField` (default `WaterProfile`, memory 1, 10 s settled, 96
columns, every column held at once): max |pinned| 0.037 px, 53 positive and 43 negative.
`floor(Y - pinned)` changes row 4 times along the run. `round(Y - pinned)` never changes.

## Root cause

- `WaterBody.ice_top()` (water_body.gd:315) returns `surface_rest_y() - pinned`, a fractional
  y. `FreezableWater` captures it unrounded (freezable_water.gd:52).
- `ice_sheet.gdshader:29-30` takes the first ice row as `floor(data.r)`. Any pinned > 0, even
  0.001, puts that column's top one row higher than a column with pinned <= 0. The water
  draws the same column with `round` (`wc_surface`, water_common.gdshaderinc), and the collider
  with `roundf` of the joint mean (ice_sheet_shape.gd:69). So on those columns the drawn ice
  is 1 px above both the frozen waterline and the floor Ivo stands on.
- `IceSheet.relayout()` (ice_sheet.gd:35) starts the rect at `y_range().x`, the unrounded
  highest top. The texel row above it is only partly covered, so at 2x raster its
  top-line row comes out one screen pixel tall.

## Fix

Fixed before commit (2026-10-07): `FreezableWater` rounds the captured top (`roundf(ice_top(c))`), so a band's top and bottom are whole world px; `rain_basin_test.test_its_ice_lies_on_whole_pixels`.

Original: Open. Make a band's top and bottom whole world pixels when it is captured, rounded the way the
water rounds its surface (`roundf` in `FreezableWater` or in `IceSheetShape.capture`). Then
`floor` in the shader, `round` in the water and the collider all give the same row, and the
rect has whole-pixel edges. Alternatively, floor/ceil the rect in `relayout()`, but the steps
would remain.

## Prevention

`ice_sheet_shape_test` checks only whole-number tops. Add a capture case with tops of ±0.04
around one line that must give one flat row and one flat chain. In a shader that reads a
world y from data, round it the way the twin shader does.
