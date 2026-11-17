---
id: playtests/2026-11-17-world45-cliff-buttresses
type: playtest
title: WORLD-45 - the frost_cliffs ledges as rock buttresses
status: active
build: uncommitted WORLD-45 change over f548cc9d
area_tested: "frost_cliffs at zoom 0.5 from (10200, -80) and (10100, -620); reach boards (tools/maps/reach_boards.tscn) for the room."
tags: [world-45, rooms, frost-edge, level-design, playtest]
related: [systems/rooms]
created: 2026-11-17
updated: 2026-11-17
ratings: { fun: 0, fluidity: 0, aesthetics: 0 }
screenshots:
  - screenshots/2026-11-17-world45-cliff-buttresses/low.png
  - screenshots/2026-11-17-world45-cliff-buttresses/high.png
---

# WORLD-45: the climb to the lighthouse

- Each ledge now has rock under it, stepping back to its wall over two rows (5 cells, then 2, under a west ledge; 4, then 2, under an east one), so it reads as an outcrop of the cliff, not a shelf in the air (`low`, `high`).
- The floor east of the block (cols 21-29, rows 42-44) is rock level with the block: the climb starts from rising ground.
- The buttress under the row-36 ledge stops at row 37, so the secret niche's mouth (cols 13-14, row 38) stays open; a first try closed it and the audit reported NO_WAY_BACK at 9,39.
- The reach board for frost_cliffs is clean (no warning: the old floor pocket is filled).

## What it does not fix

- The climb is still a regular zigzag, every 3 rows. A first attempt with switchback stair buttresses failed the audit: one-row hops under an overhang have no headroom (`UNREACHABLE` from 28,10 up). A different route is a design pass to agree with the user.
