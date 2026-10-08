---
id: architecture/ice-is-its-own-sheet
type: architecture
title: Ice is its own sheet, a per-column band captured where the water stood and decoupled from the water level (PZL-02, base for PZL-03 and PZL-06)
status: active
tags: [water, ice, freeze, rain-basin, ice-collider, shader, plan, pzl-02, pzl-03, pzl-06]
related: [architecture/the-water-level-moves, architecture/memory-gated-height-field, architecture/wind-piles-a-bounded-crest, architecture/the-shell-displaces-water-into-the-reach, architecture/a-pool-rests-below-its-painted-reach, systems/water, bugs/ice-front-leaps-dead-columns, bugs/temporary-song-floors-are-remembered-as-safe-ground, gotchas/body-state-cannot-change-in-the-physics-flush, gotchas/screen-texture-copy-scope]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - scenes/world/interactables/freezable_water/freezable_water.gd
  - scenes/world/interactables/freezable_water/ice_front.gd
  - scenes/world/interactables/freezable_water/ice_collider.gd
  - scenes/world/environment/water/water_body.gd
  - scenes/world/environment/water/water_surface_field.gd
  - scenes/world/environment/water/water_surface.gdshader
  - scenes/world/interactables/rain_basin/rain_basin.gd
  - scenes/world/interactables/floater/floater.gd
---

## Summary

Built 2026-10-07 for PZL-02 (the field's `offsets` wait for PZL-03, `ice_top` of held columns for PZL-06; `IceCollider.build(count)` takes the segment count from `IceSheetShape`; there is no separate texture class, `IceSheet` owns its data; captured tops are rounded to whole px; a `Floater` the ice lets go sinks at `sink_speed`). Before it, ice was drawn by the water shader as a band under the moving
waterline and collided by flat rectangles at the level it froze at, and the field zeroes a held
column. PZL-02 (ice outlives the drain), PZL-03 (a frozen crest ramp) and PZL-06 (a curved wall
against Redoma) all need ice with its own height per column. Decision: ice becomes a sheet of its
own: one band `[top, bottom]` per water column, captured when the column first takes ice, drawn by
its own quad above the water and collided by a chain of segments. Lands with PZL-02. Build order:
PZL-09 (`a-pool-rests-below-its-painted-reach`), PZL-02 (this), PZL-03
(`wind-piles-a-bounded-crest`), PZL-06 (`the-shell-displaces-water-into-the-reach`).

## Context

- `water_surface.gdshader` discards above the surface, its quad is the water's rect (`HEADROOM`
  12 px), and a dry body hides its quads: ice over drained water cannot be drawn by the water.
- `IceCollider.set_top()` lays every segment at one y; `WaterSurfaceField.set_hold(c, 1)` sets the
  height to 0. Neither can keep a crest or an arc.
- `RainBasin._physics_process` returns while `FreezableWater.is_frozen()`, so a frozen basin holds
  its level (`the-water-level-moves`).

## Options considered

- **Ice in the water shader, a second data texture for its top/bottom.** Still clipped by the
  water's rect and hidden with a dry body. Rejected.
- **Ice as a free 2D polygon** (arches, overhangs). Needs a clipper and a 2D growth front, and
  breaks the column-wise front/thaw contract (`IceFront`). Rejected: one band per column covers the
  shelf, the crest and the lower arc; what it cannot hold is in PZL-06's open questions.
- **Chosen: its own sheet.** Per-column band, own quad and shader, own collider chain.
- Collider: stepped rectangles per column (a body snags on every 1-2 px step of a slope); one
  `ConcavePolygonShape2D` (no per-part toggle while the thaw passes); **a chain of
  `SegmentShape2D`, one `CollisionShape2D` per `IceProfile.segment_width`** (chosen; the
  `FrostShell` ring is the precedent).
- Field hold: zero the column (today; flat ice only) vs **pin it at `height - swell`** (chosen:
  calm water pins about 0, so ordinary ice stays flat; a crest or a grey-water splash keeps its
  shape, as design 03 §6.2 says a crest does).

## Decision

- **`IceSheetShape`** (new, pure `RefCounted`, `freezable_water/ice_sheet_shape.gd`): per column
  `top`, `bottom` (world y), `present`. `capture(c, top, bottom)`, `release(c)`, `band(c)` with gap
  closing (`bottom >= neighbour's top`, so a steep run is one continuous face), `y_range()`,
  `segment_points(per_segment) -> PackedVector2Array` (count + 1 points; an endpoint is the mean of
  the two columns meeting there, whole px), `walkable(segment, max_angle) -> bool`.
- **`WaterSurfaceField`**: `_pinned` per column. The first `set_hold(c, h > 0)` pins
  `height - swell(c, last swell time)`; `hold == 0` unpins. A held column's target is
  `lerp(swell + offset, pinned, hold)`, so at hold 1 it sits on its target and couples nothing to
  its neighbours (still a wall). `pinned(c)`. `step(delta, rates, swell_time, offsets := [])`
  (offsets are PZL-03's; empty here).
- **`IceFront.advance(delta, rates, wet := PackedByteArray())`**: a reached column crystallises only
  while wet; the front crosses a dry column at the memory rate (dry is not dead). Empty `wet` is
  today's behaviour.
- **`WaterBody`** loses `_solidity`, `set_solidity`, `set_ice_thickness`; the texture's `a` is
  written 0 (`water_common.gdshaderinc` comment: unused); `water_surface.gdshader` loses
  `ice_ramp`, `ice_thickness` and the ice block, and `WaterLook.ice_ramp` moves to the sheet. Adds
  `ice_top(c) -> float` (rest line minus `pinned(c)`; INF where the column holds no water; PZL-06
  adds held columns), `wet_columns() -> PackedByteArray`, `is_frozen_at(x) -> bool` (field hold
  1).
- **`IceSheet`** (new `Node2D`, `ice_sheet.gd`, `ice_sheet.gdshader`; in
  `freezable_water.tscn` and `rain_basin.tscn`): `z_index` 51 absolute, authored in the scene with
  the constraint "above `WaterQuad.Z`: ice covers water". RGBAF texture per column: r top, g bottom
  (world y), b solidity. The shader discards outside the band, stipples by solidity on the texel
  Bayer grid (as the water's ice did), samples `ice_ramp` by depth from the top. No screen texture,
  no `TIME`, no `FRAGCOORD`. Its rect is the body's width by `y_range()`, re-laid only on
  capture/release. Greyed by the greyhush like any world pixel.
- **`IceCollider`**: `build(count)` makes disabled segments;
  `set_profile(points)` moves endpoints and sets `one_way_collision` (deferred) to
  walkable only (steeper than 45°, the engine's default `floor_max_angle`, is a two-sided wall);
  `set_solid(mask)` unchanged (deferred, on change). Endpoints move only while their segment is
  disabled: a column is captured at its first hold, long before `solid_at`; assert it. `set_top`
  goes. Stays `unsafe_ground`.
- **`FreezableWater`** (glue) per physics frame while active: `advance(delta, rates,
  wet_columns())`; `set_hold(c, hold)`; first hold > 0 captures `top = ice_top(c)`,
  `bottom = max(top, rest line) + thickness`; ice back to 0 releases. A capture or release re-lays
  the sheet and `set_profile`; solidity goes to the sheet; `set_solid(solid_segments())`.
- **PZL-02**: `RainBasin` refuses only a RISE while frozen (ice is a lid) and keeps draining:
  replace the `or is_frozen()` early return with `if target > _level and frozen: return`. Ice keeps
  its world height over the sinking water; thawed over air it is gone; over water the unpinned
  column is simply water again. `Floater` holds its y while `is_frozen_at(x)` (a log frozen in stays
  in the ice).
- No new signals: the receivers' `song_entered`/`song_left` stay the only events; everything else
  is state polled per physics frame. One writer each: `IceFront` the ice amounts and thaw clock,
  `IceSheetShape` the bands, `WaterBody` the water, `RainBasin` the commanded level.

## Consequences

- Rules kept: growth at the memory under the front, the thaw ignores memory (`IceFront`
  unchanged); `wc_held()`/`_refresh_dry()` untouched; deferred collision changes; the pause map
  gains nothing (sheet and collider are pausable, like the water).
- SOLID: the water no longer knows ice exists beyond a hold (single responsibility); a new ice
  shape is new data in `IceSheetShape`, not a branch in a shader (open/closed).
- Tests: new `ice_sheet_shape_test.gd` (flat capture is a flat chain, a wedge a constant slope, gap
  closing, 45° classification, `y_range`). `water_surface_field_test`:
  `test_full_hold_locks_a_column_flat` becomes `test_full_hold_keeps_the_shape_it_held` plus
  `test_full_hold_locks_calm_water_flat`; `test_a_frozen_column_is_a_wall` holds with a pinned
  crest. `ice_front_test`: dry column never freezes, the front crosses it, a column wet later
  freezes then. `rain_basin_test`: `test_frozen_it_holds_its_level` becomes
  `test_frozen_it_keeps_draining_under_its_ice` (the collider's endpoints do not move) and
  `test_frozen_it_does_not_rise`; ice over a drained column is gone after the thaw.
- Trial: none new. Spring trial #2 (the dry moat) already is Combinado 1; change its comment, re-run
  `song_rain_freeze_moat`, add `song_rain_freeze_moat_drain.json` (Congelar while full, wait: the
  shelf over sinking water, then a fall onto the dry floor once the thaw passes; the moat is
  climbable, so never a trap). Numbers unchanged: thaw 1.5 s + 48 px/s, so the 16-cell moat thaws
  in about 12 s; the drain is 4 s at memory 1 and about 11 s at the spring region's memory, so the
  two clocks are of one order.
- Risks: a column's band is captured while its surface still settles (at most 1 px for 0.1-0.3 s,
  hidden by the band). Seams between segments may snag; walk the moat in the playtest. Audit
  anything drawn at z 51. Today's playtests must still pass.
- When built, update `systems/water` (FREEZE and Chuva bullets: "ice is its own sheet",
  "drains under its ice") and CLAUDE.md's Water row if its never-break rule changes.
