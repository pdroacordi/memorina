---
id: bugs/the-kit-check-counts-a-guardian-arena-as-an-exit-before-the-guardian-exists
type: bug
title: The kit check counts a milestone room as a way out even when nothing in the game gives that milestone yet (orchard_arena, caldera_arena, lighthouse_interior)
status: resolved
severity: medium
tags: [tech-08, kit-check, reachability, guardians, softlock, audit, grd-04, story-03]
related: [architecture/room-reachability-audit, systems/rooms, bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera, bugs/the-kit-check-drops-a-door-sealed-on-one-side-so-a-one-way-door-trap-is-never-flagged]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - scenes/world/rooms/maps/reach/reach_kit_check.gd
  - resources/world/maps/reach_kits.tres
  - tests/scenes/world/rooms/maps/reach/room_kit_test.gd
---

## Symptom

Found in the TECH-08 review (2026-10-14, uncommitted). `ReachKitCheck._exits` (`reach_kit_check.gd:19-35`) makes every
milestone room the kit lacks an exit, as long as the next kit gets home from it. Three of those rooms give nothing in
today's game:

- `orchard_arena` and `caldera_arena`: no guardian is placed (GRD-04, "Arena empty until GRD-04").
- `lighthouse_interior`: the Memorina is not handed over in the world (STORY-03).

The 2026-10-14 summary lists `caldera_arena` among the lake kit's exits, `orchard_arena` among the woods and both
kits' exits, and `lighthouse_interior` as the base kit's exit. A pocket that holds one of these rooms is reported safe
because "beating the guardian" gets the player out, but no guardian exists to beat.

No kit depends on an exit today. In a scratch run of `ReachAudit.run_kit` with no exits, all nine kits (plus
woods_orchards and woods_orchards_caldera) found 0 pockets. The risk is that the next room change, WORLD-35 first,
gets a trap excused. `room_kit_test.test_the_lake_kit_gets_out_of_the_caldera` guards
`bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera`. If that trap came back with `caldera_arena` inside the
pocket, and Sombra opened the way home for lake_caldera, the test would still pass.

## Root cause

`ReachMilestone` cannot say whether the game gives the milestone yet. Its `note` mentions GRD-04 and STORY-03, but
`_exits` never reads it.

## Fix

Fixed 2026-10-14, before commit. The exit rule now reads what the game places. `ReachWorldLoader` records each guardian
that a room's contents instance (a scene whose `stats` is a `GuardianStats`) in `ReachGrid.guardians`, as id to room.
`ReachKitCheck.given(grid, milestone)` holds only when the milestone restores at least one guardian, and each of them
fights in the milestone's room. `_exits` skips the rest. So:

- orchard_arena and caldera_arena (no guardian, GRD-04) are no way out;
- lighthouse_interior (the Memorina, no guardian; STORY-03 has no hand-over) is no way out;
- bloom_hollow and lake_frost_arena still are.

The kit stages are unchanged. Today's world stays at 0 kit traps, and a scratch `run_kit` with no exits at all gives 0
pockets in all 11 kits. `room_kit_test` adds two checks: every exit is a placed guardian's arena (today exactly
bloom_hollow and lake_frost_arena), and the lake kit counts no Caldera room as an exit. `reach_kit_check_test` adds an
arena whose guardian is not placed (still a trap) and a milestone with no guardian (never given).

## Prevention

A rule that excuses a trap must depend on something the game actually does today, not on a planned feature.
