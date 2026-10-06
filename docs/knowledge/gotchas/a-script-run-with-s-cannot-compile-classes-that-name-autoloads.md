---
id: gotchas/a-script-run-with-s-cannot-compile-classes-that-name-autoloads
type: gotcha
title: A SceneTree script run with -s cannot name autoloads, nor type a variable as a class that names one
status: active
tags: [tools, cli, autoload, typing, screenshots]
related: [systems/notebook]
created: 2026-10-06
updated: 2026-10-06
source_files: []
---

## Summary

`godot --path . -s script.gd` compiles the script before the autoloads exist as identifiers.
`InputDevice.glyph_set` in it fails with `Identifier not found: InputDevice`. Typing a variable as a
project class whose script names an autoload (`var notebook: Notebook`) fails too, with
`Failed to compile depended scripts`.

## Details

- Measured in 4.7.2 (UI-03 screenshot scripts, 2026-10-06). The autoload nodes are still in the tree
  at run time: `root.get_node("InputDevice")` works.
- Fix used: reach autoloads with `root.get_node(...)` and keep the script's variables untyped
  (`Node`), calling methods dynamically. Enums from a class with no autoload references
  (`Enums.Song`) compile.
