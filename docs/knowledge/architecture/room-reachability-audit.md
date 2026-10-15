---
id: architecture/room-reachability-audit
type: architecture
title: Room reachability audit - a JumpReach lattice over the stitched world, dominators for "leads nowhere"
status: active
tags: [rooms, room-map, reachability, level-design, audit, tests, jump-reach]
related: [systems/rooms, systems/world, systems/roots-and-climbing, systems/water, architecture/rooms-are-text, gotchas/zigzag-ledges-two-rows-apart-seal-a-shaft, bugs/the-tavern-upper-floor-has-no-way-down, bugs/the-mill-loft-is-unreachable-from-the-lowered-drawbridge, bugs/the-woods-deep-pit-shaft-traps-a-kit-without-the-double-jump, bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera]
created: 2026-10-10
updated: 2026-10-15
source_files:
  - scenes/world/rooms/maps/reach/reach_grid.gd
  - scenes/world/rooms/maps/reach/reach_lattice.gd
  - scenes/world/rooms/maps/reach/reach_audit.gd
  - scenes/world/rooms/maps/reach/reach_world_loader.gd
  - scenes/world/rooms/maps/jump_reach.gd
  - resources/world/maps/room_legend.tres
  - resources/world/maps/reach_allowlist.tres
  - resources/world/maps/reach_kits.tres
  - resources/world/maps/reach_puzzles.tres
  - scenes/world/rooms/maps/reach/reach_kit_check.gd
  - tools/maps/reach_boards.gd
---

# Room reachability audit (BUILT 2026-10-11)

User, 2026-10-10: "There are plenty of weird places that lead nowhere and random platforms that lead nowhere too." Choice: "Audit tool + rework (Recommended)".

## Context

`JumpReach` steps Ivo's real arc but is applied to no geometry. Reach crosses seams (`bugs/the-mill-loft-is-unreachable-from-the-lowered-drawbridge`) and depends on song state.

## Options considered

- **Scope.** Per room with open edges as entrances: rejected, since an entry from below or above carries a jump the room cannot know. The whole world stitched into one cell grid: chosen. Rooms tile one grid without overlap and neighbours run (`systems/world`), so seams vanish; doors are edges; trials excluded.
- **Movement.** A closed-form envelope: rejected, blind to ceilings and lips (`gotchas/zigzag-ledges-two-rows-apart-seal-a-shaft`). Headless Player physics: rejected, slow. A cell lattice over JumpReach's profile: chosen.
- **Song state.** Enumerating states: rejected, combinatorial. One permissive union: chosen.
- **Exceptions.** `.room` comments: rejected, the parser strips them, and a section bumps `FORMAT_VERSION`. A central allowlist Resource: chosen.

## Decision

**Code.** These are pure `RefCounted`s in `scenes/world/rooms/maps/reach/`:
- `ReachGrid.add_room(id, map: RoomMap, cell_origin: Vector2i)` and `set_start(cell)`. Each cell is solid, one-way, hazard, climbable or song floor. Outside every room is air that never supports.
- `ReachLattice.new(reach: JumpReach, body: Vector2i).landings(grid, from: Array[Vector2i], tier: int) -> Array[Vector2i]`.
- `ReachAudit.run(grid, lattice) -> ReachReport`: surfaces, reach per tier, and `findings: Array[ReachFinding]` (`room`, grid `cell` of the surface's left end, `cells`, `kind`, `error`).
- `ReachWorldLoader.load()` (not pure) instances the non-trial region scenes out of the tree and reads the Room rects. It parses each `.room` from text as `room_files_test` does, so it never reads stale imports, and asserts that each map's size equals its room's bounds.

`tests/scenes/world/rooms/maps/reach/room_reach_test.gd` fails on:
- any error finding that is not in `resources/world/maps/reach_allowlist.tres` (`room`, `cell`, `kind`, `reason`);
- an allowlist entry with an empty reason;
- a stale entry that no longer matches a finding.

Fixtures cover each finding and the zigzag seal, and pin the lattice to `JumpReach`.

**Movement.**
- The body is `ceil(capsule width / 32)` by `ceil(capsule height / 32)` cells, read from `ivo.tscn` as `MapGuide.ivo_reach()` reads it (1x2 today). The redraw changes only data.
- A standing cell has its footprint in air with no hazard, over solid ground, a one-way or song floor. A **surface** is a maximal run of standing cells in one row. It is a **platform** if all its support is one-way ledge or an island (a solid group touching no room edge); otherwise it is **ground**.
- A lattice step is the 1/6 s Ivo takes to run one cell. It moves -1, 0 or +1 column plus the rise or fall rasterized from `JumpReach.arc`. One-ways pass upward and land downward. There is no drop-through until WORLD-19.
- Tiers: base; +DOUBLE_JUMP (the air jump branches at any step); +WALL_CLIMB (a footprint against a 2-cell wall is a take-off). ROLL is no tier: `Player._try_jump` refuses jumps while rolling. Expected reach: base up 4 cells and across 8, double jump up 8 and across 13; falls are unlimited. Coyote time and air inertia are ignored (optimistic, under a cell).

**Findings.**
- **Graph.** Nodes are surfaces, with grip and climb cells as transit. Edges come from the lattice for each tier; door pairs are two-way edges.
- **Anchors** are the new-game start, door surfaces, surfaces under an entity whose new `RoomLegendEntry.reach_role` is CONTENT (benches, puzzle pieces, collectibles; never `B`), and surfaces touching a secret.
- (a) **UNREACHABLE** (error): a platform the start cannot reach with the full kit. Unreached ground is a warning.
- (b) **LEADS_NOWHERE** (error): a reached platform with no anchor that dominates no anchor in any tier, neither from the start nor in the reversed graph back to it (so escape ledges count as useful). Flagged platforms are then removed greedily, row then column. One whose removal cuts an anchor is demoted to **REDUNDANT_ROUTE** (warning), so of two parallel stepping-stone routes only one is flagged.
- **DEAD_END_POCKET** (warning): the ground of a connected group of reached surfaces that holds no anchor and dominates none. Roofs land here; the group's platforms still face (b). Promoting pockets to errors is the user's call.
- **NO_WAY_BACK** (error, free from the reversed graph): a reached surface from which that tier cannot return to the start.

**Song state: one permissive union.**
- **Assumed all at once:** every `RootSpanFinder` span at the wet length, ice on every `f` top and `r`/`u` reach top, every `~`/`f` pool passable (Redoma), the lake `w` a hazard, gates, barriers, leaf covers and sealed doors open, and `W` currents carrying Ivo across their box.
- **Movers:** each mover's root script supplies a static `reach_cells(cell, params, map) -> Array[Vector2i]` (lift, lowering platform, floater, drawbridge, seesaw), so the audit never branches on a symbol.
- **Not modelled:** Vendaval without a current, Sombra, timing.
- **Honesty:** the union is not a real state.
  - (a) and NO_WAY_BACK never fire because of songs; only the lattice's limits can produce them.
  - (b) leans to false positives. Those become warnings or allowlist entries.
  - Gates and fairness stay with trial tests and playtests.

**Boards.** `tools/maps/reach_boards.tscn` is a scene because entity scripts need autoloads. For each room it writes:
- `<room>.txt`: the grid, marked on the standing row (`X` unreachable, `N` leads nowhere, `r` redundant, `p` pocket, `v` no way back);
- `<room>.png`: the same marks, 8 px per cell.

Output goes to `--out` (default `tools/maps/reach_boards/`, gitignored). The rework shows before/after pairs, then playtests.

## Consequences

- The first allowlist entries cite STORY-06 where a planned collectible will anchor the flagged ledges (design 04 §3): woods_hut's two ledges (the letter), the bell tower's five climb ledges (its top) and lake_high_wall's four ladder ledges (the high exit). Each goes stale when its collectible lands. Every other error is "TODO WORLD-25: rework". caldera_long_corridor, orchard_well and orchard_leaf_path have no story entry: the corridor and the well's collectible alcove raise no error, orchard_well's 2,5 ledge is not the alcove, and design 04 plans no collectible on the leaf path.
- `room_legend.tres` gains `reach_role` (NONE, CONTENT, DOOR, MOVER). Then regenerate the guide and update `systems/rooms`.
- A new mover must implement `reach_cells`.
- The audit must finish in under 10 s headless. Measure before optimising.

## Revision (2026-10-11, built)

Built as decided, with these deviations:
- **`reach_role`** has CURRENT (wind boxes carry Ivo), HAZARD (the lake) and ICE (water a shell passes and that freezes on top) besides NONE, CONTENT, DOOR and MOVER, so water and currents never branch on a symbol. `RoomLegend.problems()` keeps entity roles on entities and water roles on water.
- **`reach_cells(map, at)` is an instance method** on the mover's root script, called on an instance with the room's params applied and its placement point `at` passed in: a scene's defaults (a lift's travel, a gate's shape) live in its `.tscn`, which a static method cannot read, and the live position moves in `_ready` and with travel, so only authored values count. The floor helper is `MapCells` (`scenes/world/rooms/maps/`), so game scripts do not depend on the audit. `Mechanism` returns nothing for a body taller than wide (a gate). The floater rises only through open cells of the water its own cell is in.
- **Currents carry, never launch.** `WindZone.reach_cells` is the box Ivo enters, `reach_exit_cells` its downwind edge; a current node starts its falls only there, with the air jump kept and no ground jump (`bugs/the-reach-audit-jumps-from-mid-air-inside-a-current`). A jump seeds only from a floor, a root hold or, with wall climb, a wall slide.
- **Doors pair within a region** (`region/link`); an unpaired link is an UNPAIRED_DOOR error.
- **`ReachWorldLoader.load_world()`**, not `load()` (it would shadow the global). It reads the regions and the start from `game.tscn`'s scene state.
- **Song floors are optional**: a fall may land on one or pass it, or a root bridge over a drop hole would seal it. Ice forms only on water whose host is ICE (a rain reach over a `~` pool rises but does not freeze).
- **Surfaces in water** (a pool's bed, reached only with Redoma) stand apart and are a song's: never flagged. NO_WAY_BACK otherwise fired at the bottom of every flooded pit.
- **The body's overhang** (`JumpReach.body_radius`, twice at least half a cell) lets a take-off start one column past a surface's end, so the lattice clears JumpReach's 8-cell gap.
- **Anchors keep 16 px** (an air jump's start and a terminal fall are re-anchored, rounded up). A late air jump clears about 15 cells, more than the guide's apex press (13); `reach_lattice_test` pins the lattice to the widest press over every step.
- **Roofs count as ground** for platform-or-ground, so a building's top lands in DEAD_END_POCKET, not LEADS_NOWHERE.
- **A pocket is its ground only.** A useless group's ground and roofs are one DEAD_END_POCKET warning; every platform in it is judged for LEADS_NOWHERE like any other (`bugs/useless-platforms-beside-useless-ground-hide-in-a-pocket-warning`). Parallel routes count too: of a mirrored climb, one side is LEADS_NOWHERE and the other REDUNDANT_ROUTE.
- **Board marks are punctuation** no legend character uses: `!` unreachable, `*` leads nowhere, `+` redundant route, `:` dead-end pocket, `&` no way back, `?` unpaired door (not X, N, r, p, v: X is the barrier).
- **Only nodes the start reaches are searched**: an unreached node's edges change no finding.
- **Allowlist cells are the `.room` column and row** of the surface's left feet cell, not world cells, so a region that moves keeps its entries. The first entries are every current error, reason "TODO WORLD-25: rework" (the STORY-04/06 slots among them).
- **Boards default to `user://reach_boards`** and take `-- --out <dir>`.
- **Time**: about 1.2 s loading and 4-5 s auditing headless (2.3 M lattice states over 819 nodes), under the 10 s budget.

## Revision (2026-10-11, TECH-06: wall shelves and the roots a ledge grows)

The WORLD-25 playtest found wall ledges left from a removed route that the audit passed: a ledge joined to a wall touches a room edge, so it was ground and landed in a DEAD_END_POCKET warning (`playtests/2026-10-11-world25-rework`).
- **Support.SHELF.** Ground is a shelf when the run is at most `SHELF_CELLS` (6) wide, one end drops (no wall, and no solid or one-way within `SHELF_DEPTH + 1` rows below the feet in the next column, and not the world's edge), and more than half of the solid or one-way cells holding it have air within `SHELF_DEPTH` (2) rows below (outside every room counts as solid). A shelf is a LEADS_NOWHERE candidate like a platform; UNREACHABLE stays a warning for it. Roofs stay ground.
- The drop rule keeps floors out: a block on a one-cell floor (lake_well's bank) and a notch between two walls (village_mill's trail, woods_root_caves' well bottom, a pit in woods_canopy) are thin underneath but step down or are walled, so they stay pockets.
- **Roots go with their ledge.** `ReachGrid.add_roots` keeps each span as a `ReachGrid.Root` (its earth ends; a shaft's walls on every row; and its cells). A platform's or shelf's solid is its island, or the slab under its feet down to `SHELF_DEPTH`; it grows a transit node only when every root crossing that node's cells has an end in it and no current runs through it, because `_node_for` floods transit cells across spans into one node and a node another span also makes stays when the ledge goes (`bugs/a-ledge-is-credited-with-a-whole-merged-root-node-and-its-dead-end-goes-unreported`). A ledge growing a useful node is useful, which is sound only with that rule, and the greedy check removes a ledge with the nodes it grows (restored together on a cut). Before, removing an island kept its pillar, so a stepping stone parallel to the pillar was LEADS_NOWHERE too. A ledge whose roots share a node with other spans is credited with nothing, which leans to LEADS_NOWHERE: a visible error, never a silent skip.
- **World effect**: LEADS_NOWHERE 20 to 29 (ten new shelves; woods_deep 50,14 became the REDUNDANT_ROUTE of the ressalto climb once its pillars went with it), DEAD_END_POCKET 33 to 32. Five new errors are allowlisted with a reason; the other five wall shelves were merged into their walls on the user's decision (`systems/rooms`, Reachability audit), leaving LEADS_NOWHERE at 24. Time unchanged (about 5-6 s).
- **Known blind spot, not fixed**: a root bridge's feet join the banks' tops into one surface, so a ledge level with ground within a bridge's reach merges into that ground's surface and is never judged as a platform.

## WORLD-34 revision (2026-10-14)

`architecture/world-edges-from-the-room-list`. The world now walls every room and caps each open top with a 152 px sky band, so the lattice models the same space:

- `ReachWorldLoader.add_sky` adds `RoomEdges.bands` to `ReachGrid.bands` as whole cells (4 rows). The fixtures add them the same way.
- `ReachLattice.bake` opens cells outside the rooms only inside bands. Every other outside cell is `_OUTSIDE`: never open, never stood on, never a wall to slide on. `ABOVE` (10 rows of sky) and the one-column side poke are gone.
- `ReachAudit` adds OUTSIDE_ROOM (a standing footprint in a band, reached or not, or any grid flag in no room and no band; never allowlisted; band cells keep their grid flags, `bugs/outside-room-misses-a-song-floor-above-a-rooms-first-row`) and OPEN_EDGE (side or bottom edge cells Ivo's body can fill that open onto no room and no band; hazards excluded). Board marks `x` and `|` (`$` is reserved for the WORLD-35 reward slot).
- On the real world neither new kind fires, and the errors are unchanged: no required route rose more than 4 rows over an open top or crossed a first-row pillar. Warnings moved, and findings went from 60 to 63:
  - lighthouse_top 1,0: DEAD_END_POCKET became UNREACHABLE (its roof over the lantern is no longer reached through the sky).
  - Pockets the sky used to join split in three places: lake_high_wall 1,7 went from 13 cells to 2, with a new lake_chasm 30,17 (11 cells); village_lane_west 1,0 went from 21 to 6, with a new woods_edge 11,3 (15); threshold_fields 38,3 went from 72 to 63, with a new frost_shore 9,6 (9).

## TECH-08 revision: the kit check (2026-10-14)

User, 2026-10-14, on the WORLD-35 board: "Yes (Recommended)" to "Run the reach audit once per stage of the journey (base kit, +Memorina, +Woods, +Lake, +both, +Orchards, +Caldera) and fail when an entrance that kit can take has no way back for it, so new routes can't trap the player. Today the audit assumes every ability at once." The union's "Honesty" note above says why it was needed: NO_WAY_BACK never fires because of songs, and the Redoma-first Caldera trap (`bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera`) was found only by a traversal playtest.

**What the tiers were.** `ReachLattice.Tier` (BASE, DOUBLE_JUMP, WALL_CLIMB) is movement only; one search per node with the full kit, and edges are sorted into tiers by the KEPT_AIR and GRIP bits. Songs, barriers and sealed doors are one union for every tier. A kit is a tier plus a grid, so the check is built on the tiers. It is not a parallel graph.

**Options considered.**
- *Run the union audit seven times on filtered grids* (about 5 s each, plus dominators and greedy cuts nobody reads): rejected, too slow.
- *Every combination of songs*: rejected, combinatorial; the user chose the stages.
- *Generate kits by exploring which milestone rooms each kit reaches*: deferred. The Memorina is not given in the world yet (STORY-03), and the stages are the user's.
- *Chosen:* a kit mode in `ReachAudit` that searches with the kit's own skills (`search(grid, seeds, double_jump, wall_climb)`, records its tier only, and skips edge findings, ledge classes, anchors and dominators), on `ReachGrid.for_kit(kit)`.

**Decision.**
- **Data.** `ReachMilestone` (id, room, skills, songs, items, restored guardians, note) and `ReachKit` (id, milestones) in `resources/world/maps/`; `reach_kits.tres` holds eleven kits: the user's seven, and four orchestrator calls (2026-10-14) for the other orders design 04 section 2 allows. Those are woods_orchards and woods_orchards_caldera (the Orchards before the Lake) and lake_caldera and both_caldera (the Caldera before the Orchards). `ReachKit.opened_by` maps a gate's facts to its need, and no facts to `ReachKit.NEVER`, which no kit holds. `ReachKit.holds(need)` reads each packed fact (`kind << 8 | index`) with `SaveFact.check` on the kit's `PlayerData`, the same code a barrier runs in the game.
- **Grid.** `ReachGrid` keeps `_base` (ungated flags) next to `_cells` (the union, unchanged), plus layers keyed by need: `_opens` (root spans, ice, mover sweeps; in the union) and `_closes` (a hazard over standing water until Redoma, a GATE entity's closed body until its need; never in the union). `for_kit` builds base + held opens + unheld closes, and marks each door "open" when the kit holds its own `requires`. `_connect` adds a directed way from each open door to its partner, because `Player._try_door` checks only the door Ivo stands at (`bugs/the-kit-check-drops-a-door-sealed-on-one-side-so-a-one-way-door-trap-is-never-flagged`). Ice at the top of the highest water follows that cell's kind: `f` Congelar, `r` Congelar + Chuva, `u` Congelar + Redoma. Under a reach, the resting water's top also freezes with Congelar alone. That layer is kit-only: in the union it merged lake_high_wall's ladder step into ice and hid it from LEADS_NOWHERE (`bugs/kit-check-ice-forms-only-on-the-highest-water-any-song-can-raise`). A root bridge wider than `RootGrower.max_bridge_cells` needs Chuva, as `RootGrower.reaches` does.
- **Legend.** Two roles appended: GATE (`X`, `G`, `F`: an anchor whose root script answers `reach_wall_cells(map, at)`) and BENCH (`R`: an anchor `ReachGrid.benches` lists). `FactBarrier.reach_needs()` returns its `requires`. A mover's or song gate's need comes from `reach_puzzles.tres`, keyed by room and entity id, with a reason. A plate's weight is the puzzle's, not the gate's, so the entity cannot know it. Eleven placements today, one entry each: four gates, two curtains and five movers.
- **Traps.** `ReachAudit.run_kit` walks forward from the start and backward from the start plus the exit cells. Trapped nodes are reached and not home. They are grouped over the kit's edges, either way, into `ReachReport.Pocket`s (KIT_TRAP finding, rooms, ways in as "room col,row -> room col,row", bench). A group of song surfaces only is skipped.
- **Exits.** `ReachKitCheck.run` runs the kits latest first. For each milestone a kit lacks whose listed next kit (`ReachKits.next`, exactly one more milestone) was already run, the surfaces in that milestone's room that the next kit gets home from become exits, but only when the world gives the milestone today. `ReachKitCheck.given` requires a restored guardian that `ReachGrid.guardians` places in the milestone's room; the loader reads guardians from the rooms' contents (`bugs/the-kit-check-counts-a-guardian-arena-as-an-exit-before-the-guardian-exists`). Beating a guardian inside a pocket is a way out, and only that guardian's.
- **Tests.** `reach_kit_check_test` (pure): a 6-row pit traps the base kit, and neither the double jump nor wall climb is trapped; a bench does not make a pocket safe; a barrier holds back the kit without its fact; woods_deep's shape (a pool under a 2-row tunnel) stops the base kit and lets a Redoma kit down the hole; root bridges by width; sealed doors; a milestone room as exit. `reach_kits_test`: the order and the gifts. `room_kit_test` (world): allowlist with kit and reason, no stale entry, every kit reaches what its earlier kits reach, the fences, the chimney barrier, the root wall keeping Redoma out of the root caves, the lake kit out of the Caldera.

**Consequences.**
- The union audit's errors are unchanged. After the woods_deep fixes it has 362 surfaces and 64 findings: woods_canopy's DEAD_END_POCKET split in two, because the root wall is an anchor.
- The kit check takes about 17 s headless for eleven kits. `room_kit_test` loads the world again.
- **First run.** One pocket, at woods_deep's pit, for +Memorina and +Lake (`bugs/the-woods-deep-pit-shaft-traps-a-kit-without-the-double-jump`); both fixed the same day. woods_deep col 44 opens at rows 28-29 (orchestrator call), and a root wall (FactBarrier on the new `knows_root.tres`) stands before the hole. User, 2026-10-14: "Root wall that opens with Enraizar (Recommended)". The kit check now finds 0 traps, and the allowlist holds no KIT_TRAP entry.
- **The union cannot see a kit-only step.** A stone step at (43,30) also fixed +Memorina, but the union flagged it LEADS_NOWHERE, because the union holds every song. A future escape ledge for an early kit will need an allowlist entry, or a kit-aware LEADS_NOWHERE.
- **Not modelled.** A mover's rest floor without its song: the base kit loses a hung lowering platform, so the check leans to false traps (visible errors), but a rest floor that leads into a trap would be missed. Vendaval's extra reach: a natural current carries every kit, and orchard_windy_gap's 20-cell chasm "clears" without the gale. Timing. Fragments found apart from their guardian: each fragment comes with its guardian's milestone.
- **GRD-04** appends `Enums.Guardian` members for autumn and summer. Give those milestones `restored_guardians` then; `all_guardians_restored.tres` will stop holding at +both.
  - Revision, 2026-10-15 (WORLD-35 step 5): the members came early, for the sun stair's grate (`guardian_restored_summer.tres`). The autumn and summer milestones now set them, so `all_guardians_restored.tres` holds only for the caldera kit, and lighthouse_top is new only for it. `ReachKitCheck.given` still finds no placed guardian in orchard_arena or caldera_arena, so neither is an exit until GRD-04. Four guardians for the hatch is an orchestrator call (2026-10-15), following design 04 section 2, which names four guardians.
