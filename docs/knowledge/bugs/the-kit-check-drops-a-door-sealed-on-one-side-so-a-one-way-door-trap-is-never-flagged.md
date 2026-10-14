---
id: bugs/the-kit-check-drops-a-door-sealed-on-one-side-so-a-one-way-door-trap-is-never-flagged
type: bug
title: The kit check drops a door pair when either side is sealed, so a door that lets a kit in but not back out is never flagged as a KIT_TRAP
status: resolved
severity: medium
tags: [tech-08, kit-check, reachability, doors, softlock, audit]
related: [architecture/room-reachability-audit, systems/rooms, architecture/doors-and-interiors, bugs/the-kit-check-counts-a-guardian-arena-as-an-exit-before-the-guardian-exists]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/world/rooms/maps/reach/reach_audit.gd
  - scenes/world/rooms/maps/reach/reach_grid.gd
  - scenes/world/interactables/door/door.gd
  - scenes/characters/ivo/player.gd
---

## Symptom

Found in the TECH-08 review (2026-10-14, uncommitted). No room shows it today. Take a door pair where door A has no
`requires` and its partner B has one the kit lacks. In the game, the kit goes in through A and cannot come back through
B. The kit check skips the pair entirely, so the kit never goes in, and the trap the check exists to find cannot be
reported.

## Root cause

`ReachAudit._connect` (`reach_audit.gd:380`) skips a pair when `not pair[0].open or not pair[1].open`, and adds the
pairs it keeps as two-way edges. In the game, a door gates only its own use: `Player._try_door` checks `door.is_open()`
on the door Ivo stands at (`player.gd:589`), then moves him to the partner. So a pair sealed on one side is a one-way
edge. The architecture entry records the "both must hold" rule as intended, but that rule does not match the game.

Today the only asymmetric pair in a loaded region is `lighthouse_hatch`: the interior side requires
`all_guardians_restored`, the top side requires nothing. `lighthouse_top` has no other way in, so nothing is hidden. The
`trial_hatch` pattern (open outside, sealed inside; `architecture/doors-and-interiors`) is exactly the case the check
cannot see. Trials are not loaded today.

## Fix

Fixed 2026-10-14, before commit. `ReachAudit._connect` builds directed ways. A stair joins both ends. A door pair adds
one way per door: from each door the kit may use (`"open"`, which only a kit's grid sets; the union's doors are all
open) to its partner, as `Player._try_door` checks only the door Ivo stands at. The union is unchanged: two open doors
give both directions. `reach_kit_check_test` pins it: a door open outside and sealed inside, leading to a closed room,
is a KIT_TRAP for the base kit and none for a kit holding `owns_memorina.tres`. Today's world: no new trap. The
lighthouse hatch is one way into the interior for a kit without `all_guardians_restored`, and lighthouse_top has no
other way in, so nothing changes.

## Prevention

A gate model must follow the code that decides the gate in the game (here `Player._try_door`), direction included.
