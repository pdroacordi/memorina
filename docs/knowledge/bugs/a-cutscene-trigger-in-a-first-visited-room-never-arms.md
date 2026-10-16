---
id: bugs/a-cutscene-trigger-in-a-first-visited-room-never-arms
type: bug
title: A CutsceneTrigger in a room whose contents are instantiated on this visit never arms, because Game emits room_changed before Room adds its contents (deferred)
status: fixed
severity: medium
tags: [cutscene, trigger, room-changed, residency, deferred, story-15, story-16, latent]
related: [systems/cutscenes, architecture/cutscenes-are-data-played-between-two-rest-states, gotchas/first-process-frame-can-precede-the-first-deferred-flush, gotchas/queue-free-deferred-add-still-enters-the-tree, bugs/a-debug-boot-reveals-map-cells-ivo-never-saw]
created: 2026-10-16
updated: 2026-10-16
source_files:
  - scenes/world/cutscene/cutscene_director.gd
  - scenes/world/cutscene/cutscene_trigger.gd
  - scenes/world/game.gd
  - scenes/world/rooms/room.gd
  - scenes/world/rooms/room_residency.gd
---

## Summary

FIXED 2026-10-16, latent (STORY-15 review; no trigger is placed yet). `CutsceneDirector.on_room_changed` finds triggers with
`get_nodes_in_group(CutsceneTrigger.GROUP)`. A trigger joins that group in `_enter_tree`. On a room's first
activation `Room.activate()` instantiates the contents and adds them with `call_deferred`, and `Game` emits
`room_changed` in the same frame. The trigger is not in the tree yet, so it is not armed, and nothing arms it later.

## Symptom

A trigger placed in the first room of a world build with no bench never plays. This is the new game's start room,
and STORY-16's opening is planned exactly there (`systems/cutscenes` "Limits"). The same happens after any room
change into contents instantiated on that call (an evicted room, a debug teleport). A trigger in a room entered by
walking from a neighbour works, because `RoomResidency.settle` activated that room one visit earlier.

## Root cause

- `scenes/world/rooms/room.gd:56-58`: `_contents_node = contents_scene.instantiate()` then
  `_add_contents.call_deferred(_contents_node)`.
- `scenes/world/game.gd:112-113` (`_on_room_entered`, the no-bench start): `_enter_room(room)` then
  `room_changed.emit(room)` in the same call. `_on_player_fell_into_hazard` (lines 210-211) does the same.
- `scenes/world/cutscene/cutscene_director.gd:125-134`: `on_room_changed` resets `_armed` and scans the group once.
  `_in_room` would accept the trigger (`room.contents()` returns the not-yet-added node), but the group scan
  never returns it.

`_land_in` (bench arrival, doors) awaits `contents.ready` before it emits, so those paths arm correctly.

## Fix

Fixed 2026-10-16 at the source: `CutsceneDirector.on_room_changed` reads the triggers from `room.contents()` (walking
its children, `_triggers_under`), not from the tree's group, so contents made on this visit and not yet added are seen.
`_tick_trigger` does not count the delay or play until the armed trigger `is_inside_tree()`, so the scene starts once
its contents are in the world and its ids resolve. `Game` is unchanged.

`tests/scenes/world/cutscene/cutscene_trigger_test.gd`: a trigger in a first-visited room (contents added deferred,
`room_changed` in the same frame: the new game's start and a respawn into an evicted room), after a door's arrival
(contents ready first), in a resident room, its delay and Ivo's gates, a seen scene not replayed, leaving the room
disarms it, and a room change drops a playing scene unrecorded.

## Prevention

- A test: a trigger in a contents scene added only through `Room.activate()`, with `room_changed` emitted in
  the same frame, must play. No test covers `CutsceneTrigger` or `on_room_changed` today. `systems/cutscenes` says
  the trigger "is built and tested through the director's arming only", but no test under `tests/` references either.
- Any `room_changed` listener that looks up nodes inside the new room's contents must handle contents that are
  not yet in the tree.
