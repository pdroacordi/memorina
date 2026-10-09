---
id: bugs/the-backdrop-editor-preview-calls-methods-on-placeholder-resources
type: bug
title: The @tool Backdrop calls BackdropLayer.strip_size() in the editor, where the non-tool resource is a placeholder, so every contents scene with a Backdrop logs five SCRIPT ERRORs on open and shows no preview
status: resolved
severity: medium
tags: [backdrop, tool-script, editor, placeholder, resource, world-06]
related: [systems/backdrops, architecture/vertical-backdrops, gotchas/a-tool-script-cannot-call-methods-on-a-non-tool-resource]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/environment/backdrop/backdrop.gd
  - resources/world/backdrops/backdrop_layer.gd
  - resources/world/backdrops/backdrop_set.gd
---

## Summary

`backdrop.gd` is `@tool`, but `backdrop_layer.gd` and `backdrop_set.gd` are not. In the
editor their instances carry a placeholder script, so `Backdrop._add_layer` fails at its
first method call on a layer. No layer is built and the editor logs one SCRIPT ERROR per
layer each time a scene with a Backdrop opens. That covers the 8 trial rooms and the 31
new-world rooms.

## Symptom

Reproduced on 4.7.2 with `"$GODOT" --headless --editor --path . res://scenes/world/rooms/trials_winter/contents/winter_trial_contents.tscn --quit-after 900`
(WORLD-06 review, 2026-10-08). The log shows this five times (one per `pine_woods` layer):

```
SCRIPT ERROR: Invalid call function 'strip_size' in base 'Resource (BackdropLayer)': Attempt to call a method on a placeholder instance. Check if the script is in tool mode.
   at: Backdrop._add_layer (res://scenes/world/environment/backdrop/backdrop.gd:53)
```

The plan's editor preview (layers at the reference pose) is never drawn. The runtime is
unaffected because scripting is enabled there. `backdrop_test.test_without_a_room_it_builds_from_the_preview_bounds`
passes because GdUnit runs with scripting enabled, so no test can catch this.

## Root cause

- `backdrop.gd:53` calls `layer.strip_size()` and, through `backdrop_layer.gd:37-46`, any
  `problems()` call would fail the same way. Exported properties are readable on a
  placeholder; methods are not (`gotchas/a-tool-script-cannot-call-methods-on-a-non-tool-resource`).
- Static calls are fine. `BackdropMath.cover_rect` (line 52) and `Room.of` (line 41) ran
  before the failure.
- Precedent in this repo: `RoomMapNode` is `@tool`, and so are the resources it calls
  (`room_map.gd`, `room_legend.gd`, `room_legend_entry.gd`).

## Fix

Not fixed. Add `@tool` to `backdrop_layer.gd` and `backdrop_set.gd`.

Related, editor only: the live refresh does nothing. `Backdrop` rebuilds on `backdrop_set.changed`
(`backdrop.gd:16-20`), but nothing in the backdrop scripts calls `emit_changed()`.
`BackdropSet` also does not forward its layers' `changed`, so editing a layer's
`horizon_row` or fills in the inspector does not redraw the preview. If that is wired
(setters that call `emit_changed()`), guard `refresh()` with `is_inside_tree()`. Scenes in
background editor tabs are out of the tree, and they share the cached `pine_woods.tres`.
A refresh there would read `global_position` off-tree.

## Prevention

A `@tool` node may call methods only on resources whose scripts are also `@tool`. A
headless editor run that opens one scene using the node shows the failure in seconds:
`--headless --editor --path . <scene> --quit-after 900`. A GdUnit test cannot show it.

## Resolution (2026-10-08)

`BackdropLayer` and `BackdropSet` are `@tool`; `Backdrop.refresh()` returns when the node is out of the tree. The reviewer's headless editor run on `winter_trial_contents.tscn` logs no script error.
