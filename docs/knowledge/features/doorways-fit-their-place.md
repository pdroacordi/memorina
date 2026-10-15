---
id: features/doorways-fit-their-place
type: feature
title: Every doorway fits its place - building fronts with walkable roofs, and arches, stairwells and hatches where no building stands
status: active
tags: [doors, facades, roofs, props, rooms, legend, secrets]
related: [systems/rooms, systems/props, architecture/doors-and-interiors, bugs/the-cistern-stairwell-shows-through-the-closed-secret-wall, bugs/the-lighthouse-hatch-ceiling-caps-the-last-climb-step, features/rooms-end-in-black]
created: 2026-10-13
updated: 2026-10-15
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
  - scenes/world/environment/props/frost_edge/wreck_hull_facade.tscn
  - tools/art/cut_door_breach.py
  - tools/art/cut_facades.py
  - tests/scenes/world/environment/props/facade_doors_test.gd
---

## Summary

No door stands alone in the open. An outdoor door is set in its building's front, and Ivo can stand on that building's roof; where there is no building the doorway is drawn as an opening that belongs to the place: an arch cut in stone, steps down through a floor, or a hatch in a ceiling or floor. WORLD-24; contracts in `systems/rooms` (Doors and interiors, Roofs) and `systems/props` (Facades).

## Details

- **Door looks.** `Door.LOOKS` maps a door's `look` param to a two-frame sheet (open, sealed) in `assets/sprites/world/props/door/`: `door` (wood, inside a facade), `passage`, `stairwell`, `hatch_up`, `hatch_down`, `breach` (inside a facade that draws its own hole; WORLD-35 step 6). `Door.SINKS` draws the stairwell's art 67 px below the floor line; `Door._dress` applies both.
- **Where each look stands.** `passage`: the cistern vault (`caldera_cistern_bottom.room`, door at 49,17). `breach`: the wreck on the beach (`frost_shore.room`, 18,8; WORLD-35 step 6). Its open frame is clear, so the wreck facade's own dark breach shows; its sealed frame fills the breach's dark pixels with hull planks from beside it (`tools/art/cut_door_breach.py`, 48x48 per frame). The orchestrator's call (2026-10-15): "The shore door must not draw the stone arch inside a ship" (`tools/art/prompts/door_breach.md`). `stairwell`: the cistern chamber's floor (`caldera_cistern.room`, 8,10). `hatch_up`: the lighthouse interior's ceiling (`lighthouse_interior.room`, 12,4). `hatch_down`: the lantern's floor (`lighthouse_top.room`, 20,20).
- **Region fronts.** Five buildings outside the village, one `Sprite2D` scene each in `scenes/world/environment/props/<region>/`: the woodcutter's hut (woods_edge), the abandoned farmhouse (threshold_fields), the fisher's hut (lake_fishing_village), the inn with its dovecote (orchard_mill_town), the lighthouse base (lighthouse_base, rising out of the room's top edge). All five are cut from one Codex sheet at 2x by `tools/art/cut_facades.py`; `--rows` repeats or drops plain wall rows so each roof lands on the 32 px grid. A sixth, the beached wreck (frost_shore, `frost_edge/wreck_hull_facade.tscn`, WORLD-35 step 6), is a single Codex picture cut by `tools/art/cut_single_prop.py`, with no walkable roof (its gunwale slopes and its ribs are snapped). The six village fronts came earlier (WORLD-11, `systems/props`).
- **Roofs.** Legend `^`, kind `RoomLegendEntry.Kind.ROOF`: a one-way ledge with no tile art, ground `WOOD`, drawn by the facade behind it. Four rooms use it: woods_edge, threshold_fields, lake_fishing_village, orchard_mill_town. Grass never grows under a roof (`GrassPlacement`).
- **Doors inside a secret.** `RoomMapNode` calls `Door.hide_until` for a door inside a closed `[secret]`; its art stays hidden until the secret is found.
- **Tests.** `facade_doors_test` covers every region: each facade stands on a door (`test_every_facade_stands_on_a_door`); each outdoor door whose look is in `FACADE_LOOKS` (`door`, `breach`) stands in a facade, and the trials are exempt (`test_every_outdoor_facade_look_stands_in_a_facade`); a `breach` stands in a facade in every room, interiors and trials included, since its art is clear and the hole is the facade's (`test_every_breach_stands_in_a_facade_everywhere`); every look is in exactly one of `ALONE_LOOKS` and `FACADE_LOOKS` and every placed look is known; each run of roof cells lies over a facade with both ends within `ROOF_TOLERANCE` (8 px) of its top edge (`test_every_roof_lies_on_a_facade_roof`).

## Why

- The request: "The door in the cave makes no sense. Why is there a wood door in a cave? There are still doors in the middle of nowhere" (user, 2026-10-10); the board: "Approve (Recommended)" (user, 2026-10-10).
- A roof is a legend cell rather than collision on the prop because a prop never collides or carries gameplay (`systems/props`, Never break); the facade only draws it.

## Gotchas / pitfalls

- A new outdoor door with a look in `FACADE_LOOKS` needs a facade, or `facade_doors_test` fails. A new look goes in `ALONE_LOOKS` or `FACADE_LOOKS`. A new look needs an entry in `Door.LOOKS`, a contract in `tools/art/prompts/door_<look>.md` and, if its art sinks, a `SINKS` value matching that contract's floor line.
- A roof run must start and end on its facade's top edge; resizing a front with `--rows` moves that edge.
- A stairwell or `hatch_down` needs drawn ground under its sunk art; `room_files_test` keeps door art off void cells.
- A sunk stairwell inside a secret showed through the closed wall before `hide_until` (`bugs/the-cistern-stairwell-shows-through-the-closed-secret-wall`).
- The lighthouse's lowered ceiling covers only the hatch, so the last climb jump still clears (`bugs/the-lighthouse-hatch-ceiling-caps-the-last-climb-step`).
- `^` arrived with room format 8; any later parser change bumps `FORMAT_VERSION` again (`systems/rooms`).
