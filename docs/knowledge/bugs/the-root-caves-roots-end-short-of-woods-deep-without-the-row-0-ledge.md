---
id: bugs/the-root-caves-roots-end-short-of-woods-deep-without-the-row-0-ledge
type: bug
title: WORLD-25 removed woods_root_caves' row-0 ledge, so the Enraizar climb out of the earth well ends 11.6 px below woods_deep's floor and a jump off the top rung falls back to the well floor
status: resolved
severity: medium
tags: [rooms, level-design, spring-woods, world-25, root, climb, regression]
related: [playtests/2026-10-11-world25-rework, bugs/the-root-caves-well-is-climbable-without-enraizar, systems/roots-and-climbing, systems/rooms, playtests/2026-10-09-traversal-woods-lake]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/rooms/spring_woods/contents/woods_root_caves.room
  - tools/playtest/scripts/traverse_woods_lake_i11_rv2_caves_root_climb_one_run.json
  - tools/playtest/scripts/traverse_woods_lake_i10_rv_caves_root_climb_ledge_to_deep.json
---

## Summary

The WORLD-25 rework (uncommitted, worktree agent-a5ca98ed7ee598b83 on 9df7ec6) turned `woods_root_caves.room`
row 0 `==..` into `....`. That one-way at y 384 was the landing the 2026-10-10 fix added for the Enraizar rungs
(`bugs/the-root-caves-well-is-climbable-without-enraizar`, Resolution). Without it the rungs end at feet ~426 and
no single jump reaches woods_deep's floor (y 288). Espacial 2 (design 02 section 8) now needs the double jump,
and only a ground jump from mid-climb followed by the air jump gets out.

## Symptom

Re-run on the rework tree (imports 03:28:52), `"skills": [0]`, songs ROOT and RAIN:

- `traverse_woods_lake_i11_rv2_caves_root_climb_one_run.json` unchanged. Roots grow, Ivo climbs from 704 to 433
  and bobs at the top at feet ~426 (`climb=false`). The jump at t 12.5 is the air jump (`air_spin`): peak feet
  **299.6** at t 13.1, 11.6 px below the floor at 288. He falls straight back to the well floor at
  (-3564.5, 703.9). Before WORLD-25 the same jump landed on the ledge at 384, and one more jump reached woods_deep
  (`playtests/2026-10-09-traversal-woods-lake`, rows 264 and 355).
- Variant (scratch timeline): a ground jump from the hold at feet 461, then the air jump with left held, lands on
  woods_deep at (-3699.9, 288). So the double jump gets out.

## Impact

- Not a softlock. The Bloom Guardian gives Enraizar and the double jump together (design 04 section 2), so
  every player with roots also has the air jump.
- The obvious move is to climb to the top and press jump. From the top bob that jump is the air jump, and it
  fails and drops him 280 px back to the floor. The working exit (jump mid-climb, then the air jump) is
  non-obvious.
- The header (`woods_root_caves.room:2`, "roots climb it, rows 1-5, back to the hole") is now wrong twice. Roots
  alone do not reach the hole. With row 0 clear, `RootSpanFinder._shafts` makes the shaft rows 0-5, not 1-5,
  though the pulse disc from the well floor still ends the rungs near row 1.
- `i10_rv_caves_root_climb_ledge_to_deep` and `i11_rv2_caves_root_climb_one_run` no longer reach woods_deep.

## Root cause

The audit models a root SHAFT as climbable to the top of its earth walls (`systems/rooms`, Reachability audit,
"a shaft or pillar is climbed"). It does not model the pulse-limited rung extent, or the 143 px jump from a hold.
So it reported the ledge as LEADS_NOWHERE, and the rework removed it on that basis.

## Fix

Not fixed. Options:
- restore `==` at row 0 cols 28-29 and allowlist it with the reason the audit cannot see (the rungs' landing,
  this file). The DJ skip stays closed, because the shelf block is still two rows lower (best peak 431.3);
- or make the over-the-top hop land on woods_deep's floor (raise `top_hop_height`, or grow rungs into woods_deep's
  rows 33-35). This is a bigger change and touches `systems/roots-and-climbing`.

## Prevention

Before removing a ledge the audit flags, search `docs/knowledge/bugs/` for its room and cell. A ledge that a
resolved bug added on purpose belongs in the allowlist, not in the rework. Re-run the room's existing timelines
(`tools/playtest/scripts/*<room>*`) after a rework.

## Playtest confirmation (2026-10-11, `playtests/2026-10-11-world25-rework`)

Same tree, my own timelines, `"skills": [0]`, songs ROOT and RAIN, Enraizar played on the well floor at x -3488:
- Two probes (deleted after the review): up held to the top. The bob starts at feet ~459 (`climb=false`), so the first press is already the air jump: peak 332, then he falls to 704. The second press does nothing. 2 of 2 failed.
- A probe: a jump off the rungs at feet 489 (`climb=true`), no air jump: peak 339.5, fails.
- A probe: the same jump, then the air jump 0.55 s later with left held: peak 216, lands on woods_deep at (-3674.5, 288), 72 px of margin. `world25_caves_return_loop.json` repeats it at the end of a 45 s loop and lands at (-3675.9, 288).
- Window (inferred from those peaks): the rung jump must leave from feet <= ~560 and before the top bob, which is about 1.2 s of the 80 px/s climb. The timing is generous. The problem is that the order is non-obvious.

## Resolution (2026-10-11)

Restored `==` at `woods_root_caves.room` row 0, cols 28-29, and listed it in `reach_allowlist.tres` (woods_deep 28,35, LEADS_NOWHERE) with this file as the reason; the header names the landing. Re-run on the fixed tree:
- `traverse_woods_lake_i11_rv2_caves_root_climb_one_run`: lands on the one-way at (-3520, 384) at t 13.6, then on woods_deep at (-3700, 288) at t 14.8.
- `traverse_woods_lake_i10_rv_caves_root_climb_ledge_to_deep`: lands on woods_deep at (-3700, 288) at t 15.6.
- `world25_caves_return_loop`: ends on woods_deep at (-3672.7, 288).

