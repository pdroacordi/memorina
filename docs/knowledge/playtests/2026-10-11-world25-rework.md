---
id: playtests/2026-10-11-world25-rework
type: playtest
title: "WORLD-25 room rework: seven changed main paths played with the kit a player has there"
status: active
build: 9df7ec6 + uncommitted WORLD-25 rework (worktree agent-a5ca98ed7ee598b83; .room imports 03:28:52, re-import at 09:05 was a no-op; no scene, resource or asset changed after it)
area_tested: "woods_pond, woods_deep, woods_root_caves, lake_waterfall_path, lake_high_wall, orchard_leaf_path, village_mill"
tags: [traversal, rooms, world-25, reachability, level-design]
related: [systems/rooms, architecture/room-reachability-audit, bugs/the-woods-pond-shelf-jump-takes-ivo-out-of-the-top-of-the-frame, bugs/the-root-caves-roots-end-short-of-woods-deep-without-the-row-0-ledge, bugs/world-25-re-pointed-timelines-no-longer-test-their-scenario, playtests/2026-10-09-traversal-woods-lake, playtests/2026-10-10-traversal-orchards-caldera]
created: 2026-10-11
updated: 2026-10-11
ratings: { fun: 3, fluidity: 3, aesthetics: 2 }
screenshots:
  - screenshots/2026-10-11-world25-rework/pond_step_and_pillar.png
  - screenshots/2026-10-11-world25-rework/pond_on_one_cell_pillar.png
  - screenshots/2026-10-11-world25-rework/pond_shelf_jump_ivo_out_of_frame.png
  - screenshots/2026-10-11-world25-rework/deep_boulder_step.png
  - screenshots/2026-10-11-world25-rework/deep_bare_upper_west.png
  - screenshots/2026-10-11-world25-rework/caves_corner_head_bump.png
  - screenshots/2026-10-11-world25-rework/caves_tunnel.png
  - screenshots/2026-10-11-world25-rework/caves_alcove_empty.png
  - screenshots/2026-10-11-world25-rework/caves_well_exit_air_jump.png
  - screenshots/2026-10-11-world25-rework/waterfall_dead_end_east_ledges.png
  - screenshots/2026-10-11-world25-rework/high_wall_ladder_top.png
  - screenshots/2026-10-11-world25-rework/high_wall_drop_column.png
  - screenshots/2026-10-11-world25-rework/leaf_running_jump_overshoots_steps.png
  - screenshots/2026-10-11-world25-rework/leaf_jump_from_top_step.png
  - screenshots/2026-10-11-world25-rework/mill_street_to_trail_jump.png
---

## What was tested

The reworked rooms were played in the real game, windowed, with timelines (`tools/playtest/scripts/world25_*.json`; the six full routes in the table below are kept, the single-step probes and sweeps were deleted after the review). Every jump was checked against logged positions, not only frames. The kit matched what the player has at that point (design 04 section 2):
- Base kit (no skills): the pond, the woods_deep boulder, the waterfall, the high wall, the leaf path and the mill.
- Root caves: `"skills": [0]`, songs ROOT and RAIN. The Bloom Guardian gives Enraizar and the double jump together.

Single steps were tested from spawns on each platform (sweeps of take-off x, press length or release time). Then each path was run end to end in one continuous timeline.

## Verdicts

| # | Path | Verdict | Tries | Continuous run |
|---|---|---|---|---|
| 1 | woods_pond: floor → stone step → pillar → shelf → bloom_hollow | playable, one fiddly jump | step 1/1; pillar 0/6 with left held (5 overshoot, 1 press too short), 5/7 with a release; shelf 5/6 | `world25_deep_pond_to_bloom` (first try) |
| 5 | woods_deep: boulder → mound → west → pond | playable | 1/1 with a release over the boulder; held left overshoots into the pit (1/1, -1 HP) | same run |
| 2 | woods_root_caves: corner col 26, tunnel rows 19-20, shaft A, the well | playable; the well exit needs a non-obvious double jump | corner 1/1 (head bump); tunnel walked; shaft A 1/1; well 1 of 4 input orders | `world25_caves_return_loop` (second run; the first stopped 39 px short of the shaft, a timeline error) |
| 3 | lake_waterfall_path: single zigzag, 16 jumps | playable | 15/16 first plan; step 14 held overshoots (fixed by a release) | `world25_waterfall_zigzag_climb`: 16/16 first try |
| 4 | lake_high_wall: 2-cell ladder up, drop column col 18 down | playable | 5/5 rungs; drop 1/1 (the first walk-off stopped on the edge, a timeline length issue) | `world25_high_wall_ladder_up_and_drop` |
| 6 | orchard_leaf_path: steps cols 8-10 → hill | playable | running jump at the steps 0/1 (overshoots); hop + jump 4/5 timings | `world25_leaf_path_west_climb` |
| 7 | village_mill: street → trail floor (one 4-row jump) → waterfall stub | playable | 7/10 take-off positions | `world25_mill_street_to_waterfall` (first try) |

No jump on these paths is pixel-perfect. The tightest are the pond pillar (a 0.2 s release window) and the waterfall's bonk steps (a 60 px take-off window). The leaf steps need a second press within ~0.23 s of landing.

## Findings

**woods_pond (path 1)**
- The step works: a jump from the floor with left held lands on the step (`pond_step_and_pillar.png`).
- **The pillar is one cell wide and cannot be landed with left held.**
  - The apex hang carries Ivo ~58 px sideways (velocity.y goes from -57 to +5 over 0.15 s), so every press of 0.2-0.35 s with left held overshoots the 32 px top into the basin (probes).
  - Releasing left 0.30-0.50 s after the press lands (probes: 1.50-1.70 land, 1.45 and 1.75 miss; `pond_on_one_cell_pillar.png`).
  - Feel note: most players hold the direction and will fall in a few times. The basin is escapable: two jumps east with right held, peak 16 px over the pillar (a probe). A 2-cell pillar top would remove the trap.
- Pillar → shelf: a full press lands from anywhere on the pillar. A 0.3 s press from its east edge falls short.
- **Ivo leaves the frame on the shelf jump**: wholly above the view for ~0.45 s, partly for ~0.7 s (`pond_shelf_jump_ivo_out_of_frame.png`; `bugs/the-woods-pond-shelf-jump-takes-ivo-out-of-the-top-of-the-frame`). The 2026-10-09 report showed his feet only. Now the 5-cell gap needs a full jump.

**woods_deep (path 5)**
- The boulder stops the floor walk, which fixes the 2026-10-09 #7 (the walk ended in the pit; `deep_boulder_step.png`).
- A jump at it with left held clears all 3 cells and lands in the corridor beyond. The walk then ends in the pit (-1 HP, respawn at -3184, 288). From the respawn, a jump right onto the boulder works.
- Releasing left over the boulder lands it. Boulder → mound is easy (peak 47 px over the mound).
- **Bare space:** with the branch one-ways gone, the air above the mound's west half is empty (`deep_bare_upper_west.png`). Design 04 calls the room "plataformas nas copas", so this reads thinner than it did. This is an aesthetic note, not a defect.

**woods_root_caves (path 2)**
- Corner: the jump onto the 992 step from under col 26 bumps the head on its bottom (feet stop at 982) and still lands (`caves_corner_head_bump.png`).
- The tunnel is walked with no jump (`caves_tunnel.png`). Enraizar at shaft A's bottom grows rungs; Ivo climbs to feet ~780, and a jump left off the top bob lands on the west ledge (768).
- Standing at the shaft's west edge (x -2877, under col 49) a jump with up held does not grab. From x -2838 it does. This is a timeline lesson more than a defect.
- **The well exit** (`bugs/the-root-caves-roots-end-short-of-woods-deep-without-the-row-0-ledge`, filed by the reviewer the same morning, confirmed here):
  - Up held to the top: the press is the air jump, peak 332, back to the floor (2 runs).
  - A rung jump without the air jump: peak 339.5.
  - Only a jump off the rungs plus the air jump lands on woods_deep: peak 216 (`caves_well_exit_air_jump.png`).
- **The alcove is empty** (`caves_alcove_empty.png`). The Enraizar bridge (played from the stone post in the pit, as designed) leads to a bare 7x8-cell room with nothing in it. The audit counts it as fine only because the bridge is a song's floor. To a player it is a place that leads nowhere.

**lake_waterfall_path (path 3)**
- All 16 steps pass with single jumps, and the continuous climb landed every one.
- **Bonk steps** (3, 4, 6, 9, 11, 12): the ledge 6 rows up caps the jump at 9.8 px over the next top. Step 3 lands from take-off x 2640-2699 and falls from 2620.
- **A miss on the west side falls down col 4 to the bottom of the room** (mill trail ledge, y 0). The whole climb restarts.
- Step 14 (3-cell gap to cols 8-11) overshoots with right held. A release 0.55-0.95 s after the press lands.
- **Dead ends:** wall ledges east rows 30, 24, 18 (and west row 39) are left over from the removed parallel route (`waterfall_dead_end_east_ledges.png`).
  - East 30 is reachable from the middle island and then leads nowhere. East 24 is 192 px above it, past the 146 px jump (inferred from the grid).
  - The audit does not flag wall ledges because they touch the room edge.
- The static waterfall the header names (cols 6-13) is not visible in any frame. This predates the rework, and its cause was not checked.

**lake_high_wall (path 4)**
- Five straight jumps climb the 2-cell ladder. Walking right off the top rung into col 18 drops 480 px to the passage floor with no damage (`high_wall_drop_column.png`).
- The rungs read as floating slabs beside the column. The top still leads to empty sky (`high_wall_ladder_top.png`); it is allowlisted for the STORY-06 collectible.

**orchard_leaf_path (path 6)**
- Each 32 px step needs its own hop: held right against the second step stalls.
- **A running jump at the first step clears both steps and the 3-cell gap.** Ivo lands at the hill's base against the leaf curtain, and the hill's top is 160 px up, out of reach (`leaf_running_jump_overshoots_steps.png`).
- Recovery: hop back left onto the top step, then jump right.
- The route that works: the minimum hop (0.1 s) lands on the top step's east edge, then a full jump within ~1.72-1.95 s lands on the hill (`leaf_jump_from_top_step.png`).

**village_mill (path 7)**
- One jump from the street lands on the trail floor from take-off x ~2575-2735. Ivo peaks 16 px over the floor.
- From x 2740 he bumps the slab's underside corner; from 2560 he falls short (`mill_street_to_trail_jump.png`).
- From there: the step, the ledge, and the waterfall's west stub at the bench, with no retries.
- At the step the top ~40 px of the frame shows lake_waterfall_path's backdrop over the mill. This is the camera's yield over the open top, and it predates the rework.

## What this cannot judge

- Whether the pillar release or the leaf steps' second press feel fair: these are timing windows from logs, not felt input.
- The camera feel during the shelf jump: only its position is measured.
- Audio.

## Ratings rationale

- **Fun 3 (low confidence, inferred):** every path is passable and the waterfall's zigzag reads clearly. Two short traps a player will fall into first (the pond pillar, the leaf steps) and the well's hidden input cost a point.
- **Fluidity 3 (inferred from logs):** the continuous runs never stall at a seam. A held direction overshoots three of the new or narrowed features, which goes against the hold-and-jump habit the rest of the world teaches.
- **Aesthetics 2:** the waterfall's dead-end wall ledges, woods_deep's bare upper west, the empty caves alcove and the high wall's floating rungs all read as unfinished. Ivo is still the placeholder figure (CORE-08).

## Revision (2026-10-11, after the review fixes)

The maps were changed after this run:
- the pond pillar top is 2 cells (cols 28-29; the step moved to col 30);
- the leaf steps are three treads (cols 7-8, 9-10, 11-12), and the slot at col 13 is raised one row;
- woods_deep's boulder has a 2-cell lip at col 44;
- woods_root_caves' row-0 one-way is back;
- on lake_waterfall_path:
  - the leftover wall ledges are gone (east rows 18, 24, 30, 45, 51; west row 39);
  - the west shelves at rows 18 and 45 and the middle island at row 36 are one cell shorter;
  - the islands at rows 21 and 27 sit one cell east;
  - the row-15 middle runs cols 6-11.

The six kept routes were re-run on that tree:
- `world25_deep_pond_to_bloom` reaches bloom_hollow with hp 3. It now ends at t 21.8, before the guardian.
  - A jump at the boulder with left held lands on it against the lip, at (-3028, 192), and stays (probe).
  - Boulder → mound is a single jump.
  - From the step onto the pillar, a 0.2 s press with left held now lands. A full 0.35 s press with left held still carries past it into the basin (probes).
- `world25_caves_return_loop` ends on woods_deep at (-3672.7, 288).
- `world25_waterfall_zigzag_climb` lands all 16 steps after one walk was retimed (step 8, 0.25 s shorter, because the row-36 island is narrower).
  - Peak clearance over each landing is 44-48 px on 14 steps. Steps 3, 4, 6 and 12 were capped at ~10 px and are now free.
  - Step 11 is 23.4 px. Step 9 is still 9.4 px: the row-27 island caps it, and one cell does not clear it.
- `world25_high_wall_ladder_up_and_drop`: unchanged, passes.
- `world25_leaf_path_west_climb`: passes. A running jump at the first step with right held now lands on the top tread (y -1344). Walking on off it drops two rows into the slot, and the top tread is one 2-row hop back (probe).
- `world25_mill_street_to_waterfall`: unchanged, passes.
