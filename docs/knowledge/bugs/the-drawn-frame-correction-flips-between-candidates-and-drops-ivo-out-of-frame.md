---
id: bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame
type: bug
title: CameraReach.drawn_frame picks the nearest drawn frame without regard to Ivo, so it can drop him wholly out of frame and jumps up to 171 px in one step when the nearest candidate flips
status: resolved
severity: medium
tags: [camera, rooms, open-sky, reach, void, discontinuity]
related: [bugs/a-neighbours-open-sky-lifts-the-camera-reach-over-village-mills-void, bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top, bugs/a-hop-below-a-seam-flips-the-room-twice, systems/rooms]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
  - scenes/world/environment/backdrop/backdrop_math.gd
  - scenes/world/rooms/room_ring.gd
  - scenes/world/rooms/camera_reach.gd
  - scenes/world/camera.gd
  - tests/scenes/world/rooms/camera_reach_test.gd
---

## Summary

`CameraReach.drawn_frame` (camera_reach.gd:24-45) replaces an undrawn frame with the candidate nearest to it by
Euclidean distance. It never looks at the body. Where the reach box holds a void corner, the drawn frames form an
L-shaped set, and the nearest point of a non-convex set changes branch at the diagonal: the frame jumps from "slid
sideways" to "dropped down" in one step, and the dropped frame can leave Ivo wholly above it.

## Symptom

Found in review of the uncommitted open-sky change (on 9f55197), by a headless probe. Not played.

The probe used the frame model from `camera_reach_test._frame` on the 56 rooms of `game.tscn`. Each room was the current
one, with feet every 2 px along rows (and columns) 8 px apart, kept only where `RoomExit` would keep that room current.
- 104,138 positions where the correction acts. In 79,819 of them the corrected frame cuts Ivo, and in 8,960 none of his
  body is in frame.
- 354 steps where a 2 px body move moves the corrected frame more than 8 px (the uncorrected frame moved 2 px).

village_mill (1920, 0, 1280x384) as current, Ivo in the air above its top in lake_waterfall_path's column:
- feet (2764, -56): frame (2560, -118). It slides right; Ivo is in frame.
- feet (2760, -58): frame (2440, 0). It drops down; Ivo (y -112..-58) is wholly above the frame. 171 px in one step.

The slide cost is 2560 - (x - 320) and the drop cost is the lift. They cross at x = 2880 - lift. A full jump west from
the step (cols 33-34, feet 96) onto the west half of the ledge (cols 24-29) crosses that line just before it lands. A
hover at the crossing point (an updraft) would flip between the two frames on each step.

`camera_reach_test.test_a_neighbours_sky_never_shows_the_void_over_a_room_without_one` asserts one of these cases:
feet (1911, 0), body y -54..0, corrected frame top 0, so Ivo is not drawn.

## Root cause

camera_reach.gd:36-44. The candidate is chosen by `distance_squared_to(frame.position)` alone. Nothing prefers frames
that keep `body` in view, and nothing damps a change of branch. The void corners are real: tops covered only partly
(village_mill, orchard_terraces, orchard_well, caldera_cistern_bottom) have no sky, but a neighbour's sky or a taller
neighbour lifts the box over them.

## Fix

Not fixed. Options:
- Remove the corners. Give a partly covered top a sky over the columns no room lies above (the per-column sky that
  `systems/rooms` "Open sky" put aside). After that the correction would only act at rare corners.
- Prefer candidates that keep the body inside the frame, then the nearest. The probe shows this keeps him whole in 33,938
  of the 79,819 cut positions, at a median of 114 px more travel. On its own that is a large move too.
- Rate-limit the corrected frame's travel per step, as `fall_lead_follow` does for the lead, so a change of branch eases
  instead of cutting.

## Prevention

Extend `camera_reach_test.test_no_frame_in_the_world_shows_the_void`. On its own it cannot fail: `drawn_frame` returns
either a covered candidate or the room clamp, and the room clamp is always inside the room. The test should also sweep
the body 1-2 px at a time and assert two things: the corrected frame moves no more than the body plus a few px per
sample, and the body stays in frame wherever the uncorrected frame held it, or the case is allowlisted with a reason.

## Resolution (2026-10-11)

The correction step is gone, because the drawn area no longer has corners inside the camera's reach. Every room's backdrop now draws the void within 160 px (`RoomRing.WIDTH`) of it wherever it is the nearest room. The ring is square-cornered (farther-axis distance), its dividing lines are hard, and ties go to the lower x, then y; `BackdropMath.keeps` and the shader are changed together. The camera's reach is the current room's bounds grown by the same 160 px (`RoomRing.reach`).

Rooms that do not touch are more than 320 px apart, so the nearest room to any pixel of that ring is resident. Every frame the camera can place is therefore drawn, and the frame follows the body by plain clamps: it can never move further than the body did in a step.

What I dropped from the requested rework:
- **Per-column skies:** the ring covers mill's west half and the tall-beside-short corners.
- **Candidate selection and travel cap:** no corrected frame exists any more.
- **Skies computed once:** no sky is computed at all; the reach is a rect grown each step.

`room_ring_test.test_a_body_swept_around_every_room_stays_in_a_drawn_frame` sweeps the body 2 px at a time along nine lines across every room's edges and top. Per step it checks:
- the frame moves no more than the body;
- the frame holds the body wherever the body is inside the ring;
- the frame stays inside the ring.

Every 48th frame it also checks that each sampled pixel has exactly one resident owner, using `BackdropMath.keeps` with and without jitter. It failed on the way to this design (a jittered ring edge, round ring corners, float edges), so it can fail. `camera_reach_test.gd` and its pinned mill frame are deleted with `CameraReach`.

Played on 9f55197 plus this change, 2026-10-11. Visibility is the share of the 54 px body inside the 640x360 view:
- **Pond pillar to shelf** (`open_sky_pond_shelf_jump.json`): visible 1.00 throughout.
- **Seam wall-top full jump** (`open_sky_seam_wall_top_full_jump.json`): body over bloom_hollow's columns, feet peak -142.5. Before this change visible was 0.00 for 0.85 s; now its minimum is 0.32, while the frame's top sits at the ring's top (-160). The left edge holds at -5801 with no snap.
- **Seam wall-top double jump** (`..._double_jump.json`): feet peak -267.5, past the ring as designed. The left edge holds at -5804.5, with no snap and no fade.
- **lane_west to woods_edge region cut** (`open_sky_region_cut_lane_to_woods.json`): the cut frame's top is -28.9, his head minus the margin, between -32.7 before and -24.8 after.
- **village_mill step to ledge** (`ring_mill_step_to_ledge.json`): feet peak -46.5 under lake_waterfall_path, visible 1.00. The frame's top reaches -108 and moves smoothly. The still `mill_1_80` shows the waterfall path's backdrop above the mill and no void.
