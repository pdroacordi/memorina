---
id: architecture/one-air-channel
type: architecture
title: One air channel - Airflow sums every moving air into a velocity that bodies steer toward
status: active
tags: [wind, gale, vendaval, physics, locomotion, water, songs]
related: [architecture/rooms-are-text, architecture/memory-field-cpu-gpu-split]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/environment/wind/airflow.gd
  - scenes/characters/components/airflow_body.gd
  - scenes/characters/components/locomotion_component.gd
  - scenes/world/environment/wind/wind_zone.gd
  - scenes/world/memory/song_effects/gale/gale_field.gd
  - scenes/world/memory/song_effects/gale/gale_shape.gd
  - scenes/world/rooms/maps/jump_reach.gd
---

## Summary

Design 03 wants wind, current, the Vendaval song and the weather to push through "o mesmo
canal fisico". `Airflow` is that channel: sources register, `sample(point)` sums their air
as a VELOCITY scaled by the memory at the point, shelters zero it. `AirflowBody` hands it
to its body before the body moves; a `Character` accumulates it as `carry()` and its
locomotion steers toward input speed plus wind.

## Why a velocity and not a force

The first model added `wind * delta` to velocity after locomotion. Locomotion brakes at a
capped rate toward the input speed, so a force below the cap did nothing (measured: 900
px/s^2 moved a running jump by 15 px/s) and a force above it accelerated without bound.
Steering toward `input + wind` is bounded and reads the way wind should: a tailwind carries
a jump further, a headwind shortens it, and a body with no input drifts at the wind's speed
in the air. On the ground a deadzone and a grip fraction keep a breeze from moving feet -
which is exactly design 5.4's "execution breaks only past a threshold of force", for free,
through `is_still()`.

## Consequences

- Composition is arithmetic: a gale played into a current adds to it; a shelter cancels
  both; memory freezes all of them; water reads the same channel.
- A fully radial gale lifted a jumping body ever higher the higher it went (it launched off
  the top of the frame); the gale blows mostly along the ground (`GaleShape.VERTICAL_SHARE`).
- Reachability tests use the same numbers: `JumpReach.wind` is a Callable of the air along
  the arc, steered as `air_update` steers, so a trial room's gap is proven, not guessed.
