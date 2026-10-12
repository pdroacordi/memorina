---
id: bugs/the-woods-pond-shelf-jump-takes-ivo-out-of-the-top-of-the-frame
type: bug
title: On the main path through woods_pond, the jump from the col-28 pillar to the rock shelf takes Ivo wholly out of the top of the frame for ~0.45 s
status: resolved
severity: medium
tags: [camera, rooms, spring-woods, open-top, world-25, feel]
related: [playtests/2026-10-11-world25-rework, playtests/2026-10-09-traversal-woods-lake, bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top, bugs/crossing-a-seam-upward-takes-ivo-out-of-the-frame, systems/rooms]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/spring_woods/contents/woods_pond.room
  - scenes/world/camera.gd
  - scenes/world/game.gd
  - scenes/world/rooms/open_sky.gd
  - scenes/world/environment/backdrop/backdrop.gd
---

## Summary

woods_pond (x -5760..-4480, y 0..384) has an open top and no room above it. The camera is clamped at the room's top (view top y 0) and never yields into the void (`Game._reach_for`). The main-path shelf (row 2, top y 64) is 64 px below that edge. The jump onto it from the pillar (col 28, top y 128) peaks at feet y -15, so Ivo is wholly above the view for about 0.45 s.

## Symptom

Worktree agent-a5ca98ed7ee598b83 (WORLD-25 rework, uncommitted, on 9df7ec6). Timeline `tools/playtest/scripts/world25_deep_pond_to_bloom.json`: a full jump (0.45 s press) from x -4850 on the pillar top, with left held. Visibility = the share of the 54 px body inside the 640x360 view around `cam_centre`, computed from `log` every 0.1 s:

```
t=15.60 feet  62.8 cam_y 180 view_top 0 visible 1.00
t=15.70 feet  29.8                       visible 0.55
t=15.80 feet   5.1                       visible 0.09
t=15.90 feet -11.3                       visible 0.00
t=16.00..16.20 feet -15..-10             visible 0.00
t=16.30 feet   1.2                       visible 0.02
t=16.40 feet  22.1                       visible 0.41
t=16.50 feet  52.8                       visible 0.98
```

Screenshot `playtests/screenshots/2026-10-11-world25-rework/pond_shelf_jump_ivo_out_of_frame.png`: no Ivo in the frame.

## Impact

- This is the one jump on the first-visit route to the Bloom Guardian that needs a full arc: a 160 px gap and 64 px of rise. The player loses sight of Ivo exactly while steering the landing.
- `playtests/2026-10-09-traversal-woods-lake` reported a milder version (only his feet showed). The rework replaced the plank route (plank at y 128 over a 1-cell gap) with a 5-cell gap from the pillar, so a full jump is now required and he leaves the frame entirely.

## Root cause

The camera does not yield over an open top with no neighbour, by design (`bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top`). The level puts a required full jump 64 px under that edge.

## Fix

Options considered:
- Level: lower the shelf and the pillar by 2-3 rows. The 2026-10-09 report already suggested 2. The basin and its Chuva passage would need the same shift (design 02 section 8, Primavera Logico 2).
- Camera: let the frame rise over an open top with no room above by up to Ivo's height plus `subject_margin`, showing the backdrop's sky rather than the void. This touches the void rule in `systems/rooms`.

## Prevention

A required jump whose apex rises above an open room top with no room above it should be flagged when the room is authored. The reachability audit knows both the apex height and the open edges.

## Resolution (2026-10-11)

Camera, not level. `OpenSky.of(bounds, rooms)` gives a room that no room meets in the 80 px strip over its top that strip as sky. `Game._reach_for` starts the keep-in-view reach from it, and `Backdrop` uses the sky-grown rect for its own `room_rect`, its cover and each neighbour's seam rect, so the band shows the first layer's EDGE sky, never the void (`systems/rooms` "Open sky", `systems/backdrops`). Resting framing still clamps at the room's top.

Why this and not the level:
- A level-only fix cannot work here. With no sky, a whole Ivo at the apex needs feet at y 62 or lower, so the take-off at y 205 (row 7). The shelf at y 64 is then 141 px up, beyond the margin of a 143 px jump. Lowering the shelf breaks the Chuva basin's passage and alcove under it (design 02 section 8, Primavera Logico 2): the basin floor is already the room's bottom row.
- 80 px = a full jump's apex (143 px) from a floor 4 rows (128 px) under the top, plus Ivo's 54 px body and the 8 px `subject_margin`, rounded up. The pillar (row 4, y 128) peaks at feet -15: body top -69, frame top -77 at most. `open_sky_test` pins the number to `JumpReach`.
- Ownership stays exact: rooms never overlap and a sky exists only where no room meets the strip, so `BackdropMath.keeps` and the shader are unchanged.

Scan of every open top (feet cells in rows 1-4 under a column no room lies above): the main-path take-offs at row 4 (woods_pond pillar, lake_shore causeway, orchard_leaf_path hill and one-way, orchard_windy_gap step, woods_edge and threshold_fields roofs, lake_high_wall ledge) are now whole in frame. Floors in rows 1-3 are not required take-offs and are listed in `open_sky_test`'s `NEAR_TOP` with the reason: the woods_pond shelf (eastbound drops into the dry basin), the lake_shore bump, the fisher hut's and gatehouse's roofs (optional double-jump perches), the lighthouse lantern's roof (unreachable). Partly covered tops (village_mill, orchard_terraces, orchard_well, caldera_cistern_bottom) get no sky; the only floor there that clips is orchard_terraces row 6 (cols 26-31), by about 5 px of head at a full jump's apex. Accepted.

Tests: `open_sky_test` (sky shape, the 80 px pin, the near-top floor list), `camera_test` (yields into the sky; stops at its top), `backdrop_test` (the backdrop's rect includes the sky; a room above closes it). Gates: import, 1152 GdUnit cases, smoke, all green.

Playtest: `docs/knowledge/playtests/2026-10-11-open-sky-over-open-tops.md` (timelines `tools/playtest/scripts/open_sky_pond_shelf_jump.json`, `open_sky_seam_wall_top.json`). It was still running when this fix was written. Re-open this bug if it shows Ivo out of frame at the apex or a seam in the sky band.

## Revision (2026-10-11, room ring)

`OpenSky`, `CameraReach` and the drawn-frame correction named above are replaced by `RoomRing`
(`systems/rooms` "Room ring", `bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame`).
The camera yields up to 160 px past the current room, and every room's backdrop draws the void it is nearest within that ring. A full jump from a floor 2 rows under an open top now stays whole; `NEAR_TOP` keeps only the row-1 roofs. The pond jump stays at visible 1.00.
