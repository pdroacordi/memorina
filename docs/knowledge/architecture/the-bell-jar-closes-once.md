---
id: architecture/the-bell-jar-closes-once
type: architecture
title: Redoma's shell closes when its pulse stops growing, and lets out only what was inside then
status: active
tags: [redoma, bell-jar, frost-shell, collision-exception, water, shelter, pulse-effect]
related: [architecture/one-air-channel, architecture/the-water-level-moves]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/memory/song_effects/shell/frost_shell.gd
  - scenes/world/environment/wind/disc_shelter.gd
  - scenes/world/environment/water/water_body.gd
---

## Summary

"Nothing enters, everything may leave" is one collision ring plus exceptions. The ring
(48 `SegmentShape2D` on its own physics layer) stays off while the pulse grows, so it never
sweeps into anything; when it closes, a shape query finds every Player/Props body inside and
excepts it, and each exception is dropped once the body is clear of the ring. A shrinking
ring only moves away from what is outside, so nothing is ever pushed.

## Details

- Creatures pass because the shell is on a layer only Ivo and loads collide with.
- Air: a `DiscShelter` registered with `Airflow`. Rain: `RainFall` and `RainBasin` ask
  `ColorPulse.lit(self, BELL_JAR)`.
- Water: `WaterBody.hold_out` marks columns dry (depth 0, the shaders clip them) and rebuilds
  the hazard as runs of wet columns, only when the dry set changes.

## Not yet

The water does not stand against the curve (no arc waterline), so there is no wall of water
for Congelar to freeze into an arch (Inverno Logico 2).
