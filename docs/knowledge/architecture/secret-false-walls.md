---
id: architecture/secret-false-walls
type: architecture
title: Secret spaces behind false walls - a `[secret]` grid resolved as if solid by the ground resolver, drawn twice (a reflected world twin and a foreground copy over the creatures), opened for good by Ivo's body as a live save fact (WORLD-21)
status: active
tags: [secret, false-wall, rooms, room-map, importer, legend, dual-grid, foreground, canvas-pass, reflection, save, hint, grass, plan, world-21]
related: [architecture/biome-tilesets, architecture/rooms-are-text, architecture/foreground-layer, architecture/generated-grass, systems/foreground, systems/rooms, systems/greyhush, systems/seasonal-art, systems/map, systems/water, systems/life-benches-death, architecture/water-is-world-art-reflecting-two-passes, architecture/doors-and-interiors, architecture/props-and-ambient-life, gotchas/import-plugin-output-is-stale-when-its-logic-changes, gotchas/a-failed-import-is-cached-and-not-retried, gotchas/tileset-padding-bakes-only-defined-tiles, gotchas/monitorable-false-hides-an-area-from-every-monitor, gotchas/body-state-cannot-change-in-the-physics-flush, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, gotchas/tilemaplayer-enabled-does-not-hide-children, bugs/room-map-node-rebuild-renames-and-doubles-its-children, bugs/the-canvas-passes-draw-one-frame-behind-a-camera-zoom-tween]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/maps/room_map_parser.gd
  - scenes/world/rooms/maps/room_tile_resolver.gd
  - scenes/world/rooms/maps/room_map_node.gd
  - scenes/world/rooms/maps/secret_wall.gd
  - resources/world/maps/room_map.gd
  - resources/world/maps/room_legend_entry.gd
  - resources/world/maps/room_legend.tres
  - resources/world/tiles/biome_tileset.gd
  - addons/room_maps/room_map_importer.gd
  - globals/player_data.gd
  - globals/save_system.gd
  - scenes/world/environment/draft/draft.tscn
---

> **Status: PLANNED** (2026-10-10, roadmap WORLD-21). Nothing is built.

## Summary

A `.room` gains an optional `[secret]` grid. Its cells are air in `[grid]` (no collision, `ground_at()` says NONE) and are drawn as solid ground of the look given. `RoomTileResolver` resolves them as if they were solid, so a closed secret is the tile set the room would have with those cells filled in. `RoomMapNode` builds one `SecretWall` per 8-connected group. It draws the closed tiles twice: a world-canvas twin at z 40, which water reflects, and a `ForegroundPass` copy, which covers Ivo and anything inside. The first frame Ivo's body overlaps a secret cell, both copies fade out over 0.4 s and the wall records `found_secrets`, a live save fact (a bench keeps it, a death forgets it). Hints are a cracked-stone secret character, a dust `Draft` entity, and the gap in WORLD-23's grass, which follows from the data.

## Context

- User, 2026-10-10: "Secret places (such as the image) should be more hidden. Not impossible to find, but with only subtle hints." Choice: "False wall that fades (Recommended)" (design 04 §1, "Segredos").
- SILHOUETTE creatures are culled from the root and composited after `Greyhush`. Nothing in the world canvas covers them, whatever its z (`architecture/foreground-layer`).
- The foreground composite (`greyhush_creatures.gdshader`) and the world pass (`greyhush.gdshader`) call the same `gh_memory`/`gh_quantise`/`gh_shade`/`gh_vignette`. An opaque pixel comes out identical from either. `seasonal_art.gdshader` clips in world space (`clip_rect`, `MODEL_MATRIX`) and reads the season mask at `SCREEN_UV`, so it works in both.
- Water reflects the screen copy (world art below z 50) plus the creature pass, never the foreground pass (`systems/water`). `lake_shore` puts a secret on a lake's far shore (04 §3).
- Dual-grid tiles are whole 32 px tiles that do not overlap. A boundary tile's quadrants belong to the cells at its corners. A face sits within ±2 px of the midline, and a lip spills at most 6 px into the air half (`architecture/biome-tilesets`).
- `RoomMap.ground` drives collision (`Solid`), roots, rain and `SafeGroundTracker`. WORLD-23 places grass from `RoomMap.looks` and draws a front row in `ForegroundPass` (`architecture/generated-grass`). `LeafCover` (`F`) already uses the word "cover", so this system says "secret".

## Options considered

**Authoring**
- A legend character in `[grid]` (a "false earth"): rejected. It takes one character per look, and an entity cannot sit in a secret cell, so a reward could not be hidden inside.
- An entity with a rect param: rejected. Rects are not grid data, and the tiles could not be resolved at import.
- **Chosen: a `[secret]` layer** with `[grid]`'s rows, like `[back]`. It takes GROUND characters (a plain secret of that look) and SECRET characters (a look plus a hint). It stacks over `[grid]` entities and lives beside `[water]`.

**Resolution**
- A per-secret fill sprite: rejected. Its edges cannot meet the real ground.
- **Chosen: the same resolver over "looks with the secret cells filled in"**, kept only in display tiles that have a secret corner. In those tiles the closed copy draws the tile solid ground would draw, including the real neighbour's quadrants, which hides that neighbour's faces. Every other tile is unchanged.

**Real tiles under the closed copy**
- Move the owned tiles out of `Ground_*` into per-wall `Open_*` layers and crossfade: rejected for now. It is pixel-exact, but costs a third copy and a split of the ground build.
- **Chosen: keep the real tiles under it.** The only difference is in the air quadrants of boundary tiles, where both lips' spill shows. That is 1 art px of turf in spring once WORLD-23 lands, and autumn litter and winter snow (at most 6 px). The playtest pixel diff decides. The rejected option is the fallback.

**Where it draws**
- World canvas only, at z 40: rejected. Ivo, enemies, rain (creature pass) and grass front rows draw over a closed wall.
- Foreground pass only: rejected. A lake reflects the hollow (`lake_shore`).
- **Chosen: both**, under one parent `modulate`. The foreground copy is what the screen shows; the world twin is what water reflects. This complies with `systems/foreground`: the foreground copy draws only in `ForegroundPass`.

**Persistence**
- Fade back on each visit: rejected. A known passage hidden again is friction, not mystery, and 02 §6.1 says the world keeps the result of a first resolution.
- A death-proof fact (like `notebook_read`): rejected. The user chose "Map rewinds" (2026-10-02) for the other piece of player knowledge.
- Reuse `resolved_shortcuts`: rejected. A found secret is not a puzzle's consequence, and a separate list keeps a count a one-liner.
- **Chosen: `PlayerData.found_secrets: Array[StringName]`**, live data that rewinds like a shortcut.

**Map** (`systems/map`): no change. The map draws seen camera cells, not terrain, so a secret's cells are seen like the wall they imitate and nothing leaks. If the map ever draws terrain, a closed secret must read as ground there.

## Decision

**Legend.** `RoomLegendEntry.Kind.SECRET` is appended, so existing ints stay stable. Add `@export var crack := false`. `RoomLegend.problems()` requires SECRET to have a look other than WALL and ground NONE. New characters (proposals):
- `k` (SECRET, STONE, crack): cracked stone.
- `d` (ENTITY, `Draft`, anchor CENTER): a dust draft.

**Parser (FORMAT 7).** `[secret]` is optional.

Errors:
- `[secret] has N rows, [grid] has M`
- `'=' cannot be a secret` (platforms, `h`, water and entities)
- `'S' at c,r is already ground: [secret] hides air`
- `secret at c,r touches water` (8 neighbours: a foreground copy would draw lip spill over the water)
- `tileset 'x' has no crack: 'k' at c,r`
- the existing `_check_look` error

Groups are 8-connected, because a group that touched another only at a corner would share its display tile. A group's id is `"<room file basename>@<x>,<y>"`, taken from its first cell in row-major order (local coordinates), at most 254 groups per room.

`RoomMap` gains:
- `secret_rows`;
- `secret_ids: PackedStringArray`;
- `secret_cells: PackedByteArray` (one byte per cell: the group index + 1);
- `secret_cracks: PackedByteArray` (crack variant + 1);
- `secret_layers: Dictionary[int, PackedByteArray]` (the Look → display-cell format of `ground_layers`; 0 outside the owned tiles);
- `secret_at(cell)` and `secret_owning(display_cell)`.

`looks` and `ground` stay air at secret cells.

**Resolver.** `secret_layers = _layers(map, looks_with_secrets, true)`, masked to the display tiles that have a secret corner. Fill and edge variants come from the same display-cell hash, so they match.

**Build (`RoomMapNode`).** The child order becomes `Back_*`, `Ground_*`, `Ledges`, (`Grass`, WORLD-23), `Solid`, `Water_*`, `Secret_<x>_<y>`, `Entities`. Each `SecretWall` (Node2D, no process mode of its own) holds:
- `World_<Look>` and `World_Crack`: world canvas, z 40. That is above ground, grass back rows and entities (0), props (-10) and back walls (-20), and below water (50).
- `Front_<Look>` and `Front_Crack`: the same cells, z -1, so foreground pieces draw over them.
- `Trigger`: an Area2D with one rect per horizontal run of the group's cells. Mask: physics layer 9 (Player body; never the hurtbox, never Enemy 17). Layer 0, `monitorable` false.

The display layers come from `_display_layer` with the room's two clipped materials, so the closed copy also clips to the room rect. Crack layers are cell-aligned. In the editor the wall is drawn at alpha 0.5 so the author sees the hollow. Collision is untouched: secret cells are NONE, and `Solid`, `ground_at()`, roots and rain see the real hollow.

**`SecretWall` (runtime only, not `@tool`).**
- `_ready`: `CanvasPass.join_layer(front, CanvasPass.FOREGROUND)` for each `Front_*` layer. If `SaveSystem.is_secret_found(secret_id)`, it sets `visible = false` and stops monitoring; otherwise it connects `Trigger.body_entered`.
- On entry: `SaveSystem.find_secret(secret_id)`, emit `found(secret_id)`, tween `modulate.a` 1 → 0 over `FADE_TIME` (0.4 scaled s, a node-bound tween: a hold stops it), then `visible = false` (never `enabled`). `monitoring` is set deferred, because the callback runs in the physics flush.
- The fade ignores memory, because it is readability and not world time, as with `ForegroundPiece`; a secret in a place at memory 0 still opens.

**Save.** `found_secrets` is copied by `SaveLedger` like every live field, and old saves load it empty. `SaveSystem.is_secret_found(id)` and `find_secret(id)` emit nothing, like `resolve_shortcut`.

**Hints** (data where an author chooses them; keep them sparse):
- **Crack.** `k` cells draw a decal from `BiomeTileset.crack`: 128x96, 4 variants × 3 bands, binary alpha, a 1 px hairline 6-14 px long in the stone's darkest joint colour, at least 4 px from the cell edges. It is atlas source `CRACK_SOURCE` (16), with every slot of every band defined. The variant is chosen by `fill_variant(cell)`, folded onto the 4 variants. It sits on the closed copy and fades with it. `legacy` gets a placeholder from `make_placeholders.gd`.
- **Draft.** `d` (`scenes/world/environment/draft/`, a `Draft extends CPUParticles2D` with a `MemoryClock` child). Param `facing` (1 right, -1 left, 0 up), placed on the air cell at the mouth. Starting values: 5 motes, 1 px, alpha 0.5, 8 px/s, lifetime 2 s, emitted from the cell edge facing the secret. It freezes in the grey and moves again under a pulse.
- **Grass gap.** No data and no suppression mark. This answers `architecture/generated-grass` "Coverage". Secret cells are not in `looks`, so WORLD-23 grows no blades on a secret's top, while the closed copy still draws the turf. To avoid the gap, keep a real ground row over the secret.
- `room_files_test`: every secret has a `k` cell or a `d` within one cell ("Not impossible to find").

**Signals.** `Trigger.body_entered` → `SecretWall` (internal). `SecretWall.found(secret_id: StringName)` is emitted once, when first found. WORLD-21 connects nothing to it; it is the hook for a discovery sound, and the test seam. No autoload, no new global.

**i18n.** No user-facing string. Legend descriptions, parser errors and the guide are developer text, not `tr()` keys.

**SOLID.**
- Open/closed: a hint or a secret look is a legend entry; a biome's crack is a sheet.
- Single responsibility: the parser groups cells, the resolver resolves tiles, `RoomMapNode` places, `SecretWall` reveals and records, `Draft` animates.
- Composition: `SecretWall` is a plain Node2D that composes its layers and its Area2D, with no subclass of a tile node.
- Dependency inversion: the wall reads the save through `SaveSystem`'s two calls, as `FactBarrier` does, and knows no room or player node.

## Consequences

- A closed secret is truth for every song (`ground_at`). A root span or rain may enter a closed wall; it draws under the foreground copy. Accepted: songs act on the real world.
- Secrets are optional spaces. A required route behind a secret contradicts "not impossible" (see the question).
- **Constraints on WORLD-23** (`GrassPlacement`):
  - A cell whose upper neighbour is a secret cell is not a grassy top. Otherwise front-row blades (`ForegroundPass`, z 0) on the hollow's floor draw over the closed `Front_*` (z -1).
  - A run end beside a secret cell counts as closed (no corner radius), so the gap is exactly the secret's width.
- A new `systems/foreground` line: `SecretWall.Front_*` is the second kind of foreground item (tiles, no parallax). The "never over a landing, bench, door or song interactable" rule stays a `ForegroundPiece` art rule: a secret may hide those, because it opens whenever Ivo's body is in it.
- Pause-mode map (`systems/songs-and-the-memorina`): `SecretWall` and `Draft` inherit (pausable).

## Files

- **Create:**
  - `scenes/world/rooms/maps/secret_wall.gd`
  - `scenes/world/environment/draft/draft.tscn`, `draft.gd`
  - `assets/sprites/world/tilesets/legacy/crack.png` (placeholder)
  - `tools/art/prompts/tiles_<biome>_crack.md` (village first)
  - `tests/scenes/world/rooms/maps/secret_wall_test.gd`
  - `tests/scenes/world/environment/draft/draft_test.gd`
  - a demo secret in `trials_solstice` (`water_trial`, above its lake, for the reflection)
- **Change:**
  - `room_map.gd`, `room_legend_entry.gd`, `room_legend.gd`, `room_legend.tres`
  - `room_map_parser.gd`, `room_tile_resolver.gd`, `room_map_node.gd`, `map_guide.gd` (layer column for SECRET)
  - `room_map_importer.gd` (`FORMAT_VERSION` 6 → 7: delete `.godot/imported/*.room-*`, run `--import`, commit every `.room.import`)
  - `biome_tileset.gd`, `legacy.tres`, `village.tres`
  - `player_data.gd`, `save_system.gd`
  - `make_placeholders.gd`
  - the parser, resolver, node, `room_files_test`, `save_ledger_test`, `player_data_test` and `biome_tileset_test` suites
  - `docs/maps/README.md` (`[secret]` prose, errors, regenerated legend and params)
  - `systems/rooms`, `systems/foreground`, `systems/life-benches-death`, `systems/songs-and-the-memorina`, `glossary.md` (segredo / parede falsa → `SecretWall`, `[secret]`; sopro de poeira → `Draft`; rachadura → `crack`), roadmap

## Tests

- **Resolver (the seam guarantee):** parse a map A with `[secret]` and a map B with the same cells in `[grid]`. For every display tile: if A owns it, `A.secret_layers == B.ground_layers`; otherwise `A.ground_layers == B.ground_layers`. Include stone over earth, a secret at the map edge, and secrets under air, beside air and inside rock.
- **Resolver coverage:** every non-air corner of an owned tile is drawn by some look.
- **Parser:** rows and looks; every error above; 8-connected groups and their ids; `[secret]` leaves `ground`, `looks`, `platform` and `ground_at` unchanged; an entity under a secret is kept.
- **Node:** child order. `World_*` at z 40 and `Front_*` with bit 4 only after ready. A point query at a secret cell misses `Solid`. One trigger rect per run.
- **`secret_wall_test`:**
  - a layer-9 body entering fades `modulate.a` to 0 in 0.4 s, then hides the wall and records the id;
  - a layer-17 body does nothing;
  - a found id at ready starts hidden;
  - `found` is emitted once.
- **Save:** `found_secrets` is forgotten by a death and kept by a rest; an old save loads it empty.
- **`biome_tileset_test`:** the crack source defines 12 slots.
- **`room_files_test`:** secret ids are unique across every map; every secret has a hint.
- **`draft_test`:** `facing` sets the direction; the `MemoryClock` resolves.
- **Playtest:**
  - **Pixel diff:** a frame of the demo secret closed against the same room with the cells as ground. Zero difference outside boundary air quadrants, in colour, in the grey, across a pulse edge, while panning and through the Memorina focus zoom. This also checks for pass lag (`bugs/the-canvas-passes-draw-one-frame-behind-a-camera-zoom-tween`).
  - Walk in: Ivo is hidden, then revealed.
  - The lake reflects the wall closed.
  - A death before a bench closes it; a rest keeps it.
  - The draft is readable but quiet at the trials' memory.

## Risks

- **Spill union.** If the diff shows doubled lips (autumn litter and winter snow are the largest), take the `Open_*` fallback.
- **Pass lag.** A foreground pass one frame behind the root shows the seam in motion. The diff while panning and zooming decides.
- **Import.** The format bump does not reimport on its own (`gotchas/import-plugin-output-is-stale-when-its-logic-changes`).
- **Sombra's shadow.** If it is on physics layer 9 it opens secrets too. Accepted: it counts as Ivo.

## Question for the user

1. **The cistern.** The dry shaft in your screenshot is the Caldera's Redoma entrance from the village (04 §2, §3 `caldera_cistern`), a required route. Should that shaft stay visible, with secrets only for optional spaces (recommended: hiding a gate route works against "not impossible to find"), or should it be hidden too?
