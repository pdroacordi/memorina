---
id: gotchas/queue-free-keeps-the-name-until-frame-end
type: gotcha
title: A queue_free()d node keeps its name until the frame ends, so a same-frame replacement is renamed @Type@N
status: active
tags: [node-names, queue-free, rebuild, nodepath, scene-tree]
related: [bugs/room-map-node-rebuild-renames-and-doubles-its-children]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/rooms/maps/room_map_node.gd
---

## Summary

`queue_free()` only schedules the deletion. The node stays in its parent, with its name,
until the end of the frame. If you add a replacement with the same name in that frame,
`add_child()` resolves the clash by giving the NEW node a generated name like
`@TileMapLayer@2`, not `Ground2`. The generated name stays after the old node is gone.

## Details

Measured on 4.7.2: a rebuild that freed `Ground` and `Water_w` and added new nodes with
the same names left `["@TileMapLayer@2", "@TileMapLayer@3"]` two frames later. Anything
that addresses the replacement by name then breaks: `get_node("Ground")`, and any
`NodePath` built from a name (`"../gate_a"`). During the frame it resolves to the dying
node, and afterwards to nothing.

## Gotchas / pitfalls

- For a same-frame replacement, call `remove_child(node)` and then `node.queue_free()`.
  Removing it releases the name immediately.
- `add_child(node, true)` (force readable name) gives `Ground2` instead. That is still
  not the name you asked for.
