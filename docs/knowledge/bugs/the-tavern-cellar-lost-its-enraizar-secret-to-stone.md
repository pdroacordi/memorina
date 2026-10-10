---
id: bugs/the-tavern-cellar-lost-its-enraizar-secret-to-stone
type: bug
title: The tavern cellar's Enraizar secret cannot be reached once its earth banks became stone
status: resolved
severity: medium
tags: [rooms, interior, enraizar, roots, secret, grass, world-10, tavern-cellar]
related: [systems/roots-and-climbing, systems/grass, systems/rooms, architecture/roots-join-earth-to-earth, bugs/interiors-still-grow-grass-on-stone-and-the-cellar-ledge]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/home_village/contents/village_tavern_cellar.room
  - scenes/world/memory/song_effects/roots/root_span_finder.gd
---

## Summary

The uncommitted interiors change (2026-10-10) turned every `#` in `village_tavern_cellar.room` into `S` so no
grass grows under the roof. `RootSpanFinder` only roots from `Enums.Ground.EARTH`, so the cellar's designed
Retorno secret (design 04 section 3.1 table: "Adega ... Segredo sob a taverna. Enraizar (retorno)") has no root
bridge any more and its alcove can never be reached.

## Symptom

Measured with a probe scene that runs `RoomMapValidator.validate` and `RootSpanFinder.find(map, 8, 3, 3, 8)` on
the map text: HEAD finds 23 spans in the cellar (including the 6-cell bridge over the flooded gap, cols 10-15),
the working copy finds 0. Playing Enraizar at the near bank (col 9) grows nothing; the gap is 192 px under a
64 px tunnel (rows 7-8), so no jump crosses it, and the alcove (cols 16-18) is unreachable.

The room's own header (line 2) still says "earth on both banks ... roots played at the near bank (col 9)
bridge it", which is now false.

## Root cause

`root_span_finder.gd:15` tests `map.ground_at(cell) == Enums.Ground.EARTH`; stone and wood never root by design
(`systems/roots-and-climbing`: "Roots join earth to earth"). The grass fix chose a material (stone) that the
room's puzzle forbids. Nothing tests a Retorno gate's spans per room, so `room_files_test` stays green.

## Fix

Not fixed. Keep the two banks and the gap's walls earth (at least the bank tops at row 9 cols 9 and 16 and the
cells the bridge finder reads), and keep grass off them another way: either accept blades on the banks (they
read as the "earth here" hint roots need), or give `GrassPlacement` an interior exclusion (`Room.interior`)
instead of changing the material. Then restore the header's claim.

## Prevention

- A room test: every room whose design row names Enraizar as its gate (`village_tavern_cellar`,
  `woods_root_caves`) has at least one `RootSpanFinder` bridge, like `spring_trial_test` does for the trials.
- When a material swap is done for looks, check `ground_at` readers first: `RootSpanFinder`,
  `RootCatchFinder`, `WaterBody` (grep `ground_at(` and `Ground.EARTH`).

## Fix (2026-10-10)

Reverted before commit: the cellar keeps its earth banks (root spans back to 23). Grass is kept out of interiors by `Room.interior` instead (`RoomMapNode._indoors`), so no floor material has to change.
