---
id: gotchas/find-child-skips-nodes-a-script-built
type: gotcha
title: find_child matches only owned nodes by default, so rows a script built are not found
status: active
tags: [find-child, owner, tests, scene-tree, ui]
related: [gotchas/duplicate-copies-script-built-unowned-children, systems/settings]
created: 2026-11-10
updated: 2026-11-10
source_files:
  - scenes/ui/settings/settings_screen.gd
---

## Summary

`Node.find_child(pattern, recursive = true, owned = true)` skips every node whose `owner` is null. Rows `SettingsScreen` builds in `_ready` have no owner, so `screens.find_child("SettingsVolumeMaster")` returned null (measured 4.7.2) while `get_node("SoundPage/SettingsVolumeMaster")` found it.

## Details

In tests, find a script-built node with `find_child(name, true, false)` or by a path from an owned parent. Code-built names should be stable (`SettingRow.make` names a row after its key in PascalCase, `BindingRow.make` after its action) so tests can reach them.
