---
id: architecture/world-edges-from-the-room-list
type: architecture
title: World edges from the room list - walls on the boundary of rooms and sky bands, one body from a pure rule
status: active
tags: [rooms, edges, collision, camera, reach-audit, world]
related: [systems/rooms, systems/world, architecture/room-reachability-audit, features/the-camera-shows-falls-and-open-tops, bugs/the-drawn-frame-correction-flips-between-candidates-and-drops-ivo-out-of-frame]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/world/rooms/room_edges.gd
  - scenes/world/rooms/world_edges.gd
  - scenes/world/game.gd
  - scenes/world/rooms/room.gd
  - scenes/characters/ivo/abilities/wall_mobility_component.gd
  - scenes/characters/components/safe_ground_tracker.gd
  - scenes/world/rooms/maps/reach/reach_lattice.gd
  - scenes/world/rooms/maps/reach/reach_audit.gd
---

# World edges from the room list (BUILT 2026-10-14, WORLD-34)

## Context

User, 2026-10-14: "there are some places that should have invisible walls or something like that. Look at this, for ex. the characther will be able to escape pretty much every place in the game." Choice "Closed edges + ceiling (Recommended)": "Every room edge with no room beyond gets an invisible wall. Over open-sky tops an invisible ceiling sits about one jump above the top: Ivo can jump into the sky but never land on anything outside. Caves and other enclosed rooms open to the sky get a drawn rock ceiling. A test fails if any surface outside a room can be reached."

Before this, a room was its bounds plus its `.room` art. Nothing stopped Ivo leaving over an open top, over a trial's side wall, or standing on top-row ground outside every room: frost_shore's col-39 pillar top at (9589, 0), reached by a double jump from the breaker (`playtests/2026-10-14-world34-edges`). `RoomExit.is_lost` caught only falls out of the world.

## Options considered

1. **Walls drawn in each `.room`.** Rejected: the guarantee would rest on every map, an open-sky top cannot be closed with ground, and ground there fights the backdrop's sky.
2. **Per-room colliders built by `RoomMapNode` in the contents.** Rejected: a room's walls depend on its neighbours' bands, so on their maps, and a neighbour's neighbour is not resident.
3. **A camera or kill-plane net** (`is_lost` on every exit). Rejected: it punishes instead of stopping, and a double jump over an open top is not an escape.
4. **A flat sky band over the whole top.** Rejected: Ivo could still stand on top-row ground.
5. **Chosen:** walls on the boundary of the allowed space, which is every room plus a sky band over each run of open first-row columns with no room above. The rule is the pure `RoomEdges`; one `WorldEdges` body is built by `Game` from every Room.

## Decision

- **Allowed space** = rooms plus bands. A band is `[run.x0, run.x1] x [top - CEILING_RISE, top]` over a maximal run of first-row columns that are open (not solid, one-way, roof or void; air, water and a secret are open) and have no room at (column centre, top - 1).
- **`CEILING_RISE` = 152 px** = `RoomRing.WIDTH` (160) - `GameCamera.subject_margin` (8). This is an orchestrator call, not a user decision. The camera's keep-in-view yield never has to pass the ring, and it is about one jump (a full jump is 143 px). A full jump from `RoomRing.FLOOR_ROWS` under an open top puts his head at top - 133.
- **Walls**: 16 px (`THICKNESS`) slabs covering every point outside the allowed space within 16 px of it, corners included, merged along rows and columns. A seam between rooms, a corner contact and a gap of 32 px or less get no slab inside a room. The real world gives 26 bands and 216 slabs in 2 ms.
- **Layer 5, "Invisible Walls"** (`WorldEdges.LAYER` 16). Only Ivo masks it (`collision_mask` 11 -> 27).
- **Never grippable.** `WallMobilityComponent` takes a wall only from a slide collision with |normal.x| > 0.7 whose collider is off layer 5, so Ivo never slides up, wall-jumps from or refreshes his air jump on an edge.
- **Never safe ground.** `SafeGroundTracker` probes `collision_mask & ~WorldEdges.LAYER`.
- **`Room.map()`** reads a room's `RoomMap` from its contents scene's `SceneState`, without instancing it. `ReachWorldLoader` uses the same lookup (`Room.map_node`).
- **A first-row seam pillar is never crossed through the sky.** Crossing a 32 px pillar and standing on it need the same headroom. Seams are crossed through their openings (rows 5-8, `systems/world`). An orchestrator call, following from "never land on anything outside".
- **An opening drawn onto the void is fixed in the map.** An `OPEN_EDGE` allowlist entry needs a reason the map cannot change. An orchestrator call.

## Consequences

- Every open top is capped, so the frame always holds Ivo. `room_ring_test`'s `NEAR_TOP` list is retired.
- `RoomExit.is_lost` and `fall_out_of_world` stay as the safety net. They now also `push_warning` "an edge leak": that warning in a playtest log means a hole in the walls.
- The reach audit models the bands (`architecture/room-reachability-audit`, "WORLD-34 revision"): `ReachGrid.bands`, cells outside rooms open only inside bands (4 whole rows, up to 24 px stricter than physics), no side poke, `OUTSIDE_ROOM` (never allowlisted) and `OPEN_EDGE`.
- `OPEN_EDGE` skips hazard cells (an orchestrator call, 2026-10-14). The three dead lakes on a room's bottom row (village_mill, frost_shore, lake_fishing_village) lie under a solid or one-way floor, so Ivo never enters them. The skip is safe because HAZARD comes only from the lake `w` (`takes_reach = false`), which no song raises or holds back.
- A new room needs nothing. A rock-wall room (`ROCK_SETS` in `gen_world_shells.py`) gets a closed first row. The five that were open (frost_cliffs, lake_waterfall_path, lake_high_wall cols 1-14, lake_chasm cols 23-38, orchard_counterweights) got a drawn stone ceiling ("Drawn rock ceiling, all five (Recommended)", user, 2026-10-14).
- Changing `RoomRing.WIDTH` or `subject_margin` changes `CEILING_RISE`; `room_edges_test` pins it.
- One `ROCK_SETS` room keeps sky: lighthouse_top's row 0 is open over a solid row 1, so its band is unreachable and it needs no drawn ceiling.
- The trials are walled like every room. The audit never loads them, so they are exempt from `OPEN_EDGE`: their sides are open in rows 0-8 above their walls.
