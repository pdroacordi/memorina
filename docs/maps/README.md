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
has `map` set to the `.room` file. It builds, as its children and in this
order: one `Back_<look>` and one `Ground_<look>` `TileMapLayer` per look the
room uses, `Ledges`, the hidden `Solid` collision layer, one `WaterLayer` per
kind of water, then every entity. The ground draws through
`floor_tiles_seasonal_material.tres` (back walls through the darker
`back_tiles_seasonal_material.tres`), so a pulse redraws it in its season.

## The file

```
; downtown.room - comments start with ';' outside the grids
[room]
origin = -43, -6        ; tile coordinates of the grids' top-left character
tileset = village       ; the biome whose sheets draw the ground (required)

[grid]                  ; ground, ledges and entities
...............................................###...........
..............................B...................####.......
-------------------------------------------#......###########
...........................................##################

[water]                 ; optional: kinds of water, same size as [grid]
.............................................................
.............................................................
............................................ffffff...........
wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww..................

[back]                  ; optional: walls drawn behind the room, same size as [grid]
.............................................................
.......................................hhhh..................
.............................................................
.............................................................

[secret]                ; optional: false walls over air, same size as [grid]
.............................................................

[entities]              ; params for entities, by grid column,row
30,1 = {"save_id": "downtown_brute"}
```

- **One character is one 32 px cell.** The world position of grid column `c`,
  row `r` is `((origin.x + c) * 32, (origin.y + r) * 32)` - its top-left corner.
  Row 0 is the top. The floor Ivo walks on is the top edge of a ground cell.
- **`origin`** puts the grid in the room: it is the tile coordinate of the
  top-left character. Match the room's `Area2D` bounds (in its `<room>.tscn`).
- **`tileset`** names a biome, `resources/world/tiles/biomes/<id>.tres`
  (the table below). A character fixes what the ground is made of; the biome
  only draws it. A character whose look the biome lacks is an import error.
- **`[back]` is an optional third layer** of walls behind the room: a cellar's
  earth wall, a house wall seen from the street. It takes ground characters
  (a wall of that look) and back characters (`h`) only, never ledges, water or
  entities, and has exactly as many rows as `[grid]`. It never changes the
  ground, collision or `ground_at()`. A whole-room interior wall is the room's
  backdrop strip instead (`docs/knowledge/systems/backdrops.md`). A `[back]`
  wall in a passage between two rooms with different backdrops hides the hard
  cut between them (`backdrop_seams_test` names the cells it needs).
- **`[secret]` is an optional layer** of false walls (`docs/knowledge/architecture/secret-false-walls.md`):
  its cells must be air in `[grid]`, and each is drawn as solid ground of the
  look given until Ivo's body enters it, then fades open for good (a bench
  keeps it found, a death forgets it). It takes ground characters and secret
  characters (`k`, cracked stone: the hint), never ledges, water or entities;
  an entity in `[grid]` under a secret cell stays hidden with it. Cells are
  grouped 8-connected, each group named `<room file>@x,y` by its first cell. A
  secret never collides, so songs, roots and rain act on the real hollow. Keep
  a hint by every secret: a `k` cell or a `d` draft at its mouth.
- **Pool water must be held**: `~` or `f` with open air beside or under it is
  an error, and so is air above it below its surface unless that air is a
  sealed pocket. Water painted under the ground beside a pit fills a passage
  (`docs/knowledge/systems/water.md`).
- **`[water]` is a second layer** because water can fill a covered passage
  under ground as well as a pit. It has exactly as many rows as `[grid]`.
  Each 32 px water character becomes 2x2 of the water system's 16 px cells
  (`WaterLayer`), which works out the basins, surfaces and depths itself
  (`WaterBasins`).
- **A lake (`w`) lies only over air**, in front of the land: never over ground
  or a ledge, each of its rows runs off a room side (onto the next room's
  solid ground) or ends against solid ground, each column runs to the room's
  bottom or onto solid ground, and it never touches another kind of water
  (WORLD-29). Ivo never falls into one: a lake lies under a deck with no
  drop-through or a solid shore.
- **`r` is a reach, not water**: painted above `~` or `f` in the same pit, the
  pool rests at the water painted under it and Chuva raises it to the top `r`
  row; painted alone, it is a dry basin. The parser joins each group of `r` to
  the one kind of water it touches.
- **`[entities]`** gives params to entity characters. Keys are **grid**
  column,row (0-based, from the top-left character), not tile coordinates.
  An entity without params needs no line.
- Short rows are padded with `.` and warned about. Keep rows the same width.

### How the ground is drawn

You never pick tiles. The ground is drawn on a **dual grid**
(`docs/knowledge/architecture/biome-tilesets.md`): each drawn tile sits on a
cell corner, and its four quarters belong to the four cells around it, so
`RoomTileResolver` picks it at import from which of those cells are solid. That
gives a grassy (or the season's) top on every exposed top, rounded corners,
pillars and lone boulders, and exact inner corners. Each look draws on its own
layer; where two looks meet, the earlier look (earth, then stone, then wood) is
laid under the later one only beside it, so cobbles over earth show earth
between their rounded bottoms. One-way ledges draw their own thinner strip.

Past the map's **left, right and bottom** edges the edge cells continue (the
world runs on beyond the room); past the **top** is open sky. So: to make a
floor, write `#` down to the bottom of the grid. A floor that stops above the
bottom row shows a rounded underside.

Collision never comes from the art: a hidden, cell-aligned `Solid` layer
(`GroundCollision`) holds one full square per solid cell, carries the cell's
material in its `ground` custom data, and the map answers
`RoomMapNode.ground_at(point)` for anything that asks.

### Tilesets

<!-- generated:tilesets -->
| `tileset =` | Looks | What it is |
|---|---|---|
| `frost_edge` | stone, wood, wall | Frost Edge: dark sea-cliff rock (the shared rock body, dark palette), the village oak planks, white masonry back walls; no earth ("No earth there", user, 2026-10-08). |
| `frozen_lake` | earth, stone, wood | Frozen Lake: bluish lake stone (the shared rock body, blue palette), cold dark chasm earth, grey stilt planks (design 04 section 6; tools/art/tiles/frozen_lake_*.json). |
| `legacy` | earth, stone, wood, wall | The pack's earth and stone converted to the corner-Wang contract; placeholder wood and wall. Test fixtures only: no room uses it (WORLD-07, 2026-10-13). |
| `lighthouse` | stone, wood, wall | The lighthouse rooms: white masonry ground and back walls, the village oak planks ("Lighthouse masonry tiles", user, 2026-10-13); no earth. |
| `spring_woods` | earth, stone, wood | Spring Woods: forest earth under a moss and blossom turf, mossy cave rock, the village oak planks (design 04 section 6; tools/art/tiles/spring_woods_*.json). |
| `summer_caldera` | stone, wood, wall | Summer Caldera: porous basalt, temple sandstone back walls, the village oak planks; no earth ("No earth there", user, 2026-10-08). |
| `summer_caldera_ash` | stone, wood, wall | Summer Caldera ash scree: loose ash and cinders drawn as the STONE look, so S cells are Ground STONE and roots never take them ("Caldera ash as scree", user, 2026-10-13); temple sandstone back walls, the village oak planks. |
| `threshold` | earth, stone, wood | Threshold Road: dry pale earth with stones and roots under a straw turf, worn road slabs, the village oak planks (design 04 section 6; tools/art/tiles/threshold_*.json, after the approved style board). |
| `village` | earth, stone, wood, wall | The Home Village: dark loam with a grass top, rounded street stones under a walk of pale cobbles, dark oak planks, plaster and timber walls (design 04 section 6; tools/art/tiles/village_*.json, after the approved concept). |
| `wind_orchards` | earth, stone, wood | Wind Orchards: ochre earth with stones and roots under a golden turf, a dry-stone wall, the village oak planks (design 04 section 6; tools/art/tiles/wind_orchards_*.json). |
<!-- /generated:tilesets -->

## The legend

Every character comes from `resources/world/maps/room_legend.tres`. Nothing
else in the code knows what a character means.

<!-- generated:legend -->
| Character | Section | Kind | Material | Look | Reach | What it is |
|---|---|---|---|---|---|---|
| `.` | any grid | empty | - | - | - | Nothing: air in `[grid]` and `[back]`, no water in `[water]`. |
| `#` | `[grid]`, `[back]`, `[secret]` | ground | earth | earth | - | Earth: soil with a grassy top (the season's top). Enraizar's roots grow from it. |
| `S` | `[grid]`, `[back]`, `[secret]` | ground | stone | stone | - | Stone: the biome's rock or laid stone. Roots never grow from it - use it where a song must NOT reach. |
| `=` | `[grid]` | ledge | earth | earth | - | One-way earth ledge, one cell high: jump up through it, stand on it, drop through it. |
| `%` | `[grid]`, `[back]`, `[secret]` | ground | wood | wood | - | Wood: planks, beams, stilts. Solid; roots never grow from it. |
| `-` | `[grid]` | ledge | wood | wood | - | One-way plank, one cell high: jump up through it, stand on it. |
| `^` | `[grid]` | roof | wood | - | - | Roof: a one-way ledge with no tile art, drawn by the building's facade prop; it lies on the facade's roof line (facade_doors_test). |
| `h` | `[back]` | back wall | - | wall | - | Built wall behind the room (plaster and timber, planks, sandstone): [back] grid only, no collision. |
| `~` | `[water]` | water | - | - | - | Pool water in a pit, seen edge-on: waves, splashes, reflection. A hazard - Ivo does not swim. Fill the pit to where the water should stand. |
| `w` | `[water]` | water | - | - | hazard | Lake in front of the land, seen from above: opaque, a straight far shore. Paint it over air down to the room's bottom, never over ground or a ledge; run each row off a room side or end it against solid ground. |
| `f` | `[water]` | water | - | - | ice | Pool water that Congelar freezes into a floor from where the song was played, and that thaws from there. |
| `B` | `[grid]` | entity | - | - | - | Brute Shadow: a common enemy that wanders, chases and swings. Needs a save_id unique across every map: it stays down until the next rest or death. |
| `W` | `[grid]` | entity | - | - | current | A natural current: a box of air standing on this cell (size in px, centred on the cell, rising from its floor) blowing one way, gusting through its profile. Vendaval adds to it; Congelar stops it; the grey stills it. |
| `P` | `[grid]` | entity | - | - | content | A stone pressure plate: holds whatever links to it (trigger_path) while enough weight stands on it - Ivo, his burned shadow, a released load. |
| `G` | `[grid]` | entity | - | - | content | A stone gate standing on this cell that slides up while its trigger_path (a plate) holds, and its second_trigger_path too when set. Any Mechanism: travel, move_time, start_moved. |
| `L` | `[grid]` | entity | - | - | mover | A lift platform that rises by travel while its trigger_path holds and sinks back when it lets go; while its lock_path holds (a counterweight on the wrong plate) it is jammed down. |
| `T` | `[grid]` | entity | - | - | mover | A seesaw on its pivot, leaning toward the heavier side by torque (mass times distance) - a shadow on one end raises the other. |
| `H` | `[grid]` | entity | - | - | content | A heavy cocoon on a rope, hang_height above this floor: Soltar cuts the rope, it falls, weighs a plate, rides Vendaval, and returns to its rope when the grey comes back. |
| `F` | `[grid]` | entity | - | - | content | A curtain of dry leaves blocking a passage (size in px, standing on this cell): Soltar drops it, the grey grows it back - not while someone stands inside. |
| `D` | `[grid]` | entity | - | - | mover | A drawbridge hinged at the bottom centre of this cell, held up: Soltar lets it fall across length_cells toward side (1 right, -1 left); the grey hauls it back up. |
| `r` | `[water]` | water | - | - | ice | Where Chuva brings the water: paint it above ~ or f water in the same pit and that pool rests at its painted water and rises to here while a Chuva pulse covers it. Painted alone it is a dry basin that fills, and freezes like f (Chuva then Congelar: ice where there was no water). Never over a lake. |
| `u` | `[water]` | water | - | - | ice | Where water a Redoma shell holds out rises to: paint it above f or ~ water in the same pit. While a shell holds water out of its disc the pool rises around it, up to here, and Congelar can fix it there. The rain never raises it. Never alone, never over a lake. |
| `V` | `[grid]` | entity | - | - | mover | A platform hanging hang_height above this floor on a braked rope: Soltar frees the brake and it lowers (drop px) swinging, no footing until it stops; Enraizar seizes it between earth walls a few cells away; the grey winches it back up. |
| `O` | `[grid]` | entity | - | - | mover | A fallen log that floats: it lies where placed until water reaches it, then rides the waterline (a one-way platform). Chuva's basin lifts it, and Ivo with it. |
| `R` | `[grid]` | entity | - | - | content | A bench, standing on this cell: down sits Ivo on it, which heals him, brings the creatures back and saves; a death returns him here. Full shelter from the wind. Needs a bench_id unique across every map. |
| `E` | `[grid]` | entity | - | - | door | A building's door, standing on this cell, two cells tall: up takes Ivo to the door with the same link in the room to_room (that room's scene file name, same region). Each link joins exactly two doors. Optional requires (a SaveFact .tres path) seals it until the save holds that fact; arrive_facing (1 right, -1 left) turns Ivo on arrival here. |
| `X` | `[grid]` | entity | - | - | content | A barred gate, standing on this cell, three cells tall: solid until the save holds requires (a SaveFact .tres path), then gone. Walked through, not a door: the village fences that open once Ivo owns the Memorina (design 04 section 2). |
| `k` | `[secret]` | secret | - | stone | - | [secret] only: a secret cell drawn as cracked stone until Ivo steps in - the hint that the wall is false. |
| `d` | `[grid]` | entity | - | - | - | A faint draft of dust at a secret's mouth (facing 1 right, -1 left, 0 up); it freezes in the grey. |
| `@` | `[grid]` | entity | - | - | stair | A helix stair the tower turns around: Ivo rides straight up its axis while the view turns the stair, wall and slits by his progress. Place it on the bottom floor, its cell's bottom-left corner the axis. shape is a HelixStairShape .tres path, look a HelixLook; hand 1 climbs with right held, -1 with left. The head needs a plank gallery across the shell (one-way, so Ivo rises through it), the column up the axis must be clear of solid ground, and the shell's inner faces stand at the wall's silhouette (room_files_test). |
| `_` | `[grid]` | void | stone | - | - | Void outside a room's shell: solid stone to gameplay, drawn black. Every one of its 8 neighbours is ground (not a ledge), void or off the map, so a drawn wall always stands between the room's air and the void; never under water, a reach or a secret, and only in interiors for now. |
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
| `save_id` | String | **required** |
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
| `bench_id` | StringName | **required** |
| `facing` | int | `1` |
| `bloom_strength` | float | `0.9` |
| `bloom_radius` | float | `96.0` |
| `bloom_tint` | Color | `Color(1, 0.86, 0.62, 1)` |
| `bloom_rise` | float | `0.5` |
| `bloom_hold` | float | `0.8` |
| `bloom_fall` | float | `1.8` |

#### `E` - Door

Scene `res://scenes/world/interactables/door/door.tscn`, anchored at its cell's bottom centre (standing on the cell below). A building's door, standing on this cell, two cells tall: up takes Ivo to the door with the same link in the room to_room (that room's scene file name, same region). Each link joins exactly two doors. Optional requires (a SaveFact .tres path) seals it until the save holds that fact; arrive_facing (1 right, -1 left) turns Ivo on arrival here.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `link` | StringName | **required** |
| `to_room` | StringName | **required** |
| `requires` | SaveFact | `null` |
| `arrive_facing` | int | `0` |
| `look` | enum (door,passage,stairwell,hatch_up,hatch_down) | `"door"` |

#### `X` - FactBarrier

Scene `res://scenes/world/interactables/fact_barrier/fact_barrier.tscn`, anchored at its cell's bottom centre (standing on the cell below). A barred gate, standing on this cell, three cells tall: solid until the save holds requires (a SaveFact .tres path), then gone. Walked through, not a door: the village fences that open once Ivo owns the Memorina (design 04 section 2).

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `requires` | SaveFact | **required** |
| `art` | Texture2D | `null` |

#### `d` - Draft

Scene `res://scenes/world/environment/draft/draft.tscn`, anchored at its cell's centre. A faint draft of dust at a secret's mouth (facing 1 right, -1 left, 0 up); it freezes in the grey.

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `facing` | int | `1` |

#### `@` - HelixStair

Scene `res://scenes/world/interactables/helix_stair/helix_stair.tscn`, anchored at its cell's bottom centre (standing on the cell below). A helix stair the tower turns around: Ivo rides straight up its axis while the view turns the stair, wall and slits by his progress. Place it on the bottom floor, its cell's bottom-left corner the axis. shape is a HelixStairShape .tres path, look a HelixLook; hand 1 climbs with right held, -1 with left. The head needs a plank gallery across the shell (one-way, so Ivo rises through it), the column up the axis must be clear of solid ground, and the shell's inner faces stand at the wall's silhouette (room_files_test).

| Param | Type | Default |
|---|---|---|
| `id` | String | none - names the node so other entities can link to it |
| `shape` | HelixStairShape | **required** |
| `look` | HelixLook | `Resource("res://resources/world/helix/bell_tower_look.tres")` |
| `hand` | int | `1` |
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

The air jump carries further than the table's apex press when pressed later in
the fall: about 15 cells across, not 13.

**Edges** (WORLD-34, `docs/knowledge/systems/rooms.md`, "Edges"). Ivo never
stands outside a room. Every edge with no room beyond is an invisible wall.
Over an open top (first-row cell air, water or secret, no room above) an
invisible ceiling sits 152 px up: a full jump from row 2 clears it, but a
double jump or a single jump from row 1 is cut off. Never make a first-row seam
pillar a crossing: the sky cannot pass over it, so cross a seam through its
opening (rows 5-8) or lower the pillar a row. A room inside rock gets a drawn
row-0 ceiling, not sky. Do not draw an opening onto the void: the audit flags
it as `OPEN_EDGE`.

**The reachability audit** (`room_reach_test.gd`) steps Ivo's arc over every
world room stitched together, every song assumed at once, and fails on a
platform he cannot reach, a platform that leads nowhere, a place he cannot
come back from, or a door with no partner, unless `resources/world/maps/reach_allowlist.tres` lists it with
a reason. The legend's Reach column is what it makes of each character. See the
findings room by room:
`"<godot>" --headless --path . res://tools/maps/reach_boards.tscn -- --out <dir>`
writes `<room>.txt` and `<room>.png` (`!` unreachable, `*` leads nowhere, `+`
redundant route, `:` dead-end pocket, `&` no way back, `?` unpaired door, on the
feet row). Rules:
`docs/knowledge/systems/rooms.md`, "Reachability audit".

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
| `no 'tileset' in [room]` | every room names its biome |
| `unknown tileset 'x'` | no `resources/world/tiles/biomes/x.tres` |
| `tileset must be a biome file name` | lowercase letters, digits and `_` only |
| `tileset 'x' has no <look>: 'C' at c,r` | that biome draws no such look (the Caldera and the Frost Edge have no earth) |
| `[back] has N rows, [grid] has M` | the two layers must line up |
| `'=' cannot be a back wall` | only ground and back characters go in `[back]` |
| `'h' belongs in [back], not [grid]` | a back wall has no collision; it lives in its own layer |
| `water 'w' belongs in [water], not [grid]` | water goes in its own layer |
| `'#' is not a kind of water` | only water characters go in `[water]` |
| `[water] has N rows, [grid] has M` | the two layers must line up |
| `[secret] has N rows, [grid] has M` | the two layers must line up |
| `'=' cannot be a secret` | only ground and secret characters go in `[secret]` |
| `'S' at c,r is already ground: [secret] hides air` | a secret cell is air in `[grid]` |
| `secret at c,r has water above it` | a closed secret's top lip would spill into the water |
| `tileset 'x' has no crack: 'k' at c,r` | that biome draws no crack decal |
| `'~' at c,r stands against open air (...)` | pool water must be held by ground, water or a sealed pocket |
| `'~' at c,r is water no surface reaches` | a covered passage must be one unbroken run per column |
| `'r' at C,R is over 'w': a lake does not rise` | a reach only joins pool water (`~`, `f`) |
| `'w' at C,R lies over ground` (or `a ledge`) | a lake draws in front of the land at z 50: paint it only over air |
| `'w' at C,R ends in the air` | each row of a lake runs off a room side or ends against solid ground (not air or a ledge) |
| `'w' at C,R stops in the air` | each column of a lake runs to the room's bottom or onto solid ground |
| `'w' at C,R meets '~' water` | a lake and another kind of water need solid ground between them |
| `'r' at C,R touches two kinds of water` | a reach joins one body: keep it over one kind |
| `'r' at C,R is under water` | a reach is above the water it raises, never below it |
| `no entity at column C, row R` | an `[entities]` line points at a cell that is not an entity (keys are grid coordinates) |
| `params must be a JSON object` | the right-hand side is not `{...}` |
| `id 'X' is used by two entities` | ids name nodes; they must be unique in the room |
| `'Node' has no param 'X'` | the entity's root has no such exported property |
| `cannot use V as T` | the value does not convert to the property's type |
| `needs a 'X' param` | the legend requires this param on every placement of the entity (an id the save remembers it by) |
