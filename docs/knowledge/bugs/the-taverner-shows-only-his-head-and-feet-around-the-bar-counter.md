---
id: bugs/the-taverner-shows-only-his-head-and-feet-around-the-bar-counter
type: bug
title: The bar counter prop hides all of the taverner but a 12 px head and his feet, which show under it
status: resolved
severity: medium
tags: [props, inhabitants, interiors, tavern, world-11, world-10, draw-order]
related: [systems/props]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/home_village/contents/village_tavern_contents.tscn
  - scenes/world/rooms/home_village/contents/village_tavern.room
  - assets/sprites/world/props/interiors/tavern/bar_counter.png
---

## Summary

WORLD-11 removed the one-cell bar block (row 20, cols 9-14) from `village_tavern.room` and made
`BarCounter13` (138x40, at (384, 672)) the last child of `Props`, in front of `Taverner` (400, 672). The counter
is 40 px tall where the cells were 32, and its art is open between its legs near the floor.

## Symptom

Status: open (WORLD-11 interiors review, 2026-10-11; measured by compositing frame 0 of `taverner.png`, flipped,
behind `bar_counter.png`). Of the taverner's 52 px only rows y 620..631 (his head, 12 px) and y 668..671 (his
feet, 4 px, through the gap between the counter's legs) stay visible. The head sits against the dark barrel
rack (`BarrelRack0`, y 600..672) in the same browns, so the villager the design places behind the bar barely
reads, and his feet appear detached under the counter.

## Root cause

The counter's height was set by the prop sheet's scale (`cut_props.py --ref-height=20`), not by what it must hide.
The old cells hid 32 px and left 20 px (head and shoulders) showing. `systems/props` (Inhabitants) still says
"the bar's cells hide his legs".

## Fix

Resolved 2026-10-11: the taverner stands at the counter's east end (476, 672), whole, facing the bar; the counter stays the last child of `Props`.

Not fixed. Options: fill the counter's bottom gap in its art (or place a still back panel prop between the
taverner and the counter), and either lower the counter to about 32 px or stand the taverner on a hidden step
so his shoulders clear it. Update the Inhabitants bullet in `systems/props`.

## Prevention

When a prop is placed to hide part of a character, check the composite: which rows of the character remain, and
whether the prop's art has holes over the character.
