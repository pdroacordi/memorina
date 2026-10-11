---
id: bugs/the-fall-lead-dips-the-frame-below-a-solid-floor-on-a-hard-landing
type: bug
title: On a hard landing on a floor near a seam with a room below, the fall lead pushes the frame up to 88 px past the room's bottom and holds it there for about a second
status: resolved
severity: low
tags: [camera, rooms, fall-lead, landing, feel, world-05]
related: [playtests/2026-10-10-camera-on-falls, bugs/the-fall-lead-shows-the-void-beside-a-narrower-room-below, systems/rooms]
created: 2026-10-10
updated: 2026-10-11
source_files:
  - scenes/world/camera.gd
  - scenes/world/game.gd
---

## Resolution (2026-10-11, revisions 3 and 4, re-measured in game by the playtest)

The lead is capped at the ground under the feet + 32 px (a ray on the world layer, `GameCamera._ground_below`). 60 fps `log` (`camfall_c1d_canopy_ledge_jumps_dense`, `camfall_c2d_square_jump_dense`):
- On every landing (woods_canopy ledge single and double jumps, square-floor double jump), the frame's bottom never passes the room's bottom (0 px).
- The largest one-frame step is +11/+12 px, the same as HEAD.
- The uncapped first version dipped 23 px (canopy) and 32 px (square, into the cistern).

## Summary

`_fall_lead` is `fall_view * air_axis`, whatever lies under Ivo's feet (camera.gd:331-336). A surface room's floor is 96 px above its bottom edge (`systems/world`), so a lead over 88 px reaches past the seam. Wherever a room lies below, `_reach_for` admits it (game.gd:120), and `_keep_subject_in_view` drops the frame into it. This starts before touchdown, on an ordinary landing on solid ground. After the landing the lead eases back over `vertical_smooth_time`, which `game.tscn` sets to 0.5 s.

## Symptom

Found in review of the uncommitted fall-lead change (2026-10-10). Worked out from the code, not reproduced in game.
- **woods_deep floor (y 288), with woods_root_caves below.** A fall from about 300 px lands at about 767 px/s, so the lead is 135 px. The frame's bottom goes to 288 + 8 + 135 = 431, which is 47 px of the caves' ceiling under the floor. A fall at terminal speed gives 88 px. The frame then rises back over about 1 s.
- **village_square floor in x 621-1299, with caldera_cistern below.** A double-jump landing gives a 40 px dip. Part of the dip is void (`bugs/the-fall-lead-shows-the-void-beside-a-narrower-room-below`), and the cistern shows in the village's memory, season and palette.
- The landing surface was already in frame: the room's clamp shows down to y 384. The dip shows nothing the player needs, and it is a camera bob the player did not cause.

## Root cause

The lead stands for "the ground I am about to land on". It is measured in px below the feet, with no check for ground between the feet and the seam. Once the body is on the floor, the remaining lead still counts in both the reach and the kept rect.

## Fix

Not fixed. Options:
- Grow the touch rect by the lead only where the body's column is open down to the seam. `RoomMapNode.ground_at` answers whether a cell is ground.
- Or stop the yield past the room's clamp once `air_axis()` is 0: the ease-back would then relax only inside the room, and the in-room framing keeps the landing in view.
- Or cap the lead at the distance from the feet to the first solid cell below.

## Prevention

Add a camera_test case: a subject falls at full speed onto a floor 96 px above A's bottom, with a room below A in the reach. Assert that the view's bottom never passes A's bottom.

## Revision (2026-10-11, review of revision 6): the two-ray cap reopens the dip at a ledge's edge

Revision 6 (camera.gd 00:20:24) caps the lead only when both rays hit. `GameCamera._ground_below` returns INF if either the left or the right edge of `body_rect()` has no ground within `reach`. Ivo's body is a capsule (radius 11), so it stands on a ledge until its centre is about 7.8 px past the edge (45° floor angle). Its rect is 22 px wide. **Any stance within about 11 px inside an edge, or up to 7.8 px past it, leaves one ray over the drop.** Revision 5 used one centre ray, which left only the band past the edge uncapped. Derived from the code, not reproduced. The revision 6 runs jumped from the middle of the ledges, not from an edge.

- **Landing at an edge.** After touchdown `_air_axis()` is 0, so the lead eases from its landing value over `vertical_smooth_time` (0.5 s in `game.tscn`), with no ground cap. The fall reach stays open while the lead is above 0, so the frame stays yielded past the room's bottom while Ivo stands. Examples, on floors 96 px above a same-region seam:
  - a single jump from the woods_canopy ledge's edge comes down with a ~112 px lead, a ~24 px dip for ~0.12 s;
  - a fall onto the lip of woods_deep's floor hole comes in with a ~250 px lead, a ~160 px dip that eases over ~0.5 s.
- **The claim in `systems/rooms`** ("so a landing on a floor never dips the frame past it") holds only away from edges.

**Fix options:** when `_air_axis() <= 0` (standing or rising), cap with the nearer hit, or at `LANDING_GROUND` once either ray hits within a px. Keep the both-rays rule only while descending, where it fixes the one-way hold.

**Prevention:** a camera_test floor ending under the subject's centre + 5 px, the subject falling onto it with a room below in the fall reach. After touchdown, assert that the view's bottom is never past room A's bottom.

## Resolution (2026-10-11, revision 7)

`GameCamera._ground_below(reach, descending)`: descending, ground counts only under both sides of the body (a drift off an edge keeps its lead); standing or rising, the nearer hit counts, so a stance at an edge caps the lead at the floor. The rays start 2 px above the feet, because a ray that starts on a surface misses it (the standing case found no floor at all). Tests: `camera_test.test_a_stance_at_an_edge_does_not_dip`, `test_a_descent_past_an_edge_keeps_its_lead`.
