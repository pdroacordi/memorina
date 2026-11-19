---
id: bugs/the-mentors-ice-wave-parks-at-the-lanterns-west-step-on-a-pinned-ivo
type: bug
title: The slam's ice wave stops at the lantern's west step and stays live over a pinned Ivo, so the documented single jump lands in it every time
status: fixed
severity: medium
tags: [guardians, mentor, finale, grd-17, floor-runner, ice-wave, thorn-row, lantern, fairness]
related: [systems/guardians, playtests/2026-11-19-grd17-mentor-feel, playtests/2026-11-19-grd17-mentor-fight, bugs/a-hit-at-the-lanterns-west-wall-knocks-ivo-into-the-mentor]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - scenes/characters/guardians/spawns/floor_runner/floor_runner.gd
  - scenes/characters/guardians/frost_guardian/spawns/ice_wave.tscn
  - resources/characters/guardians/mentor/mentor_slam.tres
---

## Symptom

Ivo stands pinned on the lantern's west floor, against the 96 px step (x 10987, the step's face at x 10976). The
mentor slams from 59 px. Ivo jumps from the raised arm, which is the answer in systems/guardians ("Pinned at a wall...
Slam: jump from the raised arm, then the wave"). He lands back in the west-running ice wave every time: **6 of 6** in a
forced run (`sl_jump`, feel playtest). The wave sits at x 10970-10974 from ~0.6 s to 1.5 s after its birth, and it
hits him as his feet come down (y 12 px above the floor). The same pinned spot with a double jump: 0 of 6. A single jump
with a 0.1 s step east before landing: 0 of 6.

Across 15 logs (this feel pass and the implementer's), **10 of the 13 floor-runner hits** (ice wave 10, thorn row 2) were
at x 10968-10975. That is the wave or row parked at the step. Two no-god deaths in the feel pass began with this hit
(`f_ng1` 54.4 s, `f_ng4` 53.8 s).

## Root cause

`FloorRunner._advance` probes for floor ahead with a ray from `(head + width/2, floor - 8)` down 20 px. At the step face
the ray starts inside the 30 px step solid. A ray that starts inside a shape does not report it (`hit_from_inside` is
false), so the probe reads a gap and sets `_gap_at`. The runner then holds its head there for the rest of `live` (ice
wave: `warn` 0.3 + `live` 1.2 s). The head stops one physics step past the face, at ~x 10970. Its 20 px box (x
10960-10980) overlaps the 22 px body of an Ivo pinned at x 10987 (x 10976-10998) by about 4 px.

The east side does not do this. The FightWall is inside `arena_bounds`, so `_edge()` stops the runner at x 12014, inside
the wall. Ivo pinned there (x 11989) is never under a parked runner.

## Fix

Fixed in GRD-17's fix round (2026-11-19), for every guardian. A `FloorRunner` ends where it stops: at a gap (the step
reads as one, the probe starting inside it), at the arena's edge or at its reach. `FloorRunner.is_live` and `lifetime`
use `_end_time()` (the end of `live`, or the moment its head stops), so its box goes off at once and it fades from there.
A pinned Ivo is still hit while the wave passes him, as at every wall, but never on landing.

The Frost wave and shock, Bloom's thorn row and the Sun's ember burst already have `live` equal to `reach / speed` (the
shock's 0.353 s run outlasts its 0.35 s live), so in the open nothing changed for them; only a stop short of the reach
ends earlier. The golden AI timelines do not involve spawns: none changed. Test:
`spawned_attack_test.test_a_runner_ends_where_it_stops` (a floor that ends, and a solid step).
Re-run of the forced slam pinned at the west step with a single jump from the raised arm: 0 of 6 hit, twice (was 6 of 6).

## Prevention

A `floor_runner` test with a step in its path: the runner must end (or keep its box off the face) at the step. Run the
pinned answers in systems/guardians against a forced move on both walls, not only the guardian's box.
`test_a_jump_clears_the_slam` checks the hands only, not the wave after the landing.
