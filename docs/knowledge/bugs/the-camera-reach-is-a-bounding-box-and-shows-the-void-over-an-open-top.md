---
id: bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top
type: bug
title: Game._reach_of merges the touching rooms into one bounding box, so where a neighbour touches at a corner or is offset, the camera still yields into the void over an open top
status: resolved
severity: low
tags: [world-05, camera, rooms, reach, keep-in-view, void]
related: [bugs/the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top, bugs/crossing-a-seam-upward-takes-ivo-out-of-the-frame, systems/rooms]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/game.gd
  - scenes/world/camera.gd
---

## Summary

`systems/rooms` says the keep-in-view yield stops at "the union of the room and the rooms touching it, so no
void shows over an open top". But `Game._reach_of` (game.gd:116-120) builds it with `Rect2.merge`, which is the
bounding box, not the union. Any neighbour that touches only at a corner, or that extends above the current
room's row, lifts the reach's top edge across the whole width.

## Symptom

orchard_leaf_path is x [-8960, -7680), y [-1536, -1152), and nothing lies above it. orchard_windy_gap,
x [-7680, -6400), y [-1920, -1536), touches it only at the corner (-7680, -1536); `RoomResidency.touches` grows
by 1 px, so it counts. The reach's top is therefore -1920.

A double jump on the leaf path hill (x -8300) peaks at feet -1677.6. The frame (640 px wide, centred near
-8300) yields up to about y -1740, showing ~200 px of empty grey above the room.
`playtests/2026-10-10-traversal-orchards-caldera` logged "visible 1.00 throughout" there, which confirms the
frame followed him up.

## Root cause

A rectangle cannot represent an L-shaped set of rooms. The clamp at camera.gd:361-362 is applied per axis
against one rect.

## Fix

Suggested: pass the touching rooms' rects, not their merge, and clamp per axis against only the rooms that
cover the frame's span on the other axis. For example, the vertical limit is the union of the rooms whose x
range overlaps the frame's x range. Whether Ivo may then leave the frame over an open top (about 1 s on the
threshold bridge) is the human call already open in
`bugs/the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top`.

## Prevention

A camera_test case: reach with a neighbour touching only at the corner above-right. A body above the room's
open top keeps the view's top at the room's top.

## Resolution (2026-10-10)

`Game._reach_for(body, near)` merges only the rooms his body (grown by `subject_margin`) reaches into, set every step through `GameCamera.set_reach`; `_yield_axis` stops the yield at the reach and never pulls a glide back. Playtest (2026-10-10, working tree on 5062946, `--import` at 03:35:59, real save untouched):
- **Over open tops, the frame no longer yields above the room.**
  - Leaf-path hill double jump (`..._rv_n1_*`, peak feet -1677.6): the camera centre never goes above y -1356 (the
    room's top + 180).
  - Ivo is wholly out of the frame's top from t 1.60 to 2.90 (~1.35 s). The leaf → arena double jump
    (`..._rv4_s1_*`) is wholly out for ~1.55 s.
  - orchard_well and the threshold bridge behave the same (min visible 0.00).
- **The frame still follows where a room is above, or across a seam.** Visible 1.00 on every sample in:
  - the crown hop under orchard_chasm_bridge's hole (`..._h1_*`);
  - the canopy branch → orchard_terraces double jump (`..._o1_*`);
  - the lake entrance's ledge flush with the seam (`..._rv_k1_*`).
- **No pop on the in-region glide.** square → mill (`..._rv4_g1_square_to_mill_glide.json`, a copy of
  `traverse_woods_lake_w7a_rv_square_to_mill_glide.json`):
  - per-frame pixel changes go 5k, 3k, 4k, 4k, then 73k, 97k, 91k, 102k, 218k … 37k, 5k as the camera centre glides
    1600 → 2240;
  - there is no one-frame spike while the camera is still.
