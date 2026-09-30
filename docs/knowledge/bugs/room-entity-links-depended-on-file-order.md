---
id: bugs/room-entity-links-depended-on-file-order
type: bug
title: A room entity linked to one listed after it was never linked
status: active
tags: [room-map, entities, nodepath, ready, mechanism, pressure-plate]
related: [gotchas/queue-free-keeps-the-name-until-frame-end]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - scenes/world/rooms/maps/room_map_node.gd
  - tests/scenes/world/rooms/maps/room_map_node_test.gd
---

## Summary

`RoomMapNode` added entities one by one, and each ran `_ready` on `add_child`. A lift
listed before the plate it follows resolved `trigger_path` to nothing and was never
linked. The summer door worked only because its plate came first.

## Details

Found in the autumn trial playtest: the counterweight fell on its plate, the lift never
rose. Fix: entities are filled into one `Entities` node OUTSIDE the tree and added whole,
so all are in the tree before any runs `_ready`. `room_map_node_test.gd` builds a gate
listed before its plate and checks the plate's `activated` is connected.
