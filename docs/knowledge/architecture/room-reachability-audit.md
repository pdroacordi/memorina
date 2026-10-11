---
id: architecture/room-reachability-audit
type: architecture
title: Room reachability audit - a JumpReach lattice over the stitched world, dominators for "leads nowhere"
status: active
tags: [rooms, room-map, reachability, level-design, audit, tests, jump-reach]
related: [systems/rooms, systems/world, systems/roots-and-climbing, systems/water, architecture/rooms-are-text, gotchas/zigzag-ledges-two-rows-apart-seal-a-shaft, bugs/the-tavern-upper-floor-has-no-way-down, bugs/the-mill-loft-is-unreachable-from-the-lowered-drawbridge]
created: 2026-10-10
updated: 2026-10-11
source_files:
  - scenes/world/rooms/maps/reach/reach_grid.gd
  - scenes/world/rooms/maps/reach/reach_lattice.gd
  - scenes/world/rooms/maps/reach/reach_audit.gd
  - scenes/world/rooms/maps/reach/reach_world_loader.gd
  - scenes/world/rooms/maps/jump_reach.gd
  - resources/world/maps/room_legend.tres
  - resources/world/maps/reach_allowlist.tres
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
