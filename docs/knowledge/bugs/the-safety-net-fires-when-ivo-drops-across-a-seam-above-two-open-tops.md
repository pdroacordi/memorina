---
id: bugs/the-safety-net-fires-when-ivo-drops-across-a-seam-above-two-open-tops
type: bug
title: The out-of-every-room safety net runs the hazard beat when Ivo crosses a side seam above two open room tops and falls into the neighbour
status: resolved
severity: medium
tags: [world-05, rooms, room-exit, safety-net, hazard, fade, seam, regression]
related: [bugs/the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top, bugs/wall-climb-leaves-the-world-over-the-cliff-chimneys-west-wall, systems/rooms]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/game.gd
  - scenes/world/rooms/room_exit.gd
---

## Summary

`Game._physics_process` (game.gd:69-77) skips the safety net only while the body is wholly above the
*current* room's top. When Ivo crosses a side seam above the tops of two open-topped rooms and falls into the
neighbour, there are frames where his feet are below the top line but his body's centre is still above it. In
those frames no room contains the centre and the open-top test fails, so `_lost` is set and the hazard beat
fades him out and puts him back.

## Symptom

Found in review, not yet playtested. Geometry from the working tree on 5062946:
- orchard_leaf_path x [-8960, -7680), top -1536. Its one-way at row 3, cols 3-9 (feet y -1440). Its col 0
  wall reaches row 0, and the top is open.
- orchard_arena x [-10240, -8960), top -1536. No room lies above either one.

A double jump west from the one-way peaks near feet -1710 and clears leaf path's col 0 wall. Once the body
is wholly west of x -8960, `RoomExit.has_left` is true (the sideways rule).
- While the feet are above -1536, `body.end.y <= top` holds and Game waits.
- Then the feet drop below -1536 while the centre (about 27 px higher) is still above it. Now
  `_room_at(centre)` is null and `body.end.y > top`, so Game sets `_lost = true`.

At any fall speed under ~1600 px/s at least one frame lands in that 27 px window, so the beat fires every
time. The fade and teleport read as a death.

The same happens over void airspace above a lower neighbour (a room one grid row down beside the current
room), when Ivo is falling into it.

## Root cause

The open-top exception asks about the current room's top only. The room Ivo is falling into is found by a
single point, the body centre. Neither check covers a body astride the neighbour's top line.

## Fix

Suggested: declare him lost only if no room in reach lies under his column. Before setting `_lost`, look for a
room touching the current one (`RoomResidency.touching`) whose x range contains `body.get_center().x` and whose
top is at or below `body.end.y`. If one exists, he is falling into it, so wait. This covers the current room's
open top too and replaces game.gd:72. A cheaper partial fix: try `_room_at(Vector2(centre.x, body.end.y))` (the
feet) before declaring him lost.

## Prevention

Extract the "lost" decision into a pure static next to `RoomExit` (rooms' rects in, bool out) and give it a
suite. Cases: above the current open top; above a neighbour's open top across a side seam, with the feet below
the top line and the centre above it; void beside the world edge (must be lost).

## Resolution (2026-10-10)

`RoomExit.is_lost(body, near)`: lost only when no room touching the current one lies in the column of his centre below his head (`room_exit_test`: above an open top, falling into a neighbour's column, beside and below every room). Playtest (2026-10-10, working tree on 5062946, `--import` at 03:35:59, real save untouched):
- **Into the arena** (`tools/playtest/scripts/traverse_orchards_caldera_rv4_s1_leaf_oneway_double_jump_into_arena.json`):
  a running double jump west from orchard_leaf_path's row-3 one-way (feet -1440) over the col-0 wall. Peak
  (-9057.4, -1707.2), above both open tops. No sample with `fade` > 0.05. He lands in the arena at (-9265.2, -1248),
  and the room becomes orchard_arena on landing (t 3.65).
- **The same three double jumps as before**, re-run (`..._rv_n1/n2/n3_*.json`):
  - leaf-path hill (peak -1677.6), orchard_well one-way (-1613.6), threshold bridge deck (-109.6);
  - no fade and no pull-back; each lands where it took off.

## Regression timeline re-pointed (2026-10-11, WORLD-25)

WORLD-25 removed orchard_leaf_path's row-3 one-way, and no floor near its col-0 seam is within a double jump's reach of the top any more. The seam check is now `traverse_woods_lake_rv4_s1_pond_double_jump_into_bloom_hollow.json`: a running double jump west from woods_pond's west step (-5520, 160) over its col-0 wall. Ivo crosses the seam (x -5760) at feet about -110, above both open tops (y 0); peak -109.6, `fade` 0.00, lands in bloom_hollow at (-5954.2, 288). The orchard_well run is now `traverse_woods_lake_rv_n2_pond_shelf_double_jump.json` (`bugs/world-25-re-pointed-timelines-no-longer-test-their-scenario`).
