---
id: architecture/memory-runs-through-pause
type: architecture
title: A lesson freezes time, not memory - the memory layer runs through a pause
status: active
tags: [pause, process-mode, greyhush, lesson, cinematic]
related: [architecture/memory-field-cpu-gpu-split, features/regional-weather, bugs/creature-pass-frozen-transform-floats-bodies]
created: 2026-09-21
updated: 2026-09-22
source_files:
  - scenes/world/game.tscn
  - scenes/world/memory/color_pulse/color_pulse.tscn
  - scenes/world/environment/region_weather/region_weather.tscn
  - scenes/characters/guardians/guardian.gd
---

## Summary

`WorldFreeze.freeze()` pauses the tree for a performance. Until 2026-09-21 the rule was
that nothing in the memory layer processed during the pause (the renderer would re-push
uniforms from a frozen field, so why run it). A lesson made that rule the problem: a
restored guardian's lesson was a still frame for the length of a track. The decision:
TIME is what a performance freezes - bodies, clocks, motion driven by `MemoryClock` -
but MEMORY may move. `SeasonMask`, the `Greyhush` renderer, every `ColorPulse` and
`RegionWeather` are `PROCESS_MODE_ALWAYS`.

## Details

- What moves during a lesson, all from existing systems: the guardian's well of
  forgetting (`Corruption`, a negative `MemorySource`) tweens to 0 and the region's
  `MemoryField.baseline` tweens to 1.0 (`Guardian._lift_region`, pause-process tweens);
  the guardian's own pulse is born at the first cue with `lesson_pulse_stats` (12 s
  attack) so colour spreads for the whole track; `RegionWeather.speed_scale` follows the
  baseline, so petals frozen mid-air start to fall; `GameCamera.push_in` zooms slowly.
- `CreatureMask` belongs to the layer for a different reason: it MIRRORS the main
  viewport's canvas transform every frame, so a pausable copy renders every creature at
  the transform the pause froze - bodies floating off the floor as the lesson pushes in
  (`bugs/creature-pass-frozen-transform-floats-bodies`).
- What stays frozen: every `Character`, `MemoryClock`-driven environment, `SongArea`
  receivers (they catch up on thaw). `MemoryClock` remains pausable on purpose.
- The boundary is the rule to keep: a node joins the memory layer only if what it
  renders is memory (colour, weather intensity, the mask), never if it is time (the
  motion of a body, a swaying branch).

## Why

The lore already says it: colour is memory, grey is stopped time. A lesson is the moment
memory returns, so it is the one thing that should visibly move while the world holds
its breath.
