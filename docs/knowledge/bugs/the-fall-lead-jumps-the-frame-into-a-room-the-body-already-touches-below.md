---
id: bugs/the-fall-lead-jumps-the-frame-into-a-room-the-body-already-touches-below
type: bug
title: Once Ivo's body crosses a floor seam into a narrower or other-region room, the whole fall lead applies at once, and the frame jumps 72-136 px in one physics frame and shows the void
status: resolved
severity: medium
tags: [camera, rooms, reach, fall-lead, void, region-seam, world-05]
related: [playtests/2026-10-10-camera-on-falls, bugs/the-fall-lead-jumps-the-frame-when-a-glide-swaps-into-a-narrow-room, bugs/the-fall-lead-shows-the-void-beside-a-narrower-room-below, bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top, systems/rooms]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/camera.gd
  - scenes/world/game.gd
  - scenes/world/rooms/fall_reach.gd
---

## Resolution (2026-10-10, revision 3 at 23:27:39, re-measured in game)

Game now passes the camera two reaches, `set_reach(body_reach, fall_reach)`, and the lead yields only into the fall reach (FallReach: same-region rooms spanning the frame).
- Fishing well: before the swap, the frame follows body + 8 px exactly as on HEAD (+22, then +11..+13 per frame). The void strip grows only with that yield (85 x 22..70 px).
- Square well walk-in: the frame shows at most 70 px of the cistern before the cut (old yield 129 px; limit ≤126). Steps stay ≤ +9 px before the cut.
- Square well spawn: identical to HEAD (largest step +12 px).

Still open nearby: at the fishing well's glide swap, the lead now jumps the frame +66 px in one frame (`bugs/the-fall-lead-jumps-the-frame-when-a-glide-swaps-into-a-narrow-room`).

## Summary

`FallReach` keeps the lead out of narrow and other-region rooms below. But `Game._reach_for` still merges any room that Ivo's body (grown by 8 px) touches, and `GameCamera._keep_subject_in_view` adds `_fall_lead` to the kept rect whatever produced the reach. When the feet cross the seam into lake_well (narrow) or caldera_cistern (another region), the plain touch admits that room. The full lead (capped at the ground + 32 px) then applies on that frame. The frame drops 72-136 px in one physics frame and shows the void beside the narrower room. Before the fall-lead change, the same touch only yielded body + 8 px, and the frame followed Ivo gradually.

## Symptom

Seen in game on the 23:15:20 working tree (on top of d3ae19e), in 60 fps `log` runs. Each case was run twice with the same numbers.

| Fall | Feet when it jumps | One-frame step (`cam_centre` y) | Old code, same frame |
|---|---|---|---|
| lake_fishing_village well → lake_well (`camfall_d1d_fishing_well_dense`) | -1522.5 (seam -1536) | **+136 px**, then it holds 5 frames and glides | +22, then body + 8 |
| village_square well, walked in from the east curb (`camfall_b2d_well_walk_east_dense`) | 388.4 (seam 384) | **+87 px** | +12 |
| village_square well, `player_position` [930, 250] (`camfall_b1d_well_spawn_dense`) | 388.4 | **+72 px** (lands on the beam at 416; the room stays the square) | +12 |

- The fishing well frame spans x 1368-2008. lake_well ends at 1920, so a strip 88 px wide by 136 px tall at the frame's right is void: flat grey with the backdrop's dithered fringe (`playtests/screenshots/2026-10-10-camera-on-falls/02_fishing_well_one_frame_jump_and_void.png`).
- The square-well frame shows caldera_cistern in the village palette, up to 164 px below the seam, for ~0.13 s before the region cut. The coordinator's target was the old ≤126 px. The frame's right part (x > 1280) is void (`03_square_well_one_frame_jump_and_void.png`).

## Root cause

- The lead is added in `_keep_subject_in_view` (`body.size.y += minf(_fall_lead, ...)`) whenever `_reach` allows it.
- `_reach_for` builds one rect from two sources: the body-touch merge, with no region or width test, and the FallReach strip, which has both.
- Once the body touches the room below, the first source already admits that room, so the second test is bypassed.

## Fix

Not fixed. Options:
- Keep the lead out of the body-touch reach. Game passes the camera two rects (body reach and fall reach), and the lead is clamped only against the fall reach.
- Or zero the lead in the kept rect whenever `FallReach.of` returned an empty rect this frame.

## Prevention

In camera_test, add a room A, then a room B below it that is narrower than the frame or in another region. Drop a subject at full speed until its body straddles the seam. Assert that the frame's per-step vertical change never exceeds the subject's step plus a few px, and that no frame pixel below A lies outside B.
