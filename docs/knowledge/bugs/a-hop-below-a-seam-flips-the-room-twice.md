---
id: bugs/a-hop-below-a-seam-flips-the-room-twice
type: bug
title: With the body-centre room point, a hop from a floor just below a seam enters the room above and returns on landing; on the mill slab each hop cuts to the Frozen Lake and back
status: resolved
severity: medium
tags: [rooms, seam, camera, region, cut, glide, world-05, feel]
related: [playtests/2026-10-09-traversal-woods-lake, bugs/crossing-a-seam-upward-takes-ivo-out-of-the-frame, bugs/walking-across-a-room-seam-fades-back-and-forth, systems/rooms]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/game.gd
  - scenes/world/rooms/home_village/contents/village_mill.room
---

## Summary

`Game` now makes current the room that holds Ivo's body centre (feet - 27). On a floor less than 27 px +
a hop's height below a horizontal seam, any jump carries the centre across the seam, and the landing
brings it back.
- Across a region seam that is two one-frame cuts: the camera snaps, and the baseline, season and palette
  change.
- Inside a region it would be two glides, there and back.

village_mill's slab is such a floor. It is the stepping stone into the Frozen Lake (y 32, 32 px under the
seam at y 0), so the centre stands 5 px below the seam.

## Symptom

Uncommitted tree, imported 23:58:40.

**Hops in place** (`tools/playtest/scripts/traverse_woods_lake_s1_rv2_mill_slab_hop_in_place.json`). Ivo
stands on the slab at (2800, 32); one 0.2 s hop, then one 0.45 s hop:

```
t=1.01 feet 32.0    room=village_mill         cam_centre (2880, 180)
t=1.06 feet 8.1     room=lake_waterfall_path  cam_centre (2880,-180)   cut to the lake (winter palette)
t=1.51 feet -69.4   (peak of the 0.2 s hop)
t=2.03 feet 32.0    room=lake_waterfall_path  visible 0.41
t=2.05 feet 32.0    room=village_mill         cam_centre (2880, 180)   cut back to the village
t=2.26 ... the 0.45 s hop repeats both cuts (t 2.26 and 3.31)
```

Frames: `playtests/screenshots/2026-10-09-traversal-woods-lake/rv2_mill_slab_hop_flips_to_the_lake.png`
(s1.00 village, s1.10 lake, s1.95 lake, s2.10 village).

**On the main path:** `traverse_woods_lake_k2_mill_floor_trail_slab_stub.json`. The jump from the trail
(y 160) onto the slab peaks at feet 16.3. That is never above the seam under the old feet rule, but now it
is lake_waterfall_path from t 3.90 to 4.30 (two cuts). While the lake's frame is shown he is only 54-70%
visible, because the lake's camera view ends at y 0.

## Impact

- Every hop on the slab, and the normal jump onto it, flashes the whole screen to the Frozen Lake and back
  in under a second. This is on the only route into the lake.
- Any in-region floor within ~27 px + hop height of a seam would make the camera glide away and back on
  every hop.

## Fix

Not fixed. Options for the implementer:
- Hysteresis: leave the current room only when the point is some margin past the seam (half the capsule
  height, for example), or when Ivo is grounded in the new room or has crossed a full body height.
- Or keep the body-centre rule for side seams and use the feet for horizontal seams going up, with the
  ease-out glide handling the framing.
- Or author floors at least a body height below a horizontal seam (the slab would move to y ≥ 64), and add
  a `room_files_test` check for it.

## Prevention

A test that stands a body on a floor 32 px below a seam, hops in place, and asserts no `room_changed`.

## Resolution (2026-10-10)

`Game` keeps the current room while its bounds intersect `Player.body_rect()`, and only then enters the room
under the body centre (hysteresis of a full body). `GameCamera._keep_subject_in_view` lets the frame leave the
room's bounds to keep the body plus 8 px on screen. Re-checked on the uncommitted tree, imported 00:12:13
(`playtests/2026-10-09-traversal-woods-lake`, re-check of the hop flip):
- **Hops on the slab after arriving from the trail** (`tools/playtest/scripts/traverse_woods_lake_s3_rv3_mill_trail_to_slab_then_hops.json`,
  taps of 0.05/0.1/0.2 s and jumps of 0.45/0.8 s):
  - The trail → slab jump (peak feet 18.2) stays in the mill.
  - Even the 0.05 s tap lifts the whole body above y 0, so the first hop cuts once to the lake.
  - Landing on the slab keeps the lake, and the later hops cause no cuts.
- **Back down** (`..._s5_rv3_slab_hop_then_walk_off_east.json`): one cut back to the mill at feet 61.9, as he
  walks off the slab to the trail.
- **The route** (`..._k2_mill_floor_trail_slab_stub.json`): one room change, on the stub jump.

What remains (by design):
- After any hop the slab shows in lake_waterfall_path's frame (centre y -140) and winter palette, with about
  8 px of the slab under Ivo, until he leaves it downward.
- Frames: `playtests/screenshots/2026-10-09-traversal-woods-lake/rv3_mill_slab_hop_one_cut_then_lake.png`.
