---
id: playtests/2026-10-30-grd05-fight-wall
type: playtest
title: GRD-05 - the wall of grey holds Ivo inside the Frost arena once the fight is on
status: active
build: bcdd2ad + uncommitted GRD-05 working tree (fight_wall, room_legend, four arena rooms)
area_tested: "frozen_lake/lake_frost_arena (Frost, Ivo from 5130): fight start, a walk to each exit"
tags: [guardians, grd-05, arena, fight-wall, playtest]
related: [systems/guardians, systems/rooms]
created: 2026-10-30
updated: 2026-10-30
screenshots:
  - playtests/screenshots/2026-10-30-grd05-fight-wall/first_look_run.png
  - playtests/screenshots/2026-10-30-grd05-fight-wall/fight_wall_holds_ivo.png
---

## What was tested

`tools/playtest/scripts/grd05_fight_wall.json`: Ivo starts 150 px from the golem, the fight begins, he runs west for
4.5 s, then east.

## Results

- **West: PASS.** The wall is closed when he reaches the doorway (col 0) and he stands against it for 1 s.
- **East: not reached.** The golem stands between him and the east wall, and its swings killed him on the way (no god
  mode). That is the fight, not the wall; `fight_wall_test` covers the closing logic for every side.
- **Look, first build: FAIL.** A dense curtain with a Bayer edge read as a dotted stone pillar
  (`first_look_run.png`, top row). **Second build: PASS.** A veil of grey art pixels drawn by chance (70% in the
  middle, thinning over 10 px to each side), re-rolled every 0.25 s of `greyhush_time`: the world shows through, and
  two shots 1 s apart differ (`fight_wall_holds_ivo.png`).

## What screenshots cannot show

The re-roll reads as a shimmer at 4 Hz, the same beat as the corruption edge.
