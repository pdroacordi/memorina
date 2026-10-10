---
id: bugs/the-room-shell-generator-writes-pre-world-07-rooms
type: bug
title: gen_world_shells.py still writes a .room with no `tileset =` and a contents scene with the removed `ground_material`, so every new room fails to import
status: active
severity: low
tags: [tools, rooms, world, generator, world-07, migration]
related: [architecture/biome-tilesets, systems/world, systems/rooms, gotchas/a-failed-import-is-cached-and-not-retried]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - tools/maps/gen_world_shells.py
---

## Summary

WORLD-07 migrated the 66 generated `.room` files and contents scenes by hand. The generator
that wrote them still writes the old format. The next room added to its tables gets output that
breaks the import and the smoke test.

## Symptom

Found in the WORLD-07 review (uncommitted, 2026-10-10). `systems/world` says how to add a room:
"add its row and openings, run the tool". Doing that now produces:
- a `.room` whose `[room]` has only `origin = 0, 0`. The parser reports
  `no 'tileset' in [room]`, the import fails, and the failure is cached
  (`gotchas/a-failed-import-is-cached-and-not-retried`);
- a contents scene that sets `ground_material = ExtResource("tiles_season")`, a property
  `RoomMapNode` no longer has. That stale property is the warning the smoke test fails on.

## Root cause

- `tools/maps/gen_world_shells.py:222-238` (`room_text`) writes no `tileset =` line.
- `tools/maps/gen_world_shells.py:313-327` (`contents`) still declares the
  `floor_tiles_seasonal_material.tres` ext_resource and sets `ground_material` on the
  `RoomMap` node.

## Fix

Open. In `room_text`, write `tileset = legacy` after `origin` (or the region's biome once it
has one). In `contents`, drop the material ext_resource and the `ground_material` line.

## Prevention

When a migration edits generated files by hand, update their generator in the same change.
A check that runs the generator into a temporary directory and parses its output would catch
it.

## Resolution (2026-10-10)

`tools/maps/gen_world_shells.py` writes `tileset = legacy` in every new `.room` and no longer writes the material ext_resource or `ground_material` in contents scenes.
