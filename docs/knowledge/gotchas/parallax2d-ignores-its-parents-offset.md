---
id: gotchas/parallax2d-ignores-its-parents-offset
type: gotcha
title: Parallax2D sets its local position from the camera's global screen offset, so under a parent placed far from the origin its layers drift by (1 - scroll_scale) x the parent's offset
status: active
tags: [parallax2d, background, rendering, regions, trials, camera]
related: [systems/seasonal-art, systems/rooms]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - scenes/world/rooms/trials_spring/contents/spring_trial_contents.tscn
  - scenes/world/debug/debug_trials.gd
---

## Summary

A `Parallax2D` overwrites its own LOCAL `position` every frame with
`screen_offset * (1 - scroll_scale) + scroll_offset`, where `screen_offset` is the
camera's top-left in GLOBAL coordinates. The parent's position is not subtracted. A layer
authored around a room at the origin draws `(1 - scroll_scale) * parent_x` pixels further
right when the room's region is placed at `parent_x`.

## Details

Headless probe on 4.7.2 (2026-10-07): a `Parallax2D` with `scroll_scale = (0.2, 1)` under
a `Node2D` at (7200, 6000), the camera's screen offset at x 7320. The layer's local x was
5856 (`0.8 * 7320`), global x 13056. With `scroll_offset.x = -0.8 * 7200` its local x
became 96 (`0.8 * (7320 - 7200)`), the same as a room at the origin with the camera 120 px
in.

The trials regions are placed at `DebugTrials.origin + spacing * i` (x 0, 2400, 4800,
7200, 9600) and `FrostEdge` at x 5856. Every room `*_contents.tscn` authors its five layers
with `scroll_scale` 0.1 to 0.8 and no `scroll_offset`. In the spring trial (x 7200) the
layers at 0.1, 0.2 and 0.4 shift 3600 to 6480 px and are off screen; at the room's right end
only the two front tree layers (0.6, 0.8) are seen, over the clear colour.

## Gotchas / pitfalls

- A room's background looks right in its own contents scene in the editor and wrong only
  once the region is placed away from the origin.
- Compensation is `scroll_offset.x = -(1 - scroll_scale.x) * region_x`. It depends on where
  the region is placed, so it belongs to whatever places the region, not to the contents scene.
- Moving a region (or changing `DebugTrials.spacing`) moves its backgrounds by a different
  amount per layer.
