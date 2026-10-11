---
id: architecture/room-void-outside-the-shell
type: architecture
title: Void outside a room's shell - a legend character for black solid cells, resolved as the wall's look and covered by one black mask
status: accepted
tags: [void, rooms, room-map, importer, legend, dual-grid, interiors, bell-tower, houses, collision, greyhush, plan]
related: [systems/rooms, systems/world, systems/backdrops, systems/grass, systems/map, systems/greyhush, architecture/rooms-are-text, architecture/biome-tilesets, architecture/secret-false-walls, architecture/doors-and-interiors, architecture/backdrop-seams, architecture/room-reachability-audit, architecture/walkable-helix-stair, gotchas/import-plugin-output-is-stale-when-its-logic-changes, gotchas/an-editor-open-across-an-importer-bump-rewrites-imports-to-the-old-version, bugs/a-rooms-ground-art-hangs-into-the-room-below-at-a-mismatched-seam]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - resources/world/maps/room_legend_entry.gd
  - resources/world/maps/room_legend.tres
  - resources/world/maps/room_map.gd
  - scenes/world/rooms/maps/room_map_parser.gd
  - scenes/world/rooms/maps/room_map_validator.gd
  - scenes/world/rooms/maps/room_tile_resolver.gd
  - scenes/world/rooms/maps/room_map_node.gd
  - addons/room_maps/room_map_importer.gd
  - tools/maps/gen_world_shells.py
---

# Void outside a room's shell

> **ACCEPTED 2026-10-11** (question 1: "Straight cut (Recommended)", user, 2026-10-11) and built in the WORLD-26 worktree: format 10, the nine building interiors and the bell tower adopt it; the contract is in `systems/rooms`.

User, 2026-10-11, verbatim: "It is ok for a room not to ocuppy 100% ofr the screen width (or some cases, height(. In the case of the tower, for example, the room should be slimmer. In the case of the houses, the wood tiles didn't have to fill the rest of the screen either. It's okay to leave a black space or something like that. And the spiraling is not working quite well, there should be something more 3d like. I've attached here a video to help you understand"

## Context

- A room's bounds are whole 640x384 screens and never change (`systems/world`); the camera clamps to them, the map counts cells from them, the backdrop covers them.
- Every interior today fills the screen outside its walls with its wall material (`village_house.room`: rows 9-11 of `%`; `village_tavern.room`: rows 0-3 and 21-23). The bell tower is a full-width stone box.
- The dual grid draws a look's tiles half a cell past its cells (`architecture/biome-tilesets`), so a wall's art cannot simply stop at a cell line by leaving the next cell empty.

## Options considered

**Representation**
- **A `[void]` grid** over solid cells, like `[secret]`: a second grid to keep aligned row by row, for cells that have no material anyway. Rejected.
- **A room-level rule** (`void = 1` in the header: solid cells farther than N cells from air draw black): no authoring, but the text stops showing what is black, the wall thickness is one number per room, and a thick interior mass (the tavern's ceiling, a chimney) blackens in its middle. Rejected: in a `.room` each cell's meaning is visible (`architecture/rooms-are-text`).
- **Rooms narrower than a screen** with a black clear colour: breaks the world grid, the camera clamp, `MapGrid.dims_for` and `BackdropMath.cover_rect`. Rejected.
- **A legend character** (chosen): `_`, kind `VOID`.

**Drawing**
- Clip the ground, back and backdrop shaders to non-void cells and set the clear colour black: four shaders, the backdrop's seam mapping (a GLSL twin), and a global clear colour. Rejected.
- **One black mask node over the void cells** (chosen).

**Wall edge at the void**
- Void read as air for the corner masks: the wall draws its outer face (rounded corners, the seasonal lip on the outside of a ceiling).
- **Void read as the neighbouring wall's look** (chosen, question 1): the wall's tiles toward the void are fill, and the mask cuts them on the cell line, a section cut. This is the `[secret]` resolver's "resolve as if filled" (`architecture/secret-false-walls`).

## Decision

- **Legend.** `_` (kind `VOID`, ground `STONE`, no look). To gameplay it is solid stone: the hidden `Solid` layer gets a full square, `ground_at()` answers STONE, roots never grow (`systems/roots-and-climbing`), the reach audit blocks on it. `Enums.Ground` gains nothing, so `GroundCollision` gains no alternative.
- **Placement rule** (`RoomMapValidator`, parser errors): every one of a void cell's 8 neighbours is non-platform ground, void, or outside the map. So at least one drawn cell of wall always stands between the room's air and the void, corners included. A void cell holds no entity and lies under no `[water]`, reach or `[secret]` cell.
- **RoomMap.** `void_cells: PackedByteArray` (1 per cell, empty when the room has none); `looks` is `NO_LOOK` there; `is_void(cell)`.
- **Resolver.** `RoomTileResolver` resolves the ground layers with each void cell given the look of its nearest drawn ground cell (4-neighbour BFS, ties west, east, north, south), then clears every display tile whose four corners are void. A wall tile toward the void is FULL; the mask covers its void half.
- **Mask.** `RoomMapNode` builds `Void` (`RoomVoid`, a Node2D) after `Entities` when the map has void: `_draw()` fills one black rect per merged horizontal run of void cells, merged downward like `MapOutline.fill_runs`. `VOID_Z := 60`: over every root-canvas room layer (backdrop -30, back -20, props -10, ground 0, secret twin 40, water 50). It is world art, so the greyhush greys it like the world. Built in the editor too, so the preview shows it.
- **Importer.** The next `FORMAT_VERSION` (10 after WORLD-26's 9): `RoomMap` gains a field and the resolver changes. Delete `.godot/imported/*.room-*`, reimport and commit the `.room.import` files; restart an open editor (`gotchas/import-plugin-output-is-stale-when-its-logic-changes`, `gotchas/an-editor-open-across-an-importer-bump-rewrites-imports-to-the-old-version`).
- **Unchanged.** The camera (the room keeps its bounds; the frame shows black outside the shell). Backdrops: "every room has a backdrop" and seam ownership stand; the void covers the backdrop outside the shell, and interiors touch no room. Grass: interiors grow none, and a void top is never exposed. The map: interiors are never revealed (`architecture/doors-and-interiors`).
- **Interiors only, for now.** `room_files_test` fails a void cell in a room whose `Room.interior` is false. A surface room would reveal void cells on the map; `MapOutline` must subtract them before that test is relaxed.
- **Rooms that adopt it now.** Every building interior, walls 1 cell of their material, the fill beyond turned to `_` with no layout change: `village_house`, `village_tavern`, `village_elder`, `village_bakery`, `village_empty_house`, `threshold_farmhouse`, `woods_hut`, `lake_fisher_hut`, `orchard_inn`. `village_bell_tower` is rebuilt slim: interior cols 6-13, stone cols 5 and 14, void cols 0-4 and 15-19 and rows 46-47 (`architecture/walkable-helix-stair`, Revision). Not `village_tavern_cellar` (dug ground continues; it is not a building). `lighthouse_interior` adopts it with its rotating stair (later). Narrowing a house's shell to its furniture moves its door and props: a per-room choice, not part of this item.
- **Generator.** `gen_world_shells.py` writes a new interior's shell as 1 cell of wall and `_` beyond. Existing `.room` files are edited by hand once.
- **Guide.** The legend table in `docs/maps/README.md` is regenerated (`tools/maps/gen_map_docs.tscn`); `map_guide_test` fails until it is.

## Consequences

- Nothing useful may draw over void: door art (`Door.LOOKS` sizes, `Door.SINKS`: a `stairwell` or `hatch_down` needs 3 drawn rows under it), water and secrets are kept off it by tests. A prop overlapping void is cut on the cell line. Root-canvas particles near a wall are cut by the mask; Ivo and his sword draw in the creature pass, over it.
- In a forgotten interior the void shows the greyhush's lifted black (`gh_shade` lifts blacks by how forgotten), like every black in the world art. `lighthouse_interior` sits in the frost edge (memory 0.05), so its void will be dark grey, not black.
- Void costs one draw call per room and no tiles: the cleared display tiles reduce `set_cell` calls.
- No user-facing text.

## Tests

- `room_map_parser_test` / `room_map_validator_test`: void beside air (4- and 8-neighbour), beside a platform or roof, under `[water]`, a reach or `[secret]`, and an entity on void are errors; a void cell's ground is STONE and its look `NO_LOOK`.
- `room_tile_resolver_test`: a void cell takes its nearest wall's look; a display tile with one wall corner and three void corners is FULL for that look; a tile with four void corners is empty in every layer.
- `room_map_node_test`: `Void` exists only with void, at z 60, its rects cover exactly the void cells (merged runs).
- `room_files_test`: void only in interiors; every door's art rect is clear of void; every adopting room parses.
- `reach_audit_test`: a void cell blocks a jump like stone.
- `map_guide_test` (regenerated legend), smoke (no new scene), and a playtest still of `village_house` and the bell tower.

## Questions for the user

1. Where a wall meets the void: a straight cut through the wall (Recommended; the board's tower walls end on a straight edge) or the wall's own outer edge (rounded corners and its top lip)?

## Answers (2026-10-11)

1. Where a wall meets the void: "Straight cut (Recommended)" (user, 2026-10-11).
