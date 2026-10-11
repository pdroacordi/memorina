---
id: playtests/2026-10-11-bell-tower-helix
type: playtest
title: WORLD-26 revised - the tower turning around Ivo as he rides its axis, and the void outside the shells
status: active
build: 2ea2540 + WORLD-26 working tree (Ivo at 2x with his new run, the redrawn interior props)
area_tested: "home_village/village_bell_tower (1x4, slim, in void), village_house and village_tavern (void)"
tags: [helix, stair, bell-tower, rotation, perspective, void, world-26]
related: [systems/helix-stair, architecture/walkable-helix-stair, architecture/room-void-outside-the-shell, gotchas/losing-window-focus-releases-held-actions, bugs/descending-from-the-helix-head-runs-in-place-on-the-gallery-then-drops-a-turn, bugs/a-facing-turn-in-a-one-screen-wide-room-slides-the-frame-past-its-bounds]
created: 2026-10-11
updated: 2026-10-11
ratings: { fun: 3, fluidity: 4, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-11-bell-tower-helix/a00_inside_door.png
  - screenshots/2026-10-11-bell-tower-helix/a01_u0_foot.png
  - screenshots/2026-10-11-bell-tower-helix/a02_quarter_turn.png
  - screenshots/2026-10-11-bell-tower-helix/a03_mid.png
  - screenshots/2026-10-11-bell-tower-helix/a04_head.png
  - screenshots/2026-10-11-bell-tower-helix/a05_gallery.png
  - screenshots/2026-10-11-bell-tower-helix/a06_descending.png
  - screenshots/2026-10-11-bell-tower-helix/a07_back_at_the_foot.png
  - screenshots/2026-10-11-bell-tower-helix/b00_motion_7.00s.png
  - screenshots/2026-10-11-bell-tower-helix/b05_motion_8.25s.png
  - screenshots/2026-10-11-bell-tower-helix/v00_house.png
  - screenshots/2026-10-11-bell-tower-helix/v01_tavern.png
---

## What was tested

`tools/playtest/scripts/bell_tower_helix_climb.json`: Up at the bell tower door from the square, then right held from the door up the axis to the gallery, then left back onto the head and down to the floor. Stills at u 0, a quarter turn, mid and head, the gallery, descending and back at the foot; six frames 0.25 s apart mid-climb (b00-b05). The descent is traced every physics frame (`"trace"` steps, 16.4-29.2 s); the stills were re-captured with the descent fix. `interior_void_house.json` and `interior_void_tavern.json`: one still each. Earlier the same day the first version (Ivo across a static ribbon) was played and rejected by the user.

## Findings

- **The ride.** Right held from the door walks to the axis (x 320) and boards in 0.7 s, rises straight up at 102 px/s, reaches the head 11 s later and walks onto the gallery with right still held (`a05_gallery`). Left at 16.5 s walks him back from the gallery (x 10037) to the axis and boards the head at 17.14 s. The first ride step moves his feet 6 px onto the axis and 5 px down through the one-way plank onto the top tread (`Character.teleport_body`), so he never stands on the plank while the tower turns. He then descends 659 frames, tread by tread, at most one 10 px riser per frame, with `u` never held. He reaches the foot at 28.10 s (11.0 s, the same as the climb) and left walks him onto the floor (`a06_descending`, `a07_back_at_the_foot`). Facing is right all the way up and left all the way down. The review's run before the fix ran in place on the gallery for 2.7 s and then dropped 295 px in one frame (`bugs/descending-from-the-helix-head-runs-in-place-on-the-gallery-then-drops-a-turn`).
- **It reads as a 3D stair.** Treads below the eye show their tops, the steps above show dark soffits, the wall's courses curve, the floor's top is an ellipse at the foot (`a01_u0_foot`, `a02_quarter_turn`). In the motion frames the treads slide along the spiral under Ivo, and the posts and slits drift sideways by their depth (b00-b05), while Ivo stays on the axis at the front. The spiral's outline stays the same from frame to frame: the stair is screw-symmetric and the camera rises with him, so the turn shows through the treads, posts and slits moving, not the outline.
- **Feet on the treads** (after "ivo while running doesn't touch the ground", user, 2026-10-11). His feet now stand on the tread under the axis every frame and climb each riser at once as the next tread passes under him (`a03_mid`, b00-b05); the camera follows the steady rise. The run clip's flight frames still lift a foot, as on the ground. The outer stringer cut by his plane is a solid band under the tread sections, and the gallery has an 18 px plank edge across the shell (`a04_head`).
- **The frame in the one-screen-wide tower.** `cam_centre` x read 9920 on every traced frame, including the turn from right to left at the head. The review's run read 9914 there (`bugs/a-facing-turn-in-a-one-screen-wide-room-slides-the-frame-past-its-bounds`).
- **The top.** The bell hangs under the roof beam, seen from the gallery (`a04_head`, `a05_gallery`).
- **The void.** Black beyond the shell's one-cell walls, cut straight on the cell line: in the tower around the shell and below the floor, in the house below the floor, in the tavern above the ceiling and below the floor, with main's redrawn props (`v00_house`, `v01_tavern`).
- **New Ivo.** The 2x sheets from main (433db63) stand on the treads with their feet on the tread line.

## Ratings rationale

- Fun 3: holding one side carries him up the turning tower in 11 s; whether the turn feels like the reference's illusion in motion needs the user's eye (the stills and the 0.25 s frames are the evidence).
- Fluidity 4: no stalls in the trace, and boarding moves the feet at most 6 px. The feet stand on a tread top every frame and step one riser at a time. The frame moves at most 1.8 px a frame while the feet step 10 px.
- Aesthetics 3: the board's palette on flat-shaded geometry, a solid stringer band across the front and a plank gallery edge.
