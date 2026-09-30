---
id: gotchas/tilemaplayer-enabled-does-not-hide-children
type: gotcha
title: TileMapLayer.enabled = false removes only the layer's own tiles; nodes added under it keep drawing and processing
status: active
tags: [tilemaplayer, rendering, scene-tree, water, level-design]
related: [architecture/water-is-world-art-reflecting-two-passes]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/environment/water/water_layer.gd
---

## Summary

In Godot 4.7, `TileMapLayer.enabled = false` removes what the LAYER itself builds from
its cells: rendering quadrants, collision, navigation, and the scene tiles it
instantiated. Ordinary children added with `add_child()` are not affected. They keep
drawing, keep `is_visible_in_tree()`, and keep processing. `visible = false` is the
opposite: it hides every child as well.

## Details

`WaterLayer` (`water_layer.gd:31-36`) depends on this. The painted cells are an editor
preview. At runtime the layer sets `enabled = false` and `add_child()`s one water body
per basin under itself. A headless probe on 4.7.2 (2026-09-23, loading
`downtown_contents.tscn` and `woods_contents.tscn` and waiting two frames) reported the
layer as `enabled=false` and every body and its `Surface` quad as
`is_visible_in_tree() == true`, at `z_index` 50 absolute.

Setting `enabled` inside `_ready` does not flash the tiles for one frame. The layer's
internal update is deferred, and by the time it runs `enabled` is already false, so no
quadrant is ever built.

Calling `add_child()` on the node itself inside its own `_ready` is also fine. The
"parent busy setting up children" error applies to adding to a parent that is still
propagating ready to its children, not to adding to yourself.

## Gotchas / pitfalls

- Hiding the preview with `visible = false` would also hide the runtime bodies.
  `enabled` is the correct switch.
- `self_modulate` on the layer tints only the swatch. `modulate` would also tint every
  body added under the layer. The presets use `self_modulate` for this reason.
- A scene tile (a `TileSetScenesCollectionSource`) is not a plain child. The layer
  frees it when it is disabled, so it cannot replace this pattern.
