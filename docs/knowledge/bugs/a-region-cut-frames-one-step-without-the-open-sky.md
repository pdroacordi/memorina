---
id: bugs/a-region-cut-frames-one-step-without-the-open-sky
type: bug
title: On a region cut while Ivo's head is in an open sky, the first frame clamps at the room's top and the next one jumps up into the sky
status: resolved
severity: low
tags: [camera, rooms, open-sky, region-seam, reach]
related: [bugs/the-woods-pond-shelf-jump-takes-ivo-out-of-the-top-of-the-frame, bugs/a-neighbour-room-in-another-region-runs-on-the-current-regions-memory, systems/rooms]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/game.gd
  - scenes/world/camera.gd
---

## Summary

`GameCamera.set_bounds` resets `_reach` to the plain bounds (camera.gd:136-137). `Game._physics_process` sets the
reach before it swaps rooms (game.gd:69), so on a swap step the camera runs with no open sky. A glide hides this:
`_glide_from` holds the frame where it stood. A region cut does not hide it. `snap(true)` reframes from scratch, so the
frame's top is clamped to the room's top for one step, and on the next step `set_reach` lets it jump up by as much as
80 px.

## Symptom

Found in review of the uncommitted `OpenSky` change (on 08c891c), by reading the code. It has not been played.

village_lane_west (home_village) and woods_edge (spring_woods) are both open-top and meet at x -1280. A wall column
stands on the seam with its top at y 0, one hop up from the gatehouse roof. Ivo stands on that wall top, so the frame
rises to about -62. He walks west off it into woods_edge. The room swaps when his centre enters woods_edge, at feet about
y 27 with his head at -27. That step is a region cut:
- the cut frame's top is 0, so his head is cut off;
- the next frame's top is -35, a 35 px jump right after the cut.

## Root cause

The order of calls in one physics step: `Game` (the parent) runs `set_reach` → `_enter_room` → `set_bounds`, which sets
`_reach = bounds`. Then `GameCamera._physics_process` runs `_keep_subject_in_view` against that reset reach.

## Fix

Not fixed. Suggested: after `_enter_room` in `Game._physics_process`, call `set_reach` again for the new room
(`_reach_for` / `_fall_reach_for` with the new `near`). Or have `set_bounds` keep the reach's open sky.

## Prevention

A camera_test case: a body in the sky. `set_bounds(room, false)` then `snap(true)` within one step, and the view's top
stays at the body's top minus `subject_margin`.

## Resolution (2026-10-11)

`Game._physics_process` calls `_set_camera_reach(body)` again after `_enter_room`, so the camera steps with the new room's reach and sky after the swap or cut. `camera_test.test_a_region_cut_keeps_the_open_sky_when_the_reach_follows_the_swap` tests that order; `test_set_bounds_drops_the_reach_to_the_room` pins the reset.

Played (`tools/playtest/scripts/open_sky_region_cut_lane_to_woods.json`, 2026-10-11, on 08c891c plus this change (the later merge of 9f55197 changed no room played here)). Ivo hops from the gatehouse roof onto the seam wall top (x -1302, feet 0), then walks west off it. The region cut to woods_edge comes at feet 33.1, head at -20.9:
- the cut frame's top is -28.9, his head minus the 8 px margin;
- the frame before the cut was at -32.7 and the frame after at -24.8, so it eases with the fall and does not jump.

## Revision (2026-10-11, room ring)

`OpenSky`, `CameraReach` and the drawn-frame correction named above are replaced by `RoomRing`
(`systems/rooms` "Room ring", `bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame`).
The camera yields up to 160 px past the current room, and every room's backdrop draws the void it is nearest within that ring. `set_bounds` now takes the new reach and `Game` still sets it after the swap. The cut frame's top is -28.9, between -32.7 and -24.8.
