---
id: bugs/cut-props-left-a-transparent-bottom-row-so-props-floated
type: bug
title: cut_props.py kept each object's source box, so a keyed fringe dropped from its bottom left a transparent row and the prop stood 2 px above the floor
status: resolved
severity: medium
tags: [art, props, cut-props, floating, world-11]
related: [systems/props, systems/art-pipeline]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - tools/art/cut_props.py
  - tests/scenes/world/environment/props/prop_grounding_test.gd
---

## Summary

`cut_props.py` reduced each object inside its source bounding box. The magenta-keyed fringe at an object's foot is
counted in that box but dropped by the block reduction (a block under half opaque is transparent), so the art kept a
fully transparent bottom row. A scene's offset of minus the bottom centre then stood the prop one art px (2 px) above
the floor. The WORLD-11 board found it on the mill house, the well head, both stalls, the tree, the bush, the laundry
line, the crate, the flag and the cart. The user had complained twice ("Many things on the game seem to just be
flaoting", 2026-10-11).

## Fix (2026-10-13)

`cut_props.py` trims every object to its opaque bounds before the base shade and the save, so the bottom row is the
base. `clean_prop.py` and `trim_strip.py` do the same for PixelLab stills and loops. `prop_grounding_test` loads every
prop scene under `props/village` and `props/interiors` and fails when a grounded prop's frame has an empty bottom row
or its offset does not put that row on the origin; hung props are a declared list. The six interior props it found
with an empty bottom row (the bakery's herb rail and bowl shelf, the elder's dried flowers, the empty house's cobweb,
the cellar's lantern and wall roots) all hang, and joined the list.
