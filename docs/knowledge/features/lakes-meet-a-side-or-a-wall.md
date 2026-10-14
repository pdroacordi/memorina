---
id: features/lakes-meet-a-side-or-a-wall
type: feature
title: A lake runs off a room side or ends against ground; the fishing village stands on a stilt-pier deck and its well is a stairwell
status: active
tags: [water, lakes, room-map, parser, fishing-village, piers, doors, world-29]
related: [systems/water, systems/rooms, architecture/water-two-projections, features/doorways-fit-their-place, features/every-region-has-its-own-look]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/world/rooms/maps/room_map_parser.gd
  - addons/room_maps/room_map_importer.gd
  - scenes/world/environment/water/water_lake_layer.tscn
  - scenes/world/rooms/frozen_lake/contents/lake_fishing_village.room
  - scenes/world/rooms/frozen_lake/contents/lake_well.room
  - scenes/world/environment/props/frozen_lake/pier_post.tscn
  - scenes/world/interactables/door/door.gd
  - tests/scenes/world/rooms/maps/lake_sides_test.gd
  - tests/scenes/world/interactables/door/door_prompts_test.gd
---

## Summary

Lakes no longer stop in mid-air or draw over solid ground. The fishing village's lake runs the whole room under one continuous plank deck on wooden posts, and its well is a stairwell down to `lake_well`'s hatch. frost_shore's lake runs off its side, and the mill's water stays between its banks. Contract: `systems/water`.

## Details

- **The rule.** `_check_lakes` (`room_map_parser.gd:408`) makes it an import error for a lake `w` to lie over ground or a ledge, for a lake row to end in air, for a lake column to stop in air, or for a lake to meet other water. Room format 11 (`room_map_importer.gd:28`). `lake_sides_test` and the parser suites hold it.
- **The surface.** `water_lake_layer.tscn` has `surface_inset` 0: no ground lies under a lake's top row, so the mirror axis is the cell top.
- **The deck.** lake_fishing_village row 9 is one-way planks across the room over a full-width lake; 22 `pier_post.tscn` props stand under it, the part above the water under `Props` (reflected), the foot (`InWater`) at absolute z 52, over the water and ice, under the void.
- **The well.** A `stairwell` door on a stone landing (`lake_fishing_village.room:39`) linked to a `hatch_up` over `lake_well`'s catch ledge (`lake_well.room:54`); `lake_well`'s top is closed. `Door.prompt_position` (`door.gd:60`) keeps a hatch's prompt inside the room (`door_prompts_test`).

## Why

- The user, 2026-10-13: "3 - Maybe we could improve the visual in these parts in which water is separated. i know that could happen, but the way we've done it, it just seems broken". Choices: "Stilt piers (Recommended)", "Continuous deck (Recommended)", "Well as a door (Recommended)".
- A lake that ends in air reads as broken because water has no wall to rest on; the parser rule makes it impossible to author again instead of fixing the three rooms by hand.

## Gotchas / pitfalls

- A parser change needs a `FORMAT_VERSION` bump and fresh imports (`gotchas/import-plugin-output-is-stale-when-its-logic-changes`); an editor left open across the bump rewrites imports to the old version.
- A post's foot must stay at z 52: under 50 the water covers it, at 60 or more it draws over the void.
- A hatch at a room's top row needs `prompt_position`, or its prompt is clipped by the frame.
