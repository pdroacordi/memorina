---
id: playtests/2026-10-10-flat-village-and-wells
type: playtest
title: Flat village and held water - the square without sky ledges, the bell tower behind its door, and the three wells' flooded passages into sealed chambers
status: active
tags: [world-20, water, redoma, playtest, level-design]
related: [systems/world, systems/water, bugs/well-water-stands-in-the-air-at-a-passage-mouth, bugs/pool-caustics-hang-from-the-waterline-like-drips]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - tools/playtest/scripts/village_flat_street_and_tower.json
  - tools/playtest/scripts/song_bell_jar_well_chamber.json
  - tools/playtest/scripts/caldera_cistern_redoma_chamber_door.json
  - tools/playtest/scripts/caldera_cistern_redoma_back_up.json
  - tools/playtest/scripts/lake_well_redoma_chamber.json
---

## Summary

WORLD-20 and the held-water fix, in the real game (windowed, `tools/playtest`). Every route reached its end at 3 HP.

- **The square** (`01_square_flat.png`): one street at ground level; the well between its two pillars is the only
  opening. Up at col 20 takes Ivo into the bell tower interior (x 9744, y 13056; `02_bell_tower_interior.png`) and back.
- **Winter trial well** (`03_trial_chamber_water_back.png`): Redoma at the edge, down the dry side, west under the wall
  and up the hole into the sealed chamber. After the shell is gone, the passage refills up to the chamber's floor. It
  shows a flat waterline under the trapped air, and the chamber stays dry.
- **Caldera cistern:**
  - Down: Redoma at the slab's east edge, drop onto the stepped pool floor (y 800, inside the shell:
    `04_cistern_pool_floor_in_shell.png`), west through the passage, up into the chamber, then the door to
    `caldera_cistern_bottom` (944, 1728).
  - Back: Redoma in the chamber, down the hole, east to the pool floor, the step at col 14, then the slab (1041, 640).
    No double jump is needed.
- **Lake well** (`05_lake_well_chamber.png`): Redoma from the floor at col 15, down the dry well, west and up into the
  chamber (y -1248). From the old block at row 5, the well floor lay exactly at the shell's 192 px edge and Ivo sank.
  The water is now one row lower.

## What screenshots cannot show

- **The shell holds water only after it closes,** about 0.8 s after its ring appears. A timeline that walked into the
  hole while the ring was still growing sank, so the first try at the climb back failed. A player waits for the ring
  anyway, but a hurried player can fall in this way.
- The chambers show the room's sky backdrop through the rock (no cave backdrop yet: WORLD-22), and the cistern's
  chamber is plainly visible from the slab until WORLD-21's false walls hide it.

## Not covered

- The mill's plank stairs and the tower's climb to its alcove were checked by reach arithmetic in review, not played.
- The `traverse_orchards_caldera_*` cistern and fishing-well scripts describe the old layouts and are stale.
