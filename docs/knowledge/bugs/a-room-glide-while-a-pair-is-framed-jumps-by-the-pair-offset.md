---
id: bugs/a-room-glide-while-a-pair-is-framed-jumps-by-the-pair-offset
type: bug
title: GameCamera.set_bounds(glide) measures from the subject alone, so a glide during pair framing starts with a jump
status: resolved
severity: low
tags: [camera, glide, pair, seam, world-05]
related: [bugs/walking-out-of-a-guardian-room-no-longer-abandons-its-call, systems/rooms, systems/guardians]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - scenes/world/camera.gd
---

## Summary

`set_bounds(bounds, true)` computes the glide offset against `clamp(subject)`, but `_physics_process` frames
`clamp(lerp(subject, pair midpoint, _pair_blend))`. With a pair framed, the first glide frame jumps by the pair
shift instead of starting where the frame stood.

## Symptom

Measured with a probe suite (2026-10-09 review): subject at x 5000, pair at 5440, blend settled, then a glided
`set_bounds` in a wide room. The frame moved 219.5 px in one physics step. The test expected less than 10 px.
Reachable when Ivo walks out of an arena while a call is staged
(`bugs/walking-out-of-a-guardian-room-no-longer-abandons-its-call`).

## Root cause

`camera.gd:110-112` rebuilds the framed position from `_subject.global_position` only. `camera.gd:92-97` also applies
the pair midpoint and the vertical offset.

## Fix

Not fixed. Extract one `_framed_position()` (subject, pair blend, bounds) and use it in both `_physics_process` and
`set_bounds`.

## Prevention

Two copies of the framing maths drift. Any new term in `_physics_process` must reach the glide's reference.

## Resolution (2026-10-09)

`GameCamera._framed_position()` is used by both `_physics_process` and `set_bounds`. `camera_test.test_a_glide_while_a_pair_is_framed_starts_where_the_frame_stood` pins it.
