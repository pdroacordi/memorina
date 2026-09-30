---
id: bugs/room-map-node-rebuild-renames-and-doubles-its-children
type: bug
title: RoomMapNode's rebuild renames what it builds to @Type@N, and duplicate() doubles the ground, water and entities
status: active
severity: low
tags: [room-maps, tool-script, editor, node-names, duplicate, rooms]
related: [architecture/rooms-are-text, gotchas/queue-free-keeps-the-name-until-frame-end, gotchas/duplicate-copies-script-built-unowned-children]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/rooms/maps/room_map_node.gd
  - scenes/world/rooms/maps/entity_params.gd
---

## Summary

`RoomMapNode._build()` frees what it built with `queue_free()` and adds the
replacements in the same frame. The old nodes still hold their names, so every
replacement gets renamed (`Ground` becomes `@TileMapLayer@2`) and keeps that name.
Entity `id` links (`EntityParams`, `"../<id>"`) resolve to the node being freed. Separately,
`Node.duplicate()` copies the unowned built children and the copy's `_ready()` builds
another full set, so the ground, water and entities are doubled.

## Symptom

This is the reproduction, headless on 4.7.2, from `woods_contents.tscn`:

- Built: `["Ground", "Water_w"]`.
- `node.map = node.map` (what the inspector does when `map` is reassigned), same frame:
  `["Ground", "Water_w", "@TileMapLayer@2", "@TileMapLayer@3"]`.
- Two frames later: `["@TileMapLayer@2", "@TileMapLayer@3"]`. The readable names are gone
  for good.
- `node.duplicate()` added to the tree: `["Ground", "Water_w", "@TileMapLayer@4",
  "@TileMapLayer@5"]`. That is two ground TileMapLayers with collision and two water
  layers (and two of every entity in a room that has any).

At runtime nothing reassigns `map` or duplicates a RoomMapNode yet. So today this shows
up only in the editor preview, where reassigning `map` breaks the preview's names and
`id` links. Any future runtime rebuild (a reset room, a room built by code) or duplicate
would get a doubled room, or links that point at freed nodes.

## Root cause

- `room_map_node.gd:70-72`: `queue_free()` without `remove_child()`. A queued node stays
  a child, with its name, until the end of the frame. `add_child()` of a same-named node
  then falls back to an `@Type@N` name
  (`gotchas/queue-free-keeps-the-name-until-frame-end`).
- `EntityParams.apply` sets `node.name = id` before `_adopt()`, so the same collision
  renames the link target. A sibling's `NodePath("../id")` then resolves to the old,
  dying node.
- `duplicate()` copies children whatever their owner
  (`gotchas/duplicate-copies-script-built-unowned-children`). `_ready()` has no guard
  against children that were already built.

## Fix

Open. In `_build()`, call `remove_child(node)` before `node.queue_free()` so the names
are free immediately. To cover `duplicate()`, `_ready()` can free any children it did
not build before building (or build under one private container node that it replaces
as a whole).

## Prevention

A parser-level suite cannot catch this. A small scene test would: instantiate a contents
scene, reassign `map`, and assert the child names and count. The same goes for anything
else that builds children in `_ready()` from an exported resource.

## Revision (2026-09-30)

A later review confirmed that the code is already fixed. The "Open" status above was
out of date when this entry was written. Commit 4ecd877 changed `RoomMapNode._build()`
(room_map_node.gd:81-83) to `remove_child(child)` before `child.queue_free()`, and to
remove EVERY child, not only the ones it built. That keeps the fresh nodes' names and
`id` links, and it also clears the children a `duplicate()` copied before `_ready()`
builds again. No scene test locks this in yet (see Prevention).
