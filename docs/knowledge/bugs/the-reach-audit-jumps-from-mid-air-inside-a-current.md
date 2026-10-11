---
id: bugs/the-reach-audit-jumps-from-mid-air-inside-a-current
type: bug
title: The reach audit launches a full ground jump from every cell of a current box, whichever way it blows
status: resolved
severity: low
tags: [rooms, reachability, audit, wind, currents, jump-reach]
related: [architecture/room-reachability-audit, systems/air, systems/rooms]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/maps/reach/reach_lattice.gd
  - scenes/world/rooms/maps/reach/reach_audit.gd
  - scenes/world/environment/wind/wind_zone.gd
---

## Summary

A `W` current is a TRANSIT node, and `ReachLattice.search` seeds a ground JUMP with the air jump kept from every seed cell. The audit therefore lets Ivo jump 4 cells up (8 with the double jump) from any point of any current box, against its direction too. The contract only says currents carry Ivo across their box.

## Symptom

TECH-05 review, 2026-10-11. In orchard_windy_gap the DOUBLE_JUMP tier reaches the west half (cols 1-15) only through the westward 90 px/s box: with currents left out of the grid, that tier reaches none of it. lake_well's 420 px/s squall (direction -1) counts as an elevator over the whole bank (rows 3-5). Today the finding list is the same with or without currents (53 findings both ways), so no error is hidden yet.

## Root cause

- `WindZone.reach_cells` (`wind_zone.gd:41`) returns every cell of the box and ignores `direction`, `speed` and the profile.
- `ReachAudit._node_for` (`reach_audit.gd:220-232`) merges the box into one TRANSIT node.
- `_connect` (`reach_audit.gd:197-199`) searches from all of the node's cells.
- `search` (`reach_lattice.gd:85-97`) pushes a JUMP with `air = 1` for any open seed.

That is right for a root, because `Player._try_jump` treats a climb as firm ground (`player.gd:940-944`). It is wrong for a current: there is no floor, no coyote time and no climb, so only a kept air jump is real.

## Fix

None yet. Seed TRANSIT cells that are currents (not CLIMB) with the FALL profile and the air jump only. Make the box carry Ivo only along its direction, or record the direction-blind union as an accepted limit in the architecture entry.

## Prevention

Add a lattice fixture: a ledge 4 rows above the top of a horizontal current box must not be reached in BASE.

## Resolution (2026-10-11)

A jump seeds only from a floor, a root hold or, with wall climb, a wall slide (`ReachLattice.search`); a current cell seeds a fall with the air jump kept. A current node starts its falls only on the box's downwind edge (`WindZone.reach_exit_cells`, grid flag `CURRENT_EXIT`, `ReachAudit._seeds`), so it carries Ivo along its direction. Fixture: `reach_lattice_test.test_a_current_gives_no_jump_from_mid_air`; `wind_zone_test`.
