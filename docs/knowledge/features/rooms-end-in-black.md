---
id: features/rooms-end-in-black
type: feature
title: Interiors end where their walls end - black void outside the shell, so a room can be slimmer than the screen
status: active
tags: [void, rooms, interiors, room-map, legend, importer, bell-tower, lighthouse]
related: [systems/rooms, architecture/room-void-outside-the-shell, architecture/walkable-helix-stair, features/rotating-spiral-stair, features/doorways-fit-their-place, gotchas/import-plugin-output-is-stale-when-its-logic-changes, gotchas/an-editor-open-across-an-importer-bump-rewrites-imports-to-the-old-version]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - resources/world/maps/room_legend.tres
  - resources/world/maps/room_legend_entry.gd
  - resources/world/maps/room_map.gd
  - scenes/world/rooms/maps/room_map_parser.gd
  - scenes/world/rooms/maps/room_tile_resolver.gd
  - scenes/world/rooms/maps/room_map_node.gd
  - scenes/world/rooms/maps/room_void.gd
  - addons/room_maps/room_map_importer.gd
  - tools/maps/gen_world_shells.py
---

## Summary

A building interior shows black outside its walls instead of filling the screen with wall material, so a house or a tower can be narrower or shorter than its 640x384 screens. The black is solid: Ivo cannot enter it. The contract is `systems/rooms` (Void).

## Details

- **Legend.** `_`, kind `VOID` (`room_legend_entry.gd:22`), ground `STONE`, no look. To gameplay it is solid stone: a full square on the hidden `Solid` layer, `ground_at()` answers STONE, roots never grow, the reach audit blocks on it.
- **Parsing.** The parser marks `RoomMap.void_cells` (`room_map.gd:53`; `is_void`, `:82`) at `room_map_parser.gd:166`. `_check_void` (`room_map_parser.gd:292`) makes it an error for any of a void cell's 8 neighbours to be air or a ledge, so a drawn wall always stands between the room's air and the void; void may not lie under water, a reach or a secret.
- **Drawing the wall's edge.** `RoomTileResolver.void_filled` (`room_tile_resolver.gd:18`) gives each void cell its nearest wall's look, so the wall's tiles toward the void are fill; `_clear_void_tiles` (`:44`) clears every display tile whose four corners are void.
- **The black.** `RoomMapNode` adds a `Void` node (`room_map_node.gd:102`), a `RoomVoid` (`room_void.gd`) that draws one black rect per merged run of void cells (`runs`) at `Z` 60, over every root-canvas room layer. That cuts the wall on the cell line. It is world art, so the greyhush greys it.
- **Rooms that use it.** The nine building interiors (`village_house`, `village_tavern`, `village_elder`, `village_bakery`, `village_empty_house`, `threshold_farmhouse`, `woods_hut`, `lake_fisher_hut`, `orchard_inn`), `village_bell_tower` and `lighthouse_interior`. Both towers keep 8 interior columns between stone at cols 5 and 14, void at cols 0-4 and 15-19 (`features/rotating-spiral-stair`). `village_tavern_cellar` does not use it: it is dug ground, not a building.
- **New rooms.** `gen_world_shells.py` writes a new interior's shell as one cell of wall with `_` beyond (`voided`, `gen_world_shells.py:223`).
- **Importer.** Room format 10 (`FORMAT_VERSION`, `room_map_importer.gd:27`).
- **Tests.** `room_files_test`: void only in interiors (`room_files_test.gd:92`), every door's art clear of void (`:110`); `room_void_test`; parser, resolver and node suites under `tests/scenes/world/rooms/maps/`.

## Why

- The request, verbatim: "It is ok for a room not to ocuppy 100% ofr the screen width (or some cases, height(. In the case of the tower, for example, the room should be slimmer." (user, 2026-10-11; full quote in `architecture/room-void-outside-the-shell`). The wall's edge at the void: "Straight cut (Recommended)" (user, 2026-10-11).
- A legend character keeps each cell's meaning visible in the `.room` text. Rooms narrower than a screen were rejected because they break the world grid, the camera clamp, the map grid and the backdrop cover; one black node was chosen over clipping four shaders. Options: `architecture/room-void-outside-the-shell`.

## Gotchas / pitfalls

- Interiors only: a surface room would reveal void cells on the map, so `room_files_test` fails void in a room whose `Room.interior` is false until `MapOutline` subtracts them.
- Nothing useful may draw over void: door art, water and secrets are kept off it by tests; a prop overlapping void is cut on the cell line.
- In a forgotten interior the greyhush lifts black: `lighthouse_interior` (frost edge, memory 0.05) shows its void as dark grey.
- The camera is unchanged: the room keeps its full bounds and the frame shows the black.
- A parser or resolver change bumps `FORMAT_VERSION`; reimport after deleting `.godot/imported/*.room-*`, and restart an open editor (`gotchas/import-plugin-output-is-stale-when-its-logic-changes`, `gotchas/an-editor-open-across-an-importer-bump-rewrites-imports-to-the-old-version`).
