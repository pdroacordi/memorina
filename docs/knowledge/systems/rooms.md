---
id: systems/rooms
type: system
title: Rooms: text maps, the importer and the legend
status: active
tags: [rooms, map, importer, legend, tilemap]
related: [systems/map, architecture/rooms-are-text, bugs/a-teleported-ivo-enters-the-room-he-left, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step, gotchas/import-plugin-output-is-stale-when-its-logic-changes]
created: 2026-10-02
updated: 2026-10-06
source_files:
  - addons/room_maps/room_map_importer.gd
  - resources/world/maps/room_legend.tres
---

# Rooms: text maps, the importer and the legend

Moved verbatim from `CLAUDE.md` ("Project structure") on 2026-10-02. The file format itself is `docs/maps/README.md`.

**Rooms are text** (`docs/maps/README.md`, the `room-map` skill). A `.room` file is an ASCII grid - one character per 32 px cell, `#` earth, `S` stone, `=` a one-way ledge, entity letters - plus an optional `[water]` layer (water can lie OVER ground; `r` and `u` are reaches the parser joins to the water under them - the rain's and a shell's - `systems/water`) and `[entities]` params by grid column,row. `addons/room_maps` imports it ONCE (bump `room_map_importer.gd`'s `FORMAT_VERSION` whenever the parser, `GroundAutotile` or `RoomMap` change, or checkouts keep stale imports) into a `RoomMap` resource with every ground tile already resolved (`GroundAutotile`), so a room's load is one `set_cell` per cell; `RoomMapNode` builds the ground `TileMapLayer`, one `WaterLayer` per kind of water and the entities as SIBLINGS of the ground (a lake parented under the ground's TileMapLayer stopped drawing in front of it); the entities share one `Entities` node filled outside the tree and added whole, so a link resolves whatever order the file lists them in. Never paint ground in the editor: the `RoomMap` node's children are a preview and are never saved. `resources/world/maps/room_legend.tres` is the only place a character means anything; `EntityParams` applies params by property name (a bare `id` in a NodePath param links to that sibling). `floor_tileset.tres` is the one floor TileSet (`tools/maps/build_floor_tileset.gd`); its `ground` custom data is each tile's `Enums.Ground`, and `RoomMapNode.ground_at()` answers what the ground is made of. The guide's legend, entity params and Ivo's reach (`JumpReach`) are GENERATED (`tools/maps/gen_map_docs.tscn`) and `map_guide_test.gd` fails when they drift; `room_files_test.gd` validates every map against the current legend. Tools that load the legend's entity scenes run as scenes (`res://tools/maps/*.tscn`), not `-s` scripts, because only a running scene has the autoloads those scenes reference.

## Regions, benches and room entry

- `Region.name_key` is the translation key of the region's name (`REGION_HOME_VILLAGE`, `REGION_FROST_EDGE`, `REGION_TRIALS` on the five trials). A rest saves it so the title can name the slot. Every new region sets it.
- A bench's `bench_id` names it on the title through `"BENCH_" + bench_id` in capitals. `room_files_test` fails when a bench in any `.room` has no such key with every language filled.
- **`Game.room_changed(room)`** fires once the camera frames the new current room: after `_enter_room` on a walk-in, after a hazard respawn that changes the room, and after `_arrive`'s seat and `snap()` (never from `_enter_room` itself, `bugs/a-debug-boot-reveals-map-cells-ivo-never-saw`). `MapRevealer` and `RegionWeather` listen to it.

## Doors and interiors (WORLD-09, design 04 §4, `architecture/doors-and-interiors`)

- A door is the legend entity `E` (`scenes/world/interactables/door/`). Its `link` is shared by exactly two doors across the world; its `to_room` is the partner's room id, the Room scene's file name (`Room.id()`), in the same region. `requires` (a `SaveFact` `.tres` path) seals it; `arrive_facing` turns Ivo on arrival there. `room_files_test` checks every pair (`DoorLinks`).
- Up in reach (or reached within `Player.DOOR_BUFFER`, 0.1 s; "Buffer it ~0.1 s", user, 2026-10-08): `Player._try_door` drops every other buffered press and emits `door_entered(door)`; `Game` disables Ivo DEFERRED (the press arrives inside his physics step, `gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move`), fades out, and lands him through `_land_in(room, place)` - the same landing `_arrive` uses (enter, wait for the contents, place, `snap`, `room_changed`). A sealed door knocks.
- `Room.interior`: never revealed on the map, no weather; the map opens on the building's door instead (`Screens.set_map_anchor`, cleared by any non-interior room).
- Authoring an interior: below its region's rooms, outside every `RegionMemory` source's reach (it then shares the region's baseline, season and death marks); bounds at least 640x360, filled; never touching another room's bounds. The test bed is `trials_solstice/door_trial` and `door_trial_inside` (F10, x 18560).
- **The map is keyed by the room's `SceneKey`**, with cells counted from the top-left of its bounds, so a region that moves keeps its map. Bounds that are not a multiple of 64 px round the grid up (a 602 px room has 10 rows). Two rooms instanced from one scene would share a map; today every room is its own scene (`systems/map`).
- A `Room`'s `body_entered` drives `Game`'s room transitions and trusts the physics server. Moving Ivo by writing his position leaves the server one step behind, and the room at his old place reports him. Every non-motion move goes through `Character.teleport` (`systems/life-benches-death`, `gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step`).

- **Format 3** (2026-10-07, PZL-09): `RoomMap.reach`. **Format 4** (2026-10-08, PZL-06): `RoomMap.shell_reach`. A format bump does not reimport on a headless `--import`: delete `.godot/imported/*.room-*` and import again, and commit the `.room.import` files (`gotchas/import-plugin-output-is-stale-when-its-logic-changes`).
