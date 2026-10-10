---
id: bugs/well-water-stands-in-the-air-at-a-passage-mouth
type: bug
title: In every "bottom of the well" room the pool stands as a vertical wall of water beside the open passage mouth, two rows high, with nothing holding it
status: resolved
severity: medium
tags: [water, level-design, redoma, puzzle, physics]
related: [systems/water, systems/bell-jar, bugs/pool-caustics-hang-from-the-waterline-like-drips]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/summer_caldera/contents/caldera_cistern.room
  - scenes/world/rooms/frozen_lake/contents/lake_well.room
  - scenes/world/rooms/trials_winter/contents/winter_trial.room
---

## Summary

The user (2026-10-10, on a screenshot of the cistern): "the water (such as in the image) is beheaving sort of weird".
Design 02 section 8, Inverno Espacial 2, puts "a low passage in the bottom wall" of a full well. All three rooms
built from it paint the pool right up to the passage's open mouth:
- `caldera_cistern`: col 12, rows 11-12;
- `lake_well`: col 16, rows 7-8;
- `winter_trial`: col 20, rows 19-20.

`WaterBasins` sees a column of water and draws it, so the water ends in a flat face beside open air, held by
nothing. Real water would flood the passage.

A scan of every `.room` (pool `~`/`f` cells with air beside or below them that is not water) finds exactly these three.

## Fix (2026-10-10)

- **Covered water.** A pool can fill a passage under the ground: a covered column draws deep water with no
  waterline, clipped under its ceiling. The Redoma's disc dries it like any other water.
- **Re-authored rooms.** The passage is flooded up to the waterline, then climbs above it into a dry chamber.
  - The cistern's passage climbs over a crest before its shaft drops to the caldera, so the cistern does not drain.
  - The Redoma's 192 px disc must cover the flooded part of the passage, so that part stays within about 5 cells of the play point.
- **An import check.** Pool water with air beside it or below it is an error.

## As built

- **Covered columns and sealed pockets** (`systems/water`, "Water must be held"). The parser rejects any other air beside, under, or above held water.
- **The three rooms.** Each is now a flooded U-passage into a sealed chamber.
  - **`winter_trial`:** chamber cols 15-17, rows 17-18.
  - **`lake_well`:** chamber sealed at col 15. Its water is one row lower, and Redoma is played from the floor at col 15, because from the block the well floor lay exactly at the 192 px edge.
  - **`caldera_cistern`:** the chamber's door replaces the open shaft to `caldera_cistern_bottom`.
- **Playtests** (2026-10-10, all at 3 HP):
  - `song_bell_jar_well_chamber.json`, `lake_well_redoma_chamber.json` and `caldera_cistern_redoma_chamber_door.json` reach the chamber dry, and Ivo stays dry after the water returns.
  - `caldera_cistern_redoma_back_up.json` climbs back to the slab without a double jump.
- **Timing.** The shell holds water out only once it closes, after its 0.8 s growth, not while its ring grows. A timeline that walks in sooner sinks.
