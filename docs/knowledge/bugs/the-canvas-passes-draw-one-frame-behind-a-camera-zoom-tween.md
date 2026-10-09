---
id: bugs/the-canvas-passes-draw-one-frame-behind-a-camera-zoom-tween
type: bug
title: While the camera zooms, the creature and foreground passes draw at the previous frame's zoom, so bodies and foreground pieces slide against the world
status: resolved
severity: medium
tags: [rendering, subviewport, canvas-pass, camera, tween, foreground, creature-pass, mem-12]
related: [gotchas/a-tween-runs-after-every-process-so-a-process-mirror-is-a-frame-late, bugs/creature-pass-frozen-transform-floats-bodies, systems/foreground, architecture/foreground-layer]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/camera.gd
  - scenes/world/memory/canvas_pass.gd
  - scenes/world/environment/foreground/foreground_piece.gd
---

## Summary

`GameCamera._tween_zoom` runs an IDLE tween. Tweens step after every node's `_process`, so
`CanvasPass._process` (and `ForegroundPiece._process`) copy the root canvas transform before the
zoom for that frame is applied. On every frame of a zoom, both passes render at the previous
frame's zoom while the root world renders at the new one.

## Symptom

Found in the MEM-12 review; not yet seen in a playtest. Draw the Memorina (focus zoom 1.0 to 1.5
over 0.5 s, quad ease out, about 0.033 zoom per frame at the start). A point d px from the
camera centre is drawn about d * 0.033 px off: about 6 px at the top edge of the frame and 1 to
2 px at Ivo's feet. A same-depth foreground column slides against the ground behind it for the
length of the zoom, near branches at the frame edges jump, and a paired guardian off centre
floats. `release_push` (0.5 s) shows the same. The 45 s lesson push-in also lags, by under 0.1 px
per frame.

Measured (Godot 4.7.2, headless probe): a node after the camera in tree order reads
`get_canvas_transform()` in `_process` during an idle `zoom` tween. In 39 of 40 frames the
transform used for that frame's draw differs from the one it read (e.g. zoom 1.0278 read, 1.0431
drawn).

## Root cause

- `scenes/world/camera.gd:204` `_tween_zoom` creates the tween without `set_process_mode`, so it
  defaults to `TWEEN_PROCESS_IDLE`. `_tween_pair` (`:183`) and `_tween_look_ahead` (`:227`) use
  `TWEEN_PROCESS_PHYSICS`, and the camera's position moves in `_physics_process`. All of those
  land before idle processing starts.
- `scenes/world/memory/canvas_pass.gd:65` copies `root.get_canvas_transform()` in `_process`.
  `foreground_piece.gd:36` reads it in `_process` to place its parallax. Both run before tweens.
- This was latent for `CreatureMask` since the pass was built: Ivo sits near the centre, where
  the error is small. The foreground makes it visible because its pieces sit at the frame edges
  and same-depth occluders are anchored to the ground.

## Fix

Not fixed. Options:
- `set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)` on `_focus_tween`, matching the other two
  camera tweens. The zoom then lands before every mirror reads it. Smallest change.
- Or have `CanvasPass` and `ForegroundPiece` sample the transform at
  `RenderingServer.frame_pre_draw`, which runs after tweens. This is robust to any future idle
  tween on the camera.

`process_priority` does not help, because tweens run after all nodes whatever their priority.

## Prevention

Test idea: during a zoom tween, assert that the transform `CanvasPass` copied equals the root
canvas transform at `frame_pre_draw`. Not added. Playtest: the MEM-12 plan's "near branch at 1.4
with no jitter" probe should run during a Memorina draw, not only while panning.

## Resolution (2026-10-09)

`GameCamera._tween_zoom` now steps on physics, like the pair and look-ahead tweens, so the zoom is set before the passes copy the canvas transform in `_process`.
