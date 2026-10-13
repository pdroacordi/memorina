---
id: bugs/the-spring-woods-near-trees-are-cut-flat-at-the-strip-top
type: bug
title: The spring_woods near layer's trunks and canopies end in a straight line at strip row 2, which the vertical parallax brings on screen in woods_deep and woods_canopy
status: resolved
severity: medium
tags: [backdrop, art-contract, spring-woods, world-07, world-28, parallax, silhouette]
related: [systems/backdrops, architecture/vertical-backdrops, systems/art-pipeline, bugs/the-winter-trial-tree-layers-end-in-vertical-cuts-over-the-squall-puzzle]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - assets/sprites/world/background/spring_woods/near.png
  - tools/art/prompts/backdrop_spring_woods_near.md
  - resources/world/backdrops/spring_woods.tres
---

## Summary

`spring_woods/near.png` was cut with `--top=0` ("silhouette top at art row 0" in its contract), so its three
big trunks and their canopies run into the top of the strip: in band 0, row 2 is opaque across 384 of 1024
columns (runs x 0-111, 392-579, 940-1023) and rows 0-1 are transparent. The layer's `fill_above` is NONE, so the
trees end in a straight horizontal line. The art passes `backdrop_set_test` (the top row is transparent), but the
contract asks for a silhouette layer whose shapes end inside the strip.

## Symptom

Found in the WORLD-07 region-art review (2026-10-13), before the set is wired to any room. It shows once
`spring_woods.tres` becomes the Spring Woods region set, at the region's horizon 235.
The cut's screen y is `-36 - 0.32 * (camera_y - 224)`: 191 eye level, minus 227 rows above the horizon, at
`scroll_scale.y` 0.32, with the reference centre 235 + 180 - 191 = 224. So:

- **woods_deep** (region y -768..384): the cut is on screen for every camera centre above y 111, which is most
  of the room. It ranges from y about 0 to y 224 (camera at -588).
- **woods_canopy** (y -1152..-768): the cut is at y about 343, at the bottom of the frame.
- **woods_edge, woods_pond, bloom_hollow** (y 0..384): about 30 px above the frame, so it does not show.

Every other region layer ends in a natural silhouette. The longest flat top run is 66 px (threshold mid),
apart from the frost edge sea's real horizon line.

## Root cause

The near layer was framed for the reference camera, where the strip top is 38 px above the frame. Under
WORLD-28's model one region has one horizon, and a layer's anchor moves `(camera - reference) * scroll` on
screen. The woods are 1.5 screens tall above that horizon, so the strip top comes into view. This is the same
class of failure as the winter trial's tree layers ending in vertical cuts, rotated 90 degrees.

## Fix

Resolved 2026-10-13, before the set was wired. Codex redrew the near strip with every crown complete inside the picture and magenta above it (`tools/art/sources/spring_woods_near_codex.png`). It is cut over the whole strip (`--cut=20,1650`, so the trees keep their drawn size) with `--top=12`: the first opaque row is now game row 24 in every band, and nothing is opaque in rows 0-23. The contract `backdrop_spring_woods_near` states the silhouette top and the reason. The layer also moved to `--kind=broadleaf` (winter crowns read as snow and bare branches).

## Prevention

`backdrop_set_test.test_no_layer_with_nothing_above_is_cut_flat_at_its_top` fails any layer with `fill_above` NONE that has more than 32 opaque px in a row within its top 16 game px, in any band. A layer meant to end in a straight top line is listed in `FLAT_TOP_ALLOWED` with its reason (today only `basalt_caves/far.png`, the crater rim of WORLD-28's `caldera_crater`). Surface contracts state a silhouette top row, never "art row 0".
