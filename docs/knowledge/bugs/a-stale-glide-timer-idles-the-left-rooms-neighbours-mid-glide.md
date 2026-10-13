---
id: bugs/a-stale-glide-timer-idles-the-left-rooms-neighbours-mid-glide
type: bug
title: A glide's residency timer from an earlier crossing of the same seam settles the room again in the middle of a later glide, idling the rooms that glide still frames
status: resolved
tags: [rooms, residency, glide, camera, backdrop, room-ring, world-28]
related: [bugs/a-ring-corner-diagonal-shows-a-rock-wall-in-the-mills-sky-on-a-jump, systems/rooms, systems/backdrops]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - scenes/world/camera.gd
  - scenes/world/game.gd
  - scenes/world/rooms/room_residency.gd
---

## Summary

RESOLVED 2026-10-13 (WORLD-28 re-review, found by reading; was low to medium). `Game._enter_room` starts one `SceneTreeTimer` per glide
and binds it to the target room. `_end_glide_residency(room)` checks only `room == _current_room`. Suppose Ivo crosses
A to B, back to A and to B again within `bounds_glide_time` (0.45 s). Then the first timer still matches, fires during
the third glide, and calls `settle(B)` with no `keep`. The rooms that touch A but not B go idle and hide their contents,
including their backdrop, while the frame is still gliding out of A's ring. That is the hole the `keep` was added to
close (terraces to chasm bridge: the sky over orchard_well).

## Symptom

Expected, not yet reproduced in a still. Ivo walks at 192 px/s and `RoomExit` swaps sideways once his 22 px body is out
of a room, so a crossing back and forth takes about 0.1-0.2 s. Turning on the spot at a seam does it. When the first
timer fires, the third glide still has part of its offset left, for example 9-18 % of up to 640 px (cubic ease-out).
Wherever that remaining frame covers a pixel that only a room touching A owns, that pixel shows the clear colour until
the glide ends.

## Root cause

`scenes/world/game.gd` `_enter_room` / `_end_glide_residency`: the timer carries the target room, not the glide's
identity. A later glide into the same room makes an older timer look current. A retargeted chain A to B to C has a
similar weakness: `keep` is only `touching(B)`, so A's other neighbours idle while the frame may still sit in A's ring.
In practice the cubic ease-out leaves under 1 % of the offset after crossing a 384 px room at terminal velocity, so the
chain is benign.

## Fix

Not fixed. Count glides (`_glide_serial += 1` in `_enter_room`, bind the serial, and settle only if it is still the
latest). Better still, settle when the camera's glide tween finishes (a `glide_finished` signal on `GameCamera`), so
the residency follows the frame and not a duplicated duration. While a glide is retargeted, carry the previous `keep`
into the new one.

## Prevention

A deferred action keyed by "the room is still current" is not idempotent across re-entries. Key it by the event that
scheduled it.

## Resolution (2026-10-13)

`GameCamera.glide_finished` fires when a glide's tween runs out, or when `snap()` cuts a running glide; a glide that
`set_bounds()` retargets emits only when the new one ends. `Game` keeps `_glide_keep`, the neighbours of every room a
running glide left (a retargeted glide adds to it), passes it to `RoomResidency.settle` and clears it and settles again
on `glide_finished`. There is no timer, so the duration lives only in the camera's tween. `camera_test`
`test_a_retargeted_glide_finishes_once_at_its_end` crosses A, B, A, B within one glide time and finds one
`glide_finished`, after the last glide's full duration; `test_snap_mid_glide_finishes_it` covers the cut.
