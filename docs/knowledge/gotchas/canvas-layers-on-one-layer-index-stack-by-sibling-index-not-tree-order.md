---
id: gotchas/canvas-layers-on-one-layer-index-stack-by-sibling-index-not-tree-order
type: gotcha
title: Two CanvasLayers with the same layer index have no documented order; in practice their sibling index decides, not tree order
status: active
tags: [rendering, canvas-layer, ui, draw-order, greyhush]
related: [bugs/the-seed-shop-panel-draws-under-the-greyhush-and-the-creature-composite, gotchas/screen-texture-copy-scope, systems/foreground]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - scenes/world/game.tscn
  - scenes/world/story/seed_shop_beat.tscn
---

## Summary

The Godot class reference for `CanvasLayer.layer` says that when several CanvasLayers share a layer index, the one drawn in front is not specified. The engine passes each layer's **index among its own siblings** as the sublayer (`canvas_layer.cpp`: `viewport_set_canvas_stacking(viewport, canvas, layer, get_index())`). Tree order does not decide it. A CanvasLayer deep in a room's contents, as child 0 of its parent, is therefore drawn before `Game/CanvasLayer` (child 6 of `Game`).

## Details

- This is read from the engine source and the class reference, not measured in this project. A test cannot assert draw order headless.
- In this project `Game/CanvasLayer` is layer 1. It holds the full-screen `Greyhush` pass, which reads the screen and writes every pixel back with alpha 1 (`gotchas/screen-texture-copy-scope`), and then the `Creatures` and `Foreground` composites. Anything else on layer 1 that is drawn before it is re-shaded by the greyhush and covered by the composites. Anything drawn after it covers the HUD, the `Fade` and the `Letterbox`.

## Gotchas / pitfalls

- "Same layer, earlier in the tree, so it is under the HUD" is not a guarantee in Godot 4. Give a UI layer its own index, or put the UI node inside `Game/CanvasLayer` in the order you want.
- `ScreenLayer` is layer 2. A new layer above the world UI and below the menus needs `ScreenLayer` raised, not a second layer 2.
