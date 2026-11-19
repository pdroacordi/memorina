---
id: bugs/the-orchard-arenas-west-lintel-caps-ivos-jump-at-74-px-so-the-leaf-claw-cannot-be-dodged-there
type: bug
title: The orchard arena's west lintel caps Ivo's jump and double jump at 74 px over the west 60 px of floor, so the Leaf's overhead claw (150 px) cannot be dodged by an Ivo pinned at the west FightWall
status: resolved
severity: high
tags: [guardians, autumn, leaf, grd-15, arena, lintel, overhead-claw, fairness, playtest]
related: [playtests/2026-11-18-grd15-leaf-feel, bugs/the-orchard-arenas-west-lintel-overlaps-a-scarecrow-placed-at-the-96-px-margin, systems/guardians]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - scenes/world/rooms/wind_orchards/contents/orchard_arena.room
  - resources/characters/guardians/autumn_guardian/autumn_overhead_claw.tres
---

## Summary

`orchard_arena.room` has a stone lintel at cols 0-2, rows 0-4 (world x -10240..-10144, bottom y -1376). Ivo's body is 54 px
tall, so with any part of his 22 px body under the lintel, his feet rise at most 74 px. During the fight he stops at the
west FightWall at x -10196.9, which is under the lintel. `systems/guardians` gives the pinned answer to the overhead claw
as "a double jump (its box reaches 150 px up), or a pogo off the head". Neither is possible there: the double jump peaks at
74 px, and the scarecrow's head is out of reach.

## Symptom

Probe run (`lintel`, GRD-15 working tree on d47c80da): teleport, wait 0.7 s, then jump 0.45 s and jump again 0.6 s later
(the air jump). Peak height of the feet above the floor (y -1248):

| start x | peak |
|---|---|
| -10219 (FightWall side) | 74.0 |
| -10150 | 74.0 |
| -10135 | 202.0 (row 0 overhang at col 3) |
| -10120 | 202.0 |
| -10100 | 234.0 (full double jump) |

In play (`sj1`, no god mode, the driver jumps the sweeps): the string sweep, second sweep, overhead claw was thrown with Ivo at
x -10183.6. The two sweeps were jumped (feet peak y -1321.5, 73.5 px). The driver double-jumped at the claw's wind-up. The
claw hit at 0.1 s into its strike with Ivo 73.5 px up, its head against the stone
(`playtests/screenshots/2026-11-18-grd15-leaf-feel/claw_under_west_lintel.png`, `claw_hits_at_74px_cap.png`).

In `sj1`, 9 of 36 wind-ups started with Ivo under the lintel. Both overhead claws in that run did too. Ivo gets there because
the gust blows him to the west wall whenever the scarecrow stands east of him. The dodging driver also backs off west.

## Why the tests pass

`autumn_guardian_kit_test.test_the_claw_reaches_a_jumper_the_sweeps_do_not` and the reach tests measure the claw against
Ivo's traced jump in open air. No test places Ivo under the arena's real ceiling.

## Fix

Fixed in GRD-15 (2026-11-19), the second proposal: the fight's floor ends before the lintel. In `orchard_arena.room`
the west `FightWall` moved from the doorway (col 0, 4 cells) to col 3, 8 cells tall (rows 1-8) up to the stone
overhang at (3,0), so it seals the column; the `Arena` (contents scene) starts at col 3 (x 96, 1184 px wide) so the
wall's anchor is inside it and closes with the fight. During a fight Ivo stops at x about 136, with 288 px of air over
the floor up to the room's top. Test: `autumn_guardian_kit_test.test_the_arena_leaves_room_to_jump_the_claw` (every
column of the fight's floor has the claw's reach plus Ivo's height of air). The lintel itself is unchanged.

Why not raise the lintel: to let the double jump clear the claw (feet over 150 px), its bottom must be at row 1 or
higher, and the lintel exists to leave only 32 px over the bramble barrier at (1,8), so it is no step into the cliff
chimney before wall climb (`bugs/the-orchard-arena-barrier-is-jumped-over-into-the-cliff-chimney`). A shorter lintel
reopens that softlock. The AI fallback (no claw under a low ceiling) was not needed.

Not changed: the room's doorway geometry, the bramble barrier, the east FightWall and the top FightWall at (30,0). The
FightWall at col 3 does not stand at the room's edge as the legend's note asks; the room's header says why.

## Options considered

Choose one:
- Raise the lintel's bottom to at least 150 + 54 + a margin over the floor. That is 4 rows of air, not 4 rows of stone.
  Re-check the chimney barrier's "no step" rule (`bugs/the-orchard-arena-barrier-is-jumped-over-into-the-cliff-chimney`).
- Move the west FightWall east of col 2, so the fight's floor never lies under the lintel.
- Leave the room and do not throw the claw while Ivo is under a ceiling lower than its reach. That is a new AI rule and the
  weakest choice.

Then add a test that measures the claw's dodge from the FightWall's stop with the room's collision loaded.
