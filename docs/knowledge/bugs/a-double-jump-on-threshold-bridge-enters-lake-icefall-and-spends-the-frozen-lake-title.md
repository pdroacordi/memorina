---
id: bugs/a-double-jump-on-threshold-bridge-enters-lake-icefall-and-spends-the-frozen-lake-title
type: bug
title: A double jump on threshold_bridge's east deck lands on lake_icefall's one-way lip, swaps to the Frozen Lake region and spends its first-visit title above the Threshold
status: resolved
severity: medium
tags: [world-35, rooms, region-title, threshold, frozen-lake, double-jump, room-exit, camera]
related: [systems/world, systems/rooms, systems/region-title, gotchas/a-room-stacked-over-a-gap-clips-the-running-jump, playtests/2026-10-14-world35-step3]
created: 2026-10-14
updated: 2026-10-15
source_files:
  - scenes/world/rooms/frozen_lake/contents/lake_icefall.room
  - scenes/world/rooms/threshold/contents/threshold_bridge.room
  - scenes/world/rooms/room_exit.gd
  - scenes/ui/region_title/region_title_watcher.gd
---

## Summary

WORLD-35 step 3 (uncommitted, on a665105). lake_icefall (frozen_lake region) sits on threshold_bridge, and its
bottom row over bridge cols 22-26 is a one-way lip at y -32. A player with only the double jump (Woods first, no
Memorina) double-jumps on the bridge's east deck, rises through the lip, lands on it and is in lake_icefall. The
"Frozen Lake" title plays over a rock shaft above the Threshold, and it is recorded, so the real first arrival at
the lake gets no title.

## Symptom

Scratch timeline (review, 2026-10-14): save with `skills [0]` (double jump) and only the threshold announced;
Ivo at (7200, 158) on the east deck; jump, release, jump again.

| t | pos | room | camera bounds | title |
|---|---|---|---|---|
| 1.0 | (7200, 160) | threshold_bridge | (6400, 0, 1280x384) | none, announced=1 |
| 2.6 | (7200, -32) | lake_icefall | (7040, -1920, 640x1920) | 'Frozen Lake' alpha 0.37, announced=2 |
| 3.6 | (7200, -32) | lake_icefall | same | alpha 1.0 |

The playtest report's `e_dj_peek` saw the landing on the lip but not the region swap or the title.

## Root cause

- `RoomExit.has_left` lets Ivo leave a room upward once he stands, or once his feet are 64 px over its top. The
  double jump's apex from the deck is feet y about -109, and the lip is a floor at -32, so he leaves
  threshold_bridge and `Game` enters lake_icefall.
- `RegionTitleWatcher.on_room_changed` announces any region on its first room, so the icefall's bottom screen
  announces the whole lake.
- The lip is one-way because a solid cell there clips the base running jump over the gap
  (`gotchas/a-room-stacked-over-a-gap-clips-the-running-jump`), so the double jump passes through it upward.

## Fix

Resolved 2026-10-15 (WORLD-35 step 3 redesign, after the user's "Straight drop into deep snow (Recommended)").
- lake_icefall ends at y -384 (c 11, r -5..-2). The icefall's last screen is a threshold room, `threshold_icefall_foot`
  (c 11, r -1), so a room swap from threshold_bridge stays in the Threshold region and spends no title.
- The highest floor under it is the east deck (y 160). A double jump plus a Redoma shell reaches feet y -302, 146 px
  short of the -448 that would leave for lake_icefall.
- The foot room is rock over the east deck from y -96 up. A double jump there stops with its feet at y -42, short of
  the 64 px that swaps rooms, so the deck's jumps stay in threshold_bridge. Only a jump into the shaft's 2-cell mouth
  over the span enters the foot room, a same-region glide.
- Measured: `world35s3_e_dj_peek`. The double jump's highest feet are y -42, the room stays threshold_bridge, and no
  title plays.

## Prevention

A stacked room in another region over a walkable room is a region entry wherever its bottom can be stood on.
Check the double jump's apex (269 px) from every floor under it, not only the single jump.
