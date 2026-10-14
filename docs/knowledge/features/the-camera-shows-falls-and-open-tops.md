---
id: features/the-camera-shows-falls-and-open-tops
type: feature
title: The camera shows where a fall lands and keeps Ivo in frame over a room with nothing above it
status: active
tags: [camera, fall, room-ring, backdrop, seams, glide, rooms]
related: [systems/rooms, systems/backdrops, bugs/the-woods-pond-shelf-jump-takes-ivo-out-of-the-top-of-the-frame, bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame, bugs/a-glide-skips-the-drawn-frame-correction-and-snaps-when-it-ends, bugs/the-frame-jumps-up-when-the-fall-reach-closes-under-a-yielded-frame, gotchas/two-quads-disagree-on-a-pixels-world-position, playtests/2026-10-10-camera-on-falls, playtests/2026-10-11-open-sky-over-open-tops, playtests/2026-10-11-room-ring-regression]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - scenes/world/camera.gd
  - scenes/world/game.gd
  - scenes/world/rooms/room_ring.gd
  - scenes/world/rooms/fall_reach.gd
  - scenes/world/rooms/room_exit.gd
  - scenes/world/rooms/room_residency.gd
  - scenes/world/environment/backdrop/backdrop.gd
  - scenes/world/environment/backdrop/backdrop_math.gd
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
---

## Summary

In the air the camera leads below Ivo's feet, so the landing is in view before he lands: 0.20-0.29 s before touchdown on same-region drops, against 0-0.11 s before (CORE-07). Over a room with nothing above it the frame may rise up to 160 px past the room to keep Ivo whole, and that space is drawn by the nearest room's backdrop, so the frame never shows undrawn space. Contracts: `systems/rooms` ("A fall shows its landing", "Room ring") and `systems/backdrops` ("Room ring").

## Details

- **Fall lead.** `GameCamera._update_fall_lead` (`camera.gd:369`) keeps at least `fall_view` (176 px, `:34`) times the fall speed below the feet, never less than the unclamped follow would show. It grows at `fall_lead_rise` (720 px/s, `:36`), moves the frame at most `fall_lead_follow` (1200 px/s, `:38`) and eases back over `vertical_smooth_time` after a landing.
- **Landing cap.** `_ground_below` (`camera.gd:386`) casts a ray at each side of the body and stops the lead at the ground plus `LANDING_GROUND` (32 px, `:9`). Descending, ground counts only under both sides; standing or rising, the nearer hit counts.
- **Fall reach.** The lead yields only into `Game._fall_reach_for` (`game.gd:132`): the current room plus, under its floor seam, rooms of the same region that span the frame's width (`FallReach.of`, `fall_reach.gd:8`). A region seam still cuts; `snap(true)` (`camera.gd:244`) keeps the lead across it.
- **Room swap on a fall.** `RoomExit.has_left` (`room_exit.gd:10`) swaps downward with no margin, so the swap happens before the landing is due; the 64 px `SEAM_MARGIN` applies only upward.
- **Room ring.** `RoomRing.WIDTH` (160 px, `room_ring.gd:10`); `RoomRing.reach` (`:16`) is the room's bounds grown by it. `Game._set_camera_reach` (`game.gd:122`) sets it every step and `_enter_room` (`:117`) on a swap. `GameCamera._keep_subject_in_view` (`camera.gd:452`) lets the room clamp yield into the ring only to keep Ivo's body plus `subject_margin` (8 px) in frame. At rest the frame still clamps at the room.
- **The ring is drawn.** Each `Backdrop` covers `RoomRing.reach` of its room and passes `ring` to its shader (`backdrop.gd:77`, `:110`). A pixel outside every room goes to `BackdropMath.void_owner` (`backdrop_math.gd:123`): a seam continues straight past the rooms, the nearest room wins only at corners, and each pixel is judged at its centre (`pixel_centre`, `:102`).
- **Glides.** A walk across a seam glides the frame over `bounds_glide_time` (0.45 s) only between rooms that share an edge (`RoomResidency.share_an_edge`, `room_residency.gd:26`). `RoomRing.glide_order` (`room_ring.gd:21`) eases both axes together, or one after the other through a corner frame, whichever keeps every frame inside the two rings.
- **Look-ahead** stays inside the room clamp, never the ring (`_set_offset_x_within_reach`, `camera.gd:479`).
- **Tests.** `tests/scenes/world/camera_test.gd`, `tests/scenes/world/rooms/room_ring_test.gd`, `tests/scenes/world/rooms/fall_reach_test.gd`, `tests/scenes/world/environment/backdrop/backdrop_math_test.gd`.

## Why

- The request: "when we fall into a new room, the camera takes too long to follow and that is really bad for the player to track where he is going to fall." (user, 2026-10-10). Before CORE-07 the frame stayed clamped to the old room with Ivo at its bottom edge, then glided 0.45 s.
- 160 px holds Ivo's 54 px body and the 8 px margin at the apex of a full jump (143 px) from a floor 2 rows (`RoomRing.FLOOR_ROWS`) under an open top, and is under half the 384 px between rooms that do not touch, so every ring pixel's nearest room is resident. `room_ring_test` pins both.
- The ring replaced, the same day, an 80 px open sky per room plus a drawn-frame correction that flipped between candidate frames (`bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame`).

## Gotchas / pitfalls

- `void_owner`, `pixel_centre`, `rect_distance` and the rest of the seam mapping exist in `BackdropMath` and `backdrop_layer.gdshader`: change both (`systems/backdrops`, Never break).
- Over an open top the sky band's ceiling (`RoomEdges.CEILING_RISE`, 152 px = the ring less `subject_margin`) stops every jump, so the yield never has to pass the ring and Ivo is always in frame (WORLD-34, `architecture/world-edges-from-the-room-list`). The `NEAR_TOP` list is retired.
- The song trials sit closer than two rings apart (32 px and 256 px gaps); they are exempt only from that premise, not from the ownership sweeps.
- Open: `bugs/the-frame-jumps-up-when-the-fall-reach-closes-under-a-yielded-frame` (sideways drift).
