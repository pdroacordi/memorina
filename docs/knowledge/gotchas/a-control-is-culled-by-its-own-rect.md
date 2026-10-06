---
id: gotchas/a-control-is-culled-by-its-own-rect
type: gotcha
title: A Control's _draw outside its own rect disappears once that rect leaves the screen, so draw large canvases from a Node2D
status: active
tags: [control, node2d, draw, culling, canvas-item, ui, map]
related: [architecture/map-reveal-seen-cells-per-room, systems/screens]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - scenes/ui/map/map_canvas.gd
  - scenes/ui/map/map_screen.tscn
---

## Summary

A Node2D's canvas item is culled by the bounds of what it draws. A Control's is culled by
`Rect2(Vector2.ZERO, size)`: on each draw it sets that rect as the canvas item's custom
visibility rect. A Control that draws far outside its size (a pannable map, a zero-size
"canvas" Control) shows correctly while its own rect is on screen, then vanishes entirely as
soon as a pan or zoom moves that rect off screen.

## Details

- Reported by the UI-04 implementation: `MapCanvas` as a zero-size Control was culled. As a
  `Node2D` under the 2x `Art` Control it draws everywhere (`scenes/ui/map/map_canvas.gd:2`,
  `map_screen.tscn` node `Art/Canvas`). The engine side is `Control`'s `NOTIFICATION_DRAW`
  calling `RenderingServer.canvas_item_set_custom_rect` with its own rect (read from the
  4.x source).
- Measured in 4.7.2 (UI-04, 2026-10-06), windowed:
  - with the canvas a zero-size Control at (-45, 90) pack px, `_draw` ran with a fill rect at pack (146, 72), well on screen, and no pixel of it appeared;
  - zoomed so that the origin landed on screen at (58, 90), it drew;
  - as a Node2D, the first case drew too (1,984 ink pixels, the same count as an open centred on screen).
- `clip_contents` is a different setting. It clips children to the rect. With it off, a
  Control's own drawing is still culled by its rect.
- A Node2D child of a Control is positioned and scaled by the Control's transform, so it still
  follows the 2x rule (`systems/screens`, Look).

## Gotchas / pitfalls

- The failure is intermittent: it depends on where the Control's rect is. A test that opens the
  map at its centre passes; a pan to an edge fails.
- Making the Control as large as everything it draws also works. Its size must then be kept in
  sync with the content at every zoom.
