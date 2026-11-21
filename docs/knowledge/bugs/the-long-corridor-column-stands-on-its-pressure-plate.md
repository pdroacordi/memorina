---
id: bugs/the-long-corridor-column-stands-on-its-pressure-plate
type: bug
title: caldera_long_corridor's first column stands on the room's pressure plate, which reads as the column's plinth
status: fixed
severity: medium
tags: [props, world-17, placement, readability, pressure-plate]
related: [systems/props, bugs/guardian-region-props-placed-inside-ground-cells-draw-nowhere]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - scenes/world/rooms/summer_caldera/contents/caldera_long_corridor_contents.tscn
  - scenes/world/rooms/summer_caldera/contents/caldera_long_corridor.room
---

## Summary

`Props/Column` (`caldera_long_corridor_contents.tscn:27`, at (240, 288), 90x256, x 195..285) has its plinth
behind the `P` plate at col 6, row 8 (x 192..224). The plate is the corridor's only puzzle part, and it now
looks like the stone base of a column.

## Symptom

Status: open (WORLD-17 review, 2026-11-20; composited from the prop and the grid). The plate draws at z 0 over
the column's sandstone plinth, so its edge disappears into it. The approved board
(`docs/design/drafts/guardian_regions_dressing_board.md`, step 4 and the caldera puzzle rows) says props
"never cover a gameplay cell" and "the puzzle parts stay the only things that read as usable".

## Root cause

The colonnade was spaced by eye from x 240; nothing compares prop rectangles with `.room` entity cells.

## Fix

**Applied.** Fixed 2026-11-20 before the WORLD-17 commit: the column moved to (320, 288), clear of the plate at col 6 (x 192..224), the amphora to (440, 288).


Not fixed. Move the column clear of col 6 (x >= 270 puts its plinth east of the plate), or onto one of the
ceiling pillars the board names (cols 14-16, 40-43, 52-53).

## Prevention

A placement test listing every `Props` child whose opaque frame-0 pixels overlap a cell of a gameplay entity
(`P`, `E`, `G`, `X`, `$`, `i`, `t`, `R`, `L`, `T`, `D`, ...) unless it is a declared exception.
