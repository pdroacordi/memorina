---
id: gotchas/showing-a-canvas-item-drops-its-rendering-server-clip
type: gotcha
title: Showing a canvas item again drops a clip set through RenderingServer; set it again in _draw
status: active
tags: [rendering, canvas-item, clip, scissor, backdrop, performance]
related: [bugs/a-split-backdrops-sky-holder-loses-its-clip-when-its-room-wakes, systems/backdrops, performance/2026-11-11-tech12-baseline]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - scenes/world/environment/backdrop/backdrop.gd
---

## Summary

Measured on Godot 4.7.2 (Forward+, D3D12). `Backdrop` scissors its layers with `RenderingServer.canvas_item_set_custom_rect`
and `canvas_item_set_clip` on its own canvas item (TECH-12). After the Backdrop, or any ancestor such as a room's contents
that `Room.deactivate` hides, was hidden and shown again, the scissor was gone. The picture did not change, because the
shader still judges every pixel. Only the cost came back: GPU time in orchard_mill_town at 1080p rose from 0.62 ms to
1.08 ms. `refresh()` restored it, and so did calling the clip functions again directly.

Setting the clip again from `NOTIFICATION_VISIBILITY_CHANGED`, even deferred, did not work: the redraw that showing queues
runs later and resets it. Setting it again in `_draw()` does work, because `_draw` runs inside that redraw, after the item is
cleared. Measured after the change: 0.61 ms after a hide and show of the Backdrop, after one of its contents, and after
leaving the region and waking its rooms.

## Rule

A node that sets clip or custom-rect state on a canvas item through `RenderingServer` sets it again from that item's own
redraw: its `_draw()`, or for a plain child node its `draw` signal. A parent's `_draw` is too early for its children:
showing an ancestor queues every descendant's redraw after the parent's, and each one clears its own item
(`bugs/a-split-backdrops-sky-holder-loses-its-clip-when-its-room-wakes`). A node that draws nothing may still override
`_draw`.

## Evidence

The scratch driver timed GPU in orchard_mill_town (1920x1080, vsync off) after each step: start 0.62; Backdrops hidden and
shown 1.08; direct re-clip 0.61; `refresh` 0.61; contents hidden and shown 1.08. With `_draw` re-clipping: 0.61 / 0.61 / 0.61 /
0.62 after leaving and waking the rooms.

## Revision (2026-11-11, review)

The rule applies to each clipped item on its own. Showing an ancestor queues a redraw for every visible descendant,
parent first, and each redraw clears that item's clip. A parent's `_draw` that re-clips a child runs before the child's
own redraw, so the child's clip is lost again. Measured with a windowed probe, 4.7.2: a plain `Node2D` holder re-clipped
from its parent's `_draw` was unclipped after its grandparent was hidden and shown. A clip set right after `add_child`
did survive the first redraw. Re-clip a child from its own `draw` signal or `_draw`
(`bugs/a-split-backdrops-sky-holder-loses-its-clip-when-its-room-wakes`).
