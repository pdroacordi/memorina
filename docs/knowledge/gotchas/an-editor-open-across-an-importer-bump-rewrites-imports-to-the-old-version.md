---
id: gotchas/an-editor-open-across-an-importer-bump-rewrites-imports-to-the-old-version
type: gotcha
title: A Godot editor left open across a room importer version bump reimports with the plugin it loaded and rewrites every .room.import to the old version
status: active
tags: [import-plugin, editor, room-maps, staleness, tooling]
related: [gotchas/a-failed-import-is-cached-and-not-retried, gotchas/import-plugin-output-is-stale-when-its-logic-changes, systems/rooms]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - addons/room_maps/room_map_importer.gd
---

## Summary

An editor started before `room_map_importer.gd`'s `FORMAT_VERSION` was bumped keeps the old plugin script in memory.
When it reimports (on focus, after a file changes on disk), it writes `importer_version=<old>` into every
`.room.import`, and a map that uses syntax the old parser rejects is written `valid=false`. Headless runs then load
nothing for those maps (`[ext_resource] referenced non-existent resource`), and `git status` shows every
`.room.import` modified.

## Details

- Seen 2026-10-10: 66 `.room.import` files went from 7 to 6; `lake_well`, `caldera_cistern` and `winter_trial`
  (held water, FORMAT 7) were `valid=false`. A Godot window was running beside the headless tools.
- Fix: `git checkout -- <the .room.import files>`, touch one `.room`, `"$GODOT" --headless --path . --import`.
- Prevention: restart the editor (or disable and re-enable the `room_maps` plugin) after pulling an importer bump.
  Never commit a `.room.import` diff that only lowers `importer_version`.
