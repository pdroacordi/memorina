---
id: bugs/the-village-valley-hills-show-a-vertical-cut-where-they-wrap
type: bug
title: The village_valley hills layer shows a straight vertical cut where column 1023 wraps to column 0
status: resolved
severity: low
tags: [backdrop, art-contract, seamless, village, world-11, tooling]
related: [systems/backdrops, architecture/vertical-backdrops, systems/art-pipeline]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - assets/sprites/world/background/village_valley/hills.png
  - tools/art/cut_backdrop.py
  - resources/world/backdrops/village_valley.tres
---

## Summary

`hills.png` does not tile: at the wrap the field patches stop on a straight vertical edge 38 game px
tall, in all three bands. The art contract requires every `repeat_x` layer to run column W-1 into
column 0 with no vertical cut (`architecture/vertical-backdrops`, "Art contract").

## Symptom

Found in the WORLD-11 review (2026-10-10) by loading the PNG with PIL. The sheet is 2x, so pixel pairs
(2k, 2k+1) are identical; compare art-pixel boundaries (col 2k+1 vs 2k+2) against the wrap (col 1023 vs 0):

| band | rows differing at the wrap | max at any interior boundary | longest straight run at the wrap | max interior run |
|---|---|---|---|---|
| spring | 118 | 66 | 38 | 20 |
| autumn | 118 | 68 | 38 | 18 |
| winter | 56 | 40 | 32 | 18 |

The wrap is the most discontinuous column in the sheet. Mountains (2 rows) and trees (54 rows, run 20,
inside the interior range) are fine. At `scroll_scale.x` 0.3 a seam is in view for about 60% of camera
positions on the village streets.

## Root cause

`tools/art/cut_backdrop.py:36` `seam_cut` scores a cut pair mainly by the silhouette top
(`top[x0]` vs `top[x1]`). When the tops match it adds the column colour difference weighted by 0.1,
against a length bonus of up to 10 (`cost -= (x1 - x0) / width * 10`). On the hills, whose body is
patchwork fields under the silhouette, the length bonus wins and the chosen columns (with
`--x-max=1390`) cut through two field patches. Nothing after the cut blends the two edges.

## Fix

Not fixed. Options: weight the body colour difference much higher in `seam_cut` (or score only body
rows), or cross-fade / redraw a few art columns on each side of the wrap after the cut, then rerun the
command in `tools/art/prompts/backdrop_village_valley_hills.md`.

## Prevention

`backdrop_set_test` checks EDGE rows but not horizontal tiling. A test that, for every `repeat_x`
layer, compares the wrap boundary with the distribution of interior art-pixel boundaries (fail when it
is above the interior maximum) would have caught this. Not added.

## Fix (2026-10-10)

`tools/art/cut_backdrop.py` keeps up to `--overlap` art px of strip past the cut and stitches the wrap along the cut of least difference (image quilting), at the approved cuts (`--cut`). Hills now change 44 rows at the wrap against 66 inside (36/46 in winter). `backdrop_set_test.test_every_repeating_layer_wraps_without_a_cut` holds every repeating layer to its own sampled column steps.
