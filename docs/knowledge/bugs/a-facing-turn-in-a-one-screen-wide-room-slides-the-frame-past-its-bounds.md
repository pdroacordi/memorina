---
id: bugs/a-facing-turn-in-a-one-screen-wide-room-slides-the-frame-past-its-bounds
type: bug
title: A facing turn in a room one screen wide slides the frame up to 6 px past the room's side for the length of the look-ahead tween
status: resolved
severity: low
tags: [camera, look-ahead, tween, bounds, interiors, void]
related: [gotchas/a-tween-runs-after-every-process-so-a-process-mirror-is-a-frame-late, architecture/room-void-outside-the-shell, systems/helix-stair]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/camera.gd
  - scenes/world/game.tscn
  - tests/scenes/world/camera_test.gd
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
