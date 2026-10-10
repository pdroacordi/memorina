---
id: bugs/a-neighbour-room-in-another-region-runs-on-the-current-regions-memory
type: bug
title: A running neighbour room in another region samples the current region's baseline, and the season flips under the glide
status: mitigated
severity: medium
tags: [rooms, residency, greyhush, memory-field, region, season, seam, world-05]
related: [systems/rooms, systems/greyhush, systems/seasonal-art, systems/air, bugs/a-neighbour-room-has-no-ground-until-ivo-enters-it]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/game.gd
  - scenes/world/rooms/room_residency.gd
  - scenes/world/memory/memory_field.gd
---

## Summary

`MemoryField` holds one baseline, season and palette: the current room's region's. Since 2026-10-09 rooms that touch
the current room keep running even across a region seam, and a seam crossing no longer hides behind a fade. So a
neighbour region's contents simulate on the wrong baseline, and the old region's visible art switches season on
the frame the feet cross.

## Symptom

Found in review. Region seams on the world grid include village_mill / lake_waterfall_path (baselines 0.8 / 0.3) and
woods_canopy / orchard_terraces (0.4 / 0.25).
- Gameplay off screen: with Ivo in the village, the lake room next door runs `WindZone._time` (`wind_zone.gd:55`),
  `WaterBody` column clocks (`water_body.gd:560-567`) and `Airflow` wind on `AirflowBody` holders (BruteShadow,
  HangingLoad) at 0.8 instead of 0.3.
- On crossing: the baseline eases over 0.45 s, so for that time the new region's wind and water near Ivo run at a
  blend of the two baselines.
- Visual: `_memory_field.season` and `palette` change on the crossing frame while `GameCamera` is still gliding over
  the old room. `seasonal_art.gdshader:28` and `backdrop_layer.gdshader:74` read `greyhush_region_season`, so the old
  room's seasonal art and backdrops jump to the new region's band, and `RegionWeather` remounts its particles
  (`region_weather.gd:23`).

## Root cause

`Game._enter_room` (`game.gd:93-96`) writes one region's state into the global field, which was correct only while
the current room was the one running and visible room. `RoomResidency.touching` ignores regions.

## Fix

Not fixed. Options: give `MemoryField` a per-region baseline that `sample()` picks by point (the region owning the
room at that point), with the shader still using the current one; or restrict running neighbours to the current
region and keep only a collision-only shell across a region seam. For the visual, ease or delay the season/palette
switch with the camera glide.

## Prevention

Anything that runs outside the current room must not read region-scoped globals. When residency grows, check
`MemoryField.sample()` callers and `greyhush_region_season` readers.

## Resolution (2026-10-09)

A region seam now cuts: `Game._physics_process` glides only when the new room is in the same region and touches the old one; otherwise `_enter_room(room, false)` + `GameCamera.snap()` set the baseline, season, palette and bounds on one frame, so nothing shows mixed and Ivo keeps moving. Still open: a neighbour in another region runs off screen on the current region's memory (its wind and water clocks); accepted until the memory field has a per-region baseline.
