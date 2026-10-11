---
id: bugs/the-lighthouse-hatch-ceiling-caps-the-last-climb-step
type: bug
title: The lowered ceiling over the lighthouse hatch landing cuts the final spiral jump to 10 px of clearance
status: resolved
severity: low
tags: [rooms, lighthouse-interior, traversal, jump, ceiling, hatch, world-24]
related: [systems/rooms, playtests/2026-10-09-traversal-opening, architecture/doors-and-interiors]
created: 2026-10-10
updated: 2026-10-11
source_files:
  - scenes/world/rooms/frost_edge/contents/lighthouse_interior.room
  - scenes/world/interactables/door/door.gd
---

## Summary

For the `hatch_up` look, WORLD-24 filled `lighthouse_interior.room` rows 1-6 with stone, so the ceiling sits 64 px over
the hatch landing (row 9, cols 13-17). The last step of the spiral starts on the row-12 ledge (cols 1-10). On that
jump Ivo's head now hits the ceiling at y 224, so his feet top out at y 278: 10 px over the landing instead of about
47 px. A running jump taken off more than about 30 px before the edge, or an apex-steered jump, misses the landing
and drops him to row 15.

## Symptom

Measured in the running game with the base kit (review, 2026-10-10). Start on the row-12 ledge at world y 12384; the
landing top is 12288 and the ledge edge is at x 24352:
- Right held from take-off at x 24350 or 24336: lands on the landing (12287.9). The peak is 12278.2, so the head hit
  the ceiling.
- A running jump taken off at x 24286 (77 px before the edge): falls to row 15 (12479.9).
- Jump straight up, right pressed 0.15 s later: the capsule catches the corner at x ~24407, rests there 0.6 s, then
  slides off and falls.
- Right pressed 0.25 s or 0.35 s after the jump: falls to row 15.

The traversal playtest of 2026-10-09 found that this room needs apex steering on its overhung steps, and that 3-row
steps clear by 43-46 px. On this step, apex steering now fails.

## Root cause

- `lighthouse_interior.room:10-16`: rows 0-6 are solid, so the shaft's ceiling is row 7's top, y 224.
- The take-off ledge's top is 384. Ivo's capsule is 54 px tall with its origin at the feet (`ivo.tscn`, capsule
  height 54 at y -27). Ivo's jump would peak 143 px up (`JumpReach`, `MapGuide.ivo_reach()`), at feet 241. The
  ceiling stops it at feet 278.
- The landing's top is 288, so Ivo's feet are above it for only the 10 px either side of the bonk. That is about
  0.15 s, and Ivo has to cross the landing's west face (x 24416) in that time.

## Fix

Not fixed (review only). Possible fixes:
- Raise the ceiling over the take-off side only: keep rows 1-6 solid over cols 11-19 and open them over cols 1-10,
  so the hatch still meets a low ceiling.
- Or lower the row-12 ledge's step to 2 rows.
- Or move the landing one row lower and keep the ceiling 64 px above it.
- `systems/rooms` (Doors) states the 64 px ceiling as a rule for `hatch_up`. Any fix has to keep the room's climb
  clearance as well.

## Prevention

- Re-run the room's climb when a change fills cells over a route.
- `tools/playtest/scripts/traverse_opening_k_lighthouse_interior_climb.json` is stale. It dates from the 4-row
  version of the room and falls to the floor at its second jump, so it no longer proves the spiral.
- The planned reachability audit (`architecture/room-reachability-audit`) would compute this from the capsule and
  the ceiling.

## Resolution (2026-10-11)

The lowered ceiling now covers only cols 14-19 (rows 1-6), over the hatch and the landing's east part; the jump from the row-12 ledge arcs through open air over cols 9-13. Re-run in game: the scratchpad timelines `lh_run_a`, `lh_r025` and `lh_r035` (the late-steer cases that fell) all land on the landing at y 12288.
