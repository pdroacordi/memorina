---
id: bugs/a-facing-turn-in-a-one-screen-wide-room-slides-the-frame-past-its-bounds
type: bug
title: A facing turn in a room one screen wide slides the frame up to 6 px past the room's side for the length of the look-ahead tween
status: resolved
severity: low
tags: [camera, look-ahead, tween, bounds, interiors, void]
related: [gotchas/a-tween-runs-after-every-process-so-a-process-mirror-is-a-frame-late, architecture/room-void-outside-the-shell, systems/helix-stair, playtests/2026-10-11-room-ring-regression]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/camera.gd
  - scenes/world/game.tscn
  - tests/scenes/world/camera_test.gd
  - scenes/world/game.gd
  - scenes/world/rooms/room_ring.gd
---

## Summary

`GameCamera._apply_bounds` clamps `global_position + offset` in `_physics_process`. The look-ahead tween then changes `offset.x` after that, in the same physics frame. So the drawn centre is the clamped centre plus one step of tween motion. In a room exactly one screen wide the clamp allows a single x, so every turn shows the area outside the room at one side. This was in main before WORLD-26; the slim, void-framed interiors make it easy to see.

## Symptom

Found in review of WORLD-26 (2026-10-11) in the windowed game. In the bell tower (640 px wide, bound centre x 9920), Ivo turned from facing right to facing left at the helix head at t 16.6. The logged `cam_centre` x then read 9920, 9919, 9918, 9917, 9916, 9914 (t 17.35), 9915 ... and back to 9920 at t 17.95. A still at t 17.5 shows a strip about 4 game px wide past the room's left edge, at x < 0. That strip is the clear colour, a different dark from the void's greyed black next to it.

## Root cause

- camera.gd:113-124: `_physics_process` sets the position, then calls `_apply_bounds()` (camera.gd:426-438), which uses this frame's `offset`.
- camera.gd:314-326: the look-ahead tween uses `TWEEN_PROCESS_PHYSICS`, and tweens step after every node's process (`gotchas/a-tween-runs-after-every-process-so-a-process-mirror-is-a-frame-late`). Its later `offset.x` write is not clamped. game.tscn sets it to 1.5 s, cubic, in-out, so the error peaks mid-way at about 3 px per step, and `cam_centre` peaked at 6 px.
- In wider rooms the overshoot shows the neighbouring room or happens away from a bound, so it went unnoticed.

## Fix

Fixed 2026-10-11 in WORLD-26. The tween now writes `_look_ahead`, not `offset.x`. Its setter calls `_set_offset_x_within_reach`, which sets `offset.x` and moves the frame's centre with it only as far as `_yield_axis` allows inside the reach. A write that would carry the centre past the reach moves `global_position` back by the same amount. A centre already outside (a room glide) does not move further out, and is not pulled in, so the glide still starts where the frame stood.

The write applies at once, not on the next physics step, because the camera is pausable (`World` is `PROCESS_MODE_PAUSABLE`). During a performance freeze the tween keeps running, and `_check_focused` reads the canvas transform when it lands.

`camera_test.test_a_turn_in_a_room_one_screen_wide_keeps_the_frame_inside` turns an Ivo instance both ways in a room one viewport wide. It checks `view_rect()` after every tween step. Without the fix it fails at -30 px.

## Prevention

When a tween writes a property that a per-frame clamp reads, the clamp must run after the tween, or the tween must write a value that the clamp then applies.

## Revision (2026-10-11, room ring review)

Reopened. The fix bounds the look-ahead write by `_reach` (camera.gd:481-488). The uncommitted room-ring change makes
`Game` set `_reach` to `RoomRing.reach(bounds)`, the room grown 160 px on every side (game.gd:117, game.gd:127), so the
write once more moves the frame past the room clamp by one tween step.

Measured on the room-ring worktree (on 9f55197), windowed, with a scratch timeline: enter the bell tower by its door from
village_square (656, 286), then tap left and, 2 s later, right. The bound centre is x 9920 (room 640 px wide). Per-frame
`cam_centre` x ran from 9913.7 to 9926.3: up to 6.3 px past each side, as in the original symptom. Past the side, the
strip now shows the tower's own backdrop, drawn in its ring, next to the black void mask, not the clear colour.

`camera_test.test_a_turn_in_a_room_one_screen_wide_keeps_the_frame_inside` still passes. It calls `set_bounds(room)`
with no reach, so `_reach` equals the bounds. Game never does that now.

Suggested fix: bound the look-ahead by the room clamp, not the reach. Use `_bounds` in `_set_offset_x_within_reach`.
`_yield_axis` never pulls back a centre that is already outside, so a frame yielded into the ring to keep Ivo whole stays
where it is. Give the test the ring reach, as Game does.

## Playtest evidence (2026-10-11, room-ring regression)

`playtests/2026-10-11-room-ring-regression` ran the same timelines on 9f55197 and on the room-ring worktree, with a
per-frame trace. It counted frames where the view passes the current room's side while the body is inside the room and
no glide runs:
- `bell_tower_helix_climb` turn: main none; ring 64 frames, max 6.3 px.
- counterweights walk-off (`camfall_a1d`): main none; ring 64 frames, max 6.3 px. The strip is the room's flat grey ring
  backdrop where the brick wall should continue.
- lane_west walk to woods_edge (`w7b`): main 1 frame; ring 26 frames, max 11.0 px. That strip is woods_edge, another
  region, before the cut.
- mill walk to square (`w7c`): main 1 frame; ring 29 frames, max 11.4 px.
- woods_pond seam wall-top runs: main 0-53 frames, only while his body touches bloom_hollow; ring 63-74 frames, max
  6.3-7.6 px.

So the drift is not limited to one-screen rooms: any turn while the frame sits at a side clamp shows it. Stills:
`playtests/screenshots/2026-10-11-room-ring-regression/01_counterweights_turn_strip_left_edge.png` and
`02_bell_tower_turn_strip_left_edge.png`.

## Resolution after the ring (2026-10-11)

`_set_offset_x_within_reach` now limits the look-ahead's move by the room clamp (`_bounds`), not the ring reach. A frame already yielded past the clamp to keep Ivo whole holds, because `_yield_axis` never pulls back. `camera_test.test_a_turn_in_a_room_one_screen_wide_keeps_the_frame_inside` now binds the room with the ring reach, as `Game` does. With the old `_reach` bound it fails.

Played on 9f55197 plus this change. The measure counts frames where the view passes the room's side by more than the body and margin need, with the body inside the room and no glide:

| Timeline | Main | Ring before | Now |
|---|---|---|---|
| `bell_tower_helix_climb` (725 frames) | none | 64 frames, max 6.3 px | none |
| `camfall_a1d_counterweights_dense` | none | 64 frames, max 6.3 px | none: at rest after the turn the centre is -6080, the room's centre |
| `traverse_woods_lake_w7b_rv_lane_west_to_woods_edge_cut` | 1 frame | 26 frames, max 11.0 px | none (sparse logs, 8 frames) |
| `open_sky_seam_wall_top_full_jump` (188 frames) | | 74 frames, max 7.6 px | none |
