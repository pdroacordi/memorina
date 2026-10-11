---
id: bugs/world-25-re-pointed-timelines-no-longer-test-their-scenario
type: bug
title: WORLD-25 moved six playtest timelines' start positions onto ground but kept their inputs; c2 now ends in the dry basin, and rv4_s1 and rv_n2 never rise above the open top their bugs need
status: resolved
severity: medium
tags: [playtest, timelines, world-25, regression-coverage, spring-woods, wind-orchards]
related: [playtests/2026-10-11-world25-rework, bugs/the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top, bugs/the-safety-net-fires-when-ivo-drops-across-a-seam-above-two-open-tops, bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top, playtests/2026-10-09-traversal-woods-lake]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - tools/playtest/scripts/traverse_woods_lake_c2_pond_shelf_to_bloom.json
  - tools/playtest/scripts/traverse_woods_lake_rv4_s1_pond_double_jump_into_bloom_hollow.json
  - tools/playtest/scripts/traverse_woods_lake_rv_n2_pond_shelf_double_jump.json
---

## Summary

The rework removed the one-ways these timelines started on and moved each `player_position` onto the ground
below. Every new start does stand on ground. But the inputs were timed for the old ledge, so one timeline now
fails its route. Two are regression checks whose scenario is no longer reached.

## Symptom

Worktree agent-a5ca98ed7ee598b83 on 9df7ec6, imports 03:28:52:

- **c2_pond_shelf_to_bloom** (start (-4834, 116), woods_pond's col-28 pillar top, y 128): the first hop releases
  left at t 1.7 for the removed one-way (cols 24-26). Ivo stops at x -4925, falls to the step (y 256), then into the
  dry basin. At t 25.5 he is at (-5299.9, 351.9) in woods_pond, not bloom_hollow. The route itself works: with
  left held, the pillar top to the shelf lands at (-5096.8, 64) (scratch probe), and the east steps to the pillar
  top land at (-4836.5, 128).
- **rv_n2_orchard_well_oneway_double_jump**: start (-3700, -1250), 286 px below orchard_well's open top (-1536).
  A 270 px double jump peaks near -1520. That is below the top, so it never comes `SEAM_MARGIN` (64 px) past it.
  `bugs/the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top` cites this timeline at the old
  start (-3700, -1344, peak -1613.6) as its regression check. The check now passes without exercising anything.
- **rv4_s1_leaf_oneway_double_jump_into_arena**: start (-8700, -1282), on the new step at orchard_leaf_path
  col 8, 254 px below the top. `bugs/the-safety-net-fires-when-ivo-drops-across-a-seam-above-two-open-tops`
  needs "a running double jump west from the row-3 one-way (feet -1440) over the col-0 wall, peak -1707, above
  both open tops". From the new start the peak is near -1550, and the wall is no longer jumped over: rows 5-8
  are open.
- **c3/c4/c5 `pond_oneway_*_probe`**: they probe a one-way that no longer exists. c5 now starts on the step's
  west cell, 3 px from its edge, and walks into the basin.

## Root cause

The re-point checked only that each start stands on ground (`playtest_starts.py` in the rework's scratch). It did
not check what each timeline was for, and it did not re-run them.

## Fix

Options as filed:
- c2: hold left through the first jump (t 1.2 to about 2.6), or start from the east floor. Re-run to bloom_hollow.
- rv_n2 / rv4_s1: pick a floor within about 200 px of an open top, as `rv_n1` does with the leaf-path hill top
  (-8300, -1408). For rv4_s1, the hill top running west. Update the coordinates the two bug files quote.
- c3/c4/c5: delete them, or rename them after what they now probe.

## Prevention

When a rework removes a timeline's start surface, grep `docs/knowledge/` for the timeline name before moving
it. If a bug or playtest cites it, the scenario (height above a seam, ledge under test) must survive the move.

## Playtest note (2026-10-11, `playtests/2026-10-11-world25-rework`)

`world25_deep_pond_to_bloom.json` replaces c2 for the reworked pond. In one run it walks from woods_deep's east floor over the boulder, the mound, the pond's step, the pillar and the shelf into bloom_hollow. One input differs from the old route: from the step, a jump onto the 1-cell pillar must release left 0.30-0.50 s after the press. Every press of 0.2-0.35 s with left held overshoots into the basin.

## Resolution (2026-10-11)

- **c2** keeps its name: the old release and the one-way hop are gone, left is held from the pillar top (now 2 cells, cols 28-29) through the shelf, and it stops in bloom_hollow before the guardian (max_duration 8). Re-run: shelf at (-5036.3, 64) at t 2.3, bloom_hollow at t 6.2, hp 3.
- **rv_n2** is now `traverse_woods_lake_rv_n2_pond_shelf_double_jump.json`: a straight double jump on woods_pond's rock shelf (feet 64, open top y 0). orchard_well has no floor within 206 px of an open top any more (its east half lies under lake_chasm). Re-run: peak feet -205.6, `fade` 0.00 throughout, lands back at (-5264, 64).
- **rv4_s1** is now `traverse_woods_lake_rv4_s1_pond_double_jump_into_bloom_hollow.json`: a running double jump west from woods_pond's west step (feet 160) over the col-0 wall into bloom_hollow, crossing the seam (x -5760) at feet about -110, above both open tops. orchard_leaf_path has no floor near its col-0 seam within reach. Re-run: peak -109.6, `fade` 0.00, lands in bloom_hollow at (-5954.2, 288).
- **c3/c4/c5** are deleted.
- The two safety-net bug files note the new timelines.
