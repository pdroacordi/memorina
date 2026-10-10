---
id: bugs/a-teleport-across-the-world-glides-like-a-seam-walk
type: bug
title: A debug teleport is taken for a seam walk, so the camera glides across the world and the baseline eases
status: resolved
severity: low
tags: [camera, glide, rooms, debug, playtest, teleport, world-05]
related: [systems/rooms, systems/life-benches-death]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/game.gd
  - scenes/world/debug/debug_trials.gd
  - tools/playtest/playtest_runner.gd
---

## Summary

`Game._physics_process` treats any change of the room under Ivo's feet as a walk (`_enter_room(room, true)`). A
teleport that `Game` does not handle itself, such as `DebugTrials` F10 or the playtest runner's `player_position`, is
also detected there, so the frame glides for 0.45 s from the old place, possibly thousands of px away. The baseline
also eases from the old region.

## Symptom

Found in review. `DebugTrials` calls `camera.snap()` right after `teleport`, but `snap()` does not move the camera, and
on the next step `set_bounds(bounds, true)` starts a glide from the old position. A playtest timeline that places Ivo
starts with a world-wide pan, and its first 0.45 s of screenshots and memory samples are not of the target room.

## Root cause

`game.gd:61-70` cannot tell motion from a teleport.

## Fix

Not fixed. Glide only when the new room touches the old one (`RoomResidency.touching(_current_room, ...)` already
answers that); otherwise enter without a glide and snap.

## Prevention

Inferring intent ("walked") from a state change needs a guard for the other ways that state can change.

## Resolution (2026-10-09)

`Game._physics_process` glides only when `RoomResidency.touches(old, new)` and both are in one region; a teleport cuts and snaps.
