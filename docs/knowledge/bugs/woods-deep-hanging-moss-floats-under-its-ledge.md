---
id: bugs/woods-deep-hanging-moss-floats-under-its-ledge
type: bug
title: woods_deep's two hanging moss props start 24 px under the ledge they hang from, because they are hung at the `=` cell's bottom and the ledge art is only ~10 px deep
status: resolved
severity: low
tags: [props, spring-woods, world-14, hung-props, ledges, placement-test]
related: [systems/props, playtests/2026-11-23-world12-14-early-regions-dressing, bugs/cut-props-left-a-transparent-bottom-row-so-props-floated]
created: 2026-11-23
updated: 2026-11-23
source_files:
  - scenes/world/rooms/spring_woods/contents/woods_deep_contents.tscn
  - scenes/world/environment/props/spring_woods/hanging_moss.tscn
  - tests/scenes/world/environment/props/region_prop_placement_test.gd
---

## Summary

RESOLVED, low. Found in the running game (WORLD-12..14 dressing playtest, 2026-11-23). `Props/HangingMoss` (1600, 160)
and `Props/HangingMoss2` (1250, 768) in woods_deep hang from the bottom edge of an `=` cell: (50,4) and (39,23). A
one-way ledge is drawn only in the top ~10 px of its cell, so the moss's top row is about 24 px under the drawn ledge.
On screen it is a clump of moss floating in the air under a branch. `region_prop_placement_test` passes, because it
checks that a hung prop touches a solid or ledge **cell**, not the ledge's drawn art.

## Symptom

- woods_deep, Ivo at (-2864, -516): the moss hangs beside him with a clear band of sky between its top and the branch
  above (`playtests/screenshots/2026-11-23-world12-14-early-regions-dressing/woods_deep_hanging_moss_floats_crop.png`).
- Ivo at (-3536, 92): the same for `HangingMoss2` under the `=====` branch at row 23
  (`woods_deep_hanging_moss2_floats_crop.png`).
- Measured on a column of the window frame (`woods_deep_hanging_moss_floats.png`, camera (-2880, -560)): the ledge's
  drawn underside is at room y ~137.5 (cell top 128), and the moss's first opaque row is at room y ~162. The gap is
  ~24 game px, against a 54 px Ivo.

## Root cause

The placement treats an `=` ledge like a full solid cell and hangs the prop from y = 32 * (row + 1). Solid cells are
drawn to their bottom edge; one-way ledges (`=`, `-`) are drawn as a thin plank at the cell's top. The placement test
has the same blind spot: "a hung prop touches a solid or ledge cell" is true at the cell boundary.

A scan of every top-anchored prop in the three early regions (offset y >= 0) found only these two hung under an `=`
cell. The others hang from `#` or `%` cells (ravine and root-cave roots, the farmhouse onions, the wreck hold's hammock
and lantern) or are listed wall props, and they touch their art.

## Fix

**Resolved 2026-11-23.** Both moss props hang from the drawn underside: `HangingMoss` at (1600, 138) and
`HangingMoss2` at (1250, 746). `region_prop_placement_test` now counts a ledge cell as ground only in the rows its art
fills, read from the biome sheet's ledge row (`_ledge_depth`: 10 px for earth `=`, 8 for wood `-`), so a prop hung
from a ledge cell's bottom fails.

Was: Move both props up to the ledge's drawn underside (y 138 and 746, or wherever the `=` art ends in
`spring_woods`), or hang them from a solid cell. Then teach `region_prop_placement_test` that a hung prop under a
ledge cell must start within the ledge art's depth, read from the biome's ledge tile rather than assumed.

## Prevention

For a prop hung from a one-way ledge, the support is the drawn plank, not the cell. Any placement check by cells
must use the drawn depth for `=`/`-` cells.
