---
id: bugs/the-tavern-chest-overhangs-the-upper-floor-stairwell
type: bug
title: The chest in the tavern's east upstairs room hangs 15 px over the stairwell gap
status: resolved
severity: low
tags: [props, interiors, tavern, world-11, placement]
related: [systems/props, bugs/the-tavern-upper-floor-has-no-way-down]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/home_village/contents/village_tavern_contents.tscn
  - scenes/world/rooms/home_village/contents/village_tavern.room
---

## Summary

`Chest17` (`elder_house/chest.tscn`, 38x24, offset (-19, -24)) sits at (1060, 416), so it spans x 1041..1079.
Row 13 of `village_tavern.room` is open at cols 31-32 (x 992..1056, the stairwell that is the upper floor's only
way down), so the chest's left 15 px stand on nothing.

## Symptom

Status: open (found in the WORLD-11 interiors review, 2026-10-11, by compositing the props on the `.room` grid; not
seen in a running game yet). The chest floats half over the hole Ivo walks off, visible from both floors.

## Root cause

The placement was picked by eye against the east room's wall, not against the cells under it. No test checks that
a floor prop's bottom edge lies wholly on solid or plank cells.

## Fix

Resolved 2026-10-11: the chest moved to (1080, 416), x 1061..1099, on the planks and clear of the bed.

Move it right by at least 15 px (x >= 1075, so its left edge is >= 1056), e.g. (1080, 416), clear of the bed at
1117..1183.

## Prevention

A props test: for every `Props` child under an interior, a sprite whose bottom is on a cell top must have a solid,
plank or roof cell under every column of its bottom row.
