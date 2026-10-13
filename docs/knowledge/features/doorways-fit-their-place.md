---
id: features/doorways-fit-their-place
type: feature
title: Every doorway fits its place - building fronts with walkable roofs, and arches, stairwells and hatches where no building stands
status: active
tags: [doors, facades, roofs, props, rooms, legend, secrets]
related: [systems/rooms, systems/props, architecture/doors-and-interiors, bugs/the-cistern-stairwell-shows-through-the-closed-secret-wall, bugs/the-lighthouse-hatch-ceiling-caps-the-last-climb-step, features/rooms-end-in-black]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - scenes/world/interactables/door/door.gd
  - scenes/world/rooms/maps/room_map_node.gd
  - resources/world/maps/room_legend.tres
  - resources/world/maps/room_legend_entry.gd
  - scenes/world/environment/grass/grass_placement.gd
  - scenes/world/environment/props/spring_woods/woodcutter_hut_facade.tscn
  - scenes/world/environment/props/threshold/farmhouse_facade.tscn
  - scenes/world/environment/props/frozen_lake/fisher_hut_facade.tscn
  - scenes/world/environment/props/wind_orchards/inn_facade.tscn
  - scenes/world/environment/props/frost_edge/lighthouse_facade.tscn
  - tools/art/cut_facades.py
  - tests/scenes/world/environment/props/facade_doors_test.gd
---

## Summary

No door stands alone in the open. An outdoor door is set in its building's front, and Ivo can stand on that building's roof; where there is no building the doorway is drawn as an opening that belongs to the place: an arch cut in stone, steps down through a floor, or a hatch in a ceiling or floor. WORLD-24; contracts in `systems/rooms` (Doors and interiors, Roofs) and `systems/props` (Facades).

## Details

- **Door looks.** `Door.LOOKS` (`door.gd:14`) maps a door's `look` param to a two-frame sheet (open, sealed) in `assets/sprites/world/props/door/`: `door` (wood, inside a facade), `passage`, `stairwell`, `hatch_up`, `hatch_down`. `Door.SINKS` (`:22`) draws the stairwell's art 67 px below the floor line; `_dress` (`:106`) applies both.
- **Where each look stands.** `passage`: the cistern vault (`caldera_cistern_bottom.room`, door at 49,17). `stairwell`: the cistern chamber's floor (`caldera_cistern.room`, 8,10). `hatch_up`: the lighthouse interior's ceiling (`lighthouse_interior.room`, 12,4). `hatch_down`: the lantern's floor (`lighthouse_top.room`, 20,20).
- **Region fronts.** Five buildings outside the village, one `Sprite2D` scene each in `scenes/world/environment/props/<region>/`: the woodcutter's hut (woods_edge), the abandoned farmhouse (threshold_fields), the fisher's hut (lake_fishing_village), the inn with its dovecote (orchard_mill_town), the lighthouse base (lighthouse_base, rising out of the room's top edge). All five are cut from one Codex sheet at 2x by `tools/art/cut_facades.py`; `--rows` repeats or drops plain wall rows so each roof lands on the 32 px grid. The six village fronts came earlier (WORLD-11, `systems/props`).
- **Roofs.** Legend `^`, kind `ROOF` (`room_legend_entry.gd:20`): a one-way ledge with no tile art, ground `WOOD`, drawn by the facade behind it. Four rooms use it: woods_edge, threshold_fields, lake_fishing_village, orchard_mill_town. Grass never grows under a roof (`grass_placement.gd:32`).
- **Doors inside a secret.** `RoomMapNode` calls `Door.hide_until` (`room_map_node.gd:100`, `door.gd:95`) for a door inside a closed `[secret]`; its art stays hidden until the secret is found.
- **Tests.** `facade_doors_test` covers every region: each facade stands on a door (`:73`); each door outside an interior and the trials stands in a facade unless its look is in `ALONE_LOOKS` (`:10`, `:87`); every look is known (`:103`); each run of roof cells lies over a facade with both ends within `ROOF_TOLERANCE` (8 px) of its top edge (`:115`).

## Why

- The request: "The door in the cave makes no sense. Why is there a wood door in a cave? There are still doors in the middle of nowhere" (user, 2026-10-10); the board: "Approve (Recommended)" (user, 2026-10-10).
- A roof is a legend cell rather than collision on the prop because a prop never collides or carries gameplay (`systems/props`, Never break); the facade only draws it.

## Gotchas / pitfalls

- A new outdoor door needs a facade or a look in `ALONE_LOOKS`, or `facade_doors_test` fails. A new look needs an entry in `Door.LOOKS`, a contract in `tools/art/prompts/door_<look>.md` and, if its art sinks, a `SINKS` value matching that contract's floor line.
- A roof run must start and end on its facade's top edge; resizing a front with `--rows` moves that edge.
- A stairwell or `hatch_down` needs drawn ground under its sunk art; `room_files_test` keeps door art off void cells.
- A sunk stairwell inside a secret showed through the closed wall before `hide_until` (`bugs/the-cistern-stairwell-shows-through-the-closed-secret-wall`).
- The lighthouse's lowered ceiling covers only the hatch, so the last climb jump still clears (`bugs/the-lighthouse-hatch-ceiling-caps-the-last-climb-step`).
- `^` arrived with room format 8; any later parser change bumps `FORMAT_VERSION` again (`systems/rooms`).
