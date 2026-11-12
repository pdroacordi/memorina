---
id: playtests/2026-11-12-story05-garden-fixes
type: playtest
title: STORY-05 garden fixed - the mountain nests again at zoom 0.5, a soft lantern pool, a calmer late afternoon, Alba and Ivo under one moon, a thinner bank
status: active
build: 88917d5f + uncommitted garden fixes
area_tested: "garden_past and village_garden at the five times, zoom 1 and 0.5 (story05_garden_look_<n>.json, now ending on a zoom 0.5 frame); flashbacks 3, 4 and 5 end to end (story05_flashback_<n>.json), flashback 5's hidden swap by pixel diff."
tags: [story-05, flashback, garden, backdrop, lantern, light2d, canvas-modulate, lake, playtest]
related: [playtests/2026-11-12-story05-garden-rebuilt, architecture/story-05-playable-flashbacks, systems/backdrops, systems/water, systems/props, systems/cutscenes]
created: 2026-11-12
updated: 2026-11-12
ratings: { fun: 0, fluidity: 3, aesthetics: 4 }
screenshots:
  - 2026-11-12-story05-garden-fixes/f5_widest_before.png
  - 2026-11-12-story05-garden-fixes/f5_widest.png
  - 2026-11-12-story05-garden-fixes/f5_gap.png
  - 2026-11-12-story05-garden-fixes/t5_twilight_wide.png
  - 2026-11-12-story05-garden-fixes/t4_night.png
  - 2026-11-12-story05-garden-fixes/t4_night_wide.png
  - 2026-11-12-story05-garden-fixes/f4_for_you.png
  - 2026-11-12-story05-garden-fixes/t3_afternoon.png
  - 2026-11-12-story05-garden-fixes/t3_afternoon_wide.png
  - 2026-11-12-story05-garden-fixes/f3_push.png
  - 2026-11-12-story05-garden-fixes/t1_morning_wide.png
  - 2026-11-12-story05-garden-fixes/f5_swap_before.png
  - 2026-11-12-story05-garden-fixes/f5_swap_after.png
  - 2026-11-12-story05-garden-fixes/f5_swap_diff.png
---

# STORY-05: the garden fixed

The user, on `t4_night`, `f5_widest` and `t3_afternoon` of the rebuild: "Corrige sim. Além disso, na foto mais zoomed out, veja a montanha. ela tá bugada" (2026-11-12). Changes: `architecture/story-05-playable-flashbacks`, "The garden fixed".

## Found

1. **The mountain** (`f5_widest_before`). Shown layer by layer at zoom 0.5: the near layer drew nothing on screen, the mid layer a sliver over the bank, and the far layer's mesas, its forest and its flat EDGE fill filled everything between the sky and the bank, so they read as one flat-topped striped block. Cause: the bank camera stands 788 px over the region's reference camera, so each layer sat 788 x its vertical scroll lower than its authored pose (far 55, mid 142, near 252 px). Fixed by the sets' horizon rows (284, 371, 419): mesas, forest, hills and tree crowns nest at both zooms (`f5_widest`, `t3_afternoon_wide`, `t1_morning_wide`). The afternoon sun was then behind the mesas and moved up (`t3_afternoon`).
2. **The lantern's rings** were the stepped gradient, and it lit the sky. Now a smooth falloff in 2 px texels over 160 px, and no backdrop takes light; the first try (energy 0.85) barely showed on the dark grass, so the flame's energies are 2.6-3.0. It reads as a warm pool on the grass, the post, the stone's edge and the earth line, mirrored by the lake (`t4_night`). In flashback 5 the additive afterglow took the light and drew a halo over the backdrop: the sun, moon and afterglow rects have `light_mask` 0 (`f5_widest`).
3. **The afternoon** was the multiply (1, 0.88, 0.72) plus a 0.36 additive sun glow: now (1, 0.96, 0.9) and 0.12. Greens and Alba's dress keep their colour (`f3_push`, `t3_afternoon`); the lantern by day is a small faint spot (strength 0.12, 64 px).
4. **Alba grey at night**: the moonlight was a multiply rect in the root canvas; Alba's figures draw there, Ivo in the creature pass, so only she was darkened and blued. The grades are now `CanvasModulate`s, which tint the world canvas the creature pass shares: both read cool and in colour (`t4_night`). In the "For you." close shot Ivo is warmer than her only where the lantern reaches him (`f4_for_you`).
5. **The bank**: the lake rises 22 px over its painted top (`lake_rise`), so 4 px of earth show under the grass lip and the reflections start at the characters' feet (`t4_night`, `f3_push`). The fall now ends at the waterline under the foam.

## The hidden swap

`f5_swap_diff` (channel sum over 15, the last present frame against the first past frame): 5.3% of pixels, against 8.3% between two consecutive past frames; only the fall's phase, Ivo's idle frame, the lake's glints and bands and a few motes change. Sky, layers, ground, grass, grade and the lantern's pool are equal.

## What does not read

- The sky's six flat steps show as stripes over the mesas at zoom 0.5; they are the sky's drawn style everywhere and were not changed.
- The near layer's trunk feet show for a few px over the bank at zoom 0.5.
- Feel and sound are not judged from frames.
