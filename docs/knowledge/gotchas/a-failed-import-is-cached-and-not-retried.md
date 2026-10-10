---
id: gotchas/a-failed-import-is-cached-and-not-retried
type: gotcha
title: A failed import is cached as valid=false at the importer's current version, and --import never retries it until the source or the version changes
status: active
tags: [import, editor-import-plugin, room-map, godot-4.7, world-07]
related: [gotchas/import-plugin-output-is-stale-when-its-logic-changes, systems/rooms, architecture/biome-tilesets]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - addons/room_maps/room_map_importer.gd
---

# A failed import is cached and not retried

**Measured in 4.7.2 (WORLD-07).** When an `EditorImportPlugin` returns an error, Godot still writes the
file's `.import` sidecar, with `importer_version=<current>` and `valid=false`. On the next
`--import` the file looks up to date (same source, same version), so it is skipped: deleting
`.godot/imported/*.room-*` is not enough, and every scene that loads the file reports
`Failed loading resource`.

Seen when FORMAT 5 first imported the rooms before the new biome PNGs were imported (the
importer ran at order 0, as textures do): every room failed with "tileset 'legacy' has no
earth", and stayed failed after the order was fixed.

**To force a retry:** change the source, or set `importer_version` in each `.room.import` to any
value other than the importer's `FORMAT_VERSION`, then `--import`. Restoring the committed
sidecars does the same when the format was just bumped.

**Prevention:** an importer that loads other imported resources runs after them
(`_get_import_order` above 0 for textures; the room importer uses 50).
