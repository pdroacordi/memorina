---
id: bugs/facade-doors-test-subtracts-the-room-origin-the-builder-keeps
type: bug
title: facade_doors_test computes a door's feet without the room's origin, so it misjudges any room whose origin is not 0,0
status: resolved
severity: low
tags: [tests, props, facades, rooms, origin, world-11]
related: [systems/props, systems/rooms]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - tests/scenes/world/environment/props/facade_doors_test.gd
  - scenes/world/rooms/maps/room_map_node.gd
---

## Summary

`facade_doors_test._doors` places each door at `(cell - map.origin)`, but `RoomMapNode._place` puts the
entity at `_solid.map_to_local(placed.cell)`, where `placed.cell` already includes the origin. In a room
whose `origin` is not `0, 0` the test's expected door feet are `origin * 32` px away from the real door.

## Symptom

Found in the WORLD-11 review (2026-10-10). Latent today: the four `village_valley` rooms all have
`origin = 0, 0`, and no other room has a facade. Ten rooms have `origin = 0, -16` or `0, -10`;
`trials_solstice/door_trial` and `door_trial_inside` have doors and a `Props` node. A facade placed
correctly on door_trial's door would fail `test_every_facade_stands_on_a_door` ("has no door"), and a
facade placed 16 rows below it would pass.

## Root cause

- `tests/scenes/world/environment/props/facade_doors_test.gd:24`: `var cell: Vector2i = placed.cell - map.origin`.
- `scenes/world/rooms/maps/room_map_node.gd:254`: `Rect2(_solid.map_to_local(placed.cell) - size * 0.5, size)`;
  `_solid_layer` (line 204) sets cells at `map.origin + Vector2i(x, y)` with the layer at position 0, so
  RoomMapNode-local position is `(origin + grid) * CELL_PX` (`docs/maps/README.md`: a character at row r,
  col c is at `((origin.x + c) * 32, (origin.y + r) * 32)`).

## Fix

Not fixed. Use `placed.cell` directly (`(cell.x + 0.5) * CELL_PX, (cell.y + 1) * CELL_PX`), and for
robustness compare in a common space (`RoomMap` node and `Props` node transforms), as the builder does.

## Prevention

Derive test positions from the same function the builder uses (e.g. a static helper on `RoomMapNode`
for an entity's anchor point) instead of re-deriving the formula.

## Fix (2026-10-10)

`facade_doors_test` uses `placed.cell` as the builder does (`map_to_local(placed.cell)`); the origin is no longer subtracted.
