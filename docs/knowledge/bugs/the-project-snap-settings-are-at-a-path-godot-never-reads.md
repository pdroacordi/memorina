---
id: bugs/the-project-snap-settings-are-at-a-path-godot-never-reads
type: bug
title: project.godot's 2D pixel-snap settings sit at a path Godot does not read, so nothing in the game snaps transforms or vertices to pixels
status: resolved
severity: low
tags: [rendering, project-settings, pixel-art, snap, subviewport]
related: [gotchas/subviewport-does-not-inherit-default-texture-filter, systems/foreground]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - project.godot
  - scenes/world/memory/canvas_pass.gd
---

## Summary

`project.godot` has `2d/snap_2d_transforms_to_pixel=true` and `2d/snap_2d_vertices_to_pixel=true`
under `[rendering]`, so their keys are `rendering/2d/snap_2d_*`. Godot reads
`rendering/2d/snap/snap_2d_*`. Both settings are therefore off: the root viewport does not snap,
and `CanvasPass` copies `false` from it.

## Symptom

Found in the MEM-12 review, while checking whether the new snap mirroring in `canvas_pass.gd`
changes the creature pass. It does not, because there is nothing to mirror. Measured in 4.7.2:
`ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel")` is `false` and
`get_tree().root.snap_2d_transforms_to_pixel` is `false`. The keys have been at this path since
the initial scaffold (`222d605`).

## Root cause

The two lines were added to `project.godot` by hand at `project.godot:202-203`. The Project
Settings dialog writes them as `2d/snap/snap_2d_transforms_to_pixel` under `[rendering]`. Godot
ignores an unknown key without a warning.

## Fix

Not fixed. This needs a user decision. Moving the keys to `2d/snap/...` would turn snapping on for
the whole game for the first time (root, both passes via `CanvasPass`, every sprite and camera
move), and that needs a playtest. Otherwise, delete the dead lines so nobody believes snapping
is on.

## Prevention

Set project settings from the editor dialog, not by hand. A test could assert that every key in
`project.godot` exists in `ProjectSettings.get_property_list()`. Not added.

## Resolution (2026-10-09)

The user: "Turn snapping on". `project.godot` now has `rendering/2d/snap/snap_2d_transforms_to_pixel` and `snap_2d_vertices_to_pixel`; gates green, the foreground demo renders unchanged.
