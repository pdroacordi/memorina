---
id: gotchas/subviewport-does-not-inherit-default-texture-filter
type: gotcha
title: A SubViewport ignores the project's default canvas texture filter and defaults to LINEAR
status: active
tags: [rendering, subviewport, pixel-art, texture-filter]
related: [bugs/creature-pass-bilinear-blur, architecture/memory-field-cpu-gpu-split]
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/world/memory/creature_mask.gd
---

## Summary

`rendering/textures/canvas_textures/default_texture_filter` only applies to the root
viewport. Every `SubViewport` has its own `canvas_item_default_texture_filter`, whose
default is `LINEAR`, so anything rendered through a SubViewport in a nearest-filtered
pixel-art project comes out bilinear-blurred unless the property is set explicitly.

## Details

`project.godot` sets `default_texture_filter=0` (nearest). `CreatureMask`
(`scenes/world/memory/creature_mask.gd`) is a SubViewport that renders every creature
carrying a `GreyhushShield` in `SILHOUETTE` mode. Until 2026-09-20 it never touched
`canvas_item_default_texture_filter`, so Ivo and both guardians were drawn with linear
filtering while `BruteShadow` (HALO mode, world pass) stayed crisp — a difference that
only showed as "the bosses look blurry compared to the rest".

The fix is one line in `_ready()`: mirror the root's value
(`canvas_item_default_texture_filter = get_tree().root.canvas_item_default_texture_filter`).

## Gotchas / pitfalls

- The blur is subtle at 1× and obvious at 2× sprite scale or under camera zoom, which
  is exactly when guardians (scale 2) and the Memorina focus zoom (1.5) are on screen.
- Any future SubViewport (minimap, portrait, flashback layer) needs the same line.
