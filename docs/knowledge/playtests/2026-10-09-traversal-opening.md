---
id: playtests/2026-10-09-traversal-opening
type: playtest
title: WORLD-05 opening journey with the base kit - house, village, threshold road, frost edge, lighthouse
status: active
build: ba88e1d (imported 13:35; nothing under scenes/, resources/, globals/ or addons/ changed during the session)
area_tested: "home_village (village_house, square, cistern, mill, gate_east, lane_west, tavern, elder, bakery), threshold (fields, farmhouse, bridge, wayshrine), frost_edge (shore, cliffs, lighthouse_base, lighthouse_interior)"
tags: [traversal, world-05, greybox, rooms, seams, doors, benches, base-kit, softlock, one-way-ledge]
related: [bugs/walking-across-a-room-seam-fades-back-and-forth, bugs/the-tavern-upper-floor-has-no-way-down, systems/rooms, architecture/doors-and-interiors, playtests/2026-10-08-doors-and-interiors]
created: 2026-10-09
updated: 2026-10-09
ratings: { fun: 2, fluidity: 1, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-09-traversal-opening/seam_1_fading_into_mill.png
  - screenshots/2026-10-09-traversal-opening/seam_2_back_in_square.png
  - screenshots/2026-10-09-traversal-opening/well_stopped_on_inner_pillar.png
  - screenshots/2026-10-09-traversal-opening/well_beam_loop_square_side.png
  - screenshots/2026-10-09-traversal-opening/well_beam_loop_cistern_side.png
  - screenshots/2026-10-09-traversal-opening/tavern_upper_floor_no_way_down.png
  - screenshots/2026-10-09-traversal-opening/tavern_lower_floor.png
  - screenshots/2026-10-09-traversal-opening/bridge_jump_leaves_frame_top.png
  - screenshots/2026-10-09-traversal-opening/bridge_brute_knocks_to_lip.png
  - screenshots/2026-10-09-traversal-opening/cliffs_128px_step.png
  - screenshots/2026-10-09-traversal-opening/lighthouse_adjacent_ledges_w29_e25.png
  - screenshots/2026-10-09-traversal-opening/lighthouse_hatch_knocks_sealed.png
  - screenshots/2026-10-09-traversal-opening/lane_west_fence_open.png
---

# Traversal: the opening journey (WORLD-05)

## What was tested

The test used the base kit only: single jump and sword, no songs, no skills. The debug save owns the
Memorina, so the village fences are open. The route is the
`tools/playtest/scripts/traverse_opening_*.json` timelines, one or two rooms each, every leg starting near
the previous one's end with `player_position`. The runner's `log` recorded room, camera bounds, position,
fade and doors every 0.05-0.25 s. The real save's md5 was unchanged before and after.

Ivo's numbers, measured from the logs:
- run 192 px/s;
- held-jump peak 141-146 px;
- capsule radius 11 and height 54, so he needs 64 px (2 cells) of headroom.

| Leg | Timeline | Result |
|---|---|---|
| New game in the house (320, 12288), door, square | `a_house_to_fields`, `n3_house_reenter` | ok both ways |
| Square, mill, gate_east, fields | `b_square_to_fields`, `c_mill_to_fields` | passable; seam loop at every seam |
| Fields knoll and pit, farmhouse in/out | `d_fields_farmhouse`, `n5_farmhouse` | ok |
| Bridge stairs, gap jump, brute | `e_bridge_gap`, `g_bridge_brute_and_east` | ok |
| Ravine fall and climb out | `f_ravine_climb_out` | ok |
| Wayshrine bench (look_down), shore, cliffs cave | `h_wayshrine_bench_to_shore` | ok |
| Cliffs climb, cave (288) to cliff top (-864) | `i_cliffs_climb` | ok (11 jumps) |
| Cliff top, lighthouse_base, door | `j_cliff_top_to_lighthouse`, `n6_lighthouse_exit` | ok both ways |
| Interior spiral to the hatch, knock | `k_lighthouse_interior_climb`, `k2_lighthouse_hatch_knock` | ok, with three apex-steered jumps |
| Lane west, fence, woods_edge | `l_lane_west_fence` | fence open |
| Mill river trail and its barrier | `x_mill_river_trail` | barrier open; seam loop above |
| Tavern two floors | `m_tavern_two_floors`, `n2_tavern_door` | **softlock upstairs** |
| Elder (loft) and bakery in/out | `n1_elder`, `n4_bakery` | ok |
| Falling into the square's well | `w_well_fall_and_out`, `w2_well_beam_loop` | **softlock** |

## Findings

### Blockers and softlocks

- **Every room seam fades back and forth** (all rooms; `bugs/walking-across-a-room-seam-fades-back-and-forth`).
  - **Where:** every walk-in seam on the route: square/mill x 1920, mill/gate 3200, gate/fields 4480,
    fields/bridge 6400, bridge/wayshrine 7680, wayshrine/shore 8320, shore/cliffs 9600 (y 288),
    cliffs/base 10880 (y -864), and square/lane x 0 walking west.
  - **What blocks:** 6-7 fades of ~1 s each (`room` alternates, Ivo advances 3.2 px per fade).
    House to lighthouse door is ~70 s of fades.
  - **Cause:** Ivo is removed from the physics space for the fade. When he comes back, the room he left
    reports `body_entered` again.
  - **Fix:** accept a room only when it contains Ivo's position.
  - Screenshots: `seam_1_fading_into_mill.png` (fading into the mill), then `seam_2_back_in_square.png`
    (1.5 s later, back in the square at x 1919).
- **Falling into the square's well is a softlock** (village_square well, x 896..1024, into
  village_cistern).
  - **What blocks:** Ivo lands on the cistern's top beam at (930, 416). His capsule spans y 362..416,
    across the seam at y 384, so the seam loop never ends: 30 s of alternating rooms, and 18 jump presses
    did nothing (`well_beam_loop_square_side.png`: only his head shows at the frame bottom).
  - That beam is also the only way back up: the next beam (y 544) is 256 px below the square's floor.
  - Falling in is easy. A jump from the well's west curb (x 822) lands on the 1-cell inner pillar
    (col 32) at x 1033, 10 px past the hole. Any earlier take-off drops into the shaft
    (`well_stopped_on_inner_pillar.png`). Ivo then needs a second hop over the east rim.
  - **Fix:** the seam fix removes the loop. Even then the way out is tight: beam y 416 to the square's
    floor (288) is 128 px, and he must land on the 1-cell pillar at col 27 (15 px of apex). Consider a
    lid or one-way grate on the well until Redoma, or one more beam.
- **A jump across a horizontal seam crawls** (village_mill river trail into lake_waterfall_path).
  - **Where:** a straight jump from the trail at (3042, 160) puts his head above y 0.
  - **What blocks:** from t 5.1 to 28 he hangs at y 48→37→41 mid-arc, alternating rooms. Same bug.
  - Expected, not run: the same wherever a jump or a ledge brings his head across a room's top edge,
    e.g. standing on the square's gable ledge (row 1, y 32, under village_bell_tower) or on the mill's
    upper slab (row 1, y 32, under lake_waterfall_path).
- **The tavern's upper floor has no way down** (village_tavern, `bugs/the-tavern-upper-floor-has-no-way-down`).
  - **Where:** row 13 (y 12416) is solid earth plus a one-way span (cols 18-30). Ivo reaches it in two
    jumps from the bar floor (12672 → 12544 → 12416).
  - **What blocks:** Ivo has no drop-through, although the legend says `=` can be dropped through. On
    the span at x 2349, down, down+jump and down held each leave him at 12416. The tavern's only door is
    downstairs (`tavern_upper_floor_no_way_down.png`).
  - **Fix:** implement drop-through, or open a gap in row 13 (e.g. cols 31-32) to walk off.

### Precision, camera and feel (not blockers)

- **Three lighthouse interior steps bump Ivo's head when jumped with the direction held** (lighthouse_interior).
  - **Where:** each pair is an upper ledge that starts exactly where the lower one ends: W29 (cols 1-8)
    under E25 (cols 9-19) at x 24288; E25 to W21 (x 24288); E17 to W13 (cols 1-10) at x 24352.
  - **What blocks:** holding toward the next ledge from take-off puts his head under its underside
    after 42 px of rise (log `s04_01`: y 12928 → 12885.8, then falling). He must jump straight up and
    steer only near the apex, where he clears the ledge top by 15 px for ~0.35 s.
  - **Result:** with apex steering the whole spiral (9 jumps, door to hatch platform) worked in 4 of 4
    repeats, but two earlier runs with the same inputs fell back to the mentor landing (y 12800). The
    margin is a few px. Every other step on the route has a 2-cell gap and takes a held direction.
  - **Fix:** give these three the cliffs' 2-cell gap (E25 cols 11-19, W13 cols 1-8), or make them
    3 rows (96 px).
- **The 4-row steps are at the edge of Ivo's reach** (frost_cliffs rows 21→17→13→9, all of
  lighthouse_interior).
  - The apex clears the next ledge top by 10.8-13.5 px only with the jump held to its peak from the
    ledge's edge. A tap, or a take-off one step back, fails.
  - The 3-row cliff steps cleared by 43-46 px.
  - This is the game's first climb with the base kit, so consider 3-row steps for the first half
    (`cliffs_128px_step.png`).
- **The bridge's gap jump leaves the frame** (threshold_bridge).
  - The deck (row 5, y 160) leaves 160 px above it in a 1-screen room. The jump peaks at y 18-23, his
    head at -36, above the room's top, where the camera is clamped.
  - For ~0.5 s of the room's key jump only his feet show (`bridge_jump_leaves_frame_top.png`).
  - **Fix:** deck at row 6-7, or a 2-screen-tall bridge room.
  - The cistern's top beam does the same (head out of frame).
- **The gap and ravine themselves are fine** (threshold_bridge).
  - A running jump from the deck edge (x 6927) lands at x 7158, 22 px past the far edge (gap
    192 px; reach 271).
  - The ravine climb works: floor (352) to fallen span (256) to deck (160), apex 43 px over the deck.
  - The brute knocked Ivo back to the gap's lip (7134, 160; `bridge_brute_knocks_to_lip.png`). Stepping in
    and swinging twice a second killed it (`max_hp` 5) within ~7 s, with no damage taken.
- **Lane west's gatehouse:** walking off the lane's long ledge (row 6) west grazes the gatehouse's
  bottom corner at x -1056 (velocity 0 for one step). Harmless.

### Works with the base kit

- New game in village_house (320, 12288). Look_up at the door leads to the square's door (272, 288) and
  back.
- Tavern (1168), elder (1616, loft reachable and walked off), bakery (lane -880), farmhouse (fields
  5776) and lighthouse (11536) doors all lead back to the door they came from.
- The lighthouse hatch (24496, 12288) knocks (sprite shake ±1.3 px for ~0.2 s) and stays sealed;
  Ivo stays inside.
- Wayshrine bench: look_down seats him at (8016, 224); a jump stands him up.
- Village gates (debug owns the Memorina):
  - lane_west fence (col 3, x -1168): not drawn; walked through into woods_edge
    (`lane_west_fence_open.png`);
  - mill barrier (col 30, x 2896): not drawn; walked through on the trail at (2895, 160).
  - A non-debug start would be blocked by both (barriers require `owns_memorina`). Not run: the runner's
    save always owns the Memorina.
- Every room seam on the route has matching floors (y 288; cliffs/base at -864), and no gap, ledge or
  landing at a seam stopped the base kit.

### Not covered

lighthouse_top (sealed), the tavern cellar, the empty house, the bell tower, the cistern way out (blocked
by the loop), a non-debug fence, and a death with no bench.

## Ratings rationale

- **Fluidity 1 (measured):** every room change costs ~7 s of strobing fades, and two vertical
  connections lock the game. Inside rooms, movement is continuous and the route never needs
  a precise input except the lighthouse's three adjacent steps and the 4-row steps.
- **Fun 2 (inferred from timing, needs a human):** the bridge gap, ravine and cliff climb are fair
  base-kit challenges with honest margins. The seam fades and the two softlocks would end a first
  session.
- **Aesthetics 3:** a consistent greybox. Snow-capped stone suits the frost edge. The well and the
  bridge read as gaps at a glance. Inside the lighthouse and farmhouse the ledges still get the region's
  snow caps, and the tavern's one-way span looks exactly like the solid floor around it, which hides
  that it is one-way.

Not judged: camera smoothing, input latency and fade timing feel (frames and logs only). A human pass is
needed after the seam fix, which changes how every room change feels.
