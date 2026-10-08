# Making rooms: the `.room` text map

Every room's ground, water and placed things are authored as **text**: one
character per 32 px cell, in a `.room` file beside the room's contents scene.
The text is the source of truth. The Godot scene only holds what text cannot
say well (parallax backgrounds, set dressing, a guardian and its arena), plus
one `RoomMap` node pointing at the `.room` file.

Why text: an ASCII grid can be read, written, diffed and reasoned about by a
person or an LLM - a gap's width, whether a ledge is stone or earth, whether a
song can reach both banks - where a painted `TileMapLayer` is an opaque byte
blob in the `.tscn`. Earth and stone are gameplay (Enraizar only roots in
earth), and a character can say that; a painted tile could not.

The parts of this guide between `<!-- generated -->` markers are written by
`tools/maps/gen_map_docs.tscn` from the code itself and checked by
`tests/scenes/world/rooms/maps/map_guide_test.gd`, so they cannot go stale.
Everything else is prose: **change it in the same commit as any convention it
describes.**

## Where a room's files live

Rooms are a three-level pattern (see `CLAUDE.md`, "Project structure", and `docs/knowledge/systems/rooms.md`):

```
scenes/world/rooms/<region>.tscn                            places the rooms
scenes/world/rooms/<region>/<room>.tscn                     the Room trigger (Area2D), contents_scene exported
scenes/world/rooms/<region>/contents/<room>_contents.tscn   backgrounds + a RoomMap node
scenes/world/rooms/<region>/contents/<room>.room            THIS: ground, water, entities
```

The contents scene's `RoomMap` node (`scenes/world/rooms/maps/room_map_node.gd`)
has `map` set to the `.room` file and `ground_material` set to
`floor_tiles_seasonal_material.tres`, so a pulse redraws the ground in its
season. It builds, as its children and in this order: the ground
`TileMapLayer`, one `WaterLayer` per kind of water, then every entity.

## The file

```
; downtown.room - comments start with ';' outside the grids
[room]
origin = -43, -6        ; tile coordinates of the grids' top-left character

[grid]                  ; ground, ledges and entities
...............................................###...........
..............................B...................####.......
############################################......###########
#############################################################

[water]                 ; optional: kinds of water, same size as [grid]
.............................................................
.............................................................
wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwffffff...........
.............................................................

[entities]              ; params for entities, by grid column,row
30,1 = {"save_id": "downtown_brute"}
```

- **One character is one 32 px cell.** The world position of grid column `c`,
  row `r` is `((origin.x + c) * 32, (origin.y + r) * 32)` - its top-left corner.
  Row 0 is the top. The floor Ivo walks on is the top edge of a ground cell.
- **`origin`** puts the grid in the room: it is the tile coordinate of the
  top-left character. Match the room's `Area2D` bounds (in its `<room>.tscn`).
- **`[water]` is a second layer** because water can lie *over* ground (a lake
  in front of the land) as well as fill a pit. It has exactly as many rows as
  `[grid]`. Each 32 px water character becomes 2x2 of the water system's
  16 px cells (`WaterLayer`), which works out the basins, surfaces and depths
  itself (`WaterBasins`).
- **`r` is a reach, not water**: painted above `~` or `f` in the same pit, the
  pool rests at the water painted under it and Chuva raises it to the top `r`
  row; painted alone, it is a dry basin. The parser joins each group of `r` to
  the one kind of water it touches.
- **`[entities]`** gives params to entity characters. Keys are **grid**
  column,row (0-based, from the top-left character), not tile coordinates.
  An entity without params needs no line.
- Short rows are padded with `.` and warned about. Keep rows the same width.

### How the ground is drawn

You never pick tiles. `GroundAutotile` chooses each ground cell's tile from
its eight neighbours at import: a grassy top where the sky is above, rounded
bottoms, one-wide walls and pillars, one-high ledges, and inner corners where
a diagonal opens. Past the map's **left, right and bottom** edges counts as
solid ground (the world runs on beyond the room); past the **top** is open sky.

So: to make a floor, write `#` down to the bottom of the grid. A floor that
stops above the bottom row shows a rounded underside.

Stone (`S`) uses the same shapes cut in masonry
(`tools/art/derive_stone_tiles.gd` derives it from the earth art). Every tile
carries its material in the TileSet's `ground` custom data, and the map answers
`RoomMapNode.ground_at(point)` for anything that asks.

## The legend

Every character comes from `resources/world/maps/room_legend.tres`. Nothing
else in the code knows what a character means.

<!-- generated:legend -->
| Character | Section | Kind | Material | What it is |
|---|---|---|---|---|
| `.` | any grid | empty | - | Nothing: air in `[grid]`, no water in `[water]`. |
| `#` | `[grid]` | ground | earth | Earth: soil with a grassy top (the season's top). Enraizar's roots grow from it. |
| `S` | `[grid]` | ground | stone | Stone: cut masonry. Roots never grow from it - use it where a song must NOT reach. |
| `=` | `[grid]` | ledge | earth | One-way earth ledge, one cell high: jump up through it, stand on it, drop through it. |
| `~` | `[water]` | water | - | Pool water in a pit, seen edge-on: waves, splashes, reflection. A hazard - Ivo does not swim. Fill the pit to where the water should stand. |
| `w` | `[water]` | water | - | Lake in front of the land, seen from above: opaque, a straight far shore. Paint it over the ground down to the room's bottom, and run it off the room's sides. |
| `f` | `[water]` | water | - | Pool water that Congelar freezes into a floor from where the song was played, and that thaws from there. |
| `B` | `[grid]` | entity | - | Brute Shadow: a common enemy that wanders, chases and swings. Needs a save_id unique across every map: it stays down until the next rest or death. |
| `W` | `[grid]` | entity | - | A natural current: a box of air standing on this cell (size in px, centred on the cell, rising from its floor) blowing one way, gusting through its profile. Vendaval adds to it; Congelar stops it; the grey stills it. |
| `P` | `[grid]` | entity | - | A stone pressure plate: holds whatever links to it (trigger_path) while enough weight stands on it - Ivo, his burned shadow, a released load. |
| `G` | `[grid]` | entity | - | A stone gate standing on this cell that slides up while its trigger_path (a plate) holds, and its second_trigger_path too when set. Any Mechanism: travel, move_time, start_moved. |
| `L` | `[grid]` | entity | - | A lift platform that rises by travel while its trigger_path holds and sinks back when it lets go; while its lock_path holds (a counterweight on the wrong plate) it is jammed down. |
| `T` | `[grid]` | entity | - | A seesaw on its pivot, leaning toward the heavier side by torque (mass times distance) - a shadow on one end raises the other. |
| `H` | `[grid]` | entity | - | A heavy cocoon on a rope, hang_height above this floor: Soltar cuts the rope, it falls, weighs a plate, rides Vendaval, and returns to its rope when the grey comes back. |
| `F` | `[grid]` | entity | - | A curtain of dry leaves blocking a passage (size in px, standing on this cell): Soltar drops it, the grey grows it back - not while someone stands inside. |
| `D` | `[grid]` | entity | - | A drawbridge hinged at the bottom centre of this cell, held up: Soltar lets it fall across length_cells toward side (1 right, -1 left); the grey hauls it back up. |
| `r` | `[water]` | water | - | Where Chuva brings the water: paint it above ~ or f water in the same pit and that pool rests at its painted water and rises to here while a Chuva pulse covers it. Painted alone it is a dry basin that fills, and freezes like f (Chuva then Congelar: ice where there was no water). Never over a lake. |
| `u` | `[water]` | water | - | Where water a Redoma shell holds out rises to: paint it above f or ~ water in the same pit. While a shell holds water out of its disc the pool rises around it, up to here, and Congelar can fix it there. The rain never raises it. Never alone, never over a lake. |
| `V` | `[grid]` | entity | - | A platform hanging hang_height above this floor on a braked rope: Soltar frees the brake and it lowers (drop px) swinging, no footing until it stops; Enraizar seizes it between earth walls a few cells away; the grey winches it back up. |
| `O` | `[grid]` | entity | - | A fallen log that floats: it lies where placed until water reaches it, then rides the waterline (a one-way platform). Chuva's basin lifts it, and Ivo with it. |
| `R` | `[grid]` | entity | - | A bench, standing on this cell: down sits Ivo on it, which heals him, brings the creatures back and saves; a death returns him here. Full shelter from the wind. Needs a bench_id unique across every map. |
<!-- /generated:legend -->

## Entity params

A param sets a property of the entity's root node, by name, converted to the
property's type:

| Property type | Write it as |
|---|---|
| int / float / bool / String | JSON number / boolean / string |
| enum | its number (the order in the enum's declaration) |
| StringName | a string |
| Vector2 / Vector2i | `[x, y]` |
| Color | `"#rrggbb"` or `"#rrggbbaa"` |
| a Resource (a wind profile, stats) | its path, `"res://resources/world/wind/gusty_wind.tres"` |
| NodePath (a link) | the other entity's `id` - `{"target_path": "gate_a"}` |

**Links.** Give an entity an `id` and it becomes the node's name, unique in
the room (the importer rejects two entities with the same id). A `NodePath`
param given a bare id resolves to that sibling (`../gate_a`) - in any order: the
entities enter the tree together (under the room's `Entities` node), so a gate
may be listed before the plate it follows; a path starting
with `.` or `/` is used as written.

A param the entity does not have, or a value its type cannot take, fails the
import (and the room-files test) instead of silently doing nothing.

**Required params.** Some entities are remembered by the save under an
authored id - a bench by `bench_id`, a creature by `save_id` - and a scene
default would quietly give every placement the same one. The legend lists
these as the entry's `required_params` (marked **required** in the tables
below): a placement without one fails the import, and the room-files test
also fails when two maps use the same id.

<!-- generated:entities -->
#### `B` - BruteShadow

Scene `res://scenes/characters/enemies/brute_shadow/brute_shadow.tscn`, anchored at its cell's bottom centre (standing on the cell below). Brute Shadow: a common enemy that wanders, chases and swings. Needs a save_id unique across every map: it stays down until the next rest or death.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `save_id` | String | **required** - unique across every map |
| `terminal_velocity` | float | `500.0` |
| `gravity_scale` | float | `1.0` |
| `knockback_time` | float | `1.0` |
| `knockback_damping` | float | `6.0` |
| `hurt_flash_color` | Color | `Color(1, 0.5, 0.5, 1)` |
| `hurt_flash_time` | float | `0.18` |

#### `W` - WindZone

Scene `res://scenes/world/environment/wind/wind_zone.tscn`, anchored at its cell's bottom centre (standing on the cell below). A natural current: a box of air standing on this cell (size in px, centred on the cell, rising from its floor) blowing one way, gusting through its profile. Vendaval adds to it; Congelar stops it; the grey stills it.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `size` | Vector2 | `Vector2(256, 160)` |
| `direction` | Vector2 | `Vector2(1, 0)` |
| `speed` | float | `220.0` |
| `profile` | WindProfile | `Resource("res://resources/world/wind/gusty_wind.tres")` |
| `phase` | float | `0.0` |
| `edge` | float | `24.0` |

#### `P` - PressurePlate

Scene `res://scenes/world/interactables/pressure_plate/pressure_plate.tscn`, anchored at its cell's bottom centre (standing on the cell below). A stone pressure plate: holds whatever links to it (trigger_path) while enough weight stands on it - Ivo, his burned shadow, a released load.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `required_mass` | float | `1.0` |

#### `G` - Gate

Scene `res://scenes/world/interactables/gate/gate.tscn`, anchored at its cell's bottom centre (standing on the cell below). A stone gate standing on this cell that slides up while its trigger_path (a plate) holds, and its second_trigger_path too when set. Any Mechanism: travel, move_time, start_moved.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `trigger_path` | NodePath | `NodePath("")` |
| `second_trigger_path` | NodePath | `NodePath("")` |
| `lock_path` | NodePath | `NodePath("")` |
| `travel` | Vector2 | `Vector2(0, -96)` |
| `move_time` | float | `0.6` |
| `start_moved` | bool | `false` |

#### `L` - Lift

Scene `res://scenes/world/interactables/lift/lift.tscn`, anchored at its cell's bottom centre (standing on the cell below). A lift platform that rises by travel while its trigger_path holds and sinks back when it lets go; while its lock_path holds (a counterweight on the wrong plate) it is jammed down.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `trigger_path` | NodePath | `NodePath("")` |
| `second_trigger_path` | NodePath | `NodePath("")` |
| `lock_path` | NodePath | `NodePath("")` |
| `travel` | Vector2 | `Vector2(0, -128)` |
| `move_time` | float | `1.4` |
| `start_moved` | bool | `false` |

#### `T` - Seesaw

Scene `res://scenes/world/interactables/seesaw/seesaw.tscn`, anchored at its cell's bottom centre (standing on the cell below). A seesaw on its pivot, leaning toward the heavier side by torque (mass times distance) - a shadow on one end raises the other.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `length` | float | `160.0` |
| `pivot_at` | float | `0.5` |
| `degrees_per_torque` | float | `0.35` |
| `max_degrees` | float | `24.0` |
| `turn_speed` | float | `60.0` |

#### `H` - HangingLoad

Scene `res://scenes/world/interactables/hanging_load/hanging_load.tscn`, anchored at its cell's bottom centre (standing on the cell below). A heavy cocoon on a rope, hang_height above this floor: Soltar cuts the rope, it falls, weighs a plate, rides Vendaval, and returns to its rope when the grey comes back.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `hang_height` | float | `64.0` |
| `rope_length` | float | `96.0` |
| `return_time` | float | `0.5` |

#### `F` - LeafCover

Scene `res://scenes/world/interactables/leaf_cover/leaf_cover.tscn`, anchored at its cell's bottom centre (standing on the cell below). A curtain of dry leaves blocking a passage (size in px, standing on this cell): Soltar drops it, the grey grows it back - not while someone stands inside.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `size` | Vector2 | `Vector2(32, 96)` |
| `regrow_time` | float | `0.8` |

#### `D` - Drawbridge

Scene `res://scenes/world/interactables/drawbridge/drawbridge.tscn`, anchored at its cell's bottom centre (standing on the cell below). A drawbridge hinged at the bottom centre of this cell, held up: Soltar lets it fall across length_cells toward side (1 right, -1 left); the grey hauls it back up.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `length_cells` | int | `4` |
| `side` | int | `1` |
| `fall_time` | float | `0.45` |

#### `V` - LoweringPlatform

Scene `res://scenes/world/interactables/lowering_platform/lowering_platform.tscn`, anchored at its cell's bottom centre (standing on the cell below). A platform hanging hang_height above this floor on a braked rope: Soltar frees the brake and it lowers (drop px) swinging, no footing until it stops; Enraizar seizes it between earth walls a few cells away; the grey winches it back up.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `width_cells` | int | `3` |
| `hang_height` | float | `160.0` |
| `drop` | float | `320.0` |
| `lower_speed` | float | `35.0` |
| `return_speed` | float | `80.0` |
| `swing_degrees` | float | `14.0` |
| `swing_rate` | float | `0.8` |

#### `O` - Floater

Scene `res://scenes/world/interactables/floater/floater.tscn`, anchored at its cell's bottom centre (standing on the cell below). A fallen log that floats: it lies where placed until water reaches it, then rides the waterline (a one-way platform). Chuva's basin lifts it, and Ivo with it.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `draft` | float | `4.0` |
| `sink_speed` | float | `240.0` |

#### `R` - Bench

Scene `res://scenes/world/interactables/bench/bench.tscn`, anchored at its cell's bottom centre (standing on the cell below). A bench, standing on this cell: down sits Ivo on it, which heals him, brings the creatures back and saves; a death returns him here. Full shelter from the wind. Needs a bench_id unique across every map.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `bench_id` | StringName | **required** - unique across every map |
| `facing` | int | `1` |
| `bloom_strength` | float | `0.9` |
| `bloom_radius` | float | `96.0` |
| `bloom_tint` | Color | `Color(1, 0.86, 0.62, 1)` |
| `bloom_rise` | float | `0.5` |
| `bloom_hold` | float | `0.8` |
| `bloom_fall` | float | `1.8` |
<!-- /generated:entities -->

## Sizing gaps: what Ivo can reach

<!-- generated:reach -->
| Move | Pixels | Cells |
|---|---|---|
| Jump height (holding jump) | 143 | 4.5 |
| Double-jump height (both jumps) | 270 | 8.5 |
| Widest gap, running jump, same height | 271 | 8.5 |
| Widest gap, running double jump, same height | 434 | 13.6 |
| Widest gap onto a ledge one cell higher | 258 | 8.1 |
| Widest gap onto a ledge one cell higher, double jump | 425 | 13.3 |

Computed by `JumpReach` from `ivo_jump_stats.tres`, `ivo_locomotion_stats.tres`, the double jump's `height` and Ivo's collision radius. A gap wider than these is a song's job - that is what makes a song useful.
<!-- /generated:reach -->

A puzzle for a song should be a gap (or a height, or a door) these numbers say
Ivo cannot clear alone, and the song makes clearable. Each song-trials room
has a reachability test that checks both halves.

## The loop

1. Edit the `.room` file (any text editor, or ask an agent).
2. Reimport: switching to the Godot editor reimports it; headless,
   `"<godot>" --headless --path . --import`. An error names the file, line and
   column, and the last good import stays in use.
3. Run the suite (`tests/scenes/world/rooms/maps/room_files_test.gd` parses
   and validates every `.room` in the project against the current legend).
4. Look at it: the contents scene previews the room in the editor, or run a
   playtest timeline with `player_position` in the room (`tools/playtest/`).

## Adding to the legend

1. Add a `RoomLegendEntry` to `room_legend.tres`: one unused character, its
   kind, and for ground/ledge the material, for water the `WaterLayer` preset,
   for an entity its scene and anchor. Write a one-line `description` - it
   becomes this guide's legend row.
2. An entity's params are its root's exported properties: document them with
   `##` comments on the export, and keep the root a `Node2D`.
3. Regenerate this guide:
   `"<godot>" --headless --path . res://tools/maps/gen_map_docs.tscn`
4. A legend change does not reimport maps on its own. Reimport them (step 2
   of the loop); the room-files test already reads them fresh.

## Errors and what they mean

| Message | Meaning |
|---|---|
| `unknown character 'X'` | not in the legend (or in the wrong grid) |
| `water 'w' belongs in [water], not [grid]` | water goes in its own layer |
| `'#' is not a kind of water` | only water characters go in `[water]` |
| `[water] has N rows, [grid] has M` | the two layers must line up |
| `'r' at C,R is over 'w': a lake does not rise` | a reach only joins pool water (`~`, `f`) |
| `'r' at C,R touches two kinds of water` | a reach joins one body: keep it over one kind |
| `'r' at C,R is under water` | a reach is above the water it raises, never below it |
| `no entity at column C, row R` | an `[entities]` line points at a cell that is not an entity (keys are grid coordinates) |
| `params must be a JSON object` | the right-hand side is not `{...}` |
| `id 'X' is used by two entities` | ids name nodes; they must be unique in the room |
| `'Node' has no param 'X'` | the entity's root has no such exported property |
| `cannot use V as T` | the value does not convert to the property's type |
| `needs a 'X' param` | the legend requires this param on every placement of the entity (an id the save remembers it by) |
