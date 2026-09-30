---
id: gotchas/duplicate-copies-script-built-unowned-children
type: gotcha
title: Node.duplicate() copies children a script built (owner null) too, so a node that builds in _ready() ends up with two sets
status: active
tags: [duplicate, owner, tool-script, ready, scene-tree]
related: [bugs/room-map-node-rebuild-renames-and-doubles-its-children]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/rooms/maps/room_map_node.gd
---

## Summary

A node's owner decides what `PackedScene.pack()` (and so a scene save) keeps. Unowned,
script-built children are skipped along with their whole subtree. `Node.duplicate()` does
not work that way: it copies every child, owned or not. If the node rebuilds its children
in `_ready()`, the copy gets the duplicated children plus a freshly built set.

## Details

Measured on 4.7.2 with `RoomMapNode`: `duplicate()` of a built node, added to the tree,
had `["Ground", "Water_w", "@TileMapLayer@4", "@TileMapLayer@5"]`. That is two ground
TileMapLayers, both colliding, and two water layers.

## Gotchas / pitfalls

- "Unowned, so it is never saved" is true for scene saves and false for `duplicate()`.
  Do not rely on the owner to mean "derived, rebuild me".
- A builder that must survive `duplicate()` should free what it did not build before it
  builds, or build under one container node it replaces as a whole.
