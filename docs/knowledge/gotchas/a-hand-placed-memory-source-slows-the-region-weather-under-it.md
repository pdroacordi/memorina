---
id: gotchas/a-hand-placed-memory-source-slows-the-region-weather-under-it
type: gotcha
title: A memory patch added for set dressing also slows and weakens the region's weather, snow and sounds under it
status: active
tags: [greyhush, memory-field, weather, air, props, grass, sfx]
related: [systems/greyhush, systems/air, systems/props, systems/world, bugs/the-threshold-fields-memory-hold-stills-nothing-because-the-wheat-was-built-as-a-still]
created: 2026-11-23
updated: 2026-11-23
source_files:
  - scenes/world/environment/weather/weather_gust.gd
  - scenes/world/environment/weather/region_wind.gd
  - scenes/world/environment/wind/airflow.gd
  - scenes/world/rooms/threshold.tscn
---

## Summary

The memory field is one field. A `MemorySource` placed to hold props or grass still changes every reader of
`MemoryField.sample`, not only `AmbientMotion` and the grass. No source can be scoped to props alone.

## Details

- `WeatherGust.step` advances the regional gust clock by `delta * memory` at Ivo (`region_wind.gd`). `Airflow.sample`
  then scales the push by the memory at the body. Halving the memory halves both the clock rate and the push.
- Worked example, `FieldsStillMemory` (strength -0.15) in threshold_fields, `winter_blizzard.tres` (speed 220, calm
  6 s): at 0.3 the peak is 66 px/s and a calm lasts about 20 real s; at 0.15 the peak is 33 px/s and a calm lasts about
  40 real s. A walk-in restarts the gust at calm, so a player who crosses the 1920 px room meets no gust in it.
- `RegionWeather` (the snow), `SfxMuffle`, `WaterBody`, `RootGrower`, `ColorPulse` and `GreyhushShield` also sample the
  field (grep `.sample(` under `scenes/`).
- The only per-drawable threshold is `AmbientMotion.stop_threshold`. Raising it per prop would break the shared 0.2
  stop (`AmbientMath.STOP_THRESHOLD`, `systems/props` "Shared stop threshold").

## Gotchas / pitfalls

- Before adding a dressing patch, list every memory reader in its rect: weather, water, roots, sound. Record the side
  effects in `systems/air` (its "Today" numbers assume the region's baseline).
- In a winter region, generated grass has no blades (`density.z` 0), so a patch "for the grass" holds nothing outside
  a pulse.
- MEM-05's "Fixed per region (Recommended)" fixes the prevailing direction, not the strength. A patch does not break it.
