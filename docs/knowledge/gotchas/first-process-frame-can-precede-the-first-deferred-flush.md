---
id: gotchas/first-process-frame-can-precede-the-first-deferred-flush
type: gotcha
title: At boot, the first process_frame can fire before a call_deferred queued in the main scene's _ready has run
status: active
tags: [call-deferred, process-frame, await, boot, message-queue, scene-tree]
related: [architecture/the-life-loop-rewinds-by-reloading, gotchas/queue-free-deferred-add-still-enters-the-tree]
created: 2026-10-01
updated: 2026-10-01
source_files:
  - scenes/world/game.gd
  - scenes/world/rooms/room.gd
---

## Summary

The pattern "call_deferred something, then `await get_tree().process_frame` once, and it
is done" holds inside a running game. It does NOT hold for the main scene's own `_ready`
on the first frame. `SceneTree.process()` emits `process_frame` BEFORE its own deferred
flush. The only flush that comes earlier is the one inside a physics step, and the first
`Main::iteration` may run zero physics steps.

## Details

Measured on 4.7.2 with a minimal project: the main scene's `_ready` did `call_deferred`
and then awaited `process_frame`. Headless, the deferred call had not run in 4 runs out
of 5, and each of those runs reported `physics_frames=0`. Windowed, it had run in 3 out
of 3, each with one physics step first.

In the real `game.tscn` (`Game._arrive()` booted with `--continue` on a save naming
`downtown_bench`), the seat was found in 7 out of 7 headless runs. The scene's load time
makes the first iteration take a physics step. So `_arrive`'s one-frame wait works today
only because loading is slow, and nothing guarantees it. A control run with a bench id
that does not exist did print the fallback warning, so the save was being read.

Inside a reload this is safe. `Game._reload_world` runs from a deferred call, so the fresh
world's `_ready` runs inside a flush, and a `call_deferred` queued during a flush runs in
that same flush.

## Gotchas / pitfalls

- If `Game._arrive()` misses the seat at boot, it has already `_enter_room`ed the bench's
  room. Ivo then stands at the authored start, in another room, while `_current_room`,
  the memory field and the camera bounds belong to the bench's room, until his
  re-enabled body triggers the start room's `room_entered`. The player sees an extra fade.
- Robust alternatives:
  - Await the thing itself. For example, `Room` could expose the contents' `ready`, or
    emit `contents_ready` when its deferred add lands.
  - Loop `await process_frame` until the node exists, with a frame cap.
