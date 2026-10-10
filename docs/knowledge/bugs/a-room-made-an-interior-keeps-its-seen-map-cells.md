---
id: bugs/a-room-made-an-interior-keeps-its-seen-map-cells
type: bug
title: A surface room turned into an interior keeps its map_seen bytes under the same SceneKey, so the map draws it as a lone patch in the interior band
status: active
severity: low
tags: [map, save, scene-key, interiors, world-20, save-compat]
related: [systems/map, systems/rooms, systems/world, architecture/doors-and-interiors]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/ui/map/map_screen.gd
  - scenes/ui/map/map_revealer.gd
  - scenes/world/rooms/home_village/village_bell_tower.tscn
---

## Summary

WORLD-20 moved `village_bell_tower` from a surface room (640, -1152) to an interior (9600, 12000)
and kept its scene uid (`uid://bcfix7snx77at`) on purpose. A save that had seen tower cells still
holds `map_seen["uid://bcfix7snx77at"]`, and `MapScreen` draws it at the room's new bounds.

## Symptom

Found in the WORLD-20 review (uncommitted, 2026-10-10), from the code. Not reproduced in a run.
Load a save written after WORLD-05 in which Ivo climbed the bell tower, then open the map:

- a patch of the tower's seen cells is drawn alone at y 12000..13152, under the village. Design 04
  section 4 says "Interiores não aparecem no mapa".
- `MapCanvas.seen_rect()` grows to take it in, so the pan clamp lets the view travel about 12000 px
  down into empty map.

The bounds keep their size (640x1152), so `MapGrid.from_bytes` accepts the old bytes and the
patch builds.

## Root cause

- `map_screen.gd:115-131` (`_seen_patches`) draws every room in `Room.GROUP` that has bytes,
  with no `room.interior` check.
- Only `MapRevealer.reveal_room` (`map_revealer.gd:28-31`) skips interiors. It stops new
  cells from being written but does nothing about bytes already in the save.
- Map data is keyed by `SceneKey` and placed at the room's current bounds (`systems/rooms`,
  "a region that moves keeps its map"). That is what we want when a room moves, and wrong when
  a room stops being on the map.

## Fix

Not fixed. Suggested: `_seen_patches` skips `room.interior`, so the draw side follows the same
contract as the reveal side whatever the save holds. A `PlayerData.migrate()` erase of one
key also works, but every later surface-to-interior change would need another.

## Prevention

When a room's `interior` flag changes, its `SceneKey` data changes meaning too. Before you keep
the uid, check every save dictionary keyed by `SceneKey` (`map_seen`, `bench_room`, `deaths`
for regions). Keep the map's draw side and reveal side on the same predicate.

## Fix (2026-10-10)

`MapScreen._seen_patches()` skips interiors, as `MapRevealer` already did.
