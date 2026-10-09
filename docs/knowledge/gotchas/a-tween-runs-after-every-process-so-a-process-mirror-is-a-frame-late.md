---
id: gotchas/a-tween-runs-after-every-process-so-a-process-mirror-is-a-frame-late
type: gotcha
title: An idle Tween steps after every node's _process, so a node that mirrors a tweened value in _process copies last frame's value
status: active
tags: [tween, process-order, camera, subviewport, mirror]
related: [bugs/the-canvas-passes-draw-one-frame-behind-a-camera-zoom-tween, gotchas/physics-parent-before-children-one-frame-lag, bugs/creature-pass-frozen-transform-floats-bodies]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/camera.gd
  - scenes/world/memory/canvas_pass.gd
---

## Summary

In a frame, the SceneTree runs every node's `_process` first and steps `TWEEN_PROCESS_IDLE`
tweens afterwards. Tree order and `process_priority` do not change this. A node that copies a
tweened property in `_process`, such as a SubViewport copying the root's canvas transform while
the camera's `zoom` is tweened, reads the value from before this frame's step. The frame is then
drawn with the new value. The copy is one frame late on every frame the tween runs.

## Details

- Measured in 4.7.2: a `_process` reader during an idle `zoom` tween on the current `Camera2D`
  disagreed with the drawn transform in 39 of 40 frames.
- `TWEEN_PROCESS_PHYSICS` tweens step during the physics step, which comes before idle, so a
  `_process` mirror sees their result. So does a value set in `_physics_process`, once the
  transform notifications are flushed.
- `RenderingServer.frame_pre_draw` fires after tweens, just before drawing. It is the reliable
  place to copy a value that anything (an idle tween, a late `_process`) may change during the
  frame.

## Gotchas / pitfalls

- Pausing does not cause it and `ALWAYS` does not cure it (compare
  `bugs/creature-pass-frozen-transform-floats-bodies`): the mirror runs, but too early.
- The error grows with the tween's rate and with the distance from the zoom centre, so it hides
  near the middle of the screen.
