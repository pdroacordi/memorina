---
id: architecture/doors-and-interiors
type: architecture
title: Doors pair by a shared link and a room id; Ivo's body takes the door, Game travels through the shared landing; interiors are ordinary rooms flagged `interior` (WORLD-09)
status: active
tags: [doors, interiors, rooms, room-map, legend, transition, fade, teleport, save-fact, lock, map, weather, plan, world-09]
related: [systems/rooms, systems/life-benches-death, systems/map, systems/input, systems/notebook, architecture/rooms-are-text, architecture/the-life-loop-rewinds-by-reloading, architecture/notebook-entries-are-derived-from-the-save, architecture/map-reveal-seen-cells-per-room, architecture/character-controller-input-split, architecture/hazard-respawn-on-safe-ground, bugs/a-teleported-ivo-enters-the-room-he-left, bugs/a-debug-boot-reveals-map-cells-ivo-never-saw, bugs/presses-made-while-sinking-fire-on-respawn, bugs/player-input-edge-state-goes-stale-across-a-pause-menu, bugs/sitting-is-not-gated-on-a-guardian-fight, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step, gotchas/a-stick-is-pressed-on-every-motion-event, gotchas/a-killed-tween-never-emits-finished, gotchas/a-freed-object-in-a-deferred-call-fails-its-typed-argument, gotchas/monitorable-false-hides-an-area-from-every-monitor, gotchas/queue-free-deferred-add-still-enters-the-tree]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/interactables/door/door.gd
  - scenes/world/interactables/door/door.tscn
  - scenes/world/interactables/door/door_links.gd
  - scenes/characters/components/door_component.gd
  - resources/save_facts/save_fact.gd
  - scenes/world/game.gd
  - scenes/world/rooms/room.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/player_input.gd
  - scenes/ui/map/map_revealer.gd
  - scenes/ui/map/map_screen.gd
  - scenes/world/environment/region_weather/region_weather.gd
  - resources/world/maps/room_legend.tres
  - resources/ui/notebook/notebook_entry.gd
---

## Summary

BUILT (2026-10-08, WORLD-09; design 04 §4; user: "All doors"). Differences from the plan: Game disables Ivo with `set_deferred` and `_try_door` drops the other buffers before it emits (`bugs/taking-a-door-disables-ivo-inside-his-own-physics-step`); `arrive_at` also stands him up. Up is taken while walking (the builder's reading of 04 §4, not yet ruled by the user), and is not buffered (`playtests/2026-10-08-doors-and-interiors`). A `Door` is a room-map entity (`E`) whose params are `link` (the doorway's name, shared by exactly two doors), `to_room` (the partner's room id, i.e. its Room scene's file name, same region) and an optional `requires: SaveFact`. Ivo's body takes a door on a `look_up` press edge and emits `Player.door_entered(door)`, as it emits `sat_down(seat)`; `Game` carries the travel out through a `_land_in(room, place)` coroutine that `_arrive` also uses. An interior is an ordinary `Room` with `interior = true`: never revealed on the map, no weather. No save key, no text.

## Context

- Room contents load lazily (`Room.activate` adds them deferred), so the partner door does not exist until its room is entered. Whatever names it must also name its room.
- `Game` owns room transitions. Today it has two "enter a room behind the black and place Ivo" paths: `_arrive` (seat, then `snap`, then `room_changed`) and the hazard beat. A third copy would drift from them.
- Every non-motion move goes through `Character.teleport`. `room_changed` fires only once the frame shows the room (`bugs/a-debug-boot-reveals-map-cells-ivo-never-saw`).
- `look_up` already means three things: a held camera peek (`look_axis`, 0.3 s hold), grabbing a climbable (`_try_climb`, held), and standing up from a bench (`_wants_to_stand`). With the Memorina drawn, the Up arrow is `note_up`.
- The notebook already has a pure predicate over save facts: `NotebookEntry.Requirement` + `index`, `is_present(data)`.
- `RegionWeather` follows the camera everywhere, so without a change it would snow inside the tavern.

## Options considered

**Naming the partner**
- `door_id` unique per world plus `to_door`: three params per door, and two names for one doorway. Rejected.
- Implicit pairing (the door in `to_room` that points back): ambiguous once two doors join the same two rooms. Rejected.
- A generated door → room index: one more generated artifact that can drift. Rejected.
- **Chosen: a shared `link` plus `to_room`.** Both doors carry the same `link`, which is unique per pair across the world (exactly two doors). Each door names the room it leads to. The redundancy is checked by a pure `DoorLinks` validator in `room_files_test`.

**Naming the room**
- The Room node's name in the region: PascalCase and renamed freely. Rejected.
- A `PackedScene` export: it loads the target room, which loads its `contents_scene`, so every door would pull in its partner's whole contents. That is the cycle `Game.title_scene` avoids. Rejected.
- A uid string: survives renames but cannot be read in a `.room`. Rejected.
- **Chosen: the room id, which is the Room scene's file basename** (`village_tavern`, the ids of design 04 §3). `Room.id()` derives it. The lookup is confined to the current room's region, which enforces "same region" (04 §4). A rename that breaks a pair fails `room_files_test`.

**Who performs the travel**
- The Door reaches into Game: an upward `get_node`. Rejected.
- Game connects to every Door: doors come and go with lazily loaded contents. Rejected.
- **Chosen: `Player.door_entered(door)`**, the same shape as `sat_down(seat)`. The body judges the press (CLAUDE.md, input split); Game connects once in `_ready`.

**The transition**
- Copying `_arrive`: rejected.
- `WorldFreeze.hold()` during the fade: walk-in transitions don't hold, `WorldFreeze` is for menus and performances, and a disabled Ivo is already out of physics. Rejected.
- **Chosen: the walk-in shape** (Ivo `PROCESS_MODE_DISABLED`, pausable `Fade`) with the room swap factored into `_land_in`, which `_arrive` now shares.

**The lock**
- An enum and an int on Door: duplicates the notebook's `match`, and the numbers are unreadable in a `.room`. Rejected.
- A script per lock, or an expression string: rejected.
- **Chosen: a `SaveFact` Resource** (`kind` + `index`, `holds(data)`), referenced from a `.room` by path. `NotebookEntry` delegates to it, so the save-fact `match` exists once.

**Map exclusion**
- A list of interior keys in the map code: a second source of truth. Rejected.
- **Chosen: `Room.interior`.** `MapRevealer` disarms on an interior, so interiors never enter `map_seen`. The same flag hides the weather.

**Arrival facing**
- Always keep his facing: wrong at a door set in a side wall.
- **Chosen: `arrive_facing`**: 0 keeps his facing, ±1 forces it.

## Decision

**`Door`** (`scenes/world/interactables/door/door.gd`, `class_name Door extends Area2D`). It is the legend's root, so its script exports are its params. Shallow scene: `Door` → `CollisionShape2D` (32x64, bottom on the floor), `Sprite2D` (2 frames: shut, sealed), `Prompt` (`KeyGlyph`, `look_up`).
- `collision_layer = Seat.LAYER` (6, Interactable). The mask is the player BODY (layer 9), never the hurtbox (`gotchas/monitorable-false-hides-an-area-from-every-monitor`). Group `&"doors"`, joined in `_enter_tree`.
- Exports:
  - `link: StringName` (required)
  - `to_room: StringName` (required)
  - `requires: SaveFact` (null: always open)
  - `arrive_facing: int = 0`
- `signal knocked`: a press at a sealed door; a sound can attach later.
- `is_open_for(data: PlayerData) -> bool` (pure) and `is_open() -> bool` (reads `SaveSystem.player_data`, pulled at the press, never a cached flag: `bugs/sitting-is-not-gated-on-a-guardian-fight`).
- `knock()`: the sprite shakes ±2 px in whole pixels for 0.2 s on a pausable tween, then emits `knocked`.
- `static find(tree: SceneTree, room: Room, link: StringName) -> Door`: the door in `room` that carries `link`.
- The look refreshes in `_ready` and on `SaveSystem.progress_changed`. A sealed door shows the sealed frame and no prompt; an open one shows the prompt while Ivo's body is in reach. **No text** (i18n): the seal, the missing prompt and the knock say everything.

**`SaveFact`** (`resources/save_facts/save_fact.gd`, Resource, pure):
- `enum Kind { SKILL, SONG, ITEM, GUARDIAN_MET, GUARDIAN_RESTORED, ALL_GUARDIANS_RESTORED }`. Append only; the first five keep `NotebookEntry.Requirement`'s order, so the notebook `.tres` files (stored as ints) still load.
- `@export var kind: Kind` and `@export var index: int`, which `ALL_GUARDIANS_RESTORED` ignores.
- `holds(data: PlayerData) -> bool` and `static check(kind: Kind, index: int, data: PlayerData) -> bool`.
- Instances: `owns_memorina.tres` (ITEM, `PlayerItem.MEMORINA`) and `all_guardians_restored.tres`.
- `NotebookEntry.requirement` becomes `SaveFact.Kind`, and `is_present` returns `SaveFact.check(...)`. `NotebookEntry.Requirement` is deleted; `NotebookCatalog.SECTION_REQUIREMENT` and its test switch names.
- The lock re-derives from the save, so a death rewinds it for free (`architecture/notebook-entries-are-derived-from-the-save`).

**Ivo**
- `PlayerInput`:
  - `signal look_up_pressed`, an edge through `_up_held` (`gotchas/a-stick-is-pressed-on-every-motion-event`).
  - `resync(jump_held, down_held, up_held := false)`. On re-enable after the fade, Up held from the press is not a new press; without this he would bounce straight back through the door.
- `DoorComponent` (`scenes/characters/components/door_component.gd`): `sensor_path = ^"../DoorSensor"`, `reachable() -> Door`. It is the twin of `SitComponent.reachable`.
- `ivo.tscn` gains `Doors` (the component) and `DoorSensor` (Area2D, layer 0, mask 32, monitorable false), beside `SeatSensor`.
- `Player`:
  - `signal door_entered(door: Door)`.
  - `_input.look_up_pressed.connect(_as_move.bind(_request_door))`. With the Memorina drawn, Up is a note and is dropped. Seated, the press only stands him up.
  - `_try_door(on_floor) -> bool` runs after the seated block and before `_try_climb`; a door taken skips the climb.
  - The press is refused when he is: off the floor, rolling, attacking, in knockback, climbing, wall-sliding, holding the Memorina, in a staged or set call, in a pending or armed recall, or inside `Guardian.fight_at`.
  - Holding a direction does not refuse it.
  - A sealed door gets `door.knock()` and no signal.
  - The sink branch, `respawn()` and `block_input()` clear `_door_requested`.
  - `arrive_at(door: Door)`: release the climb, stop the wall slide, `clear_knockback`, `cancel_recovery`, `teleport(door.global_position)`, `velocity = ZERO`, `face_towards(door.arrive_facing)`, then drop the jump, roll, attack and draw buffers. The buffers have not ticked under the fade and would fire on arrival (`bugs/presses-made-while-sinking-fire-on-respawn`). Factor `_drop_buffers()` out of `block_input`.

**Game**
- `_land_in(room: Room, place: Callable)`: `_enter_room(room)`, await `room.contents().ready` if it is not ready, `place.call()`, `_camera.snap()`, `room_changed.emit(room)`. `_arrive` becomes: disable Ivo, `await _land_in(room, seat)`, enable, fade to clear. Its order is unchanged.
- `_on_player_entered_door(door)`:
  1. Return if `_is_transitioning or _dying`.
  2. Resolve `room := _room_named(door.to_room, _current_room.get_region())`. Warn and return if missing.
  3. **Copy `link`, `door.global_position` and `_current_room.interior` before the first await.** The `Door` is not touched after it (`gotchas/a-freed-object-in-a-deferred-call-fails-its-typed-argument`).
  4. `_is_transitioning = true`, Ivo DISABLED, `await _fade.to_black()`.
  5. `await _land_in(room, func(): _player.arrive_at(Door.find(...)))`.
  6. If the trip goes from an on-map room into an interior, `_screens.set_map_anchor(door_point)`.
  7. `await _fade.to_clear()`, Ivo INHERIT, `_is_transitioning = false`.
- After that, the target Room's `body_entered` finds it already current, as after a hazard respawn. Re-adding a disabled body after `teleport` is the path `_arrive` already proves.
- `_enter_room` calls `_screens.clear_map_anchor()` for every non-interior room.
- `Room.id() -> StringName` (`scene_file_path.get_file().get_basename()`) and `@export var interior: bool = false` (doc: off the map, no weather; design 04 §4).

**Map and weather**
- `MapRevealer.on_room_changed`: an interior sets `_grid = null` and records nothing.
- `MapScreen`: `anchor: Vector2` and `anchored: bool`, set through `Screens.set_map_anchor` / `clear_map_anchor`. The map opens at the anchor (the building's door) instead of Ivo while he is indoors. After a death rebuild into an interior bench there is no anchor, and today's clamp applies.
- `RegionWeather.on_room_changed(room)`, wired in `game.tscn` like `MapRevealer`, hides its particles in an interior. It fires behind the black.

**Interiors (authoring rules for `systems/rooms`)**
- Place each interior below its region's rooms, outside every `RegionMemory` source's reach. It then sits at the region baseline: same season, memory and death marks (04 §4).
- An interior's bounds never touch another room's, so no walk-in transition can start or end in one.
- Its bounds are at least 640x360. The camera centres a smaller room and would show empty space, so the contents fill every pixel inside the bounds.
- A pair joins two different rooms of one region.

**Death and benches**: nothing new. A bench indoors saves the interior's `SceneKey` and is arrived at through `_arrive`. A death indoors marks the region at the interior's point and counts against the six-mark budget. Doors hold no state, so no save field and no `migrate()` change.

**Legend**: `E` → `door.tscn`, anchor bottom centre, `required_params = ["link", "to_room"]`. Regenerate the guide. No `FORMAT_VERSION` bump (the parser and `RoomMap` are unchanged).

**Test bed** (trials are debug-only and WORLD-05 builds the real rooms): a new `trials_solstice/door_trial` room after `the_catch`, with an F10 `trial_spawn`, and `door_trial_inside` (interior) 2048 px below it.
- Pair `trial_front`: open both ways.
- Pair `trial_hatch`: open from outside, sealed inside with `requires = all_guardians_restored.tres`.
- Add both rooms to `tools/smoke/scenes.txt`.

## Files

- **Create**:
  - `resources/save_facts/save_fact.gd`, `owns_memorina.tres`, `all_guardians_restored.tres`
  - `scenes/world/interactables/door/door.gd`, `door.tscn`, `door_links.gd`
  - `scenes/characters/components/door_component.gd`
  - `tools/art/prompts/door.md` (32x64, 2 frames; placeholder via `make_placeholders.gd`)
  - the two trial rooms (`.tscn`, `_contents.tscn`, `.room`)
  - `tools/playtest/scripts/door_*.json`
- **Change**:
  - `scenes/world/game.gd`, `scenes/world/game.tscn` (weather wiring), `scenes/world/rooms/room.gd`
  - `scenes/characters/ivo/player.gd`, `player_input.gd`, `ivo.tscn`
  - `scenes/ui/map/map_revealer.gd`, `map_screen.gd`, `scenes/ui/screens/screens.gd`
  - `region_weather.gd`
  - `resources/ui/notebook/notebook_entry.gd`, `notebook_catalog.gd`
  - `room_legend.tres`, `docs/maps/README.md` (regenerated)
  - `scenes/world/rooms/trials_solstice.tscn`, `tools/smoke/scenes.txt`
  - `CREDITS.md` (placeholder)
  - `systems/rooms` (a doors-and-interiors section), `systems/map`, `systems/input`, `systems/notebook`, `systems/life-benches-death`
  - `glossary.md`: "porta (de construção)" → `Door`, "interior" → `Room.interior`, and a note that the puzzle "porta" stays `Mechanism`
  - `CLAUDE.md`, Rooms row: "a door pair joins two rooms of one region by `link`"

## Tests

- `tests/resources/save_facts/save_fact_test.gd` (pure):
  - each kind true and false;
  - `GUARDIAN_MET` true when only restored;
  - `ALL_GUARDIANS_RESTORED` false with one missing and true with all;
  - `index` ignored by `ALL_GUARDIANS_RESTORED`.
- `tests/scenes/world/interactables/door/door_links_test.gd` (pure; records are room, region, link, to_room, source). It reports:
  - a link used once;
  - a link used three times;
  - a `to_room` that is not the partner's room;
  - both doors in one room;
  - a pair across two regions.
  A well-formed pair reports nothing.
- `room_files_test`:
  - `test_every_door_has_its_partner` feeds every `.room`'s doors (region = the folder above `contents/`) to `DoorLinks`;
  - each `to_room` must exist as `<region>/<to_room>.tscn`;
  - a door without `link` or `to_room` is refused.
- `door_test`: `is_open_for` with no fact, a held fact and a missing one; `find` scoped to a room.
- `player_input_test`:
  - `look_up_pressed` once per stick tilt (two motions past the deadzone);
  - `resync(..., up_held = true)` makes no edge;
  - existing two-argument calls still pass.
- `player_door_test` (a real Ivo on a floor, like `screens_map_test`):
  - an open door emits `door_entered` once;
  - refused in the air, with the Memorina drawn, while climbing, and seated (he stands instead);
  - a sealed door emits `knocked` and no `door_entered`;
  - `arrive_at` lands on the door, applies `arrive_facing` (0 keeps), and a buffered jump does not fire.
- `map_revealer_test`: an interior writes no `map_seen` bytes. `map_screen_test`: an anchor centres the open, and clearing it returns to Ivo.
- Playtest (`godot-playtester`):
  - in and out through `trial_front`, and the camera bounds inside;
  - Up held through the fade does not bounce him back;
  - the sealed hatch knocks;
  - the map opened inside centres on the facade;
  - no weather indoors.

## Consequences

- Room ids (file basenames) become load-bearing strings in `.room` files. A rename from the FileSystem dock does not rewrite them, but `room_files_test` names the broken pair.
- `SaveFact.Kind` is append-only and shared with the notebook.
- `ALL_GUARDIANS_RESTORED` reads every `Enums.Guardian`. Today that is two guardians; GRD-04 makes it four. If the mentor ever joins that enum, this kind must exclude him.
- The village west fence and the river trail (04 §2, "ter a Memorina") are walked through, not doors: they belong to WORLD-05 as a barrier that composes `owns_memorina.tres`. GRD-05's arena barriers must not be named `Door`.
- Ivo has no "enter" clip. He holds his pose under the fade, as on a walk-in. An over-the-shoulder clip and hatch art (overhead, not a wall leaf) are WORLD-11 / WORLD-13 dressing.
- Not refusing a press while a direction is held follows design 04 §4 ("Ivo para diante dela e aperta para cima") as the result of the press, not a precondition. The playtest confirms it.
