---
id: gotchas/two-quads-disagree-on-a-pixels-world-position
type: gotcha
title: Two canvas_item quads covering one screen pixel compute different world positions for it from MODEL_MATRIX * VERTEX, so an exact cross-quad test leaves holes
status: active
tags: [shader, canvas-item, float, model-matrix, backdrop, pixel-snap]
related: [bugs/the-ring-dividing-line-leaves-a-one-pixel-diagonal-hole-above-a-seam, architecture/backdrop-seams, gotchas/glsl-gdscript-math-must-be-duplicated]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
---

## Summary

A varying such as `world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy` is computed per vertex and interpolated per
quad. Two quads with different transforms (two rooms' backdrop layers, two parallax layers) do not give bitwise-equal
values for the same screen pixel. A test that splits pixels between quads by exact comparison then makes both quads skip
a pixel, or both draw it, wherever the dividing line passes through pixel centres.

## Details

- Observed 2026-10-11 in Godot 4.7.2, Forward+, with snap_2d transforms and vertices on
  (`bugs/the-ring-dividing-line-leaves-a-one-pixel-diagonal-hole-above-a-seam`). A 45-degree dividing line, x + y an
  integer, passes through every pixel centre on it. The near layers of both rooms skipped the whole line, and only the
  far layer drew it. The line held still from frame to frame, so the disagreement is systematic per quad, not random
  noise.
- Not established: whether the source is the varying's interpolation precision, or that vertex snapping moves
  `gl_Position` but not the varying. Either way the fix is the same.
- Axis-aligned dividing lines at whole pixels lie 0.5 px from every pixel centre, which is more than the disagreement,
  so they mostly hide this. Diagonals and lines on half pixels do not.

## Gotchas / pitfalls

- Give such a test a margin that resolves to overdraw (`SEAM_EPSILON` in `BackdropMath`: own rect grown, neighbour rects
  shrunk). Or compute the position every quad tests from something they share bitwise: the pixel centre snapped from
  `world_pos`, or `SCREEN_UV` with a camera-rect global uniform.
- A GDScript twin that samples exact pixel centres in doubles agrees with itself and passes. It cannot catch this. Check
  a windowed still.
