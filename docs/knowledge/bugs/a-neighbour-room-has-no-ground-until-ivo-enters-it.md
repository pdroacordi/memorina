---
id: bugs/a-neighbour-room-has-no-ground-until-ivo-enters-it
type: bug
title: A neighbouring room that is not resident has no ground, so Ivo jumps through its floor from below and is embedded in it
status: resolved
severity: high
tags: [rooms, room-transition, seam, collision, world-05, sequence-break]
related: [playtests/2026-10-09-traversal-woods-lake, bugs/walking-across-a-room-seam-fades-back-and-forth, systems/rooms]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/game.gd
  - scenes/world/rooms/room.gd
---

## Summary

`Game` keeps `MAX_RESIDENT_ROOMS` (2) rooms' contents: the current room and the one before it. A
`Room` creates its contents, and with them its ground `TileMapLayer`, only in `activate()`. Any other
neighbour has no collision. The world's rooms abut (WORLD-05), so wherever the current room is open at
a seam and the neighbour is solid there, Ivo passes into the neighbour's ground. When his feet cross the
seam, the neighbour activates around him and the physics pushes him out of the ground: sideways, or up
on top of it.

## Symptom

Build 6fa077a, `skills: [0]` (double jump).

**woods_canopy into orchard_well through its floor**
(`tools/playtest/scripts/traverse_woods_lake_f_canopy_west_to_branch.json`):
- The canopy's top row is open from col 1 to col 58. orchard_well (x -3840..-2560) sits above cols
  20-59. Its bottom row (row 11, y -1184..-1152) is solid earth and stone, so it should be the canopy's
  ceiling there.
- A double jump from the canopy's one-way (cols 36-41, y -992) at x -3370 is not stopped by that row:

```
t=3.00  pos=(-3347.9,-1111.8) vel=(-192,-57.5)   room=woods_canopy
t=3.20  pos=(-3370.3,-1160.8) fade=0.17 pmode=4   feet 8.8 px inside orchard_well's floor row
t=3.81  room=orchard_well
t=4.21  pos=(-3386.3,-1194.3)                     on top of the floor (y -1184)
t=5.80  pos=(-3693.5,-1344.1)                     standing on orchard_well's one-way (cols 2-6)
```

**woods_canopy into orchard_terraces through its floor**
(`traverse_woods_lake_g_canopy_branch_to_terraces_held.json`, first run):
- A straight double jump from the launch branch at x -4079.4 is under the terraces' solid floor (col 52,
  x -4096..-3840), not under its hole (cols 44-51).
- He rose into that floor to y -1166.2, 82 px inside it. After the fade he was at x -4106.1, pushed 27 px
  west into the hole, and the jump went on to the terraces.

**The resident room does collide.** Back in woods_deep after climbing out of woods_root_caves (the
previous, still resident room), Ivo stood at (-3571.9, 384) on the corner of the caves' top row
(`traverse_woods_lake_i2_caves_climb_and_jump_out.json`).

## Impact

- A sequence break wherever a room's top or side is open at a seam that its neighbour closes. The
  canopy's whole top lets a double jump reach orchard_well's west half, which is otherwise entered
  from orchard_terraces (its west edge, rows 5-8).
- Ivo can end up inside ground, and where he is pushed depends on the overlap.
- It also depends on history: the same jump is stopped if that neighbour happens to be the previous
  room.

## Suggested fix

Either:
- make every seam's ground agree on both sides (close the canopy's top at cols 20-59 and outside the
  terraces' hole, cols 0-3 and 12-19) and add a `room_files_test` check that a cell open at a room's
  edge is open in the neighbour too; or
- keep the ground of the current room's neighbours resident (collision only, without processing or
  drawing).

The first fixes the authoring. The second fixes the engine side for every future room.

## Resolution (2026-10-09)

Fixed by `RoomResidency` (uncommitted WORLD-05 work on ea47690). The current room and every room touching
it (edge or corner) are active, so the ground across a seam exists. Re-verified on the region-cut code
(`playtests/2026-10-09-traversal-woods-lake`, Re-verification):
- **canopy → orchard_well** (`tools/playtest/scripts/traverse_woods_lake_f_canopy_west_to_branch.json`):
  the same double jump now stops with feet at y -1094..-1098, which puts the head at the well floor's
  underside (-1152). The room never changes to orchard_well, and he lands back on the canopy. 2 of 2.
- **straight double jump under the terraces' solid floor**, from the launch branch at x -4050
  (`..._g_rv_branch_straight_under_terraces_floor.json`): stopped at y -1097.8 and lands back on the
  branch. No embedding.

Follow-up: running neighbours are also shown, and their backdrops draw into the current view
(`bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room`).
