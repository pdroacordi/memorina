---
id: bugs/a-glide-skips-the-drawn-frame-correction-and-snaps-when-it-ends
type: bug
title: During a room glide the camera skips CameraReach.drawn_frame, so the frame eases into the void corner of the new room's reach, then snaps by the whole correction when the glide weight reaches 0
status: resolved
severity: low
tags: [camera, glide, open-sky, reach, void, discontinuity]
related: [bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame, bugs/a-neighbours-open-sky-lifts-the-camera-reach-over-village-mills-void, bugs/a-room-glide-while-a-pair-is-framed-jumps-by-the-pair-offset]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/room_ring.gd
  - scenes/world/rooms/room_residency.gd
  - scenes/world/camera.gd
---

## Summary

`GameCamera._keep_subject_in_view` runs `drawn_frame` only when `_glide_weight <= 0.0` (camera.gd:477). A glide
frame is `yield(clamped + _glide_from * w)`, and as `w` goes to 0 it approaches the uncorrected target. While `w` is
small, the frame shows any void that target holds. On the step where the tween reaches exactly 0, the correction applies
in full, in one step.

## Symptom

Found in review of the uncommitted open-sky change (on 9f55197), by reading the code. Not played.

Ivo jumps from village_square into village_mill over the seam wall, his head above y 0. The swap glides once his body is
past x 1920. Mill's target frame is clamped to x >= 1920 and lifted over his head. With `CameraReach.of`, the box's top
is -80, and the frame lies over mill's uncovered west half, which nothing draws. The glide is 0.45 s, `TRANS_CUBIC`
`EASE_OUT`, so `w` < 0.03 after 0.3 s. For the rest of the glide the frame shows that void. Then it snaps down by the
lift that is left when the tween finishes. The snap is 0 if he has landed by then, and up to 80 px if he is still high
(a double jump).

The glide start is clean. `set_bounds` measures `_glide_from` with `_reach` reset to the plain bounds, so the target
there is the room clamp, which needs no correction.

## Root cause

camera.gd:476-479. Skipping the correction during a glide was meant to keep the glide from being pulled. But the glide
offset is added to an uncorrected target, so the correction is deferred, not avoided.

## Fix

Not fixed. Suggested: correct the target, not the glide frame. Run `drawn_frame` on `centre - _glide_from * _glide_weight`
and add the offset back. The glide then eases toward the drawn frame, and nothing changes when `w` reaches 0.

## Prevention

A camera_test case: a glide into a room whose yielded target holds an undrawn corner. Step until the glide ends and
assert that the view's move between the last two steps is a few px at most.

## Resolution (2026-10-11)

With the correction gone (`bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame`), nothing can snap when a glide ends. A straight glide could still cross void between two rings, so two changes keep every glide frame drawn:
- **Edge-sharing rooms only.** Glides now run only between rooms that share an edge (`RoomResidency.share_an_edge`). A crossing at a corner is cut like a region seam: there, the straight path and both corner paths left both rings (lake rooms at x 9600/10880).
- **Corner paths.** `GameCamera.set_bounds(bounds, glide, reach)` picks `RoomRing.glide_order`. The axes ease together if the box the two frames span lies inside the two rooms' rings; otherwise x then y, or y then x, through the corner frame whose two legs do. Each axis then eases over half the glide (`RoomRing.glide_offset`).

`room_ring_test.test_a_glide_between_touching_rooms_shows_no_void` checks every same-region edge-sharing pair, at points along the seam every 64 px and glide weights 0.9 to 0.1. Every sampled pixel has exactly one resident owner. With straight glides the test failed at three pairs, the narrow room under a wide one at each end of its seam; with ordered glides it passes.
