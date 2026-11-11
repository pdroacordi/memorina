---
id: bugs/a-split-backdrops-sky-holder-loses-its-clip-when-its-room-wakes
type: bug
title: A split room's Sky holder loses its scissor after its contents hide and show; Backdrop._draw re-clips it too early
status: resolved
severity: low
tags: [backdrop, clip, scissor, canvas-item, performance, tech-12]
related: [gotchas/showing-a-canvas-item-drops-its-rendering-server-clip, systems/backdrops, performance/2026-11-11-tech12-baseline]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - scenes/world/environment/backdrop/backdrop.gd
---

## Summary

`Backdrop._draw` re-applies the clips of itself and its `Sky` holder (`backdrop.gd` `_draw` / `_reclip`). The holder is
a plain `Node2D`, and showing an ancestor queues a redraw for every visible descendant, parent first. The holder's own
redraw therefore runs after `Backdrop._draw` and drops the clip it just set. From the first idle and wake on, a split
room's sky layers are scissored only by the Backdrop's `Part.ALL` rect, not by their `Part.OVER_TOP` cells. Cost only:
the shader still discards every pixel it should, so nothing looks different.

## Symptom

Found in the TECH-12 review, 2026-11-11, with a windowed probe on Godot 4.7.2. The tree was contents (Node2D),
backdrop (a script whose `_draw` re-clips itself to 640x360 and the holder to 50x50), holder (Node2D), and a red
`Polygon2D` 400x300 under the holder:

```
built:                      inside red, outside (200,200) grey   -> holder clipped
contents hidden and shown:  inside red, outside (200,200) red    -> holder clip gone
```

A clip set right after `add_child` survives the holder's first redraw. Only a hide and show drops it. `Room.deactivate`
hides the contents, and `settle` wakes them again on every walk back.

## Root cause

`CanvasItem._handle_visibility_change` calls `queue_redraw()` on the item, then recurses into its children. The
redraw callback clears the canvas item, and that clears its clip flag
(`gotchas/showing-a-canvas-item-drops-its-rendering-server-clip`). The deferred calls run in the order they were
queued, so the holder's clear comes after the Backdrop's `_draw`. `Backdrop._reclip` covers only items whose own
redraw runs no later than the Backdrop's.

## Fix

Fixed 2026-11-11 (TECH-12 fix round). `Backdrop.refresh` connects the holder's `draw` signal to `_clip.bind(holder, over)`
(guarded against a second connect), so the holder sets its own clip again inside its own redraw. `Backdrop._draw` now sets
only the Backdrop's own clip. Measured, GPU at 1920x1080 with vsync off, before the fix -> after:
lake_chasm built 0.405 -> 0.423, contents hidden and shown 0.489 -> 0.396, after leaving and coming back 0.502 -> 0.411;
frost_cliffs 0.450 / 0.463 / 0.543 -> 0.451 / 0.389 / 0.452. orchard_mill_town (no holder) stays 0.61-0.62 ms through
the same steps. No test can read the RenderingServer clip, so the regression check is this measurement.

Proposed before the fix: Re-clip each item from its own redraw. For example, in `refresh` connect
`holder.draw.connect(_clip.bind(holder, over))`, since `draw` is emitted inside the holder's own redraw, after its
clear. Otherwise give the holder a script whose `_draw` calls back. Keep `Backdrop._draw` for the Backdrop's own item.

## Prevention

The gotcha's rule ("set it again in `_draw()`") applies to every item that holds a RenderingServer clip, not only to
the node that owns the script. `clip_of(item)` reports the intended rect, not the RenderingServer state, so no test
can see this. Measure GPU in a split room (lake_chasm, frost_cliffs) after an idle and wake, as the gotcha did for
orchard_mill_town.
