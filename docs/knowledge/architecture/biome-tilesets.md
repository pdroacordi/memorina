---
id: architecture/biome-tilesets
type: architecture
title: Biome tilesets - a room's `tileset =` picks a BiomeTileset whose look sheets are 16-tile corner-Wang sets drawn on a dual grid (one layer per look, an underlay rule at material seams), collision on its own hidden cell layer, Enums.Ground.WOOD, and a `[back]` grid of darkened walls (WORLD-07)
status: active
tags: [tileset, tiles, autotile, wang, dual-grid, rooms, room-map, importer, legend, seasonal-art, back-wall, wood, pixellab, codex, art-contract, plan, world-07]
related: [systems/rooms, architecture/rooms-are-text, systems/seasonal-art, systems/art-pipeline, systems/roots-and-climbing, architecture/roots-join-earth-to-earth, architecture/vertical-backdrops, architecture/doors-and-interiors, architecture/foreground-layer, gotchas/tileset-padding-bakes-only-defined-tiles, gotchas/import-plugin-output-is-stale-when-its-logic-changes, gotchas/lake-hidden-under-a-tilemaplayer-parent, gotchas/tilemaplayer-enabled-does-not-hide-children, gotchas/duplicate-copies-script-built-unowned-children, gotchas/a-script-run-with-s-cannot-compile-classes-that-name-autoloads, gotchas/logger-log-error-also-receives-warnings, bugs/room-map-node-rebuild-renames-and-doubles-its-children, bugs/root-bridge-strands-meet-at-a-step]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - resources/world/tiles/biome_tileset.gd
  - resources/world/tiles/biomes/
  - resources/world/maps/room_map.gd
  - resources/world/maps/room_legend_entry.gd
  - resources/world/maps/room_legend.tres
  - scenes/world/rooms/maps/ground_autotile.gd
  - scenes/world/rooms/maps/room_tile_resolver.gd
  - scenes/world/rooms/maps/ground_collision.gd
  - scenes/world/rooms/maps/room_map_parser.gd
  - scenes/world/rooms/maps/room_map_node.gd
  - scenes/world/rooms/maps/map_guide.gd
  - addons/room_maps/room_map_importer.gd
  - scenes/world/memory/seasonal/seasonal_art.gdshader
  - tools/art/wang_sheet.gd
  - tools/art/assemble_tile_sheet.gd
  - tools/pixellab/pixellab.ps1
---

> **Status: PLAN** (2026-10-08, roadmap WORLD-07). Nothing below is built yet.

## Summary

The `[room]` header gains `tileset = <id>`, naming `resources/world/tiles/biomes/<id>.tres`, a `BiomeTileset` with one sheet per **look** (earth, stone, wood, wall). A legend character carries the gameplay `Enums.Ground` and a look; the biome only supplies the look's art. Every look sheet is the same contract: a 16-tile corner-Wang set (the PixelLab sidescroller output), plus fill variants and a ledge strip, in three season bands. The ground is drawn on a **dual grid**: one `TileMapLayer` per look, offset half a cell, where each tile's four corners are the four cells around it. Where two looks meet, the earlier look is laid under the later one only next to it. Collision moves to a hidden cell-aligned `Solid` layer with one shared collision TileSet. `Enums.Ground` gains `WOOD`. A `[back]` grid draws darkened, non-colliding walls with the same sheets plus a back-only wall look. The current sheet is converted into a `legacy` biome so every room keeps its look until new art lands.

## Context

- **Today.** `GroundAutotile` maps 8 neighbours onto about 22 tiles of a 9-column block. It approximates:
  - diagonals are read only when both sides are solid;
  - the first open diagonal wins;
  - a lone cell takes the platform's left end;
  - a one-high solid run draws as a one-way ledge.
- `floor_tiles.png` is GandalfHardcore pack art plus stone derived by `derive_stone_tiles.gd`. The pack is being retired.
- Collision and the `ground` custom data sit on the drawn tiles, but nothing reads that custom data at runtime. Gameplay reads `RoomMap.ground` through `ground_at()` (`RootSpanFinder`, `RootCatchFinder`, `WaterBody`).
- `FLOOR_TILESET.tile_size` is used as "the cell size" in `drawbridge.gd`, `lowering_platform.gd`, `root_grower.gd` and `RoomMapNode._paint`.
- **PixelLab sidescroller tileset** (measured 2026-10-08; sample in the session scratchpad `pl_tiles/`):
  - It returns 16 tiles, each with `corners` {NW, NE, SW, SE} set to `lower` (material) or `upper` (empty).
  - Its name index is NW·8 + NE·4 + SW·2 + SE·1 with upper = 1 (`wang_0` is full, `wang_15` empty).
  - The art is dual-grid: each quadrant of a tile belongs to the cell at that corner, so a cell edge is the tile's midline.
  - At `transition_size` 0.25 the grass lip fills about the top 10 px of an exposed quadrant. Allowed values are 0, 0.25, 0.5 and 1.
  - `lower_base_tile_id` links a run to an existing base tile but does not promise identical pixels.
  - The job answers 423 for about 70 s. The result is usable raw material but generic.
- **Design.**
  - 04 §6 lists the floor materials per biome. Nature art has three versions (summer uses spring's); buildings and interiors have one.
  - 02 §7.1: "Só terra enraíza, nunca pedra - o material diz ao jogador onde a canção serve."
- **Art direction.** The user approved the concept painting on 2026-10-08 with "Yes, aim for this": detailed, warm, painterly pixel art; dark earth with a grassy lip; a cobblestone street of rounded grey stones with moss in the joints. Tiles must match its density and palette.

## Options considered

**How biomes coexist**
- (a) One TileSet with an atlas source per biome. Rejected:
  - every room loads every biome's sheets;
  - source ids (biome × look) get baked into every import, so adding a biome reshuffles them;
  - one generated file grows for ever.
- (b) A generated `.tres` TileSet per biome, written by a tool. Rejected: every sheet edit needs a rebuild step that can be forgotten (the drift `build_floor_tileset.gd` has today).
- (c) **Chosen**: a `BiomeTileset` Resource lists its look sheets and builds its TileSet on first use: one atlas source per look, and the source id is the `Look` value. Only the biome id is baked into an import, so editing a sheet needs no reimport, and moving a room to another biome is a one-word edit.

**Where the room names its biome**
- An export on `RoomMapNode`: rejected. The importer could not check the room's characters against the biome, and the `[back]` grid's meaning depends on it.
- `Region`: rejected. Interiors and underground rooms differ from their region (the same reason `vertical-backdrops` rejected it).
- **Chosen: the `.room` header.** `vertical-backdrops` kept backdrops out of `.room` because they are not grid data. Tiles are grid data, and their validity is checked at import.

**What `#` and `S` mean**
- "The biome's first and second material": rejected. It would make the caldera's porous basalt `EARTH`, so roots would grow in rock, against 02 §7.1.
- **Chosen**: a character fixes the `Ground` (gameplay truth) and a look; each biome draws the look its own way. The look set is a closed enum (`EARTH`, `STONE`, `WOOD`, `WALL`).
- Wood folded into `STONE`: rejected, because `ground_at()` would lie. Wood gets its own value: `Enums.Ground.WOOD`, solid, never roots.
- A fourth look, MASONRY (built stone): deferred. Only the caldera needs two stones (basalt and temple sandstone). A `caldera_temple` biome and the caldera's `WALL` look cover it. Adding a look later takes one enum value, one legend entry and one biome export.

**The autotile**
- (a) Keep the cell-aligned layout and bake 47 blob tiles from Wang quadrants. Rejected:
  - art cannot leave its cell, so there is no lip overhang;
  - a material seam is a straight cut through both fills, so cobbles over earth read as a sliced band;
  - it needs a 256-entry mask table.
- (b) Quarter tiles (16 px, cell-aligned). Rejected: four times the cells and a 16 px atlas, for one gain (a hard material seam) that the concept does not want.
- (c) **Chosen: dual grid.** It looks identical to (b) for one material, uses the PixelLab output as-is, and needs one `set_cell` per display cell.

| | Today (8-neighbour, about 22 tiles) | Dual-grid Wang (16 tiles) |
|---|---|---|
| Grassy lip | inside the cell, only where N is open | every exposed top, including pillar tops and steps; may spill up to 6 px over the walk line |
| Inner corners | 4 tufts, only when both sides are solid, and the first open diagonal wins | exact for every combination of the 3-solid tiles, on floors and ceilings |
| One-way ledges | the same art as a one-high solid run | their own cell-aligned ledge strip (thinner), so a ledge reads apart from a solid slab |
| Lone cell / 1-wide pillar | platform left end / dedicated tiles | four quarter tiles make a rounded boulder; two half tiles make a pillar |
| Cost | one layer, collision on the art | one layer per look present, plus a hidden collision layer; the art spills 16 px past each map edge |

**Material seams** (dual grid)
- A hard cut: rejected, as in (a) above.
- A plain fill-under, where a later look counts as solid for every earlier look: rejected. It puts an earth grass lip under the top of every stone block, and a grassy stone reads as rootable.
- **Chosen: an edge-adjacent underlay.** In one display tile, a later look's corner counts for an earlier look only when it shares a tile edge with a corner of that earlier look. So cobbles over earth show earth between their rounded bottoms, the grass runs on under the last cobble where a street meets a lawn, and a stone block in the air shows no earth.

**Collision**
- On the drawn tiles: impossible with a half-cell offset.
- Merged rectangle bodies: rejected for now. That would change every collision in the game.
- **Chosen**: a hidden, cell-aligned `Solid` TileMapLayer. Its shared TileSet has one full-square tile per `Ground`, a one-way alternative, and the `ground` custom data.

**Back walls**
- Separate back-only art per look: rejected, because it doubles the art.
- **Chosen**: the look sheets drawn through a darkened seasonal material, plus one back-only `WALL` look for built walls. A natural look keeps its seasons for free.

**Season bands**
- Generate each season independently: rejected. The body's silhouette drifts between runs, so the outline would jump at a pulse edge.
- **Chosen: graft.** The assembler takes the body from spring and only the lip zone from each season. That matches today's sheet, where only the tops differ.

## Decision

**Vocabulary**
- `BiomeTileset.Look { EARTH, STONE, WOOD, WALL }`. The order is draw order, and changing it is a `FORMAT_VERSION` bump.
- `Enums.Ground` becomes `{ NONE, EARTH, STONE, WOOD }` (appended). `RootSpanFinder` and `RootCatchFinder` already test `== EARTH`, so wood never roots, with no change.

**Room file** (FORMAT 5)
- `[room]` adds `tileset = <id>`, required and matching `^[a-z0-9_]+$`. The parser resolves it with `BiomeTileset.find(id)` and stores `map.tileset` and `map.biome`; the reference makes the import depend on the `.tres`.
- `[back]` is optional, with exactly `[grid]`'s rows. It takes GROUND characters (a wall of that look) and BACK characters only. It never changes `ground`, collision or `ground_at()`.
- New errors:
  - `no 'tileset' in [room]`
  - `unknown tileset 'x'`
  - `tileset 'x' has no <look>: 'C' at c,r`
  - `[back] has N rows, [grid] has M`
  - `'=' cannot be a back wall`
  - `'h' belongs in [back], not [grid]`

**Legend** (`RoomLegendEntry` gains `Kind.BACK` and `look: BiomeTileset.Look`)

| Char | Kind | Ground | Look | Note |
|---|---|---|---|---|
| `#` | GROUND | EARTH | EARTH | also an earth wall in `[back]` |
| `S` | GROUND | STONE | STONE | the biome's rock or laid stone |
| `=` | PLATFORM | EARTH | EARTH | |
| `%` | GROUND | WOOD | WOOD | new: planks, beams, stilts |
| `-` | PLATFORM | WOOD | WOOD | new: one-way plank |
| `h` | BACK | NONE | WALL | new: built wall (plaster and timber, planks, sandstone) |

The characters are proposals; renaming one before it lands is free. `RoomLegend.problems()` requires a ground other than NONE and a look other than WALL for GROUND/PLATFORM, and NONE for BACK.

**Sheet contract** (every look, every biome; `GroundAutotile` constants)
- 128x576 px: 4 columns of 32 px; 3 bands of 6 rows, spring / autumn / winter. `band_of_season` stays (2, 0, 1, 0).
- Rows 0-3 hold the Wang tile for solid-corner mask `m` = NW·1 + NE·2 + SW·4 + SE·8, at (m mod 4, m div 4).
  - Slot (0,0) is never drawn.
  - m 12 is the exposed top, m 3 the underside, m 5/10 the faces, m 7/11/13/14 the inner corners, and m 15 the fill.
- Row 4 holds up to four fill variants. An empty slot falls back to m 15.
- Row 5 holds the ledge pieces: left end, middle, right end, single (the EARTH and WOOD looks only).
- Built looks have three identical bands, so one material serves every biome.

**Autotile** (pure, static)
- `GroundAutotile`:
  - `wang_coords(mask)`
  - `variant_coords(v)`
  - `ledge_coords(west, east)`
  - `fill_variant(display_cell) -> 0..4`, an integer hash, stable across platforms
  - `corner_mask(corners: PackedInt32Array, look) -> int`, the underlay rule. Corner order is NW, NE, SW, SE, with -1 for air.
- `RoomTileResolver.resolve(map)` replaces `RoomMapParser._resolve_tiles`.
  - Display cell (i, j), for i in 0..w and j in 0..h, has the corners: cell (i-1, j-1), (i, j-1), (i-1, j), (i, j).
  - Out-of-map corners clamp x into the map, rows below the map repeat the bottom row, and rows above are air. This is today's "solid beside and below, sky above" for edge cells.
  - Ledge cells are air to the solid looks.
  - It writes:
    - `ground_layers` and `back_layers`: `Dictionary[int, PackedByteArray]`, Look → one byte per display cell (size + 1), `mask | variant << 4`;
    - `ledge_layers`: Look → piece + 1 per cell.
- `RoomMap` gains:
  - `CELL_PX := 32`, which replaces every `FLOOR_TILESET.tile_size`;
  - `looks`, `back`, `back_rows`, `tileset`, `biome` and the three layer dictionaries;
  - `display_size()`.

  It loses `tiles`, `NO_TILE` and the `pack_tile`/`tile_coords`/`tile_alternative`/`tile_at` helpers.

**Build** (`RoomMapNode`; the `ground_material` export is removed)
- Children in order:
  1. `Back_<look>` (by Look),
  2. `Ground_<look>` (by Look),
  3. `Ledges`,
  4. `Solid`,
  5. the water layers,
  6. `Entities`.

  All are siblings (`gotchas/lake-hidden-under-a-tilemaplayer-parent`), removed before a rebuild (`bugs/room-map-node-rebuild-renames-...`).
- The display layers sit at (-16, -16). Ground and ledges use the existing `floor_tiles_seasonal_material.tres`. Back layers use a new `back_tiles_seasonal_material.tres`.
- `Solid` uses `GroundCollision.tile_set()`, a static cached TileSet:
  - one atlas source over a blank 128x32 `ImageTexture`;
  - tile (ground, 0) per Ground, a full 32 px square on physics layer 1;
  - custom data `ground`;
  - alternative 1 one-way.

  It is hidden with `visible = false`, never `enabled` (`gotchas/tilemaplayer-enabled-does-not-hide-children`). `cell_at()` and `cell_rect()` read it.
- `BiomeTileset` (Resource):
  - exports `earth`, `stone`, `wood`, `wall: Texture2D` and `description` (developer text for the guide);
  - `static find(id)`, `sheet(look)`, `has_look(look)` and `problems()`;
  - `tile_set()`, built once and cached. It defines every slot of every band (72 per look), as `gotchas/tileset-padding-bakes-only-defined-tiles` requires, with no physics.
  - Several biomes may point at one sheet (planks shared by village, lake and interior).
- **`seasonal_art.gdshader`** gains `uniform float shade = 1.0` (an RGB multiplier, 0..1), applied before the haze. The back material's starting values, to be tuned in the playtest:
  - `shade` 0.55;
  - `distance` 0.2, so a forgotten room's back wall dissolves before its floor.

**Back layer rules**: back walls are behind entities and in front of the WORLD-06 `Backdrop`. An interior's whole-room wall is its backdrop strip (`vertical-backdrops`), while `[back]` holds walls that start and end inside the room: a cellar's earth wall, a house wall seen from the street, a cave wall ending at its mouth.

**Tooling**
- **`tools/art/wang_sheet.gd`** (`WangSheet`, pure):
  - `mask_from_corners`: reads corners, never names; PixelLab's index is not a complement of ours.
  - `tiles_from_pixellab(result)`: decodes base64; refuses a size other than 32 or a missing or duplicate mask.
  - `tiles_from_grid(image)`: a Codex 4x4 grid in sheet order, after keying and shrinking.
  - `tiles_from_blob(sheet, column0, band)`: the legacy conversion. A quadrant with sides `h` and `v` and diagonal `d` takes that quarter of: outer corner (0,0)/(2,0)/(0,2)/(2,2), edge (1,0)/(0,1)/(2,1)/(1,2), inner corner (4,3)/(5,3)/(8,0)/(6,0), or fill (1,1). The pack's ledge pieces (6..8,5) are copied, with (6,5) as single.
  - `lip_zones(mask, lip)`: in each half-column whose bottom corner is solid and top corner empty, rows 0..16+lip.
  - `graft`, `ledge_pieces` (composed from quarters when no strip is supplied), and `pack`.
  - `preview(sheet)`: renders a fixed pattern through `RoomTileResolver`: steps, a pillar, a lone cell, a one-high run, a ledge, a cave rim, cobbles on earth, a road ending at a drop, a block in the air, and a diagonal earth/stone touch. Every band at 1x and 4x.
- **`tools/art/assemble_tile_sheet.gd`** (a `-s` script, so it names no autoload: `gotchas/a-script-run-with-s-...`). Arguments:
  - `--prompt=<id>`;
  - `--spring= --autumn= --winter=` (a `result.json` or a grid PNG; one season means built: copy it);
  - `--variants=<png 128x32>`, `--ledge=<png 128x32>`;
  - `--lip=` (default from the contract);
  - `--palette=<json>`, `--key=`;
  - `--from-blob=<png> --blob-column=0|9`;
  - `--preview=<scratchpad png>`.

  It snaps every tile to the palette, grafts, packs to the contract's target, and prints the per-tile silhouette difference between the bands outside the lip zones.
- **`ArtPrompt`** gains `command: tileset` and the fields `seasons` (1 or 3; shared with the backdrop plan), `top_spring`, `top_autumn`, `top_winter`, `top_size`, `lip`, `seed`, `color_image` and `top_reference`. `problems()` requires 128x576 with 1 frame, the three tops when there are 3 seasons, and `lip` in 1..16.
- **`make_placeholders.gd`** draws a tileset contract as real Wang geometry:
  - a flat hue per look;
  - a 1 px edge on air-facing sides;
  - a 4 px lip per band (green / orange / white);
  - a thin ledge strip.

  Every biome is usable before its art.
- **`pixellab.ps1`** gains a v2 command:

  ```
  tileset -Prompt <id> -Season spring|autumn|winter [-BaseTile <uuid>] [-Seed n]
  ```

  - It POSTs to `/v2/create-tileset-sidescroller` with `tile_size` 32, `view` side, the body as `lower_description`, `top_<season>` as `transition_description`, and the reference and `color_image` PNGs as base64.
  - It polls `GET /v2/tilesets/{id}` every 10 s while the answer is 423, up to 600 s.
  - It writes `%TEMP%\pixellab\<id>_<season>\result.json` plus a contact sheet, and prints `metadata.terrain_ids.lower` for `-BaseTile`.
  - The key comes only from `PIXELLAB_API_KEY` and is never printed.
- **`extract_palette.gd`** gains `--from=<pngs> --out=<json> --size=N`, producing `tools/art/palettes/<biome>.json` from approved references.
- Approved pictures live in `tools/art/references/` (with a `.gdignore`), starting with `village_concept.png` and its crops.

**SOLID**
- Open/closed: a biome is a `.tres` plus sheets, with no code. A look is the only closed set.
- Single responsibility:
  - the parser parses;
  - `RoomTileResolver` resolves art;
  - `GroundCollision` owns geometry, so art can never change collision;
  - `RoomMapNode` only places.
- Dependency inversion: the node depends on `BiomeTileset.tile_set()`, never on a sheet path.
- The legend stays the only place a character means anything.

**Not added**: no autoload, no new signal (the editor preview rebuilds when `map` is set, as today), no process mode, and no user-facing string. `description` and the parser messages are developer text, not `tr()` keys.

## Migration

1. Convert `floor_tiles.png` with `--from-blob`, columns 0 and 9, into `assets/sprites/world/tilesets/legacy/earth.png` and `stone.png`. Draw placeholder `wood`/`wall` sheets.
   - The conversion is pack art rearranged for in-game use, which the licence allows. It is never a generator reference.
   - `legacy.tres` uses them.
   - Delete `floor_tiles.png` after converting. `CREDITS.md` credits the legacy sheets.
2. Add `tileset = legacy` to all 14 `.room` files and to the 10 inline rooms in `room_map_parser_test`, `room_map_node_test`, `root_span_finder_test` and `room_files_test`.
3. Remove `ground_material` (and its `ext_resource`) from the 14 contents scenes. The smoke test fails on the warning a stale property gives.
4. Set `FORMAT_VERSION` to 5. Delete `.godot/imported/*.room-*`, run `--import`, and commit the `.room.import` files (`gotchas/import-plugin-output-is-stale-...`).
5. Delete:
   - `floor_tileset.tres`;
   - `tools/maps/build_floor_tileset.gd`;
   - `tools/art/derive_stone_tiles.gd`;
   - `tools/maps/export_room_map.gd/.tscn`, the one-shot paint exporter, which uses `tile_at`;
   - each one's `.uid`.
6. When the village sheets land, `trials_solstice` (`solstice_trial`, `empty_house`, `water_trial`, `the_catch`, `door_trial`) moves to `village`. `door_trial_inside` moves to `interior` and gains a `[back]` demo: an `h` wall, a `%` floor and a `-` shelf.
7. The other trials follow when their biomes have art: spring → `spring_woods`, summer → `summer_caldera`, autumn → `wind_orchards`, winter → `frozen_lake`.
8. `legacy` is deleted when no room uses it. The old `home_village` and `frost_edge` rooms leave in WORLD-05.

## Tests (gdUnit4, `--ignoreHeadlessMode`)

- **`ground_autotile_test`** (rewritten):
  - every mask 1..15 lands in the 4x4 block, and 0 is never drawn;
  - `corner_mask`:
    - one look;
    - (air, air, earth, stone) → earth SW|SE;
    - (stone, stone, earth, earth) → earth 15, stone NW|NE;
    - (air, air, stone, stone) → earth 0;
    - the diagonal (earth, air, air, stone) → earth NW only;
    - wood over stone over earth;
  - `fill_variant` is the same for the same cell, stays in 0..4, and is not constant over a 16x16 field;
  - the four ledge cases.
- **`room_tile_resolver_test`**:
  - a lone earth cell makes masks 8, 4, 2, 1 around it;
  - a floor to the bottom and sides continues past the map, with nothing above the top;
  - a stone row on earth: earth 15 under it, stone 3 below it;
  - a ledge is air to the solids and draws its pieces;
  - `[back]` fills only `back_layers`;
  - the display grid is (w+1)(h+1).
- **`room_map_parser_test`** (added): the tileset is parsed; missing, unknown and malformed ids; `[back]` row count; a water, entity or ledge character in `[back]` and `h` in `[grid]`; a look the tileset lacks, at its line and column; `[back]` does not change `ground_at`; `%` is solid WOOD.
- **`room_map_node_test`** (added):
  - child order;
  - the display layers at (-16, -16), `Solid` at 0 and hidden;
  - a `PhysicsServer2D` point query at a solid cell's centre hits the hidden layer, and a ledge cell is one-way;
  - `ground_at`, `cell_at` and `cell_rect` as before;
  - an empty variant falls back to m 15;
  - setting `map` twice leaves one set of children.
- **`ground_collision_test`**: one tile per EARTH/STONE/WOOD with its custom data and a full square; the alternative is one-way.
- **`biome_tileset_test`** (every `.tres`):
  - the id equals the file name;
  - no `problems()`;
  - `tile_set()` defines 72 tiles per present look, with source id = Look;
  - the earth and stone fill tiles differ in mean luminance in every band by at least legacy's measured difference (measure it first; the grey keeps only value);
  - `find()` of an unknown id is null.
- **`wang_sheet_test`**:
  - corners to mask (`wang_0` → 15, `wang_15` → 0, `wang_13` → 4, `wang_6` → 9);
  - the PixelLab decode refuses a missing or duplicate mask;
  - `tiles_from_blob` picks the right quarter on a synthetic sheet;
  - lip zones for m 12 and 13, none for m 3;
  - `graft` keeps the body and takes the lip;
  - ledge quarters;
  - `pack` slots;
  - one season gives identical bands.
- **`art_prompt_test`** (added): tileset contracts parse and validate, and the bands of a `seasons: 1` target are identical.
- **`map_guide_test`**: unchanged. It covers the new generated `tilesets` section and the Look column.
- **Playtests**:
  1. Legacy before/after at every trial position (x 0, 2400, 4800, 7200, 9600, 12160, 14912, 17872; y 6000) and the door trial. Check ledge drop-through, the root strands against the new edges (`bugs/root-bridge-strands-meet-at-a-step`), and that a pulse edge across the ground swaps bands without moving the outline.
  2. The village sheets on `trials_solstice`, in colour, in the grey and under each season's pulse.
  3. The interior's back wall, wood floor and shelf.

## Files

- **Create**:
  - `resources/world/tiles/biome_tileset.gd`
  - `biomes/{legacy, village, threshold, frost_edge, spring_woods, frozen_lake, wind_orchards, summer_caldera, caldera_temple, interior}.tres`
  - `scenes/world/rooms/maps/room_tile_resolver.gd`, `ground_collision.gd`
  - `scenes/world/memory/seasonal/back_tiles_seasonal_material.tres`
  - `tools/art/wang_sheet.gd`, `assemble_tile_sheet.gd`
  - `tools/art/references/` (`.gdignore`, the concept and its crops)
  - `tools/art/palettes/village.json`
  - `tools/art/prompts/tiles_<biome>_<look>.md`, one per sheet
  - the sheets under `assets/sprites/world/tilesets/<biome>/`
  - the five new suites
- **Change**:
  - `globals/enums.gd`
  - `room_map.gd`, `room_legend_entry.gd`, `room_legend.gd`, `room_legend.tres`
  - `ground_autotile.gd`, `room_map_parser.gd`, `room_map_node.gd`, `map_guide.gd`
  - `room_map_importer.gd` (5)
  - `seasonal_art.gdshader`
  - `drawbridge.gd`, `lowering_platform.gd`, `root_grower.gd` (`RoomMap.CELL_PX`)
  - the 14 `.room` files, the 14 contents scenes and their imports
  - the 4 test files above
  - `art_prompt.gd`, `make_placeholders.gd`, `extract_palette.gd`
  - `pixellab.ps1`
  - `tools/art/prompts/README.md` (a tileset section), `style.md` (question 3)
  - `docs/maps/README.md`: the prose for "How the ground is drawn", `tileset`, `[back]`, the errors, and the regenerated sections
  - `systems/rooms`, `systems/seasonal-art` (tiles now come per look from the assembler; the back material), `systems/art-pipeline`, `systems/roots-and-climbing` ("stone and wood never root")
  - `glossary.md`: madeira → `Enums.Ground.WOOD`; bioma → `BiomeTileset` / `tileset =`; parede do fundo (de sala) → `[back]`. A retired row: `floor_tileset.tres` and the 9-column layout.
  - a dated Revision on `architecture/rooms-are-text` (stone is no longer derived; the autotiler is dual-grid)
  - `gotchas/tileset-padding-...` `source_files`
  - `CLAUDE.md` Rooms row ("a room's art is its `tileset`; collision is the `Solid` layer, never the art")
  - `CREDITS.md`, roadmap
- **Delete**: as in Migration step 5.

## Art contract (every look sheet)

- **Format.** 1x, 128x576, alpha 0 or 255, snapped to the biome's palette, in the slot layout above.
- **The cell edge is the tile's midline.**
  - A solid quadrant reaches the midlines it shares with solid quadrants, and two tiles sharing two corners meet pixel for pixel. The preview is the check.
  - An edge facing air sits within ±2 px of the midline.
  - Fills (m 15 and the variants) are fully opaque.
- **Lip.**
  - Only on exposed tops, `lip` px below the walk line (8-10 px at PixelLab 0.25).
  - It may spill at most 6 px into the air half: sparse blades, snow or leaves, never a solid strip, or Ivo sinks.
  - Undersides and faces are the same in every band; the assembler grafts.
- **Bands.**
  - Natural looks have three bands: spring lip, autumn leaf litter, winter snow.
  - Band 0 is spring and summer, so in the summer-native caldera it is drawn as summer (sun-dried). A winter-native biome's native look is band 2.
  - Built looks (cobbles, road stone, dry-stone wall, planks, walls) have one band, copied three times (04 §6; question 2).
- **Legibility.**
  - Earth and stone must differ in value and texture at a glance in the grey, by at least legacy's luminance difference (the test above). Stone shows joints or cracks; earth shows roots and pebbles.
  - Ground ice is a winter-band glaze on rock, opaque and rimed, never Congelar's clear sheet.
  - Ledge strips draw in the top 20 px of the cell, so a one-way ledge reads thinner than ground.
- **Density from the concept.**
  - The contract records numbers measured at the concept's native resolution.
  - First reading, assuming the concept frames the 640x360 view (about 2.6 image px per game px):
    - cobbles about 8-12 px wide and 6-8 px tall;
    - the street's cobble face about 23 px;
    - the grassy lip 3-4 px;
    - pebbles 2-4 px.
  - Attach the concept crop as `reference` and `color_image`, and quote the user's approval in the contract.
- **PixelLab starting values** (proposals, to be judged on the preview): `top_size` 0.25 for natural looks and 0 for built ones; outline "selective outline" (the concept has no black outlines); shading "detailed shading"; detail "highly detailed"; one `seed` per look across its three runs; autumn and winter runs pass the spring run's `-BaseTile`. Codex draws a 4x4 grid on magenta when PixelLab misses.
- **Per biome** (04 §6). Real art comes from that biome's approved style board; placeholders until then (question 5).

| Biome (`tileset =`) | earth `#` | stone `S` | wood `%` `-` | wall `h` (back) |
|---|---|---|---|---|
| `village` | dark earth, grassy lip (3) | cobblestone, moss in the joints (1) | dark weathered planks (1) | timber frame and plaster (1) |
| `threshold` | dry pale earth (3; native band 2) | worn road stone (1) | broken fence planks (1) | farmhouse wall (1) |
| `frost_edge` | frozen dark soil (3; question 1) | dark rock, with ice and snow in band 2 (3) | wreck planks (1) | white lighthouse stone (1) |
| `spring_woods` | mossy earth with roots (3) | mossy cave rock (3) | hut planks (1) | - |
| `frozen_lake` | dark earth, the chasm walls (3) | bluish stone, with an ice crust in band 2 (3) | stilts and planks (1) | plank wall (1) |
| `wind_orchards` | ochre earth (3; native band 1) | dry-stone wall (1) | planks (1) | mill-town house wall (1) |
| `summer_caldera` | ash soil (3; question 1) | porous basalt (3; band 0 summer) | - | temple sandstone (1) |
| `caldera_temple` | - | temple sandstone (1) | - | carved sandstone (1) |
| `interior` | cellar dirt (1) | foundation masonry (1) | floor planks and beams (1) | plaster between beams (1) |
| `legacy` | converted pack earth (3) | converted pack stone (3) | placeholder | placeholder |

## Consequences and risks

- **Past the edges.** The ground draws 16 px past every map edge (continuing its edge cells), so maps that meet must agree at the shared edge. Today they meet at a cut; a mismatch was wrong before as well.
- **Hidden collision.** A hidden `TileMapLayer` must still collide, and the `room_map_node_test` point query decides it. If it does not, keep it visible over the blank texture (some overdraw), or use `self_modulate` alpha 0.
- **Graft seam.** If a season's lip meets the spring body visibly, raise `lip`, or re-run the season with the spring run's references. The preview shows every band.
- **Underlay artefacts.** In a tile holding two looks and air, the earlier look's edge can peek past the later one's rounded corner. The preview pattern has every such case. The fallback is a one-line change in `corner_mask`: underlay only in tiles with no air corner.
- **Repetition.** 16 tiles repeat; the fill variants and the hash break it up. PixelLab returns one fill per run, so the variants come from extra runs or Codex.
- **Import order.** The import now loads a `BiomeTileset` and its textures. The legend's entity scenes already do this, but if a fresh checkout's first import cannot load a sheet, raise the importer's `_get_import_order()` above the texture importer's.
- **Legacy look.** The quartered legacy look is close, not exact: pillars and lone cells come from corner quarters instead of their own tiles. One-high solid runs become slabs, and only `=` keeps the thin ledge art.
- **Concurrent plans.** `seasonal_art.gdshader` is also touched by `vertical-backdrops` (`gh_band_for`). `ArtPrompt.seasons` is shared with it; keep one meaning: the number of season versions.
- **Biome ids** are load-bearing strings in `.room` headers. Renaming a biome file fails `room_files_test` with "unknown tileset".
- **The palette.** `palette.json` was extracted from pack art. The concept needs its own palette (question 4), and 64 colours may be too few for "detailed, painterly". Measure on the preview.

## Questions for the user

1. **Earth in the Caldera and the Frost Edge.** 04 §6 lists no earth there (porous basalt and temple sandstone; dark rock, ice and snow), and only earth roots (02 §7.1). The plan makes basalt and dark rock `S` and gives `#` an ash-soil or frozen-soil look. Should those biomes have earth at all?
2. **Built ground in one band.** By 04 §6 ("construções e interiores têm uma"), cobbles, road stone, the dry-stone wall and planks never change season, so a winter pulse never snows on the village street. Is that right, or should built ground get the seasonal top while built walls stay one band?
3. **`style.md`.** Its preamble ("limited muted earthy palette", "clean single-colour dark outline", the GandalfHardcore reference) predates the approved concept. Should it be rewritten to the concept now, which changes every future prompt, or should only the tile contracts carry the concept until each biome's style board?
4. **Palettes.** Should there be one palette per biome, extracted from its approved board (village first), replacing the pack-derived `palette.json`? And how many colours?
5. **Scope.** Should WORLD-07 generate only the village (and interior) sheets now, with placeholders for the other biomes until their style boards (WORLD-12..17: "Style board approved by the user first")?
