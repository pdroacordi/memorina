---
id: gotchas/import-plugin-output-is-stale-when-its-logic-changes
type: gotcha
title: An import plugin's output is redone only when its source file or its .import file changes, not when the code or data it bakes in changes (a _get_format_version() bump alone does nothing)
status: active
tags: [import-plugin, editor, room-maps, staleness, tooling]
related: [architecture/rooms-are-text]
created: 2026-09-30
updated: 2026-10-07
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

## Revision (2026-10-07)

Measured in 4.7.2 with a throwaway project (one addon `EditorImportPlugin`, one source file):
bumping `_get_format_version()` from 1 to 2 or 3 did **not** reimport the file. This held for
`--headless --import`, for `--headless -e` and for a windowed `-e` run. The `.import` file kept
`importer_version=1` and `_import` was never called. The Summary's claim that a format-version
change makes Godot reimport is wrong for an addon importer.

What does reimport:
- A changed `.import` file. Editing `importer_version=1` to `2` in `a.foo.import` and then
  running `--import` called `_import`. This is the path that reaches other checkouts: the
  developer who bumps the version must force the reimport locally (delete
  `.godot/imported/*.room-*`, then `--import`) and commit the rewritten `.room.import` files.
  Other machines then reimport because their `.import` files changed on pull.
- A changed source file, or a missing imported file.

Bumping `FORMAT_VERSION` alone is a no-op. It only matters because the reimport it is meant to
cause writes the new `importer_version` into the committed `.import` files.
`room_map_importer.gd`'s header ("unless FORMAT_VERSION is bumped, which makes the editor
reimport every map") states the wrong mechanism. `systems/rooms` ("Format 3") states the
working one.
