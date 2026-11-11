---
id: bugs/pear-stalks-stop-short-of-the-bough
type: bug
title: The hanging pears' stalks (Line2D) end 3-4 px below the tree prop's bough, so the pear hangs from nothing
status: fixed
severity: low
tags: [hanging-load, props, puzzle-trees, world-42, rope-length, art]
related: [playtests/2026-11-11-world42-puzzle-parts, systems/props, systems/weight-presence-release]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - scenes/world/interactables/hanging_load/hanging_load.gd
  - scenes/world/rooms/wind_orchards/contents/orchard_windy_gap.room
  - scenes/world/rooms/wind_orchards/contents/orchard_counterweights.room
  - scenes/world/environment/props/wind_orchards/pear_tree.tscn
  - scenes/world/environment/props/wind_orchards/pear_limb.tscn
---

## Summary

`systems/props` (Puzzle trees) says each entity's `rope_length` is the measured gap from the fruit's top to the
bough. In the orchard rooms the stalk falls short of the bough's lowest opaque pixel, leaving a strip of sky or rock
between the stalk's top and the leaves.

## Symptom

Measured in screenshots (game px; window px / 2) and against the sprites' alpha, on the art re-imported at 16:16:

| Room | Pear | Bough underside (local y) | Stalk top (local y) | Gap |
|---|---|---|---|---|
| orchard_windy_gap | cocoon, cell 6,4 (x 208) | 84 (`pear_tree.png` row 79 at x 159, the prop at y 160) | 88 = 160 - 16 - 44 - 12 | **4 px, over bright sky** |
| orchard_counterweights | weight_wrong, cell 2,19 (x 80) | 556 | 559 = 640 - 32 - 44 - 5 | 3 px, over dark rock |
| orchard_counterweights | weight_right, cell 15,19 (x 496) | 548 | 551 = 640 - 32 - 44 - 13 | 3 px, over dark rock |
| village_empty_house | house_load, cell 12,7 (x 400) | 178 | 179 = 256 - 32 - 44 - 1 | 1 px (reads attached) |

The windy gap's gap is plain in play, in grey and in colour (`02_stalk_tops_short_of_the_bough.png`, right panel). The
counterweights' gaps are low contrast in colour. In grey the counterweights' stalks are about the colour of the rock
behind them and almost vanish, so both pears look unhung there whatever the length.

## Root cause

`HangingLoad._ready` draws the stalk from the collision shape's top (`-_half_height()`, 22 px over the body's centre),
so the pear's top is `hang_height + 44` px above the floor point. The rope lengths look measured from a fruit top
about 4 px higher, perhaps the sprite's drawn stem (the `Sprite2D` sits at y -2 and the art has a stem nub above the
shape).

## Fix

Raise each `rope_length` to the measured gap: windy gap 16, counterweights 8 and 16, empty house 2. Or measure in the
contract from the shape's top, as the code draws it. A darker or outlined stalk would help the counterweights in grey.

**Applied 2026-11-11 (WORLD-42, before its commit):** `rope_length` is measured from the 44 px collision top, not the 48 px frame top: orchard_windy_gap 16, orchard_counterweights 8 and 16, village_empty_house 2. Re-shot with `world42_windy_gap_puzzle_colour.json`: the stalk meets the bough. The three tree contracts state the rule.
