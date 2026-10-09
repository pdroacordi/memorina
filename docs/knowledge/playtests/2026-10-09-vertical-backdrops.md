---
id: playtests/2026-10-09-vertical-backdrops
type: playtest
title: Vertical backdrops - every trial layer present far from the origin, the sky continues on a peek, layers hold through the Memorina zoom
status: active
tags: [backdrop, parallax, world-06, world-04, playtest]
related: [systems/backdrops, architecture/vertical-backdrops, gotchas/parallax2d-ignores-its-parents-offset]
created: 2026-10-09
updated: 2026-10-09
source_files:
  - tools/playtest/scripts/backdrop_trials.json
  - tools/playtest/scripts/backdrop_cliffs.json
---

## Summary

WORLD-06 in the real game (windowed, `tools/playtest`), two timelines. Contact sheet:
`screenshots/2026-10-09-vertical-backdrops/contact_sheet.png`.

- **The spring trial (region x 7200)** shows all five pine-woods layers, the far mountains
  included. Before WORLD-06 the layers at scroll 0.1-0.4 were 3600-6480 px off screen there
  (`gotchas/parallax2d-ignores-its-parents-offset`).
- **Peek up** (hold `look_up`): the sky and the mountains continue to the top of the frame; no
  clear colour. **Peek down**: the ground fills the frame.
- **The Memorina draw** (zoom 1.5): the tween and the held zoom keep every layer in place
  relative to the others; no jump or drift.
- **frost_cliffs** (four screens tall, still a greybox shell): at the bottom the tree lines stand
  on the horizon; peeking up, the sky fills the top while the tree lines sink, no seam.

## Not covered

- A pulse edge across the fills (season swap and haze); `backdrop_layer.gdshader` uses the
  same `gh_season_at`/`gh_band_for` and `distance` term as `seasonal_art.gdshader`.
- The walk to the trial's right end: Ivo did not move after sheathing in this run, so
  `05_spring_right` repeats the left end. The far layers are the same quads there.
- The top of a tall room with a real climb: the cliff rooms are not authored yet (WORLD-05).
