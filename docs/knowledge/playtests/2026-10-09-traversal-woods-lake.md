---
id: playtests/2026-10-09-traversal-woods-lake
type: playtest
title: WORLD-05 traversal of Spring Woods and Frozen Lake - base kit, then double jump, Enraizar and Chuva
status: active
build: 6fa077a for the first session. Re-verification (2026-10-09, evening) on ea47690 plus the uncommitted WORLD-05 seam work (game.gd, camera.gd, room.gd, room_residency.gd, three .room files), imported 23:25:32; see the Re-verification section for which runs saw which code. First session build note: 6fa077a (imported 14:53). Room .tscn files were rewritten at 18:23 with no content change (git clean); backdrop.gd (props commit 14fea46) changed at 18:26. game.gd, room.gd, Player and every .room are unchanged for all runs.
area_tested: "spring_woods (woods_edge, woods_deep, woods_canopy, woods_root_caves, woods_pond, bloom_hollow), frozen_lake (lake_waterfall_path, lake_fishing_village, lake_fisher_hut, lake_well, lake_ice_caves, lake_frost_arena, lake_shore, lake_high_wall, lake_chasm), entries into orchard_terraces, orchard_well, orchard_chasm_bridge"
tags: [traversal, world-05, greybox, rooms, seams, gates, base-kit, softlock, double-jump, root, rain, precision]
related: [playtests/2026-10-09-traversal-opening, bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room, bugs/crossing-a-seam-upward-takes-ivo-out-of-the-frame, bugs/the-root-caves-well-is-climbable-without-enraizar, bugs/a-hop-below-a-seam-flips-the-room-twice, bugs/a-jump-across-a-horizontal-seam-loses-its-height-in-the-fade, bugs/a-neighbour-room-has-no-ground-until-ivo-enters-it, bugs/the-fishing-village-well-has-no-way-out, bugs/walking-across-a-room-seam-fades-back-and-forth, systems/rooms]
created: 2026-10-09
updated: 2026-10-10
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }   # after the 2026-10-10 re-check; the first session was fun 2, fluidity 2, aesthetics 3
screenshots:
  - screenshots/2026-10-09-traversal-woods-lake/deep_floor_walk_into_pit.png
  - screenshots/2026-10-09-traversal-woods-lake/pond_head_out_of_frame.png
  - screenshots/2026-10-09-traversal-woods-lake/bloom_guardian_reached.png
  - screenshots/2026-10-09-traversal-woods-lake/terraces_short_press_falls_back.png
  - screenshots/2026-10-09-traversal-woods-lake/canopy_double_jump_into_orchard_well.png
  - screenshots/2026-10-09-traversal-woods-lake/caves_root_shaft_climb.png
  - screenshots/2026-10-09-traversal-woods-lake/pond_rain_log_to_passage.png
  - screenshots/2026-10-09-traversal-woods-lake/mill_slab_to_stub_jump_cut.png
  - screenshots/2026-10-09-traversal-woods-lake/waterfall_r18_to_r15_under_r12.png
  - screenshots/2026-10-09-traversal-woods-lake/fishing_well_cannot_climb_out.png
  - screenshots/2026-10-09-traversal-woods-lake/frost_arena_reached.png
  - screenshots/2026-10-09-traversal-woods-lake/chasm_root_bridge_crossing.png
  - screenshots/2026-10-09-traversal-woods-lake/rv_fixed_paths_and_caves_skip.png
  - screenshots/2026-10-09-traversal-woods-lake/rv_square_to_mill_glide_flipbook.png
  - screenshots/2026-10-09-traversal-woods-lake/rv_square_to_mill_backdrop_pop.png
  - screenshots/2026-10-09-traversal-woods-lake/rv_mill_to_square_backdrop_pop.png
  - screenshots/2026-10-09-traversal-woods-lake/rv_mill_backdrop_before_and_after_residency.png
  - screenshots/2026-10-09-traversal-woods-lake/rv_region_cut_lane_west_to_woods_edge.png
  - screenshots/2026-10-09-traversal-woods-lake/rv_upward_seam_ivo_out_of_frame.png
  - screenshots/2026-10-09-traversal-woods-lake/rv2_square_to_mill_glide_clipped_backdrop.png
  - screenshots/2026-10-09-traversal-woods-lake/rv2_mill_backdrop_first_session_vs_clipped.png
  - screenshots/2026-10-09-traversal-woods-lake/rv2_mill_slab_hop_flips_to_the_lake.png
  - screenshots/2026-10-09-traversal-woods-lake/rv3_mill_slab_hop_one_cut_then_lake.png
  - screenshots/2026-10-09-traversal-woods-lake/rv3_square_to_mill_body_crossed_glide.png
  - screenshots/2026-10-09-traversal-woods-lake/rv3_region_cut_with_sliver.png
---

# Traversal: Spring Woods and Frozen Lake (WORLD-05)

## What was tested

- The timelines are `tools/playtest/scripts/traverse_woods_lake_*.json`, one leg each, started with
  `player_position`. The runner's `log` recorded room, position, velocity, state, fade and doors every
  0.1-0.2 s (0.02-0.03 s for probes).
- Climbs were run closed-loop: one take-off x per step, corrected from the logged position, rerun until
  stable. The final waterfall config passed 3 of 3 times, the chasm config 6 of 6.
- `APPDATA` was redirected for every run. The real save's md5 (`49ae7e28…`) was the same before and after.
- Coordinates are world px. Cells were read from the `.room` files with a script; column counts by eye were
  wrong once in this session.

## Summary of blockers, softlocks and skips

| # | Severity | Where | What | Entry |
|---|---|---|---|---|
| 1 | **high, blocker** | village_mill slab (y 32) → lake_waterfall_path stub (y -96) | The only way into the Frozen Lake crosses the seam at y 0 mid-jump. The fade freezes Ivo ~1 s, a release during it cuts the jump, and a 0.45 s press falls back into the mill. Only a jump held ~1.5 s gets in (9 px spare). | `bugs/a-jump-across-a-horizontal-seam-loses-its-height-in-the-fade` |
| 2 | **high, blocker (double-jump kit)** | woods_deep r04 → woods_canopy; canopy launch branch → orchard_terraces | Same cause: a 0.35 s second press peaks 54 px short on both. A 2 s hold passes. | same |
| 3 | **high, softlock** | lake_fishing_village well mouth (x 1536..1664) → lake_well one-way (y -1504) | The curbs are 160 px above the one-way and jumps are cut by the seam. No other exit; only death leaves. | `bugs/the-fishing-village-well-has-no-way-out` |
| 4 | **high, skip** | woods_canopy's open top (cols 20-58) → orchard_well | A double jump goes through orchard_well's floor, which is not resident, and lands in the well's west half. The same jump under the terraces' solid floor embeds Ivo in it. | `bugs/a-neighbour-room-has-no-ground-until-ivo-enters-it` |
| 5 | medium, precision | lake_waterfall_path r18 (S15-19, y -1344) → r15 (S8-11, y -1440) | r12 (S12-13) hangs over the 3-cell gap. Only a jump held 0.20-0.25 s with left held from the edge lands (0.15 and 0.30 fail). The mirrored west step (r18 S0-4 → r15 under r12 S6-7) has the same shape. | - |
| 6 | medium | woods_root_caves root shaft (cols 28-31) | The rungs end 3 rows below woods_deep's rim. Holding up at the top bobs forever. The jump off the hold is cut by the seam, and a second jump from a tile corner gets out. | - |
| 7 | low | woods_deep east floor | The floor walk from woods_edge leads under a low ceiling straight into the water pit. The respawn is at the pit's lip. | - |
| 8 | low | lake_shore east floor | Same shape: the floor walks under the causeway into the lake (`f`). The way on is up S37-38 to the causeway. | - |

**Song gates that were checked:**
- No song gate on the tested main paths can be skipped without its song or kit.
- The skip in #4 needs the double jump, as both routes into the orchards do.
- The accepted one was not re-tested: the pond's Chuva passage is reachable by double jump.

## Seams (the fix in 2931927): confirmed

- **Every walk-in seam on the route is now one fade.** Measured on 11 walk-ins:
  - lane_west → woods_edge, woods_edge → woods_deep, deep → pond, pond → bloom_hollow;
  - waterfall → fishing village and → ice caves, ice caves → arena;
  - fishing village → shore, shore → high wall, high wall → chasm, chasm → orchard_chasm_bridge.
- Each costs ~1 s (`pmode=4` ~0.9 s, `fade` peaking 0.8-0.9) and the room never swaps back. A held
  direction loses that second of travel; walking resumes at 192 px/s.
- `bugs/walking-across-a-room-seam-fades-back-and-forth` is fixed for walking. The fade still freezes Ivo,
  which is what breaks the jumps in #1-#3 and #6.

## Spring Woods, base kit

| Leg | Timeline | Result |
|---|---|---|
| lane_west fence → woods_edge (two blocks; hut door shows its prompt) | `a_lane_to_woods_edge` | ok |
| woods_deep: one-way (cols 44-46, y 192) → mound top (y 96) → west steps → exit | `b_deep_over_mound` | ok |
| woods_pond: col 28 → one-way (cols 24-26, y 128) → shelf (row 2, y 64) → west steps | `c2_pond_shelf_to_bloom` | ok |
| bloom_hollow: the Bloom Guardian stands at col 25 and attacks ~1.6 s after the fade | `c2_…` | reached (`bloom_guardian_reached.png`) |
| woods_pond: fall into the dry basin and climb out east (352 → 256 → 192) | `c_pond_to_bloom`, `d_pond_basin_exit` | ok, two jumps |

**The base kit passes the whole main path from village_lane_west to bloom_hollow.**

- **woods_deep: the floor walk ends in the pit** (#7, `deep_floor_walk_into_pit.png`).
  - **Where:** the corridor from woods_edge runs under the stone ceiling (row 30, 64 px headroom) into
    the pit (cols 33-39, x -3424..-3200).
  - **The way on:** a straight jump onto the one-way (x -3072..-2976), then a jump left from its east
    end. He lands on the mound at x -3173 with ~40 px to spare.
  - The hazard respawn is the pit's east lip (-3182, 288). A held left walks him straight back in, and
    three falls killed him (a timeline artefact).
  - **Fix:** a one-cell step at col 42, or raise the corridor floor east of the pit, so a floor walk
    ends at the one-way.
- **woods_pond: the shelf puts Ivo's head out of frame** (`pond_head_out_of_frame.png`).
  - The shelf (y 64) is 64 px below the room's top, and nothing is above it. For ~0.5 s of the jump
    onto it only his feet show.
  - **Fix:** lower the shelf and the one-way by 2 rows.
- **woods_pond: a full held jump from col 28 overshoots the one-way.** It drops into the 1-cell gap
  (col 23) under the shelf's end and into the basin. That is escapable, so this is a feel note only.
  The one-way is drawn as a solid floating earth block.

## Spring Woods with double jump, Enraizar and Chuva

`"skills": [0]`, `"known_songs": [6, 7]` (ROOT 6, RAIN 7).

| Leg | Timeline | Result |
|---|---|---|
| woods_deep climb: mound → r23 → r19 → r15 → r08 → r04 | `e_deep_climb_to_canopy` | ok (96-128 px steps; single jumps would do) |
| r04 → woods_canopy (224 px, hole cols 48-55) | `e_…`, `e2_canopy_jump_held_through_fade` | **fails with a 0.35 s press** (peak -809.8, 54 short); held 2 s: peak -892.5, ok |
| canopy floor → block (cols 15-18) → launch branch (cols 9-14) | `g_canopy_branch_to_terraces_*` | ok |
| launch branch → orchard_terraces (224 px, hole cols 44-51) | `g_…_tap`, `g_…_held` | **fails with a 0.35 s press** (peak -1193.8); held: peak -1278, ok (`terraces_short_press_falls_back.png`) |
| double jump from the canopy one-way (cols 36-41) | `f_canopy_west_to_branch` | **goes through orchard_well's floor** (#4, `canopy_double_jump_into_orchard_well.png`) |
| Enraizar bridge over woods_deep's pit (banks cols 32/40), drop through the hole | `h_deep_root_bridge_drop_in` | ok: lands on the caves' row 7 (y 608) |
| caves: way back without roots | `i_caves_way_back_up` | blocked as designed: single peak y 464, double y 370; rim y 288 |
| caves: Enraizar shaft, climb, jump out | `i_…`, `i2_caves_climb_and_jump_out` | ok with two jumps (#6, `caves_root_shaft_climb.png`) |
| Chuva lifts the pond log to the passage (cols 9-13) | `j_pond_rain_log_to_passage` | ok: log y 339 → 191 in ~2.4 s after the pulse; walked in to x -5451 (`pond_rain_log_to_passage.png`) |

### Does the canopy ledge under cols 4-11 reach the opening? (question from the orchard agent)

**Yes.**
- The launch branch (row 4, cols 9-14, x -4192..-4000, y -1024) lies under orchard_terraces' floor hole
  (cols 44-51, x -4352..-4096) for 3 cells (x -4192..-4096).
- The floor is 224 px up (7 rows). The measured double-jump peak from the branch is y -1278, which clears
  it by 30 px. Ivo then steps onto col 52.
- Two caveats:
  - #2: a normal press is cut at the seam y -1152.
  - The branch's other 3 cells (x -4096..-4000) are under solid floor, which a straight double jump
    enters (#4).

### Root caves (#6)

- **Drop in works.** The bridge holds while Ivo walks west over it, and he falls through the hole into
  the caves.
- **The way back up needs Enraizar, as designed.** Without it, the double jump peaks 82 px below the rim.
- **The rungs stop short of the rim.**
  - Enraizar played on the landing grows rungs in the caves' rows 0-4 only (y 384..544). `RootGrower`
    roots only the room the pulse is played in, and the shaft's last 3 rows (woods_deep rows 33-35) belong
    to woods_deep.
  - At the top rung (y ~396) holding up loops: over-the-top hop, re-grab, hop, for as long as up is held.
  - The jump off the hold is cut by the seam fade (peak y 339.8). He lands on the caves' col 27 corner at
    (-3571.9, 384), and a second jump puts him on woods_deep's floor.
  - Back on top, he is in the pocket west of the pit, so Enraizar is needed again to leave. Expected.
- **Fix:** a one-way at the shaft's top inside the caves (row 0 beside col 28), or move woods_deep rows
  33-35 into the caves room, so the rungs end at a floor.

## Frozen Lake, base kit

| Leg | Timeline | Result |
|---|---|---|
| mill floor → trail (y 160) → slab (y 32) | `k2_mill_floor_trail_slab_stub` | ok (both 128 px steps by straight jump + apex steer; margin ~15 px) |
| mill one-way (y 192) → trail by running jump | `k_mill_trail_to_waterfall_bench` | fails: the slab overhead (y 64) caps the jump at 74 px; the floor route works |
| slab → waterfall stub (y -96) across the seam y 0 | `k2_…`, `k3_slab_stub_jump_held` | **0.45 s press fails** (peak -37.9); 1.6 s hold lands (peak -105) (#1, `mill_slab_to_stub_jump_cut.png`) |
| waterfall bench: down sits Ivo on it | `u_waterfall_bench_sit` | ok (sit=true at 2640, -96) |
| waterfall climb, east branch, 16 steps to the top floor (y -1632) | `l_waterfall_climb_east` | ok, 3 of 3 with the final inputs; see precision notes |
| waterfall west branch (r15 → r12 S6-7 → r09 S0-5) | `v_waterfall_top_west_branch` | ok, 3 of 3 |
| top → lake_ice_caves (hump, dip, raised shelf) → lake_frost_arena | `n_ice_caves_to_frost_arena` | ok; the Frost Guardian stands and attacks (`frost_arena_reached.png`) |
| top → lake_fishing_village → fisher hut door in and out | `o_waterfall_top_to_fishing_village_door` | ok (prompt at x 1947; arrives at 48144, 12288; back at 1936) |
| well: running jump over the mouth | `q_fishing_village_well_jump_to_shore` | ok (lands x ~1440) |
| well: fall in and try to leave | `p_fishing_village_well_fall_and_escape` | **softlock** (#3, `fishing_well_cannot_climb_out.png`) |
| fishing village → lake_shore causeway (S37-38, then the causeway's face) → high wall floor passage → lake_chasm floor | `r_shore_causeway_high_wall_to_chasm` | ok, **no Congelar needed**; walks under the high wall's one-way |
| chasm climb (S30-33 → S34-37 → S29-32 → shelf y -2016) | `s_chasm_climb_and_root_bridge` | ok, 6 of 6 |
| Enraizar from the east lip (x -2680) → west lip → orchard_chasm_bridge | `s_…` | ok: crossed to (-3255, -2016) (`chasm_root_bridge_crossing.png`) |
| chasm control, no root (double jump at the lip) | `t_chasm_control_no_root` | blocked as designed: the roof caps the jump, Ivo falls in and respawns on the east lip |

**The base kit passes the Frozen Lake main path only if the jump into lake_waterfall_path is held
through the fade (#1).** Everything past the stub works with the base kit, with the precision notes
below.

### Waterfall precision

- **Head-bump steps.** Each upper ledge (96 px up) starts where the lower one ends, so its underside is
  10 px above Ivo's head. Holding the direction from take-off bumps. Jump straight and steer only after
  ~0.3 s, as in the lighthouse interior (`playtests/2026-10-09-traversal-opening`). Most steps
  (adjacent ledges) have this shape.
- **Capped steps (4 of them).** At r51 → r48, r42 → r39, r33 → r30 and r27 → r24, the ledge above the
  take-off ledge is 160 px up. That caps the rise at 106 px for a 96 px step across a gap of 1-2 cells.
  - The only working input is the direction held from take-off, at the ledge's edge. He lands 3-10 px
    onto the next ledge.
  - Apex steering, which the other steps need, fails here.
  - The player has to learn two opposite inputs on one climb.
- **r18 → r15 (#5)** is the hardest step on any base-kit path so far (`waterfall_r18_to_r15_under_r12.png`).
  - The 3-cell gap has r12's ledge 64 px above r15's level.
  - A full jump bumps r12 and falls short (blocked at r15's face, x 2956); a 0.1-0.15 s tap is too low.
  - Only a press of 0.20-0.25 s with left held from the edge lands.
  - **Fix:** raise r12's two ledges one row, or move r15 one cell toward r18, so the arc has open air.
- The climb has no room seam inside it (one 5-screen room), so the fade does not touch it.

### Lake shore (#8)

The floor from the fishing village runs under the causeway's east end into the freezable lake. The
causeway is reached from S37-38 (x -96..-32, y -1728): a straight jump with an apex steer from x ~-10,
then a jump with left held up the causeway's face. That reads as intended. Like woods_deep, the
obvious floor walk ends in a hazard.

## Not covered

- woods_hut's interior.
- lake_high_wall's alcove and lake_shore's far-bank niche: both song puzzles, out of scope. The niche
  was checked in the `.room` only: it is sealed from the west by S9-11 under the causeway.
- orchard_terraces beyond its entry, the Bloom and Frost fights themselves, and a non-debug save (fences
  closed).
- The tavern-style drop-through: `=` still cannot be dropped through. This matters nowhere on these
  paths.

## Ratings rationale

- **Fluidity 2 (measured in part):**
  - Walking through seams is now one ~1 s fade, a large improvement on the opening report's ~7 s.
  - But every jump across a horizontal seam hangs for a second, and three main-path jumps fail unless
    held through it.
  - The waterfall climb mixes two opposite jump techniques and one 0.05 s timing window.
- **Fun 2 (inferred from timing and inputs; needs a human):**
  - The woods' base path and the chasm are fair and readable.
  - The lake's entry and the two orchard gates would read as "my jump is too short", which is the wrong
    lesson.
  - The well softlock would end a session.
- **Aesthetics 3:** a consistent greybox. The woods are greyed at memory 0.4 and bloom green inside a
  pulse. Stone and snow in the lake. One-way ledges are drawn like solid floating blocks, which hides that
  they are one-way.
- **Not judged:** camera smoothing, input latency, fade feel, audio. Frames and logs only.

## Re-verification (2026-10-09, evening)

**What changed under test** (uncommitted, on ea47690):
- A walk across a seam no longer fades or disables Ivo. Inside one region the camera glides to the new
  bounds (0.45 s) and the baseline eases. Across a region seam it cuts on one frame.
- `RoomResidency` keeps the current room and every room touching it running.
- `.room` edits: woods_root_caves (one-way at row 0 cols 28-29, well floor at row 10, shelf exit at col 32
  rows 4-6), lake_fishing_village (a notch at cols 26-27, west curb at col 25), lake_waterfall_path
  (r12 is now one one-way at cols 8-11).

**Method:**
- 53 runs, `APPDATA` redirected for each. The real save's md5 (`49ae7e28…`) was the same before and after.
- New timelines are `tools/playtest/scripts/traverse_woods_lake_*_rv_*.json`. All presses are 0.3-0.45 s;
  none is held through a transition.
- **Code state:** the code changed twice during the session.
  - The first runs (19:31-19:40 and 23:22-23:25) saw `RoomResidency` with a glide at every seam.
  - At 23:25 the region seam became a cut (`game.gd`, `camera.gd`, `room.gd`, `room_residency.gd`,
    imported 23:25:32).
  - Every seam timeline was re-run after 23:25:32 with the same result: k2, e, g steer06 twice, the
    straight jump under the terraces' floor, f, i7, i10, p2 and p3. The waterfall (m2) and glide (w7) runs
    were made only on the new code.
- **Errors:** no `ERROR` or `SCRIPT ERROR` lines in any run, apart from the usual leak report at exit.
  Nothing about contents being activated inside the physics flush.

### Results

| # | Check | Timeline(s) | Result | Measured |
|---|---|---|---|---|
| 1 | village_mill slab → lake_waterfall_path bench stub, 0.45 s press | `k2_mill_floor_trail_slab_stub` | **PASS** (2 of 2, before and after the cut change) | Peak y -105.9 (was -37.9). Lands on the stub at -96 and sits on the bench (2640, -96). `fade` stays 0. The camera cuts to the waterfall on the crossing frame (centre (2605,180) → (2880,-180)). |
| 2a | woods_deep r04 → woods_canopy, double jump, 0.35 s second press | `e_deep_climb_to_canopy` | **PASS** (2 of 2) | Peak about y -880 (was -809.8). Lands at (-2995.9, -864). |
| 2b | canopy launch branch → orchard_terraces, 0.35 s second press | `g_rv_branch_to_terraces_tap_steer{04,06,08}` | **PASS** (7 of 7) | Peak y -1264.8 (was -1193.8): 16 px above the floor (-1248). Lands with right held from 0.4-0.8 s after the first press. The old `g_…_tap` timeline still fails, because its steer starts at T+1.4 for the old 1 s fade: by then he is back below the floor. |
| 3 | canopy double jump into orchard_well's floor | `f_canopy_west_to_branch` | **PASS** (2 of 2) | The head stops at y -1094..-1098: feet + 54 = the well floor's underside, -1152. The room never changes to orchard_well. A straight double jump under the terraces' solid floor (x -4050) stops the same way (`g_rv_branch_straight_under_terraces_floor`). |
| 4a | caves: Enraizar rungs end at the new ledge, one jump to woods_deep | `i8`, `i9`, `i10_rv_caves_root_climb_ledge_to_deep` | **PASS, with a note** | The rungs come in two runs: up from the floor to y ~620, and from ~y 551 to 426. There are none at rows 4-6, where the shelf exit opens the east wall. From the top of the lower run, one jump catches the upper run. At the top, holding up still bobs at y 426, 42 px under the ledge (same loop as before). Jump off the top rung: peak 305.7, lands on the one-way (y 384). One jump with left held then lands on woods_deep's floor at (-3700, 288). |
| 4b | caves: no double-jump climb out without Enraizar | `i3`, `i5`, `i6`, `i7_rv_caves_no_root_double_jump_skip` | **FAIL** | From the well floor (704) the double jump peaks at 463.6, so it cannot. But from the shelf block (y 608, a single 96 px jump from the well floor), a running double jump that takes off at the block's west edge peaks at 366.7-371.4. That is over the new one-way (384), and he lands on it in 2 of 3 timings. One more jump reaches woods_deep's floor at (-3678, 288). `bugs/the-root-caves-well-is-climbable-without-enraizar` |
| 5 | fishing village well: fall in, climb out with single jumps | `p2_rv_…_fall_and_climb_out`, `p3_rv_…_west_to_east_held` | **PASS** (4 of 4 west, 4 of 4 east) | One-way (-1504) → notch (-1568) → over the west curb to the floor (1389.5, -1632). From the notch, a jump held from take-off clears the east curb (x 1664, top -1664) and lands on the curb top or the floor beyond. New note: the mouth can no longer be jumped over. `q_…_jump_to_shore` (a standing jump from x 1708) now lands in the notch at (1484, -1568), where it used to land at x ~1440. Crossing the village costs one drop and one jump in each direction. |
| 6 | waterfall r18 → r15 → r12, normal jump | `m2_rv_waterfall_r18_r15_r12_*` | **PASS** | r18 → r15 lands with a 0.3 s, 0.45 s (3 of 3) or 0.8 s press, left held from take-off, and with a 0.45 s apex-steered press. Landing x 2870-2937, inside r15 (2816..2944). Only a 0.15 s tap falls short (to r21). r15 → r12 is a straight jump through the one-way: peak -1577..-1583, 41-47 px above it. r12 → r09 east (right held) lands at -1632. The first session needed 0.20-0.25 s exactly. |
| 7a | in-region walk: village_square ↔ village_mill | `w7a_rv_square_to_mill_glide`, `w7c_rv_mill_to_square_glide` | **PASS for motion; FAIL for the picture** | Ivo never stops (192 px/s throughout). The camera centre goes 1600 → 2240 (640 px, a full screen width) in 0.45 s, sine in-out: +19, +56, +85, +104, +112, +104, +85, +56, +19 px per 0.05 s. There is no void, because both rooms are 384 high. **But the backdrop pops on the crossing frame while the camera stands still**: 41% (forward) and 51% (back) of the screen's pixels change in one frame. `bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room` |
| 7b | region walk: village_lane_west → woods_edge | `w7b_rv_lane_west_to_woods_edge_cut` | **PASS** | One-frame cut. Camera centre -965 → -1600, and the palette changes from colour (village, 0.8) to grey (woods, 0.4) on the same frame. Ivo never stops. The mill → waterfall jump (#1) cuts the same way. |

### Camera: what the frames and logs show, and what they cannot

- **In-region glide.**
  - **Motion:** the numbers above are measured. The pan is fast: a whole screen in 0.45 s, peaking at about
    2,200 px/s.
  - **Ivo at the edge:** the old room's clamp holds until his feet cross, so he reaches the screen edge first.
    He is about one frame (~0.05 s) mostly off-screen at a side seam (`rv_square_to_mill_glide_flipbook.png`,
    f1.80).
  - **Going up through a seam is worse.** His body leaves the top of the frame before his feet cross, and
    the eased glide starts slowly (`rv_upward_seam_ivo_out_of_frame.png`).
    - woods_deep → canopy: he is out of frame at t 11.1.
    - root caves → woods_deep: fully out of frame for ~0.15 s and partly for ~0.4 s.
    - `bugs/crossing-a-seam-upward-takes-ivo-out-of-the-frame`
- **Region cut** (`rv_region_cut_lane_west_to_woods_edge.png`). Ivo walks to the left edge and reappears at
  the right edge, and the colour drains to grey on the same frame. It reads as a deliberate flip-screen
  boundary, and it marks the region change clearly. It is abrupt: a full-screen colour change in one frame.
  Whether that is "fine" or "jarring" is a feel judgement that a static frame cannot make.
- **Not judged:**
  - whether the 0.45 s glide feels smooth or whip-like at 60 fps;
  - whether the cut is jarring in motion;
  - input latency, audio, and any sense of weight.

  These need a human playtest. In motion the backdrop pop (7a) is probably the most visible artefact.
  That is an inference from its 41-51% one-frame pixel change, not an observation of motion.

### New problems found

1. **Running neighbours' backdrops draw into the current room's view** (medium, aesthetics).
   - The picture at a fixed camera depends on which rooms are running. It pops at every in-region seam.
   - It also changed the mill's resting view from the first session's build: a dark forest band now covers
     the sky, and a flat olive band lies under the floor (`rv_mill_backdrop_before_and_after_residency.png`).
   - Flat slabs of fill colour appear in village_lane_west, woods_deep and woods_edge too.
   - `bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room`
2. **Upward seams take Ivo out of the frame for up to ~0.4 s** (medium, feel).
   `bugs/crossing-a-seam-upward-takes-ivo-out-of-the-frame`
3. **The caves' well is climbable without Enraizar** (medium, gate). The double-jump route ends in the closed
   pocket west of woods_deep's pit, so nothing beyond the pocket is skipped. Still, design says "roots only".
   `bugs/the-root-caves-well-is-climbable-without-enraizar`
4. **Fishing village:** the well mouth can no longer be jumped over (low, feel). Crossing the village now
   always means dropping into the notch. This is not a softlock: it is escapable both ways.

### Bug status after the re-verification

- `bugs/a-jump-across-a-horizontal-seam-loses-its-height-in-the-fade`: **resolved**. There is no freeze; all
  three jumps pass with normal presses.
- `bugs/a-neighbour-room-has-no-ground-until-ivo-enters-it`: **resolved**. Neighbour ground stops both the
  canopy → orchard_well and the branch → terraces' floor jumps.
- `bugs/the-fishing-village-well-has-no-way-out`: **resolved**. Two single jumps out to the west; one jump
  out to the east from the notch.
- Root caves #6 (rungs stop short of the rim): improved. It now takes a jump from the top rung to the ledge,
  then a jump to the floor. The hold-up bob at the top rung remains.
- Waterfall #5: fixed (see row 6).

### Ratings after the re-verification

- **Fluidity 3 (measured in part):** no seam freezes or fades, and the three blockers pass with normal
  presses. Against that: Ivo leaves the frame at upward seams, and the backdrop pops at every in-region seam.
- **Fun 3 (inferred; needs a human):** the "my jump is too short" traps are gone.
- **Aesthetics 2:** the neighbour backdrop overlap degrades resting views (the mill) and pops at seams.

### Re-check of the three new findings (2026-10-10, ~00:00)

**Code under test:**
- Backdrop layers are clipped to their room's bounds (`room_rect` in `backdrop_layer.gdshader`).
- The current room is the one holding Ivo's body centre, not his feet.
- The glide is a cubic ease-out (still 0.45 s).
- woods_root_caves: the shelf block is two rows lower (rows 9-10, top y 672), the col-32 exit is rows 6-8,
  and col 32 is solid in rows 0-5.

I ran `--import` myself at 23:58:40. No file in `scenes`, `resources`, `globals` or `assets` changed after
that. 25 runs, all on this code. No `ERROR` lines apart from the leak report at exit.

To measure "visible", `vis.py` (scratch) takes each 0.05-0.1 s `log`. It computes how much of Ivo's body
rect (22x54 above the feet) lies inside the 640x360 view around `cam_centre`.

| Check | Timeline(s) | Result | Measured |
|---|---|---|---|
| Backdrop pop, square → mill | `w7a_rv_square_to_mill_glide` | **PASS** | The crossing frame changes 2k pixels (was 381k), against 4-6k for a still frame. The glide frames change 219k → 155k → 78k → 39k → 5k, falling with the pan's speed. The pines and mountains are continuous across the pan (`rv2_square_to_mill_glide_clipped_backdrop.png`). |
| Backdrop pop, mill → square | `w7c_rv_mill_to_square_glide` | **PASS** | The crossing frame changes 159k pixels, but the camera moves 74 px on that frame (2234 → 2160). That is the pan, not a pop: the frames after it change 200k, 193k, 200k… and fall smoothly. |
| Mill resting view vs the first session | `k2_mill_floor_trail_slab_stub`, frame k01.6 | **PASS** | 252 pixels differ from the 6fa077a frame (dust motes). The sky and mountains are back and there is no pine band (`rv2_mill_backdrop_first_session_vs_clipped.png`). |
| Upward seam: woods_deep → woods_canopy | `e3_rv2_deep_r04_to_canopy_dense` | **PASS** | The room changes at feet -751.6. Visible: 0.84 at t 1.80, 0.55 at 1.85, then 1.00. He is never wholly out of frame. It was wholly out at t 11.1 before. |
| Upward seam: root caves → woods_deep | `i10_rv_…`, `i11_rv2_caves_root_climb_one_run` | **PASS** | Minimum visible 0.86, one sample before the switch, then 1.00 (was ~0.15 s wholly and ~0.4 s partly out). Note: while bobbing at the top rung (feet 426, body centre in the caves) his head is cut by the frame's top. Visible 0.77-0.88 for as long as up is held. |
| Downward drop: woods_deep pocket → shaft → caves | `d1_rv2_deep_pocket_drop_into_caves` | **PASS** | 0.92, then 0.49 for one 0.05 s sample (feet 411, just before the switch), then 1.00 from the switch onward. |
| Caves: running double jump from the shelf | `i6b_rv2_caves_shelf_running_double_jump_{170..212}` | **PASS** (8 of 8 timings) | The best peak is y 431.3, 47 px under the one-way (384). Earlier take-offs bump the col-32 ceiling (peak 537). He always falls back to the well floor (704). |
| Caves: roots climb, then a jump to the ledge, then a jump to woods_deep | `i11_rv2_caves_root_climb_one_run`, `i10_rv_caves_root_climb_ledge_to_deep` | **PASS** | One continuous climb from 704 to 426, with no gap. Jump off the top rung: peak 299.6, lands on the ledge (384). One jump with left held lands at (-3699.9, 288). |
| Caves: well exit and the east chamber | `x1_rv2_caves_well_to_shelf_and_east` | **PASS** | A jump right from the well floor bumps col 32's wall above the exit (x -3466, feet 584), then drops onto the shelf (672). He walks east and drops onto the chamber's block (cols 42-49) at (-3068.6, 768). |
| Item 1 again: mill slab → bench | `k2_mill_floor_trail_slab_stub` | **PASS, with a new problem** | Peak -105.1, lands at the bench (2640, -96). But the trail → slab jump on the way flips rooms twice (see below). |
| canopy branch → orchard_terraces again | `g_rv_branch_to_terraces_tap_steer06` | **PASS** | Peak -1264.8, lands at -1248. |

**New problem: a hop on the mill's slab cuts to the Frozen Lake and back**
(`bugs/a-hop-below-a-seam-flips-the-room-twice`, `rv2_mill_slab_hop_flips_to_the_lake.png`):
- The slab's floor (y 32) is 32 px under the mill/lake_waterfall_path seam. Ivo's body centre stands 5 px
  under the seam there.
- Every hop puts the centre above the seam, including a 0.2 s tap that peaks at feet -69. The room becomes
  lake_waterfall_path: a region cut, with the camera snapping to the waterfall and the palette going to
  winter grey.
- On landing it cuts back to the village.
- `s1_rv2_mill_slab_hop_in_place` shows two hops and four cuts. The trail → slab jump in `k2` flips the
  same way: peak feet 16.3, waterfall from t 3.90 to 4.30.
- Under the feet rule this jump stayed in the mill.

**Also seen:** standing on the slab, Ivo's head is above the mill's frame (visible 0.59). Nothing above
y 0 is in the mill's camera bounds. This was already true in the first session's frames.

**After this re-check:**
- `bugs/a-running-neighbour-rooms-backdrop-draws-over-the-current-room`: resolved.
- `bugs/crossing-a-seam-upward-takes-ivo-out-of-the-frame`: resolved.
- `bugs/the-root-caves-well-is-climbable-without-enraizar`: resolved.
- New and open: `bugs/a-hop-below-a-seam-flips-the-room-twice`.
- Ratings: aesthetics back to 3 (the backdrops are continuous). Fluidity stays 3 because of the slab
  flip-flop.

### Re-check of the hop flip and the camera yield (2026-10-10, ~00:15)

**Code under test:**
- Ivo leaves the current room only when his whole body is out of it (`get_bounds().intersects(body_rect())`).
  He then enters the room under his body centre.
- `GameCamera._keep_subject_in_view` lets the frame leave the room's bounds so that his body plus 8 px stays
  on screen.

`--import` at 00:12:13; no game file changed after it. 12 runs, no `ERROR` lines apart from the leak report
at exit.

| Check | Timeline(s) | Result | Measured |
|---|---|---|---|
| Hops on the mill slab, arriving from the mill | `s3_rv3_mill_trail_to_slab_then_hops` (taps of 0.05, 0.1, 0.2 s; jumps of 0.45, 0.8 s) | **PASS: no flip-flop** | The trail → slab jump (peak feet 18.2) stays in the mill. Even the 0.05 s tap lifts his whole body above y 0 (feet -10 at t 2.75), so no hop exists that stays below. The first hop cuts once to lake_waterfall_path. On landing (feet 32) the body still overlaps the lake, so the room stays the lake. The four later hops cause no cut at all. Frames: `rv3_mill_slab_hop_one_cut_then_lake.png`. |
| Back down from the slab | `s5_rv3_slab_hop_then_walk_off_east` | **PASS** | After a hop he walks off the slab's east end. One cut back to the mill at feet 61.9, once his body is wholly below y 0. One cut each way. |
| Arriving on the slab from the lake | `s4_rv3_stub_drop_to_slab_then_hops` | **as designed** | He drops from the bench stub onto the slab and stays in the lake through hops and walking. |
| Item 1 route: trail → slab → bench | `k2_mill_floor_trail_slab_stub` | **PASS** | One room change only, on the stub jump (t 6.20, feet -20.4). Lands on the bench stub (2640, -96). |
| Out of frame: caves → woods_deep, including the top-rung hold | `i11_rv2_caves_root_climb_one_run` | **PASS** | Visible 1.00 on every 0.1 s sample, including the bob at feet 426 (was 0.77-0.88). The room changes at feet 348.6. |
| Out of frame: woods_deep → canopy | `e3_rv2_deep_r04_to_canopy_dense` | **PASS** | 1.00 on every 0.05 s sample (was a minimum of 0.55). The room changes at feet -782.2. |
| Out of frame: downward drop, woods_deep → caves | `d1_rv2_deep_pocket_drop_into_caves` | **PASS** | 1.00 on every sample (was a minimum of 0.49). The room changes at feet 464.4. |
| Out of frame: standing on the slab | `s3_…`, `k2_…` | **PASS** | 1.00. In the mill the frame yields up to centre y 150 (was 0.59 visible at centre 180). In the lake the frame sits at centre -140. |
| square → mill walk | `w7a_rv_square_to_mill_glide` | **PASS** | The room switches at feet x 1935.7, with the body wholly past 1920. Before that the frame yields 5-24 px into the mill, then the glide follows. Per-frame pixel changes rise and fall smoothly: 74k, 97k, 92k, 121k, 219k … 39k, 5k. There is no single-frame spike, so no pop. Ivo stays in frame throughout (`rv3_square_to_mill_body_crossed_glide.png`). |
| mill → square walk | `w7c_rv_mill_to_square_glide` | **PASS** | The switch is at feet x 1904.3. Same smooth curve, with a 212k peak. |
| Region cut, lane_west → woods_edge | `w7b_rv_lane_west_to_woods_edge_cut` | **PASS** | The frame yields up to 33 px into woods_edge, so a sliver of the woods shows at the left edge, drawn in the village's colour palette. Then a one-frame cut at feet x -1296.1: 288k pixels change, and the palette goes to grey (`rv3_region_cut_with_sliver.png`). |

**Notes from this re-check:**
- **The slab now belongs to the lake after any hop.** The lake is the room Ivo last fully entered.
  - Standing there after a hop, he is in lake_waterfall_path's frame (centre y -140) and winter palette.
    He stands at the bottom edge with about 8 px of the village slab showing under him.
  - It switches back when he walks off the slab to the trail.
  - This is the price of the hysteresis. There is no flicker, but the frame on the slab depends on history.
    Whether that reads as odd is for a human playtest.
- **Before a region cut, the yield shows the next region drawn in the current region's palette.** For one
  to ~0.15 s, the woods' sliver is green and coloured, then it cuts to grey. This is
  `bugs/a-neighbour-room-in-another-region-runs-on-the-current-regions-memory` (mitigated) made visible.
  It is small (≤33 px). I am noting it, not filing it.

**After this re-check:**
- `bugs/a-hop-below-a-seam-flips-the-room-twice`: resolved.
- `bugs/crossing-a-seam-upward-takes-ivo-out-of-the-frame`: visible is now 1.00 everywhere measured; one
  line added to its resolution.
