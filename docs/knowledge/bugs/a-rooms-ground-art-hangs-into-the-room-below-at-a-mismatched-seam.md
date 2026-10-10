---
id: bugs/a-rooms-ground-art-hangs-into-the-room-below-at-a-mismatched-seam
type: bug
title: A room's dual-grid ground draws 16 px past its edges, so where the next room's edge cell is air a band of ground with no collision hangs in that room
status: active
severity: medium
tags: [rooms, dual-grid, tiles, seam, residency, world-07, aesthetics]
related: [architecture/biome-tilesets, systems/rooms, systems/world, bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/maps/room_tile_resolver.gd
  - scenes/world/rooms/maps/room_map_node.gd
---

## Summary

On the dual grid each room's display layers cover half a cell past every map edge, and the
out-of-map corners copy the edge cells (`RoomTileResolver._look`). Neighbouring rooms run and
draw (`RoomResidency`). Where an upper room's bottom row is solid and the lower room's top row is
air, the upper room draws a 16 px band of fill into the lower room, below its own collision.

## Symptom

Found in the WORLD-07 review (uncommitted, 2026-10-10) by scanning every pair of touching rooms
in the region scenes for edge cells that disagree. Upper room bottom solid over lower room top
air, in columns:

| Upper | Lower | Columns |
|---|---|---|
| woods_canopy | woods_deep | 43 |
| orchard_well | woods_canopy | 39 |
| lighthouse_top | lighthouse_base | 38 (the whole sky of the base) |
| orchard_windy_gap | orchard_mill_town | 19 |
| lake_chasm | orchard_well | 19 |
| orchard_terraces | woods_canopy | 11 |
| orchard_counterweights | orchard_mill_town | 11 |
| orchard_chasm_bridge | orchard_terraces | 11 |
| village_bell_tower | village_square | 8 |
| lake_waterfall_path | village_mill | 7 |

When the camera is at the top of the lower room (it shows the top 16 px, and yields further
over a running neighbour), a flat-cut strip of the upper room's ground hangs across the
sky. Ivo's head enters 16 px of drawn ground before it meets the collision at the seam.
Before WORLD-07 the upper room's bottom row was drawn inside its own cell, so nothing showed
below the seam.

Across a region seam (lake_chasm over orchard_well) the strip will also be the wrong biome
once those regions get their own `tileset`.

## Root cause

- `room_tile_resolver.gd:44-51`: rows below the map repeat the bottom row and x clamps into the
  map. Display row `j = h` and columns `i = 0` and `i = w` are tiles whose outer half lies in
  the neighbouring room.
- `room_map_node.gd:80-98` draws every display cell, including that outer half, with no clip
  to the room's rectangle.
- The plan accepted this on the condition that "maps that meet must agree at the shared
  edge" (`architecture/biome-tilesets`, Consequences). Nothing enforces that condition, and
  the current world does not meet it.

## Fix

Open. Options:
- **Preferred:** clip each room's display layers to its own rectangle, as
  `bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room` did for backdrops
  (`room_rect`). The out-of-map corners still shape the in-map half; only the outer half is
  not drawn. This removes the cross-biome overlap too.
- **Or:** add a world test asserting that touching rooms agree on their shared edge cells,
  then edit the maps until it passes. This keeps the double draw and leaves biome seams
  unsolved.

## Prevention

Add a world-level test (`tests/scenes/world/rooms/`) that loads the region scenes and checks
every shared edge. Keep it after a clip lands, so a seam mismatch stays visible as a known
fact. The review scan was a 60-line script over the region `.tscn` positions and the
`.room` grids.

## Resolution (2026-10-10)

`seasonal_art.gdshader` gained `clip_rect` (world px; a fragment outside is discarded, `MODEL_MATRIX * VERTEX` gives its world position). `RoomMapNode._clipped()` gives each room's ground and back layers a duplicate of their material clipped to the map's world rect, so the half tile drawn past an edge never shows in the running neighbour. `room_map_node_test.test_the_ground_is_clipped_to_the_map` pins the rect. On-screen check pending (lighthouse_base sky).
