---
id: bugs/a-hop-above-a-neighbours-open-top-drops-it-from-the-camera-reach
type: bug
title: A hop from the bloom_hollow half of the woods_pond seam wall top drops bloom_hollow from the camera reach, so Ivo leaves the side of the frame for ~0.8 s
status: resolved
severity: low
tags: [camera, rooms, open-top, open-sky, spring-woods, seam]
related: [playtests/2026-10-11-open-sky-over-open-tops, bugs/the-woods-pond-shelf-jump-takes-ivo-out-of-the-top-of-the-frame, bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top, systems/rooms]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/game.gd
  - scenes/world/rooms/open_sky.gd
  - scenes/world/rooms/camera_reach.gd
---

## Summary

`Game._reach_for` adds a neighbour room to the camera reach only when its plain bounds meet Ivo's body grown by
`subject_margin` (8 px). Above an open top his body is at y < 0, so a neighbour whose top is at y 0 drops out of the
reach as soon as his feet rise 8 px. The frame then snaps back inside the current room and loses him sideways.

## Symptom

Found on the uncommitted `OpenSky` change (on 08c891c). Timeline `tools/playtest/scripts/open_sky_seam_wall_top.json`:
- From the woods_pond shelf's west end (-5494, 62), a double jump west lands Ivo on the 2-cell wall top over the
  woods_pond / bloom_hollow seam (x -5792..-5728, top y 0).
- He walks left to x -5775.9, which is wholly inside bloom_hollow's columns. The current room stays woods_pond,
  because no room contains his centre (-5776, -27).
- He hops (jump held 0.15 s).

Per-frame `trace`, view = 640x360 around `cam_centre`:

```
t=4.794 feet (-5775.9, -0.1)  cam_c (-5474.9, 117.9)  view x -5794.9..-5154.9  visible 1.00  (standing; bloom in reach)
t=4.831 feet (-5775.9, -8.2)  cam_c (-5474.9, 109.8)                          visible 1.00
t=4.846 feet (-5775.9, -16.2) cam_c (-5440.0, 101.8)  view x -5760..-5120      visible 0.00  (35 px snap in one frame)
t=4.85..5.68                  cam_c x -5440                                    visible 0.00
t=5.764 feet (-5753.6, -1.3)  cam_c (-5452.3, 116.7)                           visible 1.00  (12.5 px snap back)
```

His body spans x -5787..-5765, and the frame's left edge is -5760, so he is wholly out of frame for ~0.85 s.
Screenshot: `playtests/screenshots/2026-10-11-open-sky-over-open-tops/seam_wall_top_hop_ivo_off_left_edge.png`.
The same hop from x -5744 (the woods_pond half) keeps him in frame sideways.

## Impact

- Low. The wall top is an optional perch that only a double jump reaches, and the hop also rises above the 80 px sky,
  as designed for a floor in row 0 (`open_sky_test`: "Row 0 is a wall's top, reached only from above the room").
- The sideways loss and the two frame snaps (35 px out, 12.5 px back) are not by design. Before `OpenSky`, Ivo was
  not visible anywhere on this wall top, because the frame stopped at y 0. The change made standing there visible but
  left the hop broken.
- The same applies at any seam between two open-top rooms where Ivo can be above the neighbour's columns and above
  y 0.

## Root cause

`scenes/world/game.gd` `_reach_for`:

```gdscript
var reach := OpenSky.of(_current_room.get_bounds(), _bounds_of(near))
var touch := body.grow(_camera.subject_margin)
for room: Room in near:
	if room.get_bounds().intersects(touch):
		reach = reach.merge(room.get_bounds())
```

The current room gets its sky, but each neighbour is tested with its plain bounds. Above y -8, bloom_hollow (y 0..384)
no longer meets `touch`.

## Fix

Proposed: test and merge each neighbour with its own sky, `OpenSky.of(room.get_bounds(), _bounds_of(near))`,
as `Backdrop._neighbours` already does. The backdrop already draws each neighbour's sky band, so the frame would show
bloom_hollow's sky, not the void.

## Prevention

A camera test: Ivo's body above the open top of a neighbour (not the current room), with nothing above that neighbour,
must stay inside the reach.

## Resolution (2026-10-11)

`CameraReach.of(current, rooms, touch)` (pure, called by `Game._reach_for`) tests and merges every room with its open sky, `OpenSky.of(bounds, rooms)`. `rooms` is every room, not only the current room's neighbours, so a neighbour's sky matches the one its backdrop draws: a room over the neighbour that does not touch the current room still closes it. Tests: `camera_reach_test` (the pond/hollow seam hop keeps the hollow and its sky; a body that misses a neighbour leaves it out; a covered neighbour gives the room above, not a sky), `camera_test.test_a_hop_above_a_neighbours_open_top_stays_in_frame`.

Re-run of `open_sky_seam_wall_top.json` (2026-10-11, after `--import`). This run stood him at x -5763.1, so his body spanned -5774..-5752, 14 px over the hollow's columns. Through the whole hop (t 4.82-5.69) the frame's left edge stayed at -5782.1, and his body stayed inside it sideways. The old reach would have snapped that edge to -5760. He still leaves through the top: feet peak at y -83.4 against an 80 px sky. That is by design for a hop from a row-0 wall top (`open_sky_test`).

## Revision (2026-10-11, review)

The fix only moves the drop up 80 px. `CameraReach.of` (camera_reach.gd:15-17) still adds a neighbour only while
`touch` meets its rect plus sky, so the neighbour drops out once his feet pass `-OpenSky.HEIGHT - subject_margin`
(y -88). The re-run hop peaked at -83.4, under that line. A full jump from the same wall top peaks at about -143, over it.

Headless `CameraReach.of(POND, [POND, HOLLOW], touch)` with the body over the hollow's columns:
- feet -70: (-7040, -80, 2560x464), hollow kept;
- feet -90: (-5760, -80, 1280x464), hollow dropped.

The frame then snaps right by his overhang plus 8 px (up to ~30 px) while he is above its top. It snaps back as his feet
come down past -88, which is the moment he comes back into view. Any jump higher than the sky does this, from the
bloom_hollow half of the woods_pond seam wall top and from the woods_edge half of the village_lane_west seam wall top
(both rooms have a sky, and the wall top is at y 0).

Status set back to open (low). Suggested: above a room with a sky, test `touch` against the room's columns with no top
limit, and merge the sky rect as now, so the reach's top stays at the sky's top.

## Resolution after review (2026-10-11)

`CameraReach.of` tests a room that has nothing drawn over its top against its rect extended `OPEN_ABOVE` (384 px) upward. That is more than any jump's apex, so a neighbour stays in reach however high he goes over its columns. The extension only decides which rooms are met: the reach's top stays at the sky's top, and `drawn_frame` keeps the frame drawn. Tests: `camera_reach_test.test_a_jump_past_a_neighbours_sky_keeps_it_in_reach` (feet -90 and -150 over the hollow's columns).

Played on 08c891c plus this change (the later merge of 9f55197 changed no room played here) (`open_sky_seam_wall_top_full_jump.json`, `open_sky_seam_wall_top_double_jump.json`):
- **Full jump** from x -5779.1: his body spans -5790..-5768, wholly over bloom_hollow, and his feet peak at y -141.3. The frame's left edge stays at -5798.1 from take-off to landing, his body minus the margin, with no snap. He leaves through the top while his feet are above about -62, as designed for a row-0 wall top.
- **Double jump** from x -5756.7, feet peak -258.8: the left edge stays at -5775.7 the whole time. No fade, and the room stays woods_pond.

## Revision (2026-10-11, room ring)

`OpenSky`, `CameraReach` and the drawn-frame correction named above are replaced by `RoomRing`
(`systems/rooms` "Room ring", `bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame`).
The camera yields up to 160 px past the current room, and every room's backdrop draws the void it is nearest within that ring. The reach no longer merges neighbours, so none can drop out of it. The full jump from the seam wall top keeps its left edge at -5801 (minimum visible 0.32, at the ring's top).
