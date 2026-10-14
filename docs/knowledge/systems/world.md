---
id: systems/world
type: system
title: The world layout - seven regions on a grid of screens, interiors below, rooms generated as shells
status: active
tags: [world, layout, rooms, regions, interiors, generator, uid]
related: [systems/rooms, systems/map, systems/backdrops, architecture/doors-and-interiors]
created: 2026-10-09
updated: 2026-10-13
source_files:
  - tools/maps/gen_world_shells.py
  - tools/maps/world_uid_pool.txt
  - scenes/world/game.tscn
---

# The world layout

**Never break:** a room's bounds are a whole number of 640x384 screens on the world grid, rooms never overlap, and interiors stay in the band at y 12000 and below. A region scene, a contents scene and a `.room` file are written once by the generator; only Room triggers are regenerated.

Design 04 (the approved map, "Approve as proposed", 2026-10-08), WORLD-05.

- **The grid.** Macro cell (c, r) is world x [640c, 640c+640), y [384r, 384r+384): one screen, 20x12 tiles. A surface room's walkable floor is the top of grid row 9 of its bottom screen row (y = 384r + 288). Every region scene sits at (0, 0) in `game.tscn`; its rooms carry their world position. The song trials stay at y 5600..8100 (debug only).
- **Openings.** Rooms share edges. A side opening is air in rows 5..8 of the shared screen row with a floor at row 9; a vertical opening keeps the named columns open. The current room is the one Ivo's feet are in (`systems/rooms`).
- **Interiors** (door rooms, design 04 section 4) live at y 12000 (floor y 12288), x = region index * 12000 + n * 1600, in the generator's region order (home_village, threshold, frost_edge, spring_woods, frozen_lake, wind_orchards, summer_caldera). They never touch another room. A region keeps to its 12000 px x band, less two rings (`RING_GAP`, 320 px: rooms that do not touch are two `RoomRing.WIDTH` apart, `room_ring_test`): a slot whose room would reach past that starts a further row 2000 px lower (`INTERIOR_ROW_SPACING`, past the tallest 4-screen interior), n from 0 again. WORLD-11 (2026-10-13): slot 7 at x 11200 ends 160 px from threshold_farmhouse (x 12000) and slot 8 lies in the threshold's band, so the village's eighth and ninth interiors start row 1: the mill house at (0, 14000), the house of notes at (1600, 14000). A new game starts in `village_house` at (320, 12286).
- **The generator.** `tools/maps/gen_world_shells.py` holds the tables (regions with name key, season, memory, guardian and wall material; rooms with macro rects; side and vertical openings; benches; interiors; doors; barriers) and writes Room triggers (always), region scenes, contents scenes and `.room` shells (once). A new shell names its region's tileset (`REGION_TILESETS`, with `ROOM_TILESETS` for the lighthouse, the cistern and the two ash rooms, `systems/rooms`), an interior's shell is planks (`%`), and a new region scene gets its region's backdrop set and horizon (`REGION_BACKDROPS`, `systems/backdrops`). Every scene gets a stable `uid=` from `world_uid_pool.txt` (minted by Godot; uids already in a scene header are skipped), so `SceneKey` save keys survive renames. Every region scene gets its set and one horizon (`REGION_BACKDROPS`) and every contents scene a `Backdrop`: no override outdoors (the region's set), a rock wall inside rock (`ROCK_SETS`), its region's cave set underground (`UNDERGROUND_SETS`), `interior_timber` indoors (WORLD-28, `systems/backdrops`). A new room's cuts against its neighbours' backdrops must pass `backdrop_seams_test`. To add a room: add its row and openings, run the tool, add the printed contents scenes to `tools/smoke/scenes.txt`, and place it in its region scene by hand (region scenes are not regenerated).
- **The village is one street** ("Street only; climbs move out (Recommended)", user, 2026-10-10; design 04 section 1, "Vila plana"): the lane, square, mill and gate have no sky ledges; the bell tower is an interior; the cistern belongs to the caldera. Exploration starts outside the village.
- **Memory per region** (MEM-13, design 04 section 2): village 0.8, threshold 0.3, frost edge 0.05, woods 0.4, lake 0.3, orchards 0.25, caldera 0.15, authored on each region's `Memory` node. The village falls to 0.6 from the second restored guardian (`RegionMemory.steps = {2: 0.6}`, WORLD-11, 2026-10-13; `systems/guardians`).
- **Hand-placed region memory:** the lake well's squall has its own `MemorySource` (`frozen_lake.tscn`, `WellSquallMemory`) so its gusts break a song at the region's 0.3.
- **Known limits** (2026-10-09 traversals, `playtests/2026-10-09-traversal-opening`): in one-screen rooms the double jump reaches every height gate on the optional alcoves (woods pond, caldera seesaw, dry moat, bait); the player owns the double jump before arriving, so they stay optional. The caldera cistern is two-way without wall climb or double jump: its chamber's door joins caldera_cistern_bottom, and Redoma played in the chamber dries the way back to the slab (2026-10-10, `bugs/well-water-stands-in-the-air-at-a-passage-mouth`), so a player who does the Frozen Lake before the Orchards can leave the Caldera (`bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera`). The cliff chimney is gated by wall climb at its top (`has_wall_climb.tres`) and the arena's west wall is closed above the barrier, so nobody falls in without it (`bugs/the-orchard-arena-barrier-is-jumped-over-into-the-cliff-chimney`). lake_well's way in and out is its hatch over a calm one-way catch above the squall: a door pair with the stairwell on the fishing village's shore landing, its row 0 closed (WORLD-29, 2026-10-13: "Well as a door (Recommended)": "A stairwell on a stone landing by the shore, linked to a hatch in lake_well, with a short fade, like the caldera cistern already does."). From the bank the step (cols 13-14) and one jump west put Ivo back on the catch with the base kit (the squall carries him on). From the catch Soltar reaches the curtain, so Lógico 1's shelter step can be skipped. Accepted until the puzzle moves to a larger room (no 20x12 layout keeps the way out calm and the curtain out of Soltar's 288 px reach).

## Rooms (macro rects) (c0..c1, r0..r1 inclusive)

| Region | Room | c | r | Notes |
|---|---|---|---|---|
| home_village | village_lane_west | -2..-1 | 0 | W edge: fence gated by owns_memorina (barrier, not a door) |
| home_village | village_square | 0..2 | 0 | bench `village_square_bench`; doors: village_house, village_notes_house (col 15), village_tavern, village_elder, village_bell_tower; the well's shaft opens down into caldera_cistern at c1 |
| home_village | village_mill | 3..4 | 0 | door: village_mill_house (col 3); river under a plank bridge (cols 4-13 of the street are one-way planks `-` over the lake, which fills rows 10-11 between the earth banks at cols 3 and 14 over air since WORLD-29, so the wheel stands in visible water and Ivo crosses on the planks; "Open a plank bridge (Recommended)", user, 2026-10-13); at c4 the river trail goes up into lake_waterfall_path, gated by owns_memorina |
| home_village | village_gate_east | 5..6 | 0 | E exit to threshold |
| threshold | threshold_fields | 7..9 | 0 | door: threshold_farmhouse |
| threshold | threshold_bridge | 10..11 | 0 | broken bridge over a ravine (clearable with one jump); brute shadow |
| threshold | threshold_wayshrine | 12 | 0 | bench `threshold_wayshrine_bench` |
| frost_edge | frost_shore | 13..14 | 0 | frozen surf; the lake under the beach (rows 10-11) runs off both sides (WORLD-29) |
| frost_edge | frost_cliffs | 15..16 | -3..0 | vertical climb by single jumps; bench `frost_cliffs_bench` in a sheltered cave |
| frost_edge | lighthouse_base | 17..18 | -3 | door: lighthouse_interior |
| frost_edge | lighthouse_top | 17..18 | -5..-4 | final arena (empty); door (hatch) to lighthouse_interior; solid floor to the base below |
| spring_woods | woods_edge | -4..-3 | 0 | bench `woods_edge_bench`; door: woods_hut |
| spring_woods | woods_deep | -7..-5 | -2..0 | tall trees, ledges; a high ledge (double jump) up into woods_canopy; floor hole down into woods_root_caves (drop in, way back needs Enraizar) |
| spring_woods | woods_canopy | -7..-5 | -3 | top-left opening up into orchard_terraces at c -7 |
| spring_woods | woods_root_caves | -7..-5 | 1..2 | earth and stone faces; root bridge, earth well; collectible |
| spring_woods | woods_pond | -9..-8 | 0 | dry basin + floater (Chuva return) |
| spring_woods | bloom_hollow | -11..-10 | 0 | Bloom Guardian arena (moved from the old village) |
| frozen_lake | lake_waterfall_path | 4 | -5..-1 | vertical, single jumps; bench `lake_waterfall_bench` |
| frozen_lake | lake_fishing_village | 1..3 | -5 | a plank deck on stilts (row 9, no drop-through) over one lake from the stone landing (cols 0-5, by lake_shore) to the east side; doors: lake_fisher_hut, the landing's stairwell to lake_well (WORLD-29, "Stilt piers (Recommended)", "Continuous deck (Recommended)", user, 2026-10-13) |
| frozen_lake | lake_well | 2 | -4 | water well (Redoma; windy spot); closed above, entered by the hatch over its catch from the fishing village's stairwell |
| frozen_lake | lake_shore | -2..0 | -5 | wide lake (Congelar return); far bank secret |
| frozen_lake | lake_high_wall | -3 | -7..-5 | lake against a wall; the high exit (Redoma+Congelar / Vendaval+Congelar) holds a collectible; floor level passes W |
| frozen_lake | lake_ice_caves | 5..6 | -5 | path to the arena |
| frozen_lake | lake_frost_arena | 7..8 | -5 | Frost Guardian arena (moved from the lighthouse) |
| frozen_lake | lake_chasm | -5..-4 | -6..-5 | earth-walled chasm; Enraizar bridge W to orchard_chasm_bridge |
| wind_orchards | orchard_chasm_bridge | -7..-6 | -6 | down into orchard_terraces at c -7 |
| wind_orchards | orchard_terraces | -9..-7 | -5..-4 | bench `orchard_terraces_bench` |
| wind_orchards | orchard_well | -6..-5 | -4 | Combinado 3 (Soltar+Enraizar); collectible |
| wind_orchards | orchard_mill_town | -12..-10 | -4 | windmills; door: orchard_inn; drawbridge (Soltar, shortcut) |
| wind_orchards | orchard_counterweights | -10 | -6..-5 | lift (Soltar), shortcut to terraces |
| wind_orchards | orchard_windy_gap | -12..-11 | -5 | wind zone gap (Vendaval) |
| wind_orchards | orchard_leaf_path | -14..-13 | -4 | leaf cover (Soltar) |
| wind_orchards | orchard_arena | -16..-15 | -4 | autumn arena, empty until GRD-04 |
| wind_orchards | orchard_cliff_chimney | -17 | -4..4 | tall chimney; bottom exit E is high on a wall: wall climb |
| summer_caldera | caldera_chimney_base | -16..-15 | 4 | from the chimney |
| summer_caldera | caldera_long_corridor | -14..-11 | 4 | passable; the Solstice+Sombra plate/door guards a side alcove with a collectible |
| summer_caldera | caldera_bait | -10..-9 | 4 | territorial brute shadow (fight or Sombra) |
| summer_caldera | caldera_dry_moat | -8..-6 | 4 | Combinado 1 (Chuva+Congelar) to an optional ledge |
| summer_caldera | caldera_seesaw | -5..-4 | 4 | seesaw (Sombra) |
| summer_caldera | caldera_open_crater | -3..-2 | 2..5 | tall; open to the sky (no roof row since WORLD-28); bench `caldera_crater_bench` |
| summer_caldera | caldera_cistern | 1 | 1..2 | flooded cistern under the square's well; Redoma dries the passage into a sealed chamber; door: caldera_cistern_bottom |
| summer_caldera | caldera_cistern_bottom | -1..1 | 3..4 | door on the dais up to caldera_cistern |
| summer_caldera | caldera_temple_gate | 2..3 | 4 | plate + gate (Sombra) |
| summer_caldera | caldera_arena | 4..5 | 4 | summer arena, empty until GRD-04 |

## Interiors (y >= 12000, region-local; at least 640x360; never touching another room)

| Region | Interior | size (screens) | doors |
|---|---|---|---|
| home_village | village_house | 1x1 | village_square; Ivo's start (new game spawns here) |
| home_village | village_tavern | 2x2 (two floors) | village_square; trapdoor to village_tavern_cellar |
| home_village | village_tavern_cellar | 1x1 | village_tavern; Enraizar secret |
| home_village | village_elder | 1x1 | village_square |
| home_village | village_bakery | 1x1 | village_lane_west |
| home_village | village_empty_house | 2x1 | village_lane_west; Combinado 4 |
| home_village | village_bell_tower | 1x4 (vertical) | village_square; a slim stone shell in void, the helix stair turning around Ivo from the bell floor up through the plank gallery, the alcove above it (double jump) holds the collectible (WORLD-26, "4 screens (Recommended)", user, 2026-10-11; `systems/helix-stair`) |
| home_village | village_mill_house | 1x1 | village_mill; the working mill (row 1, (0, 14000)) |
| home_village | village_notes_house | 1x1 | village_square; the house of notes (row 1, (1600, 14000)) |
| threshold | threshold_farmhouse | 1x1 | threshold_fields; sword marker |
| frost_edge | lighthouse_interior | 1x4 (vertical) | lighthouse_base (bottom), lighthouse_top (hatch, sealed: all_guardians_restored) |
| spring_woods | woods_hut | 1x1 | woods_edge |
| frozen_lake | lake_fisher_hut | 1x1 | lake_fishing_village |
| wind_orchards | orchard_inn | 2x1 | orchard_mill_town |
