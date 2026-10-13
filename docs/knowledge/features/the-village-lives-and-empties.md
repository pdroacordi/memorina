---
id: features/the-village-lives-and-empties
type: feature
title: The Home Village is dressed and lived in, and empties when its memory falls to 0.6
status: active
tags: [village, props, ambient, region-memory, region-presence, interiors, world-11]
related: [systems/props, systems/world, systems/guardians, architecture/props-and-ambient-life, architecture/the-region-owns-its-forgetting, features/rooms-end-in-black]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - scenes/world/rooms/region_memory.gd
  - scenes/world/rooms/region.gd
  - globals/save_system.gd
  - scenes/world/rooms/home_village.tscn
  - scenes/world/environment/props/region_presence.gd
  - scenes/world/environment/props/ambient_motion.gd
  - tools/art/rotation_bake.gd
  - tests/scenes/world/environment/props/prop_grounding_test.gd
---

## Summary

The four village street rooms carry every prop of the approved WORLD-11 board, the fronts light their windows and smoke from their chimneys, and the mill's wheel turns in the river under a plank bridge. Two new interiors open from the street: the house of notes and the working mill. When the second guardian is restored, the village's memory falls from 0.8 to 0.6 and some of its people and things are gone.

## Details

- **Props.** One PNG per prop, flat style, sized against Ivo (58 px) in `tools/art/village_prop_sizes.json` and `tools/art/interior_prop_sizes.json`; placed under each contents scene's `Props` node. Lights, smoke, flags, bunting, laundry, the sign and the bush move only through `AmbientMotion` on the memory clock. The water wheel and the mill's gear are 12 frames baked over 45 degrees by `RotationBake`, whose loop closes by construction. Contract: `systems/props`.
- **Interiors.** `village_notes_house` (door at village_square col 15) at (1600, 14000) and `village_mill_house` (door in the mill front, village_mill col 3) at (0, 14000), a second interior row because slot 7 would sit 160 px from `threshold_farmhouse` (`systems/world`).
- **The bridge.** village_mill row 9, cols 4-13 are one-way planks over the lake; the wheel's foot is in the water.
- **The drop.** `RegionMemory.steps` maps a count of restored guardians to a baseline; `level_for` takes the highest key reached. `Region` pushes `SaveSystem.restored_guardian_count()` on `_ready` and on `guardian_restored`; a region's own restoration (`restore`) wins. `home_village.tscn` sets `{2: 0.6}`. No fade: Ivo is in the restoring guardian's region.
- **Who leaves.** `RegionPresence.min_baseline = 0.7` on the farmer, the seller, child_b and the seated patron (WORLD-10), the apple stall, the east road's cart, and the house of notes' lights, smoke and laundry.
- **Tests.** `region_memory_test`, `region_test`, `region_presence_test`, `rotation_bake_test`, `prop_grounding_test` (every grounded prop's base row is opaque and on its origin, its size matches the table, and each named hung prop touches its support).

## Why

- User, 2026-10-13: "finish world 11", then "All of it, board first (Recommended)"; the board: "Approve (Recommended)", "A: House of notes (Recommended)", "A: Working mill (Recommended)", "Open a plank bridge (Recommended)". The 0.6 drop comes from design 04 §2 and MEM-13.
- The step table lives on `RegionMemory`, the level's only writer, as an export beside `authored`: per-region numbers, no shared resource (`architecture/the-region-owns-its-forgetting`).

## Gotchas / pitfalls

- A death before a bench rewinds a restoration, so the rebuilt world is at 0.8 again and the leavers return.
- The Return (STORY) must call `restore`, or the steps reapply on the next `guardian_restored`.
- `prop_grounding_test` does not yet check that a grounded prop is placed on the floor (TECH-07).
- A Codex cut shrunk and flattened loses small pictograms: draw them pixel by pixel (`gotchas/flattening-a-shrunk-codex-cut-erases-small-pictograms`).
