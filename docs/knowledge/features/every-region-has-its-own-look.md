---
id: features/every-region-has-its-own-look
type: feature
title: Every region draws its own ground and its own backdrop on one horizon; where two pictures meet, the cut hides behind something solid
status: active
tags: [backdrop, tilesets, regions, seams, horizon, gate-tower, border-cairn, crater, back-wall, world-07, world-28, world-30, world-31, world-32, world-33]
related: [systems/backdrops, systems/rooms, systems/props, systems/art-pipeline, architecture/backdrop-seams, architecture/vertical-backdrops, architecture/biome-tilesets, features/rooms-end-in-black]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/world/rooms/region.gd
  - scenes/world/environment/backdrop/backdrop.gd
  - scenes/world/environment/backdrop/backdrop_math.gd
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
  - scenes/world/environment/backdrop/backdrop_seams.gd
  - resources/world/backdrops/caldera_crater.tres
  - resources/world/tiles/biomes/
  - scenes/world/environment/props/village/gate_tower.tscn
  - scenes/world/environment/props/frozen_lake/border_cairn.tscn
  - tools/art/draw_crater_rim.py
  - tests/scenes/world/environment/backdrop/backdrop_seams_test.gd
  - tests/resources/world/backdrops/backdrop_set_test.gd
  - tests/resources/world/tiles/biome_tileset_test.gd
---

## Summary

Each of the seven regions has its own ground tiles in three seasons and its own backdrop (sky, three landscape layers), and no room, trial or title screen draws pack art any more. A region's rooms share one horizon, so stacked rooms show one landscape, not the trees twice. Where two different backgrounds meet, the line between them is a hard cut hidden behind ground, a back wall, a lake or a prop. Rooms inside rock show a rock wall, the open crater shows the sky over a ragged basalt rim, and an enclosed hollow in an outdoor room shows earth behind it. Contract: `systems/backdrops`.

## Details

- **Ground.** Every `.room` names its region's biome (`tileset = <id>`; sheets under `assets/sprites/world/tilesets/<region>/`): village, threshold, frost_edge (lighthouse masonry in the lighthouse), spring_woods, frozen_lake, wind_orchards, summer_caldera (ash scree in the dry moat and the open crater). `legacy` is kept only for parser fixtures. Interiors are planks and draw band 0 in every season. `biome_tileset_test` pins every room to its region.
- **Backdrops.** `Region.backdrop_set` and `Region.horizon_y` (`region.gd`); a room's `Backdrop` only overrides the set (caves, interiors, rock rooms), and over its top every room shows its region's set (`BackdropMath.over_top`, the shader's `part`). Every surface set shares the valley's sky texture with a vertical scroll of 0, so two regions' skies are the same pixels over every border (WORLD-33).
- **Seams.** The dither is gone: one owner per pixel (`void_owner` by hold, then gap). `BackdropSeams.cuts` reports every cut between two pictures that touches no opaque cell; `backdrop_seams_test` fails on any not listed in `ALLOWED` with a reason class. The dividers are `[back]` walls in the `.room` files; over region-border wall tops a prop covers what differs: the two village gate towers (178 px over the tops) and the lake/orchard border cairn (88 px over the tops, where the lake's peaks reach 53 px). `TOWERS` and `TOPS` in the test check each cover against `BackdropMath`.
- **The crater.** `caldera_crater.tres`: the region layers, the basalt wall from 123 px under the horizon, and `crater_rim.png` (`draw_crater_rim.py`), the wall's own pixels continued up into column tops, overlapping the wall by 8 px (`test_a_straight_topped_layer_is_covered_by_the_next`).
- **Hollows.** woods_deep's pocket inside its root mound has a `[back]` earth wall over every cell, one cell into the ground around it (WORLD-31).

## Why

- The user, 2026-10-13: "1 - The background should be improved. Look at the image, for ex. There is no sense in trees there. Nor in the fade between two backgrounds. 2 - We should only our set of tiles from now on and not mix em." Choices: "Own tiles per region (Recommended)", "One horizon + hidden cuts (Recommended)", "Our own per region (Recommended)", "Cover with a tall gate tower (Recommended)", "No season indoors (Recommended)". WORLD-31/32/33: "Go ahead with WORLD-31, 32 and 33" (2026-10-13); the pocket's back wall and the cairn are the orchestrator's calls, recorded as such in the roadmap.
- The horizon stays per region (it belongs to the region's height); only the sky has to match, and only a vertical scroll of 0 makes it horizon-independent (`architecture/backdrop-seams`, "One sky over every border").

## Gotchas / pitfalls

- A new region set must use the shared sky at scroll (0.05, 0) (`test_the_region_sets_share_the_sky_and_the_horizon`), or the sky steps at its borders again.
- A new seam between two pictures fails `backdrop_seams_test` until it is hidden or listed with a reason; a cut over wall tops that a jump can reach needs a cover prop, not an allowance.
- A layer that ends in a straight top line needs a cover layer that rides with it and continues its pixels; ending a cover exactly on the wall's top row left a 1 px gap between the two quads in play.
- `[back]` beside open sky shows its own edge: keep a back wall one cell into the ground, never beside an open cell outside the hollow.
