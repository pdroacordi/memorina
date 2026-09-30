---
id: bugs/camera-zoom-out-shows-past-room-bounds
type: bug
title: While the camera zooms OUT, the frame shows 1-3 px past the room's bottom bound, which draws a dark line of terrain under a lake that runs to the room's bottom
status: active
severity: low
tags: [camera, zoom, bounds, tween, physics-vs-idle, water, lake]
related: [playtests/2026-09-23-lake-and-water-hazard, gotchas/physics-parent-before-children-one-frame-lag]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/camera.gd
  - scenes/world/rooms/home_village/contents/downtown_contents.tscn
---

## Summary

`GameCamera` clamps the visible rectangle to the room in `_physics_process`, using the
zoom at that moment. The zoom tween steps in idle time. While the zoom is falling
(release after the Memorina focus, release after a lesson push), the frame is drawn at a
smaller zoom than the one the clamp used. So the view pokes past the room's bound for a
few frames. Nothing showed this until lakes were painted down to the room's bottom
(dbfacbf): the ground tile under the bound now shows as a dark line beneath navy water.

## Symptom

Found in the 2026-09-23 lake playtest. It reproduced in 3 of 3 runs of a FREEZE timeline
(Downtown, Ivo at x 12, shots every 0.1 s from 5.8 to 7.4 s). Right after the
performance, the camera releases the 1.5 focus zoom. In the frames at about 6.50 and
6.60 s, the bottom of the screen shows the ground tile (30, 29, 24) under both the lake
and the pit pool: 2, 6 and 3 window rows, or 1 to 3 game px. Every other frame is clean.
See `playtests/screenshots/2026-09-23-lake-and-water-hazard/08_zoom_out_shows_ground_under_water.png`.
Zooming IN (`02_zooming` in `water_reflection.json`) never shows it, which fits the
mechanism below: a growing zoom shrinks the view inside the clamp.

## Root cause

Traced from the code and consistent with the size measured. It has not been instrumented
frame by frame.

- `camera.gd:86-98`: `_physics_process` sets the position and then calls `_apply_bounds()`.
- `camera.gd:303-315`: `_apply_bounds()` computes `half = viewport / 2 / zoom` from the
  CURRENT `zoom` and clamps the centre so that `centre.y + half.y <= _bounds.end.y`.
- `camera.gd:207-216`: `_tween_zoom()` builds a default (idle) tween, so `zoom` changes
  after the physics tick that clamped it and before the frame is drawn. On a zoom-out,
  each draw uses a larger half-extent than the clamp allowed. The focus release is
  `TRANS_QUAD`/`EASE_OUT` over 0.5 s (dz/dt up to 2 per second). One 60 Hz tick of lag is
  then about 180 * (1/1.467 - 1/1.5), or roughly 2.7 world px, which matches the 1 to 3 px
  seen. On frames where render runs without a physics tick, it only gets worse.
- The Downtown and Woods lakes (painted rows 0..3, so world y 8..64) end exactly on the
  room's bottom (`downtown.tscn`: shape at y -237, height 602, so the bottom is y 64),
  and the terrain continues to y 96 under them.

## Fix

Not fixed. The candidates, cheapest first:

1. Step the zoom tweens on the physics clock:
   `create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)`. Keep
   `TWEEN_PAUSE_PROCESS`, because the lesson push must still run under the pause. Then
   the clamp and the zoom share one tick. Check that the pause-mode map still holds: a
   paused tree still steps physics-mode tweens whose pause mode is PROCESS.
2. Also call `_apply_bounds()` from `_process` (or on the tween's `step_finished`), so the
   clamp always sees the zoom it will be drawn at.

## Prevention

A camera that clamps the visible RECT has to clamp with the same zoom it renders with.
Any new zoom writer (a cutscene camera, a boss-intro zoom) must go through `_tween_zoom`,
or it reopens this bug. A level-side guard would also hide it: paint water (and anything
dark-bottomed) one cell past the room's bound. That treats the symptom only.
