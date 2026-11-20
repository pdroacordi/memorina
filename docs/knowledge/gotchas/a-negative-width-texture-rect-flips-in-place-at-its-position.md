---
id: gotchas/a-negative-width-texture-rect-flips-in-place-at-its-position
type: gotcha
title: draw_texture_rect_region with a negative width flips the texture but still draws from position to position + |width|, not leftward
status: active
tags: [canvas-item, draw, texture, flip, mirror, godot-4]
related: [bugs/a-mirrored-spawn-art-frame-draws-one-frame-width-east, playtests/2026-11-20-grd19-spawn-origins-and-seams]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - resources/characters/guardians/spawn_art.gd
---

## Summary

In Godot 4.7.2, `CanvasItem.draw_texture_rect_region(tex, Rect2(x, y, -w, h), src)` mirrors the texture but covers
x..x+w. It does not cover x-w..x. A mirror written as `Rect2(at + Vector2(w, 0), Vector2(-w, h))`, which expects
the negative size to extend leftward, therefore draws one full width to the right of `at`.

## Details

Measured with a windowed `-s` probe (2026-11-20). It drew the 16x16 `bloom_seed_pod.png` frame once with
`Rect2(100, 20, 16, 16)` and once with `Rect2(116, 60, -16, 16)`, then read back the viewport:
- plain: opaque game x 100..116;
- negative width: opaque game x **116..132**, flipped.

The renderer takes the absolute size, sets the flip flag, and keeps the position.

## Gotchas / pitfalls

- To mirror in place, pass the same rect as the unflipped draw (`Rect2(at, Vector2(-w, h))`). Alternatively, use
  a `draw_set_transform` with scale (-1, 1) about the centre.
- A test that checks only the returned `Rect2` math cannot catch this. Only the rendered pixels show it.
