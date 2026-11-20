---
id: gotchas/canvas-blend-mix-accumulates-alpha-so-an-overdrawn-alpha-mark-is-lost
type: gotcha
title: A canvas_item shader on blend_mix accumulates alpha, so an exact alpha mark drawn twice on one pixel becomes 255
status: active
tags: [shaders, canvas-item, blending, alpha, alpha-mark, creature-pass, rendering]
related: [bugs/a-spawns-overdrawn-pixels-lose-the-self-lit-mark-and-grey, systems/greyhush]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/world/memory/unshielded_mark.gdshaderinc
  - scenes/world/memory/self_lit_mark.gdshaderinc
---

## Summary

On a transparent render target (a `CanvasPass`), Godot 4's `blend_mix` writes
`a = src.a + dst.a * (1 - src.a)`. Any primitive drawn over a pixel with alpha near 1 pushes it
to 255, so an alpha value used as a per-pixel flag survives only where it is drawn exactly once.

## Details

From the engine source (`renderer_canvas_render_rd.cpp`, `BLEND_MODE_MIX`: alpha factors ONE and
ONE_MINUS_SRC_ALPHA). Confirmed in game on 2026-11-20: a Bloom floor warning's light line, drawn inside its rim,
greyed to (188, 196, 183) under `blend_mix` and kept its colour, (187, 214, 147), with `blend_disabled`
(`bugs/a-spawns-overdrawn-pixels-lose-the-self-lit-mark-and-grey`).

- 254/255 over 254/255: 0.999985, stored as 255 (8-bit) or 1.0 (half float).
- 253/255 under a 0.25..0.75 alpha pixel lands on 254/255: a half-transparent pixel over the
  unshielded mark forges the self-lit mark.
- Every `draw_*` call on one CanvasItem blends over the previous ones; batching does not change
  this. One sprite quad (the corruption edge) is safe; a `_draw` that layers rects is not.

## Gotchas / pitfalls

To write an exact alpha regardless of what is underneath, use `render_mode blend_disabled;` and
`discard` the pixels that should not be drawn (writing `vec4(0.0)` would erase what is under them).
Write premultiplied colour if the reader unpremultiplies.
