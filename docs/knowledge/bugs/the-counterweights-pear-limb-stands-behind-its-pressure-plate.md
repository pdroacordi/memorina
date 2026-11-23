---
id: bugs/the-counterweights-pear-limb-stands-behind-its-pressure-plate
type: bug
title: orchard_counterweights' pear limb draws behind the room's pressure plate at (2, 20)
status: open
severity: low
tags: [props, world-42, placement, readability, pressure-plate]
related: [systems/props, bugs/the-long-corridor-column-stands-on-its-pressure-plate]
created: 2026-11-23
updated: 2026-11-23
source_files:
  - scenes/world/rooms/wind_orchards/contents/orchard_counterweights_contents.tscn
  - tests/scenes/world/environment/props/region_prop_placement_test.gd
---

## Summary

Found 2026-11-23 by `region_prop_placement_test`'s new entity check, which was written for the WORLD-12..14 review.
Not seen in a running game. `Props/PearLimb` (`wind_orchards/pear_limb.tscn`, at (46, 672)) has 120 opaque px of
frame 0 in the cell of the `P` plate at (2, 20). The plate draws at z 0 over the limb's roots, as the caldera column
did over its plate (`bugs/the-long-corridor-column-stands-on-its-pressure-plate`).

## Fix

Not fixed. The limb's roots, trunk and bough are measured against the pears' `rope_length`s (`systems/props`,
"Puzzle trees"), so moving it means new rope lengths. The test lists it in `COVERS` until someone decides.

## Prevention

`region_prop_placement_test.test_no_prop_covers_an_entity_or_a_secret` now checks every placement in the six dressed
regions.
