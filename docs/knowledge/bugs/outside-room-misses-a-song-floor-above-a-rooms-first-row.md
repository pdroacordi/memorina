---
id: bugs/outside-room-misses-a-song-floor-above-a-rooms-first-row
type: bug
title: OUTSIDE_ROOM never sees a mover floor or other grid flag above a room's first row, because bake writes 0 over every band cell
status: resolved
severity: low
tags: [rooms, reachability, audit, edges, tests]
related: [architecture/world-edges-from-the-room-list, architecture/room-reachability-audit, systems/rooms]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/world/rooms/maps/reach/reach_lattice.gd
  - scenes/world/rooms/maps/reach/reach_audit.gd
  - scenes/world/rooms/maps/reach/reach_world_loader.gd
  - scenes/world/rooms/maps/map_cells.gd
---

## Summary

`ReachLattice.bake` fills every sky-band cell's raw flags with 0 and copies `ReachGrid.flags` only for cells inside rooms. A flag `ReachGrid` holds above a room's top (a mover's `reach_cells`, a current's box) is dropped without a message, so `ReachAudit._flag_outside_rooms` cannot report a floor that stands Ivo in the sky.

## Symptom

None in the current world: on 2026-10-14 (WORLD-34 review) a probe over `ReachWorldLoader.load_world()` found 0 grid cells flagged outside every room. The gap is latent. A future mover whose floor rises more than 16 px over an open top would pass `room_reach_test.test_nothing_outside_a_room_is_stood_on`, although Ivo could stand on it outside every room. That check is the user's "A test fails if any surface outside a room can be reached" (2026-10-14).

## Root cause

- `reach_lattice.gd:205-209`: `raw.fill(_OUTSIDE)`, then each band cell is set to `0`, never `grid.flags(cell)`. Only room cells get `grid.flags` (`:214`).
- `MapCells.floor_cells` rounds a floor's top line to the nearest row (`roundi(top / CELL_PX)`). A top more than 16 px above the room's first row lands in row -1 or higher, a band cell. `ReachWorldLoader._add_movers` adds it with `ReachGrid.add_cells`, which accepts any cell.
- `_flag_outside_rooms` (`reach_audit.gd:101`) reads `_lattice.is_standing`, which derives STAND from the raw flags of the cell under the feet. A SONG_FLOOR in a band cell has become 0, so nothing stands there.

The bug predates WORLD-34: before it, cells outside rooms were zeroed the same way. It matters now because OUTSIDE_ROOM is meant to catch every standing place outside a room, "reached or not".

## Fix

Resolved 2026-10-14 (WORLD-34 review). Both options, so no grid flag outside a room is ever dropped:
- `ReachLattice.bake` gives each band cell `grid.flags(cell)`. A song floor there stands, and the feet cell above it is flagged OUTSIDE_ROOM.
- `ReachGrid` records every cell flagged before a room covered it. `stray_cells()` returns those in no room and no band, and `ReachAudit._flag_outside_rooms` reports each as OUTSIDE_ROOM (never allowlisted), placed in the nearest room. `add_room` also ORs in flags a mover of an earlier room set, instead of overwriting them.
- `ReachWorldLoader.add_movers` is public, so `ReachFixture.moving_grid` places movers the way the loader does.
- Tests (`reach_audit_test`): a song floor at row -2 gives OUTSIDE_ROOM at row -3; a real seesaw (length 320) in row 1 under an open top gives OUTSIDE_ROOM at row -2; a flag beside a room gives OUTSIDE_ROOM. The first two fail with the old bake (checked by restoring `= 0`). The real world still has none.

## Prevention

Add a `reach_audit_test` fixture: a mover's `SONG_FLOOR` cell at row -2 over an open top must give `OUTSIDE_ROOM`. Do not discard a grid flag silently when a check depends on it.
