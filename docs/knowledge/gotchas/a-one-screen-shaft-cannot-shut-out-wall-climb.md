---
id: gotchas/a-one-screen-shaft-cannot-shut-out-wall-climb
type: gotcha
title: A one-screen-wide shaft cannot be made one-way against wall climb - a hole is always within a wall-climb jump
status: active
tags: [rooms, room-map, reach, wall-climb, one-way, world-35]
related: [systems/rooms, systems/world, architecture/room-reachability-audit]
created: 2026-10-14
updated: 2026-10-15
source_files:
  - scenes/world/rooms/frozen_lake/contents/lake_icefall.room
  - scenes/world/rooms/maps/reach/reach_lattice.gd
---

# A one-screen-wide shaft cannot shut out wall climb

**Rule:** a drop that must stay one-way for a wall climber needs a gap of air at least 9 cells from any wall on
both sides, so a room at least two screens wide. In a 20-cell room, plan the drop as one-way for every kit
without wall climb, and say so.

- **Why.** Wall climb is a wall slide whose jump counts as a ground jump (`WallMobilityComponent`), so every wall
  face is a ladder and a take-off. From a slide, a jump and then the double jump rise 8.5 rows while drifting
  sideways.
  - The reach lattice moves 1 cell sideways per step, so it reaches about 8 cells across while still rising.
  - Physics, with air control 0.8, reaches about 6.4 cells (205 px) with frame-perfect timing.
  - In 20 cells (18 of air), a centred 2-cell hole sits 8 cells from each wall.
- **Measured (WORLD-35 step 3, lake_icefall's first draft).**
  - A chamber under a 2-cell throat (cols 9-10), 11 rows over the floor: the double jump falls 28 px short.
  - One wall-climb jump from the chamber walls reaches the throat's bottom cells (9,46) and (10,46) in the lattice.
  - With the glacier's mouth sealed, the four wall-climb kits climb back up from threshold_bridge's deck; the seven without wall climb do not.
  - The built icefall, one straight shaft, measures the same: the four wall-climb kits climb it. Keeping the wall-climb way back is an orchestrator call (2026-10-14): the plan's backtrack payoff.
- **Redoma too.** A gap that must stop a kit with Redoma also has to beat a shell (`gotchas/a-redoma-shell-is-standable-ground-up-to-192-px-over-its-origin`).
- **What does not help.** Stepped or domed ceilings and notched walls: each step face is a new take-off closer to
  the hole. A wall notched every other row hides the take-off from the lattice (its `_WALL` needs both body
  cells solid), but physics still slides on it. One-way `=` cells pass Ivo upward.
- **The check.** Seal the room's upper entrance on a `ReachGrid.for_kit` view, set `start` on the landing, run
  `ReachAudit.run_kit` per kit and look for the upper room in `report.rooms` (the WORLD-35 step 3 scratch test).
