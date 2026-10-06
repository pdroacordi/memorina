---
id: bugs/a-debug-boot-reveals-map-cells-ivo-never-saw
type: bug
title: A debug boot onto a saved bench marks a screen of map cells around the authored start, clamped into the bench room, behind the black
status: fixed
severity: low
tags: [map, reveal, boot, arrival, bench, camera, physics, deferred]
related: [systems/map, architecture/map-reveal-seen-cells-per-room, gotchas/first-process-frame-can-precede-the-first-deferred-flush, bugs/a-teleported-ivo-enters-the-room-he-left, systems/life-benches-death]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - scenes/world/game.gd
  - scenes/ui/map/map_revealer.gd
  - scenes/world/camera.gd
---

## Summary

When `game.tscn` is the main scene and the save names a bench (debug builds boot "Straight to
game" on slot 1), one physics step runs between `_arrive()`'s `_enter_room` and the seat. In that
step `MapRevealer` marks the cells the camera frames at Ivo's authored start, clamped into the
bench room. The screen is black, so those cells were never shown.

## Symptom

Found in review of UI-04 (uncommitted, on 5a5f9c8). Traced from the code and the measured boot
order; not reproduced.

Example: a save on `downtown_bench`. The authored start (3277, -69) is in BloomHollow. The camera
clamps it to Downtown's right edge, so about a third of Downtown (one 640 px view) is marked seen
on every debug boot. The next bench commits it into the slot save.

## Root cause

- `Game._ready` → `_arrive()` → `_enter_room(room)` emits `room_changed` synchronously
  (game.gd:82), so `MapRevealer._grid` is set before the first frame (map_revealer.gd:29-33).
- `_arrive` then awaits the contents' `ready` (game.gd:115-116). `Room.activate` adds them with
  `call_deferred`. At boot the first flush can be the one inside the first physics step, which runs
  after the nodes' `_physics_process` (`gotchas/first-process-frame-can-precede-the-first-deferred-flush`:
  the real game takes that physics step).
- In that step `GameCamera._physics_process` follows the disabled Player at his authored start and
  clamps to the bench room's bounds (camera.gd:83-88). `MapRevealer` runs after it in tree order and
  marks `view_rect() ∩ bounds` (map_revealer.gd:19-26).
- The seat and `_camera.snap()` (game.gd:117-122) come only after that step.

A death rebuild and the title's Continue build the world inside a deferred flush, so the
contents land in the same flush and no physics step runs in between. Release builds boot the
title, so only debug boots are affected.

## Fix

Fixed 2026-10-06 (UI-04 round 2), at the cause. `Game._enter_room` no longer emits `room_changed`. `Game` emits it where the frame shows the room:
- on a walk-in, after `_enter_room`, behind the black;
- after a hazard respawn that changes the room;
- in `_arrive`, after the seat and `_camera.snap()`.

The revealer has no grid until then, so the physics step before the seat marks nothing.

Evidence: reproduced and then verified windowed on a debug boot (`game.tscn` as the main scene).
- Setup: `APPDATA` redirected to a scratch folder, with `save_debug_1.tres` seeded on `downtown_bench` (room `uid://d3yi3wnqg8gub`). A temporary print in `MapRevealer` on each write was removed afterwards.
- Before: physics frame 1 marked Downtown cols 20-29, rows 4-9 (view x -83.75, the authored start clamped to the room's right edge). Physics frame 2 marked cols 1-10 (the seat).
- After: the only mark is cols 1-10 at physics frame 2, the seat's view.

Options considered:
- `Game` keeps `MapRevealer` disabled while `_is_transitioning` (as it does with the Player), or
- `_arrive` emits `room_changed` only after the seat and `snap()`, or
- the revealer marks nothing while `Fade` is not clear (it reveals "what was on screen").

## Prevention

A test that boots `Game` with a benched save, steps physics once before the contents' flush, and
asserts that `SaveSystem.map_seen(bench_room)` holds only the cells around the seat.
