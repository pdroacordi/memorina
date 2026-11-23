---
id: architecture/drop-through-ledges
type: architecture
title: Drop through a ledge - Down + Jump, read from the room map, passed by a teleport into the ledge, one rule shared with the reach audit
status: active
tags: [rooms, one-way, ledge, input, jump, reach-audit, physics, world-19]
related: [bugs/the-tavern-upper-floor-has-no-way-down, bugs/a-jump-buffered-in-the-air-with-down-held-drops-through-a-ledge-on-landing, gotchas/a-body-resting-on-a-one-way-cannot-be-pushed-down-into-it, gotchas/tilemaplayer-body-rid-names-a-physics-quadrant-not-a-cell, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step, gotchas/scripted-presses-timed-in-real-ms-collapse-at-a-low-frame-rate, architecture/room-reachability-audit, architecture/character-controller-input-split, systems/rooms, systems/input]
created: 2026-11-22
updated: 2026-11-23
source_files:
  - scenes/characters/components/ledge_drop_component.gd
  - scenes/world/rooms/maps/ledge_drop.gd
  - resources/world/maps/room_legend_entry.gd
  - resources/world/maps/room_map.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/components/jump_component.gd
  - scenes/world/rooms/maps/reach/reach_grid.gd
  - scenes/world/rooms/maps/reach/reach_lattice.gd
  - scenes/characters/character.gd
---

## Summary

BUILT (2026-11-22, WORLD-19; user: "Yes, Down + Jump (Recommended)", 2026-11-22; for which ledges drop: "Only `=` ledges (Recommended)", 2026-11-22). A jump press with Down held, on the floor, on ledge cells whose legend entry is `droppable`, drops Ivo through the ledge. A `LedgeDropComponent` reads the floor's `RoomMapNode` from the last slide collision and asks a pure `LedgeDrop` rule. It then teleports the feet `DROP_DEPTH` px into the ledge, and gravity does the rest. No physics layer, mask, TileSet or importer change is needed. The reach audit uses the same rule, so `=` gets a drop edge.

## Context

- The legend promises "drop through it" for `=` (`docs/maps/README.md`). Nothing implements it (`bugs/the-tavern-upper-floor-has-no-way-down`).
- A body resting on a one-way cannot be pushed down into it by velocity, but one already inside it deeper than the margin passes both ways (`gotchas/a-body-resting-on-a-one-way-cannot-be-pushed-down-into-it`). `HelixRiderComponent._step_to` already relies on this with `Character.teleport_body`.
- Every `=`, `-` and `^` cell is the same `GroundCollision` ONE_WAY alternative on physics layer 1 "World". That bit is masked by Ivo (27), creatures, guardians, spawns (512 is their world layer), the camera ray and `SafeGroundTracker`.
- **Resolved (user, 2026-11-22): "Only `=` ledges (Recommended)".** `=` is droppable; `-` and `^` are not. The tavern keeps its stairwell. The text below is the question as it was put.
- **Open conflict (as surfaced).** `village_tavern.room` rows 13 and 17 are `-` wood planks ("Indoors: wood planks"), not `=`. The legend gives `-` no "drop through it". So "only `=`" does not touch the tavern, which already has its stairwell (cols 31-32). The plan makes droppability per-legend-entry data, so the answer is one `.tres` line. Recommendation: `=` true now. `-` true only if the user confirms. The vault catch plank under the grate (`systems/rooms`) and the helix galleries are `-`. The reach audit run decides whether any of them needs a non-droppable twin symbol.

## Options considered

**Knowing he stands on a droppable surface**
1. *Shape-cast or ray under the feet.* This repeats what the slide collision already knows, and it still needs the cell's legend entry. Rejected.
2. *A new TileSet custom data layer or a third alternative (`DROPPABLE`).* The cell would have to carry the flag into `_solid_layer`, so the parser and `RoomMap.platform` change, and `FORMAT_VERSION` goes 11 to 12. The flag would also be duplicated in TileSet and map. Rejected.
3. **Chosen: the room map.** `RoomMap` keeps `rows` and a reference to `legend` (`ReachGrid.add_room` already reads `map.legend.entry(map.rows[y][x])` for ROOF). So `RoomMap.is_droppable(cell)` is `is_platform(cell)` and the entry's new `droppable`. The floor's `RoomMapNode` is found the way `StepSurfaceProbe.surface_of` does it (the collider is a `TileMapLayer` under a `RoomMapNode`; cells from the contact point via `RoomMapNode.cell_at`, never `get_coords_for_body_rid`). Adding an exported field to the legend is not a parser change (`systems/rooms`: "Adding the legend entry needed no FORMAT_VERSION bump"). Verify on implementation that imported `.room` resources reference `room_legend.tres` rather than embed a copy. If they embed it, bump `FORMAT_VERSION` and reimport.

**Passing through**
1. *Clear a dedicated mask bit for droppable one-ways.* This needs a second TileSet physics layer on a new collision bit, and every body that stands on `=` must add that bit to its mask: creatures, guardians, spawns, rain, the shell, the camera ray, `SafeGroundTracker`, `_hold_the_lip`. Re-enabling it needs a timer or overlap test so he never re-lands on the same ledge. A missed mask is a creature falling through the floor. Rejected: wide, and fails silently.
2. *Disable the ledge cells or the layer.* That stops collision for every body and every ledge in the room. Rejected.
3. *`add_collision_exception` or a server exception with the quadrant body.* A TileMapLayer quadrant merges solid and ledge cells (`gotchas/tilemaplayer-body-rid-names-a-physics-quadrant-not-a-cell`), so the exception would also drop him through earth. Rejected.
4. **Chosen: teleport into the ledge.** `Character.teleport(global_position + Vector2(0, DROP_DEPTH))`. Inside the shape, the motion test skips it downward, and once he is below it the one-way only lets him rise through. There is nothing to re-enable and no timer, and no other body is affected. The cost is a single-frame 6 px (3 art px) shift, the same trick the helix rider uses.

## Decision

**Data.** `RoomLegendEntry.droppable: bool` (PLATFORM only; the validator refuses it elsewhere). `room_legend.tres`: `=` true; `-` per the user's answer; `^` never (a roof's underside is the facade the prop draws). Non-tile one-ways are never droppable: `IceCollider` (water under it), `Floater` (water), root spans (a song's floor over a gap) and `WorldEdges`. They are not a `RoomMapNode` Solid layer, so the component ignores them without a check.

**Pure rule, `LedgeDrop` (`scenes/world/rooms/maps/ledge_drop.gd`, RefCounted).** `enum Cell { OPEN, DROPPABLE, STOPS }`. `static func allows(footing: Array[Cell], below: Array[Array]) -> bool` returns true when:
- every footing column is OPEN or DROPPABLE, and at least one is DROPPABLE (a heel over earth, a plank or the room's edge refuses, so the teleport never puts him into solid);
- `clearance_rows(body_height)` = ceil(54 / 32) = 2 rows under the ledge are OPEN in every footing column (he never lands with his body still inside the ledge).

`RoomMap.drop_cell(cell)` and `ReachGrid.drop_cell(cell)` each classify a cell into `Cell`. Off-map is STOPS. Water and secrets are OPEN, a one-way is STOPS. Only the classification lives twice. A test runs one fixture through both classifiers.

**Component, `LedgeDropComponent` (`scenes/characters/components/`, Node, child of `Ivo`).**
- `const DROP_DEPTH := 6.0`: px the feet go into the ledge. It must exceed the 5 px measured minimum and the body's `safe_margin`.
- `signal dropped(at: Vector2)`.
- `func try_drop() -> bool`. It requires `is_on_floor()`. It takes the floor-angle slide collisions of the last `move_and_slide` and the `RoomMapNode` of the first one. Footing columns run from `body_rect()` left+0.5 to right-0.5, on the row under the feet. On `LedgeDrop.allows`, it calls `_body.teleport(...)`, sets `velocity.y = drop_speed` (as built: an export, 90 px/s, see As built), emits `dropped` and returns true. It never reads `Input` or `SaveSystem`. It has no `enabled` flag because no `PlayerSkill` gates it.

**Player (`_try_jump`, after the existing gates and the climb branch, before `try_ground_jump`).**
```
if on_floor and _input.look_direction > DROP_AXIS and _can_drop() and _ledge_drop.try_drop():
	_jump.clear_buffer()
	_jump.spend_coyote()
	return
```
- `DROP_AXIS` 0.5 mirrors the climb's `< -0.5`. Down is the continuous property sampled on read, and jump is the discrete buffered press. No new action, signal or `PlayerInput` change.
- `_can_drop()`: not in knockback, not riding, not sitting, no recall armed or pending (that press is the recall's jump).
- `JumpComponent.spend_coyote()` zeroes `_coyote_timer`, so a second press in the coyote window is not a ground jump back up through the ledge. A double jump still may, by choice.
- Player re-emits `dropped` as `dropped_through(at)`, per the composition rule, for a later sound.

**Interplay (all from existing gates, nothing new).**
- *Order.* Down then Jump drops. Jump then Down is a jump (the buffer fires on the floor first). Both in one frame drop.
- *Jump buffer.* A jump buffered in the air with Down held is not a drop on landing: `JumpComponent.buffer_jump()` records whether he stood on the floor at the press (`buffered_on_floor()`), and the drop branch requires it as well as `on_floor` when the buffer fires. Only an on-floor press drops. As first built it read only `on_floor` at fire time, so a press up to `jump_buffer_max` (0.12 s) before landing dropped (`bugs/a-jump-buffered-in-the-air-with-down-held-drops-through-a-ledge-on-landing`, fixed 2026-11-23).
- *Benches.* The Down edge sits him when a seat is in reach, and Jump then only stands him (`_unless_seated`). A new `room_files_test` rule says no BENCH or seat entity stands on a droppable cell.
- *Helix stair.* Down at the head boards first (`_try_board` runs before `_try_jump`, and boarding drops buffers). While riding, buffers are dropped.
- *Climbing.* The climb branch returns first. *Memorina drawn:* `_try_jump` returns, and the press was a note. *Cutscene, talk or map:* `PlayerInput.blocked` emits nothing and reads axes as 0.
- *Pogo.* It is Down + attack in the air, so there is no overlap. *Jump release:* `cut_jump` only shortens rising velocity, so it is harmless.

**Reach audit.**
- `ReachGrid.DROP := 1024` is set with ONE_WAY where the entry is `droppable`.
- `ReachLattice` adds, from a standing cell over DROP whose `LedgeDrop.allows` holds, the walk-off fall started one row lower (feet in the ledge, vertical speed 0, sideways -1/0/+1). `test_a_one_way_is_jumped_up_through_and_never_dropped_through` splits in two: `=` drops, `-` (if not droppable) never does.
- The kit check then sees drops as directed edges. Every new reach (a shortcut past a GATE, a cleared KIT_TRAP, a stale allowlist line) is reviewed by hand, never allowlisted blind.

## Consequences

- A new droppable ledge kind is one legend field. Nothing in physics changes (Open/Closed). Collision stays on layer 1 for every other body.
- Ivo's feet pop 6 px in the drop frame. If the playtest reads it as a snap, a one-frame crouch clip hides it. That is the resolver's business and has no physics effect.
- The rule needs the floor to be a room's Solid layer. A drop from a mover or a song floor needs its own decision.
- Fails if Godot stops skipping overlapped one-ways in the motion test. The component's physics test pins this, with a 0.5 px control that must not pass.

## Build order

1. `RoomLegendEntry.droppable` + validator; `room_legend.tres`; regenerate `docs/maps/README.md` (the `=` line becomes true; `-` per the user).
2. `LedgeDrop` + `RoomMap.drop_cell`/`is_droppable` + `ledge_drop_test` (mid-span yes; `-`/`^` no; heel on earth no; heel over air yes; solid or one-way within 2 rows below no; off-map no).
3. `LedgeDropComponent` + `ledge_drop_component_test`. Real `move_and_slide` on a built `RoomMapNode` (unit tests cannot catch the one-way stall). Cases: it drops and falls past the ledge bottom, its y never rises, and it lands on the floor below; `-` stays; the edge beside a wall is refused; a 0.5 px depth control stalls; no `body_entered` from the old place (teleport).
4. Player wiring + `spend_coyote` + `player_ledge_drop_test` (presses via `Input.parse_input_event`). Cases: Down then Jump on `=` drops with no `jumped`, the buffer empty and coyote 0; the same on `-` jumps (if not droppable); Jump alone jumps; Jump then Down jumps; seated stands; drawn does nothing; blocked does nothing; recall armed jumps; a second press in the coyote window after a drop is not a ground jump.
5. `ReachGrid.DROP`, the lattice drop move, `reach_lattice_test` split, `room_files_test` bench rule, an audit run and its review.
6. Docs: `systems/rooms` (one-ways and droppable), `systems/input` (the binding and the user's words with the date), a dated Revision on `architecture/room-reachability-audit` ("no drop-through until WORLD-19" retired), a resolution line on the tavern bug, and the roadmap row.

## As built (2026-11-22)

- As planned: `RoomLegendEntry.droppable` (`=` only), `LedgeDrop` with `allows`, `clearance_rows` and `allows_at(classify, first, last, row, body_height)` (both classifiers pass their `drop_cell` to it), `RoomMap.is_droppable`/`drop_cell`, `LedgeDropComponent` (node `LedgeDrop` in `ivo.tscn`), `JumpComponent.spend_coyote`, `Player.DROP_AXIS`, `_can_drop`, `dropped_through`, `ReachGrid.DROP` (1024), `ReachLattice.can_drop`. The imported maps reference `room_legend.tres` (checked in `.godot/imported`), so `FORMAT_VERSION` stays 11.
- **The lattice fall starts one quantum (16 px) into the ledge, not one row.** Feet 16 px in are 10 px from the real 6 px; a whole row (32 px) would be 26 px off.
- **`ReachLattice._OUTSIDE` moved from 1024 to `1 << 30`.** It was a raw-cell bit beside ReachGrid's flags, and `DROP` took 1024, so every `=` cell read as outside the rooms until it moved.
- **`ReachGrid.drop_cell(cell, room)` takes the ledge's room**: a cell outside it is STOPS, as off-map is for `RoomMap`, so the audit never drops where the game refuses. A kit's GATE wall below a ledge is STOPS in the grid and OPEN in the room map (the map does not hold gates), so the audit can miss a drop the game allows, never the reverse.
- `Character.shape_rect(body)` is the static form of `body_rect()`, so the component works on any `CharacterBody2D` (the component test uses a bare one).
- `LedgeDropComponent.depth` (default `DROP_DEPTH`) exists so the 0.5 px control can run.
- **The drop starts at `drop_speed` (export, 90 px/s), not 0** (2026-11-23, playtest). From rest the fall moved 0.14..0.54 px per frame for about 4 frames and read as a hang; 90 px/s moves 1.5 px in the drop frame and reads as falling, well under a launch. `ledge_drop_component_test` holds the second frame to at least 1 px.
- **The press must be made on the floor** (2026-11-23, review): `JumpComponent.buffered_on_floor()` (see Interplay, Jump buffer).
- Tests: `ledge_drop_test` (rule, classifiers, legend), `ledge_drop_component_test` (real `move_and_slide`: drop and land without rising, plank, edge beside a plank, heel over air, air, the 0.5 px stall), `player_ledge_drop_test` (Down then Jump drops with no `jumped`, an empty buffer and no coyote; plank jumps; Jump alone jumps and lands back; Jump then Down jumps; blocked does nothing; a second press after a drop is no ground jump), `reach_lattice_test` (`=` drops, `-` never, `=` one row over ground never), `reach_grid_test` (the DROP flag), `room_files_test` (no bench on a droppable cell). Not written as separate cases: seated, drawn, and recall armed. Each returns before the drop branch, through `_unless_seated`, the drawn check at the top of `_try_jump` and `_can_drop`. No `body_entered` case: `teleport_body` is the helix rider's call and is covered there.
- The playtest timeline is `tools/playtest/scripts/world19_ledge_drop.json`, on orchard_terraces' row-17 `=` span (below), since the tavern's span is `-`.

## Playtest

Built as `tools/playtest/scripts/world19_ledge_drop.json` (`-` is not droppable): orchard_terraces row 17, cols 39-42 (x -4512..-4384, top y -1376). Ivo starts at [-4448, -1378]; Down held, Jump 200 ms later, expect y about -1248 (row 21). Controls: Down + Jump on the earth block top (cols 35-38, row 18; [-4592, -1346]) jumps; Jump alone on the span jumps and lands back on it. The plan as first written follows.

`tools/playtest/scripts/world19_tavern_drop.json`. It needs `-` droppable. Otherwise use a `=` span such as `woods_deep` or `orchard_terraces`, at the same steps.
- `player_position` [2349, 12416] (the tavern span, row 13, cols 18-30). Settle 0.5 s and take a screenshot.
- Hold `look_down`. Press `jump` 200 ms later (several frames apart, `gotchas/scripted-presses-timed-in-real-ms-collapse-at-a-low-frame-rate`) for 100 ms. Release both, wait 1.0 s and take a screenshot. Expect y about 12672 (the lower floor).
- Controls:
  - Down + Jump on the earth part of row 13 (x about 1800) jumps.
  - Jump alone on the span jumps and lands back on it.
  - Down + Jump on the row-17 ledge (12544) drops to 12672.
- Report what screenshots cannot show: press-to-fall latency, the 6 px pop, and the camera's follow on the 256 px fall.

i18n: no user-facing text. A controls hint, if wanted, is a separate item with a `tr()` key.
