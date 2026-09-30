---
id: architecture/water-two-projections
type: architecture
title: Water in a pit is a cross-section; water in front of the land is a plane - two shaders, one body, painted with tiles
status: active
tags: [water, lake, pool, shader, tilemap, authoring, performance]
related: [architecture/water-is-world-art-reflecting-two-passes, architecture/memory-gated-height-field, bugs/lake-clock-runs-at-the-fastest-memory-across-the-room, gotchas/tilemaplayer-enabled-does-not-hide-children]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/environment/water/water_lake.gdshader
  - scenes/world/environment/water/water_surface.gdshader
  - scenes/world/environment/water/water_reflection.gdshaderinc
  - scenes/world/environment/water/water_body.gd
  - scenes/world/environment/water/water_layer.gd
  - scenes/world/environment/water/water_basins.gd
---

## Context

The first round drew every body of water as a CROSS-SECTION (a waterline profile, see-through by
depth). The user placed one in front of the ground and it read as a dark slab pasted over the dirt,
not as a lake beside the path. Their reference (pixel-art foreground water) is a straight light line,
the scene mirrored under it in horizontally shifted rows with light dashes, and nothing below it.
They also asked whether water should be authored some other way than a scene with a typed size
("maybe tiles"), and whether it performs.

## Options considered

- **Tune the pool shader for the strip.** The problem was the projection, not the numbers: a waving
  profile at the top edge says "seen from the side", and transmission shows the dirt behind it.
- **A `projection` flag on WaterLook / WaterBody.** One shader with two modes, and a flag every
  branch would read.
- **Chosen: two shaders over the same body.** `water_surface` (pool, cross-section) and `water_lake`
  (plane seen from above), sharing the mirror (`water_reflection.gdshaderinc`) and the
  column/floor/ramp code (`water_common`). The scene chooses: `water_pool.tscn` vs `water_lake.tscn`.
- **Authoring:** a node with editor resize handles (cheap, but alignment with pits stays manual - the
  first round shipped a pool floating on flat ground) vs **painting** (chosen by the user): a
  `WaterLayer` of 16 px cells, built into bodies at runtime by `WaterBasins`.

## Decision

- **A lake has no WaterProfile.** Nobody sees its waterline edge-on, so it simulates nothing; its
  waves are the reflection tearing into row bands that grow toward the viewer (`band_of()` integrates
  1/height so each band is as tall as its rows say) plus 1 px glints. It is opaque and must run to the
  frame's bottom and off the room's sides - it has no shore art for its ends.
- **A lake keeps a clock per column** in the data texture's r (unused without a field): a room-wide
  lake on one clock ran its grey end at the pace of its remembered end
  (`bugs/lake-clock-runs-at-the-fastest-memory-across-the-room`). Discrete re-rolls (shore dashes,
  glints) read the column clock; the bands' slide keeps the shared clock, since a slide out of step
  between columns would tear the reflection permanently (the phase scar), and grey water gates the
  reflection away anyway.
- **Painting.** `WaterBasins` (pure, tested) reads cells as poured water: one flat surface per
  4-connected group at its top row, each run of surface columns a body, each column's depth its
  unbroken run of cells - a stepped basin is one body with a stepped floor (b channel, clipped by
  every shader). Unreachable cells are warned, not drawn. The layer instances its preset's
  `body_scene` per basin; the mirror axis is derived from `surface_inset` (-inset/2).

## Consequences

- Measured (windowed D3D12, 2026-09-23): two pools on screen add ~0.03 ms GPU including the extra
  screen copy; the GDScript spring field costs ~1.6 us per column per frame plus ~0.35 us upload (a
  192 px pool ~0.19 ms). Lakes, the widest water, cost only their clocks and an upload of one texel
  per 16 px.
- The editor preview is the painted swatch; the shaded water only exists at runtime.
- Rule: a lake that ends mid-screen reads as a rectangle. Run it off the room or end it behind art
  drawn above z 50.
