---
id: bugs/a-log-frozen-over-draining-water-teleports-down-at-the-thaw
type: bug
title: A log frozen into a rain basin's ice snaps down by the whole drained depth in one physics frame when the thaw releases it
status: fixed
severity: low
tags: [floater, ice, rain-basin, freeze, pzl-02]
related: [architecture/ice-is-its-own-sheet, systems/water, architecture/the-water-level-moves]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - scenes/world/interactables/floater/floater.gd
  - scenes/world/interactables/rain_basin/rain_basin.gd
---

## Summary

PZL-02 lets a frozen `RainBasin` keep draining under its ice, and `Floater` holds its y while
`is_frozen_at(x)`. When the thaw drops the hold under 1, the floater is set straight to the
water's surface, or to its rest when the basin is dry. It moves down the whole distance the
water sank, in one frame.

## Symptom

Found by code reading in the PZL-02 review; not played. In spring trial puzzle 1 (the dry
basin with the log, a `rain_basin.tscn`, so it freezes), play Chuva, then Congelar while the
log rides high. Then wait. The rain's pulse leaves, the water sinks under the ice, and the log
stays in the ice. When the thaw front reaches the log's column (`IceFront.hold` < 1, about
0.33 s into its 0.5 s melt), the log reappears at the sunken waterline or on the basin floor
the next frame, as much as the basin's depth lower. If Ivo stands on it, he is left in the air.

## Root cause

`Floater._physics_process` (floater.gd:27-34) has no motion of its own. Every frame it assigns
`global_position.y` to the target: `_ride_y` while frozen, then
`minf(_rest_y, roundf(surface_y + draft))`. Before PZL-02 a frozen basin held its level
(`RainBasin` returned while `is_frozen()`), so the target at the thaw was where the log
already was. Now `rain_basin.gd:52` keeps draining under the ice, which puts the target
anywhere down to the floor.

## Fix

Fixed before commit (2026-10-07): `Floater` sinks toward the water under it at `sink_speed` (240 px/s) instead of jumping there; it still rises with the water at once. `rain_basin_test.test_a_log_the_ice_lets_go_sinks_rather_than_jumps`.

Open. Give `Floater` a fall: move toward a lower target at a capped speed (or gravity),
and keep the snap only for rising, which the water already paces.

## Prevention

Add a `rain_basin_test` or floater test: freeze with a floater afloat, drain, thaw, and
assert that its y never changes by more than a few px per physics frame.
