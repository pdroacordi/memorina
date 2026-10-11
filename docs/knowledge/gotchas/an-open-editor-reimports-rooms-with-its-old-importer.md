---
id: gotchas/an-open-editor-reimports-rooms-with-its-old-importer
type: gotcha
title: A Godot editor left open across an importer change re-imports .room files with the old plugin and caches them as failed
status: active
tags: [import, room-maps, editor, plugin, format-version]
related: [gotchas/a-failed-import-is-cached-and-not-retried, systems/rooms]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - addons/room_maps/room_map_importer.gd
---

# An open editor re-imports rooms with its old importer

## Symptom

After a commit that raised `FORMAT_VERSION` (8 to 10, the void cell `_`), every room using the new syntax failed in the main checkout: the smoke run listed "referenced non-existent resource ... .room" for ten rooms, and the suite had 21 errors. The `.room.import` sidecars there read `importer_version=8` and `valid=false`, while the committed ones read 10.

## Cause

A Godot editor was open on the project (a GUI `Godot_v4.7.2-stable_win64` process). It keeps the room_maps plugin script it loaded at start, so when the checkout's `.room` files changed it re-imported them with the version-8 parser, which rejects `_`, and wrote the failure into the sidecars. A headless `--import` does not retry a cached failure (`gotchas/a-failed-import-is-cached-and-not-retried`).

## Fix

`git checkout --` the rewritten `*.room.import` sidecars, then `"$GODOT" --headless --path . --import`. Restart the editor after any change to `addons/room_maps/`, or close it before pulling one.

## Prevention

Before running the gates after a merge that touches the importer, check `git status` for modified `.room.import` files: a sidecar the commit did not change means another process re-imported.
