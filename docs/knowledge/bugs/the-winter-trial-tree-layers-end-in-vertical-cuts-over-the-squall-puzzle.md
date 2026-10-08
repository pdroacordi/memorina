---
id: bugs/the-winter-trial-tree-layers-end-in-vertical-cuts-over-the-squall-puzzle
type: bug
title: The winter trial's tree layers end at local x 1169, so every frame of the squall puzzle (x > ~980) shows hard vertical cuts in the background
status: fixed
severity: low
tags: [background, parallax2d, art, trials, rooms, pzl-07]
related: [playtests/2026-10-07-redoma-then-soltar-in-the-squall, gotchas/parallax2d-ignores-its-parents-offset, systems/seasonal-art]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - scenes/world/rooms/trials_winter/contents/winter_trial_contents.tscn
---

## Summary

Each of the winter trial's five background `Sprite2D`s is a 3072 px region centred at local
x -367, so it ends at x 1169. The camera there has a parallax offset of
`(1 - scroll_scale) * camera_left`. A layer's right end is therefore on screen once
`camera_left > 529 / scroll_scale`:

| Layer | scroll | On screen when camera left > |
|---|---|---|
| Front Trees | 0.8 | ~661 |
| Deep Trees | 0.6 | ~882 |
| Deeper Trees | 0.4 | ~1322 |
| Mountains | 0.2 | never in this room |

All of puzzle 2 (Ivo x 1290-2336, room widened to 2400 px for PZL-07) is past the first two
thresholds.

## Symptom

In every frame of the squall puzzle, the tree layers stop in straight vertical lines and
flat sky or mountains continue beyond them. Examples:

- `old_build_control_a_bridge_falls_without_redoma.png`: cuts at window x ~585 and ~1022.
- `control_b_bridge_stays_up.png`.

Puzzle 1 (the well, x ~624) never shows them, which is why earlier winter playtests did not
report them. This is not the region-offset drift in
`gotchas/parallax2d-ignores-its-parents-offset`: the winter region sits at x 0.

## Root cause

`winter_trial_contents.tscn`: the layers' `region_rect` is `Rect2(0, 0, 3072, 346)` at
`position.x = -367`. The `Parallax2D` nodes have no `repeat_size`, so nothing extends a
layer past its sprite.

## Fix

Fixed for the winter trial 2026-10-07: the five layers' `region_rect` is 6144 px wide, which covers the 2400 px room from the centred sprites at x -367. The general fix, `repeat_size`, is roadmap WORLD-04.

Original options: either set `Parallax2D.repeat_size.x` to the texture's width (with
`repeat_times`) so the layers tile, or widen each `region_rect` to cover
`2400 + (1 - scroll) * 1760` px. Check the other trial contents scenes, which author the
same layers. In those, the drift above may hide or move the cut.

## Prevention

A room's backgrounds must cover its widest camera position. Widening a room is the moment
to check the right edge of every parallax layer.
