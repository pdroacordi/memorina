---
id: features/regional-weather
type: feature
title: Regional weather and tint scale with the region's memory
status: active
tags: [weather, seasons, greyhush, particles, shader]
related: [architecture/memory-runs-through-pause, architecture/memory-field-cpu-gpu-split]
created: 2026-09-21
updated: 2026-09-22
source_files:
  - scenes/world/environment/region_weather/region_weather.gd
  - scenes/world/memory/seasonal/seasonal_particles.gdshader
  - scenes/world/memory/greyhush_common.gdshaderinc
  - scenes/world/memory/greyhush_renderer.gd
  - scenes/world/memory/memory_field.gd
  - resources/songs/song_catalog.gd
---

## Summary

`docs/design/03_mundo_e_ambiente.md` sections 5.1-5.2, implemented: a region's weather
exists everywhere and is frozen in the grey. `RegionWeather` mounts the region's palette
particle scene (the same one a pulse uses), follows the camera, and reads
`MemoryField.sample()` at the camera every frame - the region's baseline less any well
of forgetting, plus any pulse lit there. 0 is snow hanging in the air, 1.0 is the season
in full, and inside a pulse the flakes fall again (design section 5.1, for free). The
region's BASELINE (not the local sample) scales the season's tint on every remembered
pixel a pulse is not tinting (`region_tint`, `region_tint_amount`).

## Details

- `Game` sets `MemoryField.palette = SongCatalog.palette_for(region.season)` beside
  `season` and `baseline` on room entry. Nothing is authored twice on the region.
- `seasonal_particles.gdshader` gained `uniform bool ambient`: a pulse's particles survive
  only where the mask holds their season; ambient weather survives where the mask holds
  NO pulse (or its own season). `RegionWeather` duplicates the shared material to set it.
- **The grey must stay empty** (2026-09-22): a forgotten sky full of stopped specks reads
  as static. Memory drives three knobs that never restart the emitter (CPUParticles2D has
  no `amount_ratio` in 4.7; writing `amount` respawns the sky mid-lesson): `speed_scale`
  stops the fall, `modulate.a` fades to `quiet_alpha`, and `emission_rect_extents` is
  spread by `quiet_spread` so the same flakes scatter thin and most fall outside the
  frame. A thin band emitter (snow falling from somewhere) is lifted to the top of the
  visible frame; a screen-sized box (drifting petals) stays centred.
- Restoring a guardian tweens the baseline to 1.0 across the lesson, which is what wakes
  the weather - "a recompensa sensorial de ter restaurado o guardiao".
- Not built: any physical effect of weather on Ivo (section 5 wants wind and snow to
  push), weather-specific art beyond petals/snow/leaves, and per-region density.
