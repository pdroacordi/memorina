---
id: gotchas/import-plugin-output-is-stale-when-its-logic-changes
type: gotcha
title: An import plugin's output is redone only when its source file or _get_format_version() changes, not when the code or data it bakes in changes
status: active
tags: [import-plugin, editor, room-maps, staleness, tooling]
related: [architecture/rooms-are-text]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - addons/room_maps/room_map_importer.gd
  - scenes/world/rooms/maps/room_map_parser.gd
  - scenes/world/rooms/maps/ground_autotile.gd
  - resources/world/maps/room_legend.tres
---

## Summary

Godot re-runs an `EditorImportPlugin` for a file when that file's source hash, its import
options, or the importer's `_get_format_version()` changes. It does not track the scripts
or resources the importer reads while importing. The `.room` importer bakes in
`GroundAutotile`'s rules (the resolved tile per cell), the legend's `ground`/`kind` per
symbol, and the parser. Change any of those and every developer's
`.godot/imported/*.room-*.res` keeps the old answer until each `.room` is touched or
`.godot` is wiped. The game then runs on stale tiles and materials.

## Details

- `room_files_test.gd` re-parses the TEXT against the current legend. It never compares
  with the imported `.res`, so it stays green while the game runs stale imports.
- A fresh clone or CI export imports from scratch, so it is correct. The staleness is
  per machine, which makes it a "works on my machine" split.
- `EditorImportPlugin._get_format_version()` exists (checked in 4.7.2's ClassDB).
  `room_map_importer.gd` does not override it (it defaults to 0).

## Gotchas / pitfalls

- Override `_get_format_version()` and bump it whenever the importer's baked logic
  changes (`GroundAutotile`, the parser, `RoomMap`'s layout). A legend edit still needs a
  manual reimport. The importer comment already says so, but the "the suite catches it"
  half of that comment is not true for the imported output.
