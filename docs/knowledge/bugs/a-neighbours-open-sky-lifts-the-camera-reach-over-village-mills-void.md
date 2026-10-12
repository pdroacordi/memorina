---
id: bugs/a-neighbours-open-sky-lifts-the-camera-reach-over-village-mills-void
type: bug
title: A neighbour's open sky lifts the bounding-box camera reach 80 px over village_mill, whose half-covered top has no sky, so the frame shows the void
status: resolved
severity: low
tags: [camera, rooms, open-sky, reach, void, home-village]
related: [bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top, bugs/the-woods-pond-shelf-jump-takes-ivo-out-of-the-top-of-the-frame, bugs/a-hop-above-a-neighbours-open-top-drops-it-from-the-camera-reach, systems/rooms, systems/backdrops]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/camera_reach.gd
  - scenes/world/rooms/open_sky.gd
  - scenes/world/game.gd
  - scenes/world/camera.gd
---

## Summary

`CameraReach.of` merges rects with `Rect2.merge`, which gives their bounding box. When the current room has no open sky
and a same-top neighbour has one, the neighbour's sky raises the reach's top by 80 px across the current room's whole
width. village_mill's top is only half covered (lake_waterfall_path covers x 2560..3200), so it has no sky, and the strip
over its west half (x 1920..2560, y -80..0) is void. The frame can rise into it. No backdrop draws there.

## Symptom

Found in review of the uncommitted `OpenSky` change (on 08c891c), by arithmetic. It has not been played.

Rooms: village_square (0, 0, 1920x384), which has a sky. village_mill (1920, 0, 1280x384), whose top is half covered.
A 2-cell wall stands on the seam, rows 0-4: square col 59 and mill col 0, top at y 0. With the wall skill, Ivo can climb
mill's col-0 face (x 1952) and stand on the wall top. Body x 1900..1922, feet y 0, touch (1892, -62, 38x70):

```
OpenSky.of(mill)                     -> (1920, 0, 1280x384)       no sky
CameraReach.of(mill, rooms, touch)   -> (0, -80, 3200x464)        top -80 across mill's columns
```

(Headless run of `CameraReach.of` on the real rects, 2026-10-11.)

The current room stays village_mill: his centre (1911, -27) is in no room. The frame is clamped to mill's columns
(x >= 1920, minus the sideways yield) and yields up to show him whole, so its top is about -62. The strip x ~1952..2552,
y -62..0 is then the clear colour. Only a 32 px dithered fringe from mill's backdrop is drawn, and the square's sky fringe
covers x < 1952. The same happens on any jump over that wall top from the mill side, until he has left the mill.

Before `OpenSky`, the reach was mill ∪ square with top 0. Ivo was out of frame there, but no void showed.

## Root cause

`camera_reach.gd:13-18`. A rect cannot hold an L-shaped area: a neighbour's sky goes into the bounding box, and
`GameCamera._keep_subject_in_view` (camera.gd:459) yields each axis against that one rect. Of the world's partly covered
tops, only village_mill has a same-top neighbour with a sky beside its uncovered half (village_square). orchard_terraces,
orchard_well and caldera_cistern_bottom have no such neighbour, so their reach was already lifted by taller neighbours
before this change.

## Fix

Not fixed. Options:
- Add a neighbour's sky only if the current room has a sky too, or only over columns whose own strip is open. This is
  the per-column sky that `systems/rooms` "Open sky" put aside.
- Clamp the vertical yield against only the rooms whose x range overlaps the frame's x range. This was the suggested fix in
  `bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top`, and it would also close the older
  taller-neighbour cases.

## Prevention

A `camera_reach_test` case: the current room has a half-covered top and a same-top neighbour has a sky. A body astride
their seam above the top must not lift the reach's top over the current room's uncovered columns.

## Resolution (2026-10-11)

The camera now checks what it shows, not only how far it yields. `CameraReach.of` still builds the reach as a box: the room's sky merged with each touched room and its sky. The box can hold an undrawn corner, as here (0, -80, 3200x464) over mill's west half. At the end of `GameCamera._keep_subject_in_view`, `CameraReach.drawn_frame` replaces any frame that is not wholly inside the rooms and skies (`OpenSky.of_rooms`, passed with `set_reach`). It picks the nearest drawn frame among the frame moved onto the edges of the rects around it, or back to the room clamp's column, row or whole. Glides are left alone, and the look-ahead never moves the frame into the void.

Why not a stricter reach: I tried accepting a neighbour only when the merged box was wholly drawn, with fallbacks that widen the reach on one axis only. That kept the void out, but Ivo lost the sideways yield at about 560 body positions on real seams: square→mill, the orchard_terraces seams, the waterfall path, and taller rooms beside shorter ones. Moving the frame keeps those yields wherever the frame they need is drawn.

Tests:
- `camera_reach_test.test_a_neighbours_sky_never_shows_the_void_over_a_room_without_one`: the mill frame lifted to -62 comes back to a top of 0.
- `test_no_frame_in_the_world_shows_the_void`: every room as the current one, a body every 32 px along its edges and up to 200 px over its top, the frame placed as the camera places it. No sampled pixel lies outside a room or sky. With `drawn_frame` disabled the test fails.
- `camera_test.test_the_frame_never_shows_what_no_room_or_sky_draws`.

## Revision (2026-10-11, room ring)

`OpenSky`, `CameraReach` and the drawn-frame correction named above are replaced by `RoomRing`
(`systems/rooms` "Room ring", `bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame`).
The camera yields up to 160 px past the current room, and every room's backdrop draws the void it is nearest within that ring. mill's west half is drawn by mill's or the square's ring. In game, the step-to-ledge jump under lake_waterfall_path reaches a frame top of -108 with no void.
