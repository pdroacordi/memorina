---
id: bugs/region-tops-allowance-ignores-a-wall-climb-onto-the-gate-east-pillar
type: bug
title: The REGION_TOPS allowance over village_gate_east / threshold_fields assumes a double jump from the floor; a wall climb onto the seam pillar lets the frame show the valley's mountains cut beside the threshold's sky
status: resolved
severity: low
tags: [backdrop, room-ring, seam, hard-cut, world-30, allowlist, wall-climb, region-border]
related: [bugs/a-wall-climb-over-the-seam-pillar-shows-the-wall-up-cut-in-the-sky, systems/backdrops, architecture/backdrop-seams]
created: 2026-10-13
updated: 2026-10-14
source_files:
  - tests/scenes/world/environment/backdrop/backdrop_seams_test.gd
  - scenes/world/rooms/home_village/contents/village_gate_east.room
  - scenes/world/rooms/threshold/contents/threshold_fields.room
  - assets/sprites/world/background/village_valley/mountains.png
  - scenes/world/camera.gd
  - scenes/world/environment/props/village/gate_tower.tscn
  - assets/sprites/world/props/village/gate_tower.png
---

## Summary

Found in the WORLD-07/WORLD-30 review (uncommitted, 2026-10-13); worked out by arithmetic, not yet confirmed in play.
`backdrop_seams_test.ALLOWED["threshold_fields|village_gate_east ring: x 4480, y -160..0"]` is `REGION_TOPS`: "the
highest floor near the seam lets a double jump raise the frame about 100 px over the tops at most, and there both sets
draw only the shared sky". The reason only considers a double jump from the floor. With `WALL_CLIMB`, Ivo can stand on
the two-cell pillar over the passage. A jump from there takes the frame to the ring limit, and the village valley's
mountains rise above y 0 at the seam while the threshold's far layer does not. This is the failure class of
`bugs/a-wall-climb-over-the-seam-pillar-shows-the-wall-up-cut-in-the-sky`.

## Symptom

Expected, not yet seen in a still. Ivo stands on the pillar top (village_gate_east col 39 + threshold_fields col 0,
rows 0-4, top y 0) and jumps. For a moment a straight vertical edge stands at x 4480 between y 0 and about y -30: the
valley's mountain silhouette stops on one side, and the threshold's plain sky is on the other.

## Root cause

- The pillar's faces (y 0..160) hang over a 128 px passage. A 143 px jump from the floor (y 288) reaches the face, and
  `WALL_CLIMB`'s slide-and-jump chain climbs over the top, as at the fishing village pillar.
- Over the tops, `RoomExit` keeps the current room and `GameCamera._keep_subject_in_view` yields toward the body plus
  `subject_margin` (8 px) up to `_reach` (the ring, y -160). A jump from y 0 puts the body top near y -190, so the frame
  top reaches -160.
- Layer row r lands at world y = horizon + (r - horizon_row) + (T - T0)(1 - scroll_y), with horizon 235 and T0 44 (both
  regions). At T = -160 and camera centre x 4420..4540, `village_valley/mountains.png` (scroll 0.12, 0.07) has its top
  row at the seam column at world y -10 to -32. `threshold/far.png` has no row above 196 in any column, so it starts at
  y +12 or lower. Below y 0 the pillar hides both.
- frost_shore / threshold_wayshrine (x 8320) does not have this problem: no layer of either set reaches above y 0 at
  T -160 in any column, so that `REGION_TOPS` holds.

## Fix

See "Fix (2026-10-13)" below. The options weighed first: Options:
- Play it first: a timeline with `[DOUBLE_JUMP, WALL_CLIMB]` that climbs the gate_east pillar and jumps from its top,
  shooting at the apex. If the edge shows, either:
  - ask the user whether this line is covered by "OK until skies match (Recommended)" and record the answer, rewording
    `REGION_TOPS` for this key to say that a climb shows it; or
  - lower the mountains in `village_valley` (not wanted: the valley's look is approved), or give the tops over the
    border one set (the WORLD-28 `OVER_TOP` approach applied across regions).

## Prevention

The prevention from the WORLD-28 bug still applies. Check a ring allowance whose reason depends on frame reach with every
traversal ability the player can have there. A seam pillar with a free face is a floor once Ivo has `WALL_CLIMB`.

## Fix (2026-10-13)

User: "Cover with a tall gate tower (Recommended)" ("Draw each border gatehouse a little taller (a tower or roof peak above the seam) so the cut stays hidden behind it, the same way other seams hide behind stone."). A village gate tower prop (`gate_tower.tscn`, 80x198 px, Codex from our bell tower and tavern fronts, cut by `tools/art/cut_single_prop.py`) stands on each village border pillar: village_lane_west (local x 0) and village_gate_east (local x 1280), its bottom 16 px behind the pillar's top tiles. Its shaft is the pillar's 64 px, and its roof point sits on the seam column up to 178 px over the tops. Played with `[DOUBLE_JUMP, WALL_CLIMB]`: climbing the west face of both pillars, standing on the top and double jumping from it (and from the lane's gatehouse roof) caps the frame at the ring (camera centre y 20, frame top -160). Ivo leaves the frame top, and the tower stands at the frame's edge over the seam (stills `scratchpad/wire/towers/`, `c_towers.png`). `backdrop_seams_test` lists both keys as `GATE_TOWER`, and `test_a_gate_tower_covers_its_cut` checks that the tower's pixels cover one side of the seam at every height of the cut. frost_shore/threshold_wayshrine keeps `REGION_TOPS`, now checked by arithmetic at the ring limit (`test_a_region_tops_cut_shows_only_the_shared_sky`; with the gate_east pair added it fails at y -10, the value worked out above).

**WORLD-34 (2026-10-14):** the pillar's top is outside every room, so a slab sits flush on it. The sky band's side over the pillar is an edge wall, and an edge wall is never gripped. A wall climb therefore ends at the pillar's top and cannot get over it (by construction, `architecture/world-edges-from-the-room-list`; not re-shot).
