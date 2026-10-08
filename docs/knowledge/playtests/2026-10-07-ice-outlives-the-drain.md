---
id: playtests/2026-10-07-ice-outlives-the-drain
type: playtest
title: PZL-02 - the moat's ice is its own sheet; the water drains under it while the thaw comes from the origin
status: active
build: a0d9aaf + uncommitted PZL-02 (ice as its own sheet)
area_tested: "Spring trial puzzle 2, the dry moat (Combinado 1), trials_spring at world x 7200"
tags: [congelar, chuva, ice, rain-basin, combinado-1, pzl-02]
related: [architecture/ice-is-its-own-sheet, playtests/2026-09-30-chuva-basin-and-moat, systems/water]
created: 2026-10-07
updated: 2026-10-07
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-07-ice-outlives-the-drain/crossing_on_the_sheet_16.20.png
  - screenshots/2026-10-07-ice-outlives-the-drain/shelf_over_sinking_water_22.00.png
  - screenshots/2026-10-07-ice-outlives-the-drain/drained_and_thawed_26.00.png
---

## Summary

Run by the orchestrator, not the playtester agent. The 2026-09-30 crossing still works on the new
ice: `song_rain_freeze_moat.json` (Chuva, Congelar at the edge, walk across) ends with Ivo on the
far bank. The new `song_rain_freeze_moat_drain.json` plays the same songs and watches: once the
rain's pulse leaves, the water sinks under the ice, which stays at the height it froze at, while
the thaw eats it from the origin. The two clocks of Combinado 1 are visible.

## What was seen

Screenshots were renamed from the runs' `cross_16.20` (moat timeline) and `drain_22.00` / `drain_26.00` (drain timeline).


- Crossing (t 16.2): the ice band is drawn by the sheet above the water, with crystals still
  stippling in at the front.
- t 22: the ice near the origin has thawed; a shelf remains at the far end at its frozen height,
  over water that has dropped well below it.
- t 26: the moat is dry and the ice gone. No fall was driven; the moat is climbable (spring_trial_test).

## What this cannot judge

Whether a first-time player reads the shelf over sinking water as ice holding, and how the race
against both clocks feels by hand.
