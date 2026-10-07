---
id: architecture/a-pool-rests-below-its-painted-reach
type: architecture
title: A pool rests at its painted water and Chuva raises it to the `r` cells painted above it, in one body (PLAN for PZL-09)
status: active
tags: [water, rain-basin, chuva, room-map, water-basins, importer, plan, pzl-09]
related: [architecture/the-water-level-moves, architecture/rooms-are-text, architecture/ice-is-its-own-sheet, architecture/the-shell-displaces-water-into-the-reach, systems/water, systems/rooms, gotchas/import-plugin-output-is-stale-when-its-logic-changes]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - scenes/world/rooms/maps/room_map_parser.gd
  - scenes/world/rooms/maps/room_map_node.gd
  - resources/world/maps/room_map.gd
  - resources/world/maps/room_legend_entry.gd
  - resources/world/maps/room_legend.tres
  - scenes/world/environment/water/water_basins.gd
  - scenes/world/environment/water/water_layer.gd
  - scenes/world/interactables/rain_basin/rain_basin.gd
  - addons/room_maps/room_map_importer.gd
---

## Summary

PLAN, not built (2026-10-07). Design 03 §6.5: "poças sobem", and the level rain reaches is
authored, never computed. `r` stops being its own kind of water and becomes a REACH: `r` cells
painted above `~` or `f` water in the same pit join that body as the level Chuva brings it to; the
painted water below is its rest level. A lone `r` group is today's dry basin (rest = its floor).
Resolved at import. PZL-06 reuses the reach as the bound of displacement.

## Context

- `RoomMapNode` pours one `WaterLayer` per water character, and `WaterBasins` makes the top painted
  row of a 4-connected group the surface: `~` under `r` would be two bodies.
- `RainBasin` lerps between the painted top and the deepest floor (`_dry_y`).

## Options considered

- **A param on an entity** (a marker with rest rows): not visible in `[water]`. Rejected.
- **A character per rising kind** (rising pool, rising freezable): grows with every kind. Rejected.
- **Chosen: `r` is a reach that joins the water it sits on.**
- Where: in `RoomMapNode` at build (errors only at runtime) vs **the parser at import** (errors
  name the file and line; `room_files_test` catches them). Chosen: the parser.
- The level between rest and reach stays today's smoothstep lerp in y; volume-based filling has no
  reader.

## Decision

- **`RoomLegendEntry.reach: bool`** (WATER only; `RoomLegend.problems()` checks) and
  **`takes_reach: bool`** (default true; the lake `w` sets false). `r`: `reach = true`,
  `water_layer` = `freezable_water_layer.tscn` (it pours a lone group); description rewritten.
- **Parser** (`_read_water` keeps reach cells apart, then `_resolve_reach`): per 4-connected reach
  group, the host is the one non-reach water kind 4-adjacent to it; none, the group hosts itself.
  Errors: "'r' at C,R is over 'w': a lake does not rise", "'r' at C,R touches two kinds of water",
  "'r' at C,R is under water". **`RoomMap.reach: Dictionary[String, PackedVector2Array]`** keyed by
  host symbol. `FORMAT_VERSION` 2 to 3.
- **`RoomMapNode._pour(entry, cells, reach)`** for every symbol in `water` or `reach`; reach cells
  use alternative tile `WaterLayer.REACH_ALTERNATIVE` (1), added to `water_tiles.tres` with a paler
  modulate for the editor preview.
- **`WaterBasins.build(cells, reach := [])`**: components over both; `Basin.rest` = rows from the
  surface to the basin's top non-reach row (0 without reach; `deepest()` when only reach: dry).
- **`WaterLayer`**: `@export var rising_body_scene` for a basin with `rest > 0` (asserted set);
  sets `body.rest_depth = rest * cell.y`. `water_pool_layer.tscn` gets the new
  `rain_basin/rising_pool.tscn` (Node2D, `Water` = `water_pool.tscn`, `RainReceiver`, `Rain`);
  `freezable_water_layer.tscn` gets `rain_basin.tscn`. `rain_basin_layer.tscn` is deleted from the
  FileSystem dock (its users move to the freezable layer).
- **`WaterBody`**: `@export var rest_depth := 0.0` (px below the painted waterline; `size.y` or
  more is dry), `rest_level() -> float`. `rain_basin.tscn`'s `Water` sets 56 so the standalone
  scene stays dry (`rain_basin_test`).
- **`RainBasin`**: `_dry_y` becomes `_rest_y = rest_level()`, set deferred as today; `fill_time` /
  `drain_time` are rest to full. `Floater` is unchanged.

## Consequences

- Rules kept: levels authored (the rest and the reach are both painted); rooms are text;
  `FORMAT_VERSION` bumped; no new signals.
- SOLID: the parser resolves meaning, `WaterBasins` reads geometry, the layer picks a scene, the
  basin moves a level: each class one step (single responsibility). A new rising kind is a layer
  preset with a `rising_body_scene` (open/closed).
- Suites: `water_basins_test` (reach over water keeps the lower rest; lone reach is dry; no reach,
  rest 0; reach wider than its water). `room_map_parser_test` (r over `~` goes to `reach["~"]`;
  lone r to `reach["r"]`; the three errors). `room_map_node_test` (a pool with reach is one body
  from `rising_pool.tscn` at rest). `rain_basin_test` (a basin with a rest stands there at load,
  rain lifts it to the top, the last pulse returns it to rest, not dry; the dry tests stay).
  `spring_trial_test` reads `_map.reach.get("r")` and the freezable layer.
- Trial: a new room `water_trial` in `trials_solstice`, the last region (local x 5184 after
  `empty_house`, world x 14784, floor y 6000), with a `trial_spawn` marker, its contents in
  `trials_solstice/contents/`, both scenes in `tools/smoke/scenes.txt`. It holds PZL-09, PZL-03 and
  PZL-06 left to right (about 70 cells), walls in stone so Enraizar finds no earth to bridge.
  Section 1: a `~` pool 8 cells wide and 2 deep, `r` 4 rows (128 px) above, the log `O` in the
  rest water's top row by the far wall, a passage 3 cells tall in the far wall. Ivo plays Chuva on
  the near bank and jumps onto the rising log.
- `water_trial_test.gd`: the passage is beyond a jump from the bank and from the log at rest, and
  within `peak - MARGIN` from the log at the reach. Playtest `song_rain_rising_pool.json`. Fill 3 s
  and drain 4 s at memory 1 (the region's memory is 0.35 outside a pulse).
- Risks: stale imports without the bump; `room_legend.tres` and the spring/winter rooms have
  uncommitted edits in the working tree, so merge, do not overwrite. Playing on a floating log may
  be refused (`is_still()`); the trial plays from the bank. When built, update `systems/water`,
  `systems/rooms`, `docs/maps/README.md` (regenerate the legend; the errors table and a paragraph
  on reach) and the glossary's "nível da água" row.
