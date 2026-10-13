---
id: bugs/the-square-bunting-hangs-in-the-air-short-of-the-bell-tower
type: bug
title: The square's bunting stops about 10 px short of the bell tower it is said to hang from
status: resolved
severity: low
tags: [props, floating, hung-props, village, world-11]
related: [systems/props, bugs/cut-props-left-a-transparent-bottom-row-so-props-floated]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - scenes/world/rooms/home_village/contents/village_square_contents.tscn
  - scenes/world/environment/props/village/bunting.tscn
  - tests/scenes/world/environment/props/prop_grounding_test.gd
  - tools/art/widen_strip.py
---

## Summary

`prop_grounding_test` lists `village/bunting` as hung, "hooked to the bell tower's stone and tied to the bunting
pole". `systems/props` requires that a hung prop visibly touches what it hangs from. The pole end touches. The tower
end does not: in every frame the cloth's west end stops 9 to 11 px short of the tower's stone.

## Symptom

Found in the WORLD-11 review (staged, 2026-10-13) by measuring opaque pixels at the placed positions:
- `Bunting` at (774, 176), offset (-62, -30), 124 px frames: the west end is at x 712 in all six frames, on rows
  146-159.
- `BellTowerFacade` at (656, 288), offset (-56, -420): on rows 140-180 the stone's last opaque column is x 701 (x 703
  on rows 148-155). The texture is 114 px wide (x 600-714), but its right columns are transparent at that height.
- East end: x 835, inside the pole (x 830-845). The pole's top is y 148, and the line's top reaches y 146 in frames 3-4.

So the string of flags hangs in the air beside the tower. This is the "Many things on the game seem to just be
flaoting" complaint (user, 2026-10-11) again, on a prop the test is told is attached.

## Root cause

The bunting was placed against the tower texture's bounding box (x 714), not against its opaque stone (x 701-703).
`prop_grounding_test` skips every `HUNG` prop and never compares a placement with its support, so the claim in the
list is never checked.

## Fix (2026-10-13)

The bunting's frames were widened by 7 art px (`tools/art/widen_strip.py --column=9 --repeat=7`: the plain string
between its west hook and the first flag repeated in every frame), to 138 px, and the size table now says `bunting:w69`.
Placed at (767, 178), its west end is x 699 in all six frames, over the tower's opaque stone (x 701-703 on those rows),
and its east end x 836 lies inside the pole (x 830-845). Its top row is y 148 or lower, at or below the pole's top.

`prop_grounding_test.test_every_supported_prop_touches_its_support` now pairs placed hung props with the sprite that
holds them (`SUPPORTED`: the bunting with the tower and the pole, the tavern's sign, wall lantern and flag with its
front, the wheel with the mill front, the mill's lantern with the hoist rope and the gear with the axle) and fails
when their opaque pixels neither overlap nor touch. Its first run found the flag 2 px above the tavern's roof: it
stands at y 77 now, its pole's foot in the ridge.

## Prevention

A hung prop's support is another sprite or a wall cell, which the test cannot infer from a free-text reason. When
placing one, measure the opaque columns of both sprites at the placed positions, not the textures' rectangles. A
placement test over the contents scenes could pair each `HUNG` key with a support node name and assert that their
opaque rects overlap or touch.
