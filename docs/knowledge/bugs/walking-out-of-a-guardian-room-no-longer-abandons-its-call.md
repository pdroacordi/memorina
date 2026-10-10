---
id: bugs/walking-out-of-a-guardian-room-no-longer-abandons-its-call
type: bug
title: Walking out of a guardian's room no longer abandons its call, because a neighbour room is never disabled
status: resolved
severity: high
tags: [guardians, rooms, residency, call, camera, pair, world-05]
related: [systems/guardians, systems/rooms, bugs/a-neighbour-room-has-no-ground-until-ivo-enters-it, bugs/a-room-glide-while-a-pair-is-framed-jumps-by-the-pair-offset]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/world/rooms/room_residency.gd
  - scenes/world/game.gd
---

## Summary

`Guardian` stops a call only on `NOTIFICATION_DISABLED` or `NOTIFICATION_EXIT_TREE`. Since `RoomResidency` keeps
every room touching the current one running, a guardian's room stays enabled when Ivo walks out of it, so the call and
everything it staged keep running in the next room.

## Symptom

Found in review (not yet reproduced in a playtest). Arenas have no doors and Ivo can walk out mid-fight
(`systems/guardians`, GRD-05). In bloom_hollow, after the lucidity leap stages the call, Ivo walks across a seam into a
neighbour room:
- `GameCamera` keeps `frame_pair(guardian)`: the frame is pulled toward a guardian in another room and clamped by the
  new room's bounds;
- the `LessonCinematic` dim stays on, and `GuardianCallHud`/`MemorinaHud` keep their sheet;
- `GuardianFight` keeps ticking the answer window in `_after_move` and pushes `update_call_window` to Ivo;
- in PRESSURE the AI keeps acting on `_sight.player` and can follow him across the seam.

Before 2026-10-09, crossing the seam deactivated the old room and `_abandon_call()` ran.

## Root cause

`guardian.gd:177-180` ties the abandon to the room being disabled ("Leaving a room during a call must stop the
phrase..."). `RoomResidency.settle` (`room_residency.gd:23-40`) only disables rooms that do not touch the current room,
and an arena room always touches the room Ivo walks into.

## Fix

Not fixed. Options: drive the abandon from leaving the `Arena` (the guardian already has `_arena` and
`is_fighting_at`), checked each step in `_after_move` while a call is staged; or have `Game` tell the guardian's room it
is no longer current. Keep the disable/exit-tree path for bench wakes and evictions.

## Prevention

A behaviour tied to "my room is disabled" now means "Ivo is two rooms away", not "Ivo left my room". Grep for
`NOTIFICATION_DISABLED`, `is_visible_in_tree()` gates and `Room.deactivate` assumptions whenever residency changes.

## Resolution (2026-10-09)

`Guardian._player_in_arena()`: `_after_move` abandons the call once Ivo is outside the `Arena`, and the PRESSURE AI ticks only while he is inside it. The DISABLED/EXIT_TREE path still serves bench wakes and evictions. Not yet measured in a fight playtest.
