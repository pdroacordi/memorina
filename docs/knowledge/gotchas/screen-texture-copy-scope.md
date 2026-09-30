---
id: gotchas/screen-texture-copy-scope
type: gotcha
title: The automatic screen copy is taken once per canvas layer, so world-canvas water reads one shared copy and the greyhush still sees it
status: active
tags: [rendering, screen-texture, backbuffer, water, canvas-layer]
related: [architecture/memory-field-cpu-gpu-split, bugs/creature-pass-frozen-transform-floats-bodies]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/world/memory/greyhush.gdshader
---

## Summary

In Godot 4.7 (Forward+, d3d12) a `canvas_item` shader that declares
`hint_screen_texture` does NOT need a `BackBufferCopy`: the engine copies the screen
automatically before the first item on a canvas layer that reads it. The copy is taken
**once per layer**, and **again on the next layer** - so every world-canvas item that
reads the screen sees the same copy (taken before the first such item), and the
`Greyhush` pass on `CanvasLayer` 1 sees a fresh copy that already contains them.

## Details

Measured 2026-09-22 with a throwaway rig (four inverting quads at `z_index` 50 in
`World`, then the real game frame):

- Each inverting quad appears in the final, greyhushed frame -> the greyhush's copy is
  retaken after layer 0 drew them. The old plan's "a BackBufferCopy is mandatory"
  claim (written in the Godot 3 frame of mind) is false for this project.
- Two OVERLAPPING inverting quads show the overlap inverted once, not twice -> within one
  layer the second reader does not get a new copy containing the first.

The same rig also confirmed, for the water plan:

- A mirror computed in world space and projected with
  `SCREEN_UV + (m - world_pos) * uv_per_world`, the scale taken from `dFdx`/`dFdy`,
  agrees with the exact `SCREEN_MATRIX * CANVAS_MATRIX` projection to under half an
  output pixel at camera zoom 1, 1.15 and 1.5.
- `CreatureMask`'s texture is current-frame when the root viewport samples it (a
  reflection of a running Ivo matches his pose on the same frame).
- A `render_mode blend_mul` quad on the creature visibility layer darkens creature pixels
  and leaves transparent pixels (and alpha) untouched.

## Gotchas / pitfalls

- A screen reader never sees another screen reader on the same layer. Water never
  reflects water; that is accepted and is why every water body shares one z
  (`WaterQuad.Z`).
- The copy is at WINDOW resolution under `canvas_items` stretch (2560x1440 on a 2x
  display for a 640x360 game). Snap any fetch to an output-pixel centre, and do
  art-pixel decisions in world texels, or the sample drifts between texels.
- If a future node needs to see a screen reader on the same layer, THAT is when a
  `BackBufferCopy` is needed - not before.
