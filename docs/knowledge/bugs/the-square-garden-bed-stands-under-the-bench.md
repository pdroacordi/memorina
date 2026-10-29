---
id: bugs/the-square-garden-bed-stands-under-the-bench
type: bug
title: The village square's garden bed stands under the bench, so its replanting is almost invisible
status: resolved
severity: low
tags: [life-04, gardens, replant, props, village, bench, layout]
related: [systems/seeds-and-the-seller, architecture/season-seeds-and-the-seller, systems/props, playtests/2026-10-28-life04-seeds-and-seller]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - scenes/world/rooms/home_village/contents/village_square_contents.tscn
  - scenes/world/rooms/home_village/contents/village_square.room
---

## Summary

ACTIVE (LIFE-04 playtest, 2026-10-28). `Props/Gardens` in `village_square_contents.tscn` sits at x 380, floor y 288. The square's save bench is the entity at col 12 (`village_square_bench`, x 384..416). The bench art covers the bed, so after "Replant the village" (3 seeds, the dearest offer) the square shows only a 1-2 px green line under the bench seat. The other three beds read clearly.

## Symptom

1. Run `tools/playtest/scripts/life04_gardens_replanted.json`, then `life04_gardens_bare.json` (the same timeline with no `bought`).
2. Frame `02_square_bed` (Ivo at x 430): the bare bed is hidden under the bench. With the planted bed, a thin dark green strip shows under the seat, and the crowns and yellow buds are not seen at all.
3. Lane west (x 290 local, -990 world), mill (x 700) and gate east (x 1000): the planted bed shows its full row of green crowns and yellow buds against open ground. Evidence: `playtests/screenshots/2026-10-28-life04-seeds-and-seller/garden_beds_bare_vs_replanted_zoom.png`, the second column, bare on top and replanted below.

## Root cause

The bed's x (380) was picked without checking the room's entities. `village_square.room` row 8 has `R` at col 12, the bench (`12,8 = {"bench_id": "village_square_bench"}`), which spans x 384..416. The bed is 48 px wide, centred on 380, so it spans x 356..404 and lies under the bench sprite, which draws in front of it.

## Fix

Not fixed. Move `Props/Gardens` in `village_square_contents.tscn` to open ground away from the bench, doors (cols 8, 15, 20, 38, 50) and the talk at col 18. Cols 22-25 (x 704..832, before the pit) look free in the grid. Check it in a frame next to the bare one.

## Prevention

Before placing a prop that carries a visible reward, read the room's `[entities]` and grid row and keep it clear of benches, doors, talks and pickups. The props contract does not forbid an overlap; for a reward the player paid for, compare bare and replanted frames.

## Resolution (2026-10-28)

`Props/Gardens` moved to x 1504, the open street between the lantern post (1438) and the elder's house; the planted bed shows whole in a frame at Ivo x 1560. `life04_gardens_replanted.json` teleports there.
