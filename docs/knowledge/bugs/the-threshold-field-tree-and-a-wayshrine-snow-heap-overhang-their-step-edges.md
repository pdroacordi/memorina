---
id: bugs/the-threshold-field-tree-and-a-wayshrine-snow-heap-overhang-their-step-edges
type: bug
title: The threshold fields' bare tree and the wayshrine's west snow heap stand a few px out over air past their step edges
status: resolved
severity: low
tags: [props, placement, threshold, world-12, tests]
related: [systems/props, bugs/the-tavern-chest-overhangs-the-upper-floor-stairwell, bugs/guardian-region-props-placed-inside-ground-cells-draw-nowhere]
created: 2026-11-23
updated: 2026-11-23
source_files:
  - scenes/world/rooms/frozen_lake/contents/lake_glacier_contents.tscn
  - scenes/world/rooms/wind_orchards/contents/orchard_summit_contents.tscn
  - scenes/world/rooms/threshold/contents/threshold_fields_contents.tscn
  - scenes/world/rooms/threshold/contents/threshold_wayshrine_contents.tscn
  - tests/scenes/world/environment/props/region_prop_placement_test.gd
---

## Summary

Found in the WORLD-12..14 review, 2026-11-23, by laying each prop's frame-0 foot pixels on the `.room` grid. Not seen
in a running game. Two grounded props have foot pixels past the end of the cell row they stand on.

## Symptom

- `threshold_fields` `FieldTree` (`threshold/field_tree.tscn`) stands on row 7 of the east rise (cols 53-54, x
  1696..1760). 5 of its 16 foot pixels lie at x 1760..1764, over the open cell (55, 7).
- `threshold_wayshrine` `SnowHeap` (`frozen_lake/snow_heap.tscn`, x 122..166) stands on row 8 (cols 4-15, from x 128).
  6 of its 44 foot pixels lie at x 122..127, over the open cell (3, 8).

## Root cause

`region_prop_placement_test` checks only the cell under a prop's origin. The full-foot check proposed in
`bugs/the-tavern-chest-overhangs-the-upper-floor-stairwell` (Prevention) was never built.

## Fix

**Resolved 2026-11-23.** `FieldTree` moved to (1722, 224) and the wayshrine's `SnowHeap` to (150, 256). The full-foot
check is built: `region_prop_placement_test` fails a grounded prop with a bottom-row pixel over air beyond 2 px of one
over ground, a ledge or a roof, in all six dressed regions. It also caught two WORLD-15..17 overhangs, fixed the same
day: lake_glacier's `SnowHeap` (1206, 288) and orchard_summit's `GreatWindmill` with its sails (x 758).

Was: Move the tree at least 5 px west and the heap at least 6 px east. Alternatively, record them as drifts
that hang over an edge, if that is intended.

## Prevention

Extend `region_prop_placement_test` so that every opaque pixel in the bottom row of a grounded prop has a solid,
ledge or roof cell under it, within a small tolerance (2 px).
