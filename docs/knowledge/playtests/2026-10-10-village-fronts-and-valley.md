---
id: playtests/2026-10-10-village-fronts-and-valley
type: playtest
title: Village fronts and the valley backdrop - every street door stands in its building, the valley recedes behind the play plane
status: active
tags: [world-11, props, facades, backdrops, playtest]
related: [systems/props, systems/backdrops]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/environment/props/village/
  - resources/world/backdrops/village_valley.tres
---

## Summary

WORLD-11 (fronts and backdrop) in the real game (windowed, `tools/playtest`, one-step timelines at six street positions), spring, the village's memory 0.8.

- **Fronts** (`00_board.png`): Ivo's house, the bell tower, the tavern and the elder's house in the square; the bakery and the empty house in the lane. Each door sits in its doorway recess; the new no-outline door matches the fronts. The tavern clears the well (its door moved to col 38). Ivo draws in front of the fronts, the bench in front of Ivo's house.
- **Valley** (`00_board.png`): stepped sky with flat clouds, snowy mountains, hills with fields, a near tree line, all 2x. No seam is visible in any frame.
- **Contrast** (`01_contrast_compare.png`): before, 45/35/22 and 50/42/32 percent atmospheric depth. The strongest keeps the drawing and puts the backdrop clearly behind the buildings and Ivo; it shipped.
- **Approval**: fronts "Approve as shown (Recommended)"; backdrop "They're perfect. It just doesn't have a lot of contrast with the character..." (user, 2026-10-10), answered by the depth.

## What screenshots cannot show

- Parallax in motion was not recorded; the layers use the same model as every set (`backdrop_test`).
- Autumn and winter bands were checked as sheets, not in the game (the village is spring).
- The mill road (panel 6) has no buildings yet; its stone trail floats against the sky, which is the room's design, not this change.
