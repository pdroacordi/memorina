---
id: bugs/the-fall-lead-shows-the-void-beside-a-narrower-room-below
type: bug
title: The camera's fall lead yields the whole 640 px frame below the room, but the reach is checked only under Ivo's body, so the void shows beside a narrower room below
status: resolved
severity: medium
tags: [camera, rooms, reach, keep-in-view, void, fall-lead, world-05]
related: [playtests/2026-10-10-camera-on-falls, bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top, bugs/the-fall-lead-dips-the-frame-below-a-solid-floor-on-a-hard-landing, systems/rooms]
created: 2026-10-10
updated: 2026-10-11
source_files:
  - scenes/world/game.gd
  - scenes/world/camera.gd
---

## Resolution (2026-10-11, revision 4, re-measured in game by the playtest)

Since revision 3, the lead yields only into a separate fall reach of same-region rooms that span the frame (`FallReach`). Revision 4 kept that. 60 fps `log`, `playtests/2026-10-10-camera-on-falls`:
- **lake_fishing_village → lake_well:** before the swap the frame follows body + 8 px exactly as HEAD (steps +22, then +11..+13). The lead never enters lake_well. The largest void strip, 53 x 181 px, appears during the swap glide, where HEAD shows 60 x 180. That void comes from the room glide on HEAD too, not from the lead.
- **village_square → caldera_cistern:** at most 70 px of cistern shows before the cut (HEAD 129). The void corner beside it is at most 42 x 61 px, the same as HEAD.
- **Landings on the square's floor:** the frame never passes the room's bottom.

## Summary

`Game._reach_for` now grows the touch rect down by `GameCamera.fall_lead()` (game.gd:120). Any room the grown rect touches is merged into the reach as a bounding box. The reach only guarantees a room under Ivo's body column, which is 38 px wide. The frame then yields down across its full 640 px width. Where the room below is narrower than the frame's span, the part of the frame beside it shows empty void.

## Symptom

Found in review of the uncommitted fall-lead change (2026-10-10). Traced from the code and the world table (`systems/world`), not reproduced in game. The numbers use 980 px/s² gravity and Ivo's 1000 px/s terminal velocity.

- **lake_fishing_village → lake_well** (same region, glide). The well mouth is at cols 26-31 (x 1472-1664). lake_well covers only c2 (x 1280-1920); nothing lies at c1 or c3 on row -4.
  - Ivo drops from the floor (y -1632). He has left the room once his head is 64 px past the seam: feet at seam + 118, fall speed about 650 px/s, lead about 114 px.
  - The frame's bottom is then at feet + 8 + 114, which is seam + 240.
  - Ivo at x 1500 facing left puts the frame at x 1084-1724, so a strip about 196 x 240 px at x 1084-1280 is void. Before this change the band was seam + 126.
- **village_square → caldera_cistern** (the well shaft at cols 28-31; the cistern covers only c1): the frame always straddles c0 or c2 on row 1, which is void.
- **Landing on the floor above a narrower room.** This needs no hole. A double jump lands at about 727 px/s, which gives a lead of 128 px. On the square's floor (y 288, 96 px above the seam), anywhere in x 621-1299 the lead dips the frame 40 px past the room's bottom. The c0 or c2 part of that strip is void (`bugs/the-fall-lead-dips-the-frame-below-a-solid-floor-on-a-hard-landing`). lake_chasm over orchard_well (they overlap only at c-5) has the same shape.

## Root cause

- The reach is still one `Rect2` (`bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top`). That fix narrowed which rooms are merged to the rooms the body touches, which held while the yield was at most body + 8 px past an edge.
- The lead lets the yield reach about 300 px past the room's edge, on every column of the frame. The body-column test no longer bounds what the frame shows.

## Fix

Not fixed. Options:
- Clamp the vertical yield against only the rooms whose x range covers the frame's x span, as the open-top bug suggested. The fall lead then yields fully only where the room below spans the frame, and partly elsewhere.
- Or apply the lead past the room clamp only once the frame's x span lies inside the room below.

## Prevention

Add a camera_test case with room A 1280 wide and a room below it only 640 wide, offset so that the frame straddles the lower room's edge. With a falling subject, assert that every part of the frame below A's bottom lies inside the lower room.
