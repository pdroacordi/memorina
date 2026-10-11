---
id: gotchas/scene-state-lists-only-the-properties-a-scene-file-sets
type: gotcha
title: SceneState lists only the properties a scene file writes for a node, not the instanced scene's own values
status: active
tags: [godot, packed-scene, scene-state, tools]
related: [architecture/room-reachability-audit]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/maps/reach/reach_world_loader.gd
---

## Summary

`PackedScene.get_state()` returns one entry per node, and each entry holds only the properties that `.tscn` file stores for that node. An instanced child that does not override `position` has no `position` entry, even if the instanced scene's root sets one.

## Details

- `ReachWorldLoader.load_world` reads each region's `position` from `game.tscn`'s state with a `Vector2.ZERO` fallback, then writes it to the freshly instanced region (`reach_world_loader.gd:26`).
- If a region scene ever gave its own root a position, and `game.tscn` did not override it, the loader would reset that region to the origin.
- Today no region root sets a position (checked 2026-10-11). The loader now falls back to the region's own position (fixed 2026-10-11).

## Gotchas / pitfalls

When a node is instanced, keep its own value as the fallback, and write only when the state has an entry:

```gdscript
region.position = _property(state, i, &"position", region.position)
```

`get_node_instance(i)` returns the instanced `PackedScene`. Read that scene's own state for the values it defines.
