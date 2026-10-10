---
id: bugs/a-door-trip-evicts-the-room-ivo-left
type: bug
title: RoomResidency ranks the current room behind its neighbours, so a door trip evicts the room Ivo left and rebuilds it on return
status: resolved
severity: medium
tags: [rooms, residency, doors, interiors, eviction, world-05]
related: [systems/rooms, architecture/doors-and-interiors, bugs/a-neighbour-room-has-no-ground-until-ivo-enters-it]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/rooms/room_residency.gd
---

## Summary

`RoomResidency.settle` pushes the current room to the front of its recency list first and its neighbours after it,
so the room Ivo stands in ends up older than rooms he never entered. Going through a door into an interior, the room he
left is the first idle room evicted whenever it has two or more neighbours.

## Symptom

Measured with a probe suite (2026-10-09 review): rooms left, A, right in a row and an isolated interior;
`settle(A)` then `settle(interior)` leaves `A.contents()` null. A's neighbours stay idle with their state; A is
rebuilt fresh when Ivo comes back through the door. Killed enemies return and session state (pushed loads, frozen
water, lowered platforms) resets after a house visit. With the old `MAX_RESIDENT_ROOMS` (2), A stayed resident.

## Root cause

`room_residency.gd:25-30`: `touching()` returns `[current, neighbours...]` and the loop does
`_resident.push_front(room)` in that order, so the last neighbour is newest and `current` is behind all of them. The
idle loop at lines 31-40 then evicts from the back past `MAX_IDLE_ROOMS`.

## Fix

Not fixed. Push the neighbours first and the current room last (iterate `near` reversed, or push `current` after the
loop). Add a suite case: a room with two neighbours, then an isolated room; the first room keeps its contents.

## Prevention

`room_residency_test` covers only rows of rooms walked in one direction, where the order bug does not show. Test the
door case explicitly.

## Resolution (2026-10-09)

`RoomResidency.settle` pushes the current room to the front last. `room_residency_test.test_a_door_trip_keeps_the_room_ivo_left` (three rooms in a row, then an isolated room) pins it.
