---
id: systems/rooms
type: system
title: Rooms: text maps, the importer and the legend
status: active
tags: [rooms, map, importer, legend, tilemap]
related: [architecture/rooms-are-text, gotchas/import-plugin-output-is-stale-when-its-logic-changes]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - addons/room_maps/room_map_importer.gd
  - resources/world/maps/room_legend.tres
---

# Rooms: text maps, the importer and the legend

Moved verbatim from `CLAUDE.md` ("Project structure") on 2026-10-02. The file format itself is `docs/maps/README.md`.

**Rooms are text** (`docs/maps/README.md`, the `room-map` skill). A `.room` file is an ASCII grid - one character per 32 px cell, `#` earth, `S` stone, `=` a one-way ledge, entity letters - plus an optional `[water]` layer (water can lie OVER ground) and `[entities]` params by grid column,row. `addons/room_maps` imports it ONCE (bump `room_map_importer.gd`'s `FORMAT_VERSION` whenever the parser, `GroundAutotile` or `RoomMap` change, or checkouts keep stale imports) into a `RoomMap` resource with every ground tile already resolved (`GroundAutotile`), so a room's load is one `set_cell` per cell; `RoomMapNode` builds the ground `TileMapLayer`, one `WaterLayer` per kind of water and the entities as SIBLINGS of the ground (a lake parented under the ground's TileMapLayer stopped drawing in front of it); the entities share one `Entities` node filled outside the tree and added whole, so a link resolves whatever order the file lists them in. Never paint ground in the editor: the `RoomMap` node's children are a preview and are never saved. `resources/world/maps/room_legend.tres` is the only place a character means anything; `EntityParams` applies params by property name (a bare `id` in a NodePath param links to that sibling). `floor_tileset.tres` is the one floor TileSet (`tools/maps/build_floor_tileset.gd`); its `ground` custom data is each tile's `Enums.Ground`, and `RoomMapNode.ground_at()` answers what the ground is made of. The guide's legend, entity params and Ivo's reach (`JumpReach`) are GENERATED (`tools/maps/gen_map_docs.tscn`) and `map_guide_test.gd` fails when they drift; `room_files_test.gd` validates every map against the current legend. Tools that load the legend's entity scenes run as scenes (`res://tools/maps/*.tscn`), not `-s` scripts, because only a running scene has the autoloads those scenes reference.
