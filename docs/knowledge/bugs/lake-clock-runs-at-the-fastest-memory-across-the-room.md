---
id: bugs/lake-clock-runs-at-the-fastest-memory-across-the-room
type: bug
title: A room-wide lake runs its whole clock at the FASTEST memory anywhere along it, so the part lying in a well of forgetting moves at the baseline's speed
status: fixed
severity: low
tags: [water, lake, greyhush, stopped-time, memory-field, shader, clock]
related: [architecture/memory-gated-height-field, architecture/water-is-world-art-reflecting-two-passes, architecture/the-region-owns-its-forgetting]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/environment/water/water_body.gd
  - scenes/world/environment/water/water_lake.gdshader
  - scenes/world/rooms/home_village/contents/downtown_contents.tscn
  - scenes/world/rooms/home_village.tscn
---

## Summary

A lake (a `WaterBody` with no `WaterProfile`) moves ONLY by the shader's reading of
`water_time`, and `water_time` advances at `max(column rates)` over the whole body.
Lakes are painted room-wide on purpose. So in Downtown, the part of the lake inside
`DowntownWell` (memory about 0.1) runs its clock at the baseline's 0.8. That is 8x
faster than its memory, and design 03 §2 says a place's clock advances at the rate
that point is remembered. The lake shader's header claims the opposite: "crawls where
the lake is forgotten and stops where it is dead".

## Symptom

Found in review of 1c5117f..dbfacbf. Reasoned from the level data, not captured
in the engine.

- `home_village.tscn`: `RegionMemory.authored = 0.8`, and `DowntownWell` sits at the
  origin with radius 500, feather 140 and strength -0.7, so memory inside it is about 0.1.
- `downtown_contents.tscn` `Lake`: painted cells x -86..1 at 16 px, which is world
  x -1376..32. Every column west of about x -640 reads 0.8.
- With the camera near the pit (screen x about -320..320), every lake pixel on screen
  is at about 0.1. The reflection and glints are gated off there (0.1 is below
  `reflect_memory_low` 0.15), so the visible symptom is the far-shore light line: its
  12 px dashes open and close at `water_time * 0.25`, which is 8x the rate the water
  under them remembers. A lake that crosses the edge of a pulse or a well shows the same
  thing in the stippled 0.15..0.6 band, where the reflection's slats slide at full speed.

## Root cause

- `water_body.gd:123-128`: `fastest = max(_rates)` and then `_time += delta * fastest`.
  There is one clock per body.
- `architecture/memory-gated-height-field` accepted this for pools ("the grey columns
  chase a full-speed swell with slowed springs, so their swell is smaller rather than
  slower"). A pool, though, still has a per-column spring field under the shared clock.
  A lake has nothing per-column: every moving thing it draws (band shift and dip
  `water_lake.gdshader:101-103`, glints `:116-120`, shore-line dashes `:133`) reads the
  single uniform. And a lake is designed to be the widest water, so it is the body
  most likely to straddle a memory gradient.

## Fix

Fixed in 7cfe1fe with option 3, applied only where a phase scar cannot show:

- Each lake column keeps its own clock (`WaterBody._clocks`, advanced at that column's rate) in the
  data texture's r. Lake columns are one painted cell wide (16 px), so a dash of the shore line is
  one column and never straddles two clocks.
- The shore line's dashes and the glints are discrete re-rolls, so columns drifting out of step is
  invisible in them; they read the column clock and stop where the lake is dead.
- The bands' slide and dip stay on the body's shared clock. A per-column slide would shear the
  reflection permanently once memory returns (the scar), and in grey water the reflection is gated
  away, so the shared clock's speed never shows there.
- A lake no longer reads memory off screen.

## Prevention

A lake's shader header should not promise per-pixel stopped time while it has one
clock. Any cosmetic driven by a body-wide clock should be gated by `awake` at its own
pixel, so that the clock's speed cannot show where memory says nothing should move.
