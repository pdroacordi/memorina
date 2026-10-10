---
id: gotchas/a-tool-script-cannot-call-methods-on-a-non-tool-resource
type: gotcha
title: In the editor, a custom Resource whose script is not @tool is a placeholder; a @tool node can read its exports but every method call fails with "Attempt to call a method on a placeholder instance"
status: active
tags: [tool-script, editor, placeholder, resource, gdscript]
related: [bugs/the-backdrop-editor-preview-calls-methods-on-placeholder-resources, bugs/the-room-map-editor-preview-stops-at-the-first-water-layer, gotchas/duplicate-copies-script-built-unowned-children]
created: 2026-10-08
updated: 2026-10-10
source_files:
  - scenes/world/environment/backdrop/backdrop.gd
  - resources/world/backdrops/backdrop_layer.gd
---

## Summary

In the editor, scripting is off for non-tool scripts. That holds for Resources as well as
Nodes. A `.tres` whose script lacks `@tool` loads with a placeholder instance. Its exported
properties are readable, but `resource.some_method()` from a `@tool` script errors and aborts
the caller. Static functions of non-tool classes still work.

## Details

Measured on 4.7.2 (WORLD-06 review). `Backdrop` (`@tool`) read `layer.texture` and
`layer.scroll_scale` and called `BackdropMath.cover_rect()` (static) and `Room.of()`
(static) without error. Its first call to `layer.strip_size()` logged:
`Invalid call function 'strip_size' in base 'Resource (BackdropLayer)': Attempt to call a method on a placeholder instance. Check if the script is in tool mode.`

## Gotchas / pitfalls

- GdUnit and headless game runs have scripting enabled, so a test of the same code path
  passes. Only an editor run shows the failure:
  `"$GODOT" --headless --editor --path . <scene.tscn> --quit-after 900`.
- Making a resource `@tool` makes its setters and methods run in the editor too. Keep them
  free of side effects on the scene.
- Editing a custom resource's exports in the inspector does not emit `changed` unless a
  setter calls `emit_changed()`. A `@tool` node listening to `changed` must not assume it
  will be told.
- The same holds for a node instantiated from a `PackedScene` whose script is not `@tool`.
  Writing a property that is not exported fails as well: `Invalid assignment of property or
  key 'solid_at' ... on a base object of type 'TileMapLayer (WaterLayer)'`, and the caller
  aborts (`bugs/the-room-map-editor-preview-stops-at-the-first-water-layer`, measured on 4.7.2).
  Exported properties and native methods (`set_cell`) still work.
