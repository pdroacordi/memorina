---
id: bugs/interiors-still-grow-grass-on-stone-and-the-cellar-ledge
type: bug
title: Village interiors still grow grass - the cellar's kept earth ledge and every exposed stone top
status: resolved
severity: low
tags: [grass, interior, rooms, village-biome, stone, world-10, docs-drift]
related: [systems/grass, systems/rooms, bugs/the-tavern-cellar-lost-its-enraizar-secret-to-stone]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/home_village/contents/village_tavern_cellar.room
  - scenes/world/rooms/home_village/contents/village_bakery.room
  - resources/world/tiles/biomes/village.tres
  - scenes/world/environment/grass/grass_placement.gd
  - docs/knowledge/systems/grass.md
---

## Summary

The 2026-10-10 interiors change added a `systems/grass` "Indoors" bullet: "interiors are built of wood and
stone, never earth, so no grassy look is exposed". In the village biome stone is a grassy look
(`village.tres` sets `stone_grass`, density 0.25 spring), and the cellar kept its `=` earth ledge, so two
interiors still grow blades.

## Symptom

Probe (`GrassPlacement.runs` on the validated working-copy maps, the same callable `RoomMapNode` uses):

- `village_tavern_cellar`: 5 runs: `look0 row5 cols2-5` (the `=` earth ledge: full earth grass, density 0.7,
  plus the earth turf lip) and four stone runs (row 8 cols 6-7, row 9 cols 1-5, 8-9, 16-18).
- `village_bakery`: 2 stone runs on the oven's shoulders (row 6 cols 14-15 and col 18).
- elder, empty house, house, tavern: 0 (wood has no `wood_grass`).

The villagers playtest (`playtests/2026-10-10-villagers-and-animals`) shot only the tavern and Ivo's house.

## Root cause

The fix relies on authoring discipline ("never earth") rather than a rule, and the discipline was stated wrongly
(stone grows moss in this biome) and applied incompletely (`=` kept in the cellar). The four `legacy` interiors
(threshold_farmhouse, woods_hut, lake_fisher_hut, orchard_inn) are still earth and will grow grass the day their
biome gets a `GrassLook`.

## Fix

Not fixed. Options: skip grass in `Room.interior` rooms (one check where `RoomMapNode` builds `Grass`; an
interior's contents can learn it from its Room), which also lets the cellar keep the earth its roots need
(`bugs/the-tavern-cellar-lost-its-enraizar-secret-to-stone`); or convert the cellar's `=` to `-` and accept
moss on indoor stone, and correct the "Indoors" bullet to say so.

## Prevention

A `room_files_test` rule: an interior room has no `GrassPlacement` run, or the interior skip above with a test.

## Fix (2026-10-10)

`RoomMapNode` grows no grass in a `Room` with `interior` set (`room_map_node_test.test_an_interior_grows_no_grass`), so stone, the cellar's earth ledge and the legacy earth interiors grow none; the systems/grass note now states the rule.
