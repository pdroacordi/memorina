---
id: playtests/2026-10-10-secrets-and-seams
type: playtest
title: Secrets and seams - the cistern's chamber reads as stone until Ivo comes up its hole; the square's well dithers into the cistern's strata instead of a line
status: active
tags: [world-21, world-22, secret, backdrop, seam, playtest]
related: [architecture/secret-false-walls, architecture/backdrop-seams, systems/rooms, systems/backdrops]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - tools/playtest/scripts/caldera_cistern_redoma_chamber_door.json
---

## Summary

WORLD-21 and WORLD-22 in the real game (windowed, `tools/playtest`).

- **Secret** (`01_cistern_chamber_closed.png`, `02_cistern_chamber_open.png`): from the slab, the cistern's chamber reads as solid stone under it, and its door is hidden. With Redoma, Ivo drops to the pool floor, goes west through the flooded passage and up the hole. The wall opens, and the door takes him to `caldera_cistern_bottom` at 3 HP. The crack hint sits on the cell above the hole; at the caldera's 0.15 memory it is faint in the grey, as subtle as intended.
- **Seam** (`00_well_seam_before.png`, `03_well_seam_band.png`): at the square's well, the woods used to stop in a hard horizontal line over flat grey. Now they dither into the cistern's `village_strata` over a 64 px band at the room edge.

## What screenshots cannot show

- The dither is on the 1 game px grid, like the greyhush edge. The art is 2x, so the band is finer than the art pixels; it reads as a soft fade at 1x scale.
- The fade timing (0.4 s, front copy only after the review) was not filmed frame by frame.

## Not covered

- The lake well's and the winter trial's secrets: they reuse the same code and the same entry from below.
- Same-set seams (square to mill), now phased on the world; the region cut at the east gate.
