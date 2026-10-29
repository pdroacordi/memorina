---
id: bugs/a-teacher-whose-room-idles-leaves-ivos-echo-open
type: bug
title: A teacher closes Ivo's echo only from its own _physics_process, so a trip that idles its room while Ivo is in reach leaves the echo open and every song unplayable elsewhere (latent)
status: resolved
severity: low
tags: [core-04, teachers, echo, room-residency, doors, latent, placement]
related: [systems/teaching-creatures, systems/rooms, systems/world, architecture/teaching-creatures]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/world/creatures/teaching_creature.gd
  - scenes/world/game.gd
  - scenes/world/rooms/room.gd
  - scenes/world/rooms/room_residency.gd
  - tests/scenes/world/rooms/maps/room_files_test.gd
---

## Summary

The echo is closed only by `TeachingCreature._sync_echo()` when it sees Ivo out of reach
(`teaching_creature.gd:86-91`). Suppose Ivo leaves reach by a jump to a room that does not touch
the teacher's room. The teacher's contents go PROCESS_MODE_DISABLED before he is placed, so
it never sees him leave. `MemorinaComponent.echo_phrase` stays set, and Ivo can play only
that teacher's three notes wherever he is.

## Symptom

Latent. No current placement triggers it, and no playtest has shown it. The snail (7,8) is exactly
4 cells from the `lake_fishing_village` stairwell door (3,8), inside its reach (edges count).
That door leads to `lake_well`, which shares an edge with the village, so the village stays
active and the snail closes the echo. A teacher within reach of a door to an interior or another
non-touching room would trigger it.

## Root cause

`Game._land_in()` (`game.gd:238-243`) calls `_enter_room()` → `RoomResidency.settle()`
(`room_residency.gd:32-55`), and that deactivates every room that does not touch the target
(`room.gd:64-67`). Only then does `place.call()` move Ivo. The teacher has no
`NOTIFICATION_DISABLED` / `_exit_tree` handler, and Player never closes an echo by itself.

## Fix

Resolved 2026-10-29 by the first option below (see Resolution). The options were:
- Close the echo when the teacher's processing stops: in `_notification`, on
  `NOTIFICATION_DISABLED` or `NOTIFICATION_EXIT_TREE`, call `_ivo.close_echo()` while it owns
  the echo.
- Or add a `room_files_test` rule: no door (`E`) within a teacher's reach unless it leads to a room
  that touches the teacher's room.

## Prevention

A `teaching_creature_test` case: open the echo, set the teacher's parent to
PROCESS_MODE_DISABLED, and assert `is_echo_open()` is false.

## Resolution (2026-10-29)

`TeachingCreature._notification` handles `NOTIFICATION_DISABLED` and `NOTIFICATION_EXIT_TREE`: `_release()` closes the flow's phrase and balloon (`set_near(false)`) and closes Ivo's echo if its phrase is this teacher's. When the room wakes, the next tick reopens it if Ivo is in reach. Tests: `teaching_creature_test.test_an_idled_room_closes_the_echo` (the teacher's parent set to PROCESS_MODE_DISABLED, then back) and `test_a_freed_teacher_closes_the_echo`.
