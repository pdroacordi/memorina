---
id: playtests/2026-11-16-world46-garden-cliff
type: playtest
title: WORLD-46 - Ivo stops at the garden's drawn cliff, and the cliff covers the new stone at every height
status: active
build: uncommitted WORLD-46 change over fad101c7 (imported before each run)
area_tested: "tools/playtest/scripts/world46_garden_cliff.json: village_garden from (4180, -530), sword only (so flashback 1 is not due and nothing takes him), run right into the cliff, then the whole room at zoom 0.5."
tags: [world-46, rooms, props, garden, collision, playtest]
related: [systems/props, systems/rooms, architecture/story-05-playable-flashbacks]
created: 2026-11-16
updated: 2026-11-16
ratings: { fun: 0, fluidity: 0, aesthetics: 0 }
screenshots:
  - screenshots/2026-11-16-world46-garden-cliff/01_against_the_cliff.png
  - screenshots/2026-11-16-world46-garden-cliff/04_whole_cliff.png
---

# WORLD-46: the garden's cliff

The user's screenshot (2026-11-16) showed Ivo standing in front of the mossy rock by the waterfall, over the lake: "tá podendo flutuar na rocha". The room's stone began at col 36 (x 1152) while the drawn cliff (`falls_cliff`, x 1068..1280) begins at about x 1088 at the bank's height, so the bank's floor ran 64 px in front of the rock.

## What the run shows

- Running right, Ivo stops at x 1077 local (his body's edge at the cliff, x 1088), feet on the bank (y 640), `blocked=false` (`01_against_the_cliff`).
- The first run of the new stone showed village stone bricks between rows 12 and 16, where the upper and lower cliff copies recede (x 1112-1136). A third copy, `FallsCliffMid` at y 540, covers them; rows 0-3 of cols 34-35 stay air, since the high copy recedes there too and nothing reaches that height (16 cells over the bank).
- At zoom 0.5 (flashback 5's widest frame) the whole cliff reads as one rock face, no brick showing (`04_whole_cliff`).

## Cannot be judged from frames

- Whether the third copy's repeat of the same rock texture reads as a pattern in motion, in colour (the run was in the grey; memory 0 in this save).
- The past twin (`garden_past`) was not run; its grid and `Falls` group equal the present's (`garden_twin_test`).
