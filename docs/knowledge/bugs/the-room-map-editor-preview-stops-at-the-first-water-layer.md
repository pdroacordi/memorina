---
id: bugs/the-room-map-editor-preview-stops-at-the-first-water-layer
type: bug
title: In the editor, RoomMapNode._pour assigns the non-exported WaterLayer.solid_at on a placeholder instance, so the build aborts and a room with water previews no secret walls and no entities
status: resolved
tags: [room-map, tool-script, editor, placeholder, water, secret, world-20, world-21]
related: [gotchas/a-tool-script-cannot-call-methods-on-a-non-tool-resource, bugs/the-backdrop-editor-preview-calls-methods-on-placeholder-resources, architecture/secret-false-walls, systems/rooms, systems/water]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/maps/room_map_node.gd
  - scenes/world/environment/water/water_layer.gd
---

## Summary

`RoomMapNode` is `@tool`; `WaterLayer` is not. In the editor the water preset is instantiated with a placeholder script, and `_pour` sets `layer.solid_at`, a plain `var` the placeholder does not know. The assignment errors and aborts `_build`, so nothing after the first water layer is built: no `Secret_*` walls (WORLD-21) and no `Entities`. Runtime and GdUnit are unaffected.

## Symptom

Reproduced on 4.7.2 (WORLD-21 review, 2026-10-10) with `"$GODOT" --headless --editor --path . res://scenes/world/rooms/frozen_lake/contents/lake_well_contents.tscn --quit-after 900`:

```
SCRIPT ERROR: Invalid assignment of property or key 'solid_at' with value of type 'Callable' on a base object of type 'TileMapLayer (WaterLayer)'.
   at: RoomMapNode._pour (res://scenes/world/rooms/maps/room_map_node.gd:218)
```

Every room that pours water is affected, including all three rooms with secrets (`caldera_cistern`, `lake_well`, `winter_trial`). The plan's editor view ("drawn at alpha 0.5 so the author sees the hollow") never appears.

## Root cause

`room_map_node.gd:218` (added in 44aa86d, WORLD-20) writes `layer.solid_at`. `water_layer.gd:20` declares it as `var solid_at := Callable()`, not exported. A placeholder script instance accepts only the script's exported properties, so the write fails. Earlier writes in `_pour` are native (`set_cell`, `tile_set`) and succeed.

## Fix

Not fixed. Either skip the write in the editor (`if not Engine.is_editor_hint():`; `solid_at` only matters when `WaterLayer._ready` builds bodies at runtime), or make `WaterLayer` `@tool` with its `_ready` guarded. The first is smaller.

## Prevention

A `@tool` builder may write only exported properties of the non-tool nodes it instantiates (`gotchas/a-tool-script-cannot-call-methods-on-a-non-tool-resource`). After touching `RoomMapNode`, open one room with water in the headless editor (command above) and check the log.

## Fix (2026-10-10)

`RoomMapNode._pour` sets `WaterLayer.solid_at` only outside the editor; the editor preview draws covered columns without their sealed-pocket waterline, which it never showed anyway (water is runtime only).
