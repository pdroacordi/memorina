---
id: gotchas/rect2-intersects-is-false-for-rects-that-only-share-an-edge
type: gotcha
title: Rect2.intersects() is false for rects that only share an edge, Rect2.has_point() includes the top-left edges and excludes the bottom-right, and Rect2.merge() is a bounding box
status: active
tags: [rect2, geometry, rooms, seams, camera]
related: [bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top, systems/rooms]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/room_exit.gd
  - scenes/world/rooms/room_residency.gd
  - scenes/world/game.gd
---

## Summary

The default `include_borders = false` makes `intersects()` false for two rects that merely touch.
`has_point()` is half-open: `position` is inside, `end` is not. `merge()` returns the smallest rect that holds
both, including any empty corner between them.

## Details

- A body whose feet stand exactly on a room's top line (`body.end.y == bounds.position.y`) does not intersect
  that room. `RoomExit.has_left` relies on this for a body standing on a seam.
- Rooms that share a seam do not intersect, which is why `RoomResidency.touches` grows one rect by 1 px first.
  `intersects(b, true)` would count shared edges too, and corners as well.
- A point on a shared horizontal seam belongs to the lower room (`has_point` includes its top edge, and the
  upper room excludes its bottom edge). `_room_at(feet)` and `_room_at(centre)` can therefore disagree near a
  seam.
- `merge()` of an L-shaped set of rooms covers the empty corner. Do not use it where "only where rooms are"
  matters.

## Gotchas / pitfalls

Moving a seam test from `intersects` to `intersects(..., true)`, or from a centre point to the feet, shifts
every room change by one edge. Re-check `room_exit_test` and the seam bugs listed in `systems/rooms`.
