---
id: playtests/2026-10-10-traversal-orchards-caldera
type: playtest
title: WORLD-05 traversal of the Wind Orchards and the Summer Caldera - both entries each, gates, seams, benches, doors
status: active
build: 5062946 (HEAD), imported 00:23:06. The tree also held a sibling's uncommitted edits to lake_fishing_village, lake_waterfall_path, lake_well and village_mill .room (saved 00:22, before the import, outside the tested rooms). No file in scenes, resources, globals, assets or addons changed after the import. All 49 runs saw the same code.
area_tested: "wind_orchards (orchard_terraces, orchard_chasm_bridge, orchard_well, orchard_mill_town, orchard_inn, orchard_counterweights, orchard_windy_gap, orchard_leaf_path, orchard_arena, orchard_cliff_chimney), summer_caldera (all nine rooms), entries from woods_canopy, lake_chasm and village_cistern"
tags: [traversal, world-05, rooms, seams, gates, softlock, out-of-bounds, double-jump, wall-climb, redoma, region-cut, camera]
related: [bugs/the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top, bugs/the-village-cistern-shaft-is-sealed-by-its-new-ledges, bugs/the-mill-loft-is-unreachable-from-the-lowered-drawbridge, bugs/the-fishing-village-well-squall-blows-ivo-off-the-climb-out, playtests/2026-10-09-traversal-woods-lake, playtests/2026-10-09-traversal-opening, bugs/the-orchard-arena-barrier-is-jumped-over-into-the-cliff-chimney, bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera, bugs/wall-climb-leaves-the-world-over-the-cliff-chimneys-west-wall, bugs/leaving-a-redoma-shell-downward-catches-ivo-on-its-ring, bugs/a-hop-from-a-floor-just-below-a-seam-swaps-the-room-up-and-back, bugs/the-mill-loft-is-reached-by-double-jump-without-soltar, bugs/the-raised-mill-drawbridge-stands-through-the-windy-gap, systems/rooms, systems/world, systems/bell-jar]
created: 2026-10-10
updated: 2026-10-10
ratings: { fun: 2, fluidity: 3, aesthetics: 2 }
screenshots:
  - screenshots/2026-10-10-traversal-orchards-caldera/route_highlights.png
  - screenshots/2026-10-10-traversal-orchards-caldera/arena_barrier_double_jump_over_the_wall.png
  - screenshots/2026-10-10-traversal-orchards-caldera/chimney_floor_no_wall_climb_stuck.png
  - screenshots/2026-10-10-traversal-orchards-caldera/chimney_wall_climb_out_of_the_world.png
  - screenshots/2026-10-10-traversal-orchards-caldera/cistern_redoma_shell_holds_ivo_in_the_shaft.png
  - screenshots/2026-10-10-traversal-orchards-caldera/hop_below_seam_swaps_rooms.png
  - screenshots/2026-10-10-traversal-orchards-caldera/mill_loft_reached_without_soltar.png
  - screenshots/2026-10-10-traversal-orchards-caldera/raised_drawbridge_stands_in_the_windy_gap.png
  - screenshots/2026-10-10-traversal-orchards-caldera/rv_safety_net_on_a_plain_double_jump.png
  - screenshots/2026-10-10-traversal-orchards-caldera/rv_cistern_shaft_sealed_by_ledges_13_and_15.png
  - screenshots/2026-10-10-traversal-orchards-caldera/rv_loft_bridge_end_capped_by_counterweights.png
  - screenshots/2026-10-10-traversal-orchards-caldera/rv_windy_gap_puzzle_and_gale_crossing.png
  - screenshots/2026-10-10-traversal-orchards-caldera/rv_fishing_well_squall_blows_ivo_off_the_catch.png
  - screenshots/2026-10-10-traversal-orchards-caldera/rv2_cistern_pinch_moved_to_ledges_16_and_18.png
  - screenshots/2026-10-10-traversal-orchards-caldera/rv2_fishing_well_catch_to_floor.png
  - screenshots/2026-10-10-traversal-orchards-caldera/rv2_windy_gap_shelf_gale_moves_cocoon.png
  - screenshots/2026-10-10-traversal-orchards-caldera/rv2_double_jump_leaves_the_frame_top_on_the_threshold_bridge.png
  - screenshots/2026-10-10-traversal-orchards-caldera/rv3_redoma_first_escape_cistern_climb.png
---

# Traversal: Wind Orchards and Summer Caldera (WORLD-05)

## What was tested

- **Runs.** 49 windowed runs of `tools/playtest/scripts/traverse_orchards_caldera_*.json`, one leg each, started
  with `player_position`.
  - Each run logged every 0.05-0.1 s (room, position, velocity, state, camera centre).
  - Every press is 0.3-0.45 s. A "full" double jump is 0.45 s + 0.4 s, with the second press at +0.55 s; a
    "late" one has the second press at +0.65-0.75 s.
- **Save.** `APPDATA` was redirected for every run. The real save's md5 (`49ae7e28…`) was the same before and
  after.
- **Kits.**
  - Orchards on arrival: double jump, roll, FREEZE, BELL_JAR, ROOT, RAIN (`skills [0, 2]`, `known_songs [0, 1, 6, 7]`).
  - RELEASE and GALE were added for the Soltar and Vendaval legs, and `skills [0, 1, 2]` (wall climb) for the
    chimney.
  - Caldera through the cistern: the Orchard kit without wall climb. Through the chimney: with wall climb.
- **Cells** were read with a script (world px = room position + 32 × col).
- **Errors.** No `ERROR` or `SCRIPT ERROR` in any run, apart from the leak report at exit.
- **Camera.** Ivo's body was 100% inside the view on every logged sample of every run (`vis.py`). That includes
  hops over room tops and the out-of-world fall below: the camera yield always follows him.

## Blockers, softlocks and skips (ranked)

| # | Severity | Where | What | Entry |
|---|---|---|---|---|
| 1 | **high, softlock** | orchard_arena barrier → orchard_cliff_chimney | The 96 px barrier is a step. A double jump from its top clears the arena's west wall (top -1536, peak -1585.9). The chimney floor then has no exit without wall climb: the double jump peaks at 1647.6 and col 10's top is 1536. | `bugs/the-orchard-arena-barrier-is-jumped-over-into-the-cliff-chimney` |
| 2 | **high, progression softlock** | summer_caldera, both exits | The cistern drop is one-way (dais double jump 1487.6; the shaft starts at 1408). From the Caldera side the chimney pocket's wall is 288 px (double jump 1583-1591 against a 1536 top). A Redoma-first player (Lake before Orchards, which design 04 allows) never leaves. | `bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera` |
| 3 | **high, out of bounds** | orchard_cliff_chimney col 0 | With wall climb, Ivo climbs over the west wall's top (the world's edge) and falls forever: y 15121 after 17 s, no kill plane, the camera following him into a grey void. | `bugs/wall-climb-leaves-the-world-over-the-cliff-chimneys-west-wall` |
| 4 | medium | village_cistern dry shaft (the Redoma route) | Redoma releases Ivo by his feet (220 px from the centre). Falling out through the bowl, he hangs on the ring for 6.6 s (t 8.2-14.8) until it contracts. | `bugs/leaving-a-redoma-shell-downward-catches-ivo-on-its-ring` |
| 5 | medium, feel | mill loft, inn gallery, terraces crown, woods_canopy launch branch | Floors 64-128 px under a seam. A hop (even a 0.1 s tap on the loft and gallery) changes the room up and back: two glides, or two region cuts on the canopy branch. | `bugs/a-hop-from-a-floor-just-below-a-seam-swaps-the-room-up-and-back` |
| 6 | low, skip | orchard_mill_town loft | Reached without Soltar by a running double jump with a late second press (2 of 2 at +0.65 and +0.75 s; 9.5 px spare). It leads only to the counterweights' dead-end chamber. | `bugs/the-mill-loft-is-reached-by-double-jump-without-soltar` |
| 7 | low | mill drawbridge, held up | A solid 576 px pole through orchard_windy_gap's chasm. It stops the Vendaval crossing (x -6745.9) whenever the bridge is not lowered. | `bugs/the-raised-mill-drawbridge-stands-through-the-windy-gap` |

**Gates that hold** (measured):
- **Orchard well, Soltar + Enraizar.**
  - A running double jump from the one-way peaks at -1611.7 and lands west of col 21.
  - A double jump from the well floor peaks at -1453, 19 px under the exit top (-1472).
- **Windy gap gallery → east ledge.** Blocked by the raised bridge itself (x -6778).
- **Windy gap chasm without Vendaval.**
  - Without the bridge down, the pole stops it.
  - With the bridge down, the current alone adds ~3 px/s at memory 0.25. The jump lands at x -6948, short of
    the west floor (-7168).
- **Temple gate (Sombra).** Standing on the plate, then run + roll: the 0.6 s gate is shut at x 2137.9.
- **Arena barrier against walking.** It holds; only the jump over it (#1) gets past.
- **Corridor alcove gate and leaf-path curtain.** Sealed by geometry: the gate's 96 px fills rows 2-4 under a
  stone row, and the curtain's 32×96 fills the tunnel. Not run.

## Per-room results

### Wind Orchards

| Room | Result | Timelines | Measured |
|---|---|---|---|
| woods_canopy → orchard_terraces (region seam, up) | PASS | `o1` | Full double jump from the launch branch. The room cuts at feet -1186.5; lands at (-4044, -1248). |
| orchard_terraces | PASS | `o1`, `o2a`, `o5`, `h1` | <ul><li>The hole (cols 44-51) is cleared by a running double jump.</li><li>Bench: down sits Ivo at (-4784, -1248).</li><li>Step onto cols 26-27: 0.45 s press, peak -1391 (15 px spare). Crest (160 px): double jump, peak -1616 (80 spare).</li><li>West floor to the mill town seam: ok.</li><li>A fall through the floor hole lands in woods_canopy (-4384, -864): a region cut down, an intended drop.</li><li>Floor → one-way r13 (256 px): only a full double jump lands (peak -1517.6, 13.6 px spare). A 0.3 + 0.35 s double jump peaks at -1488.8 and drops into the hole.</li><li>r13 → r9 → crown: ok. Crown hops: #5.</li></ul> |
| orchard_chasm_bridge | PASS | `o5`, `o5b` | <ul><li>Crown → up the hole: peak -2061.6, lands at -2016.</li><li>Across the mound to lake_chasm: the region cuts at x -3178 going east and at -3222 coming back.</li><li>Walking off into the hole lands on the crown at (-4239.5, -1792).</li></ul> |
| orchard_well | PASS | `o6` | <ul><li>In from the terraces (in-region switch at x -3811) and out again (-3855).</li><li>The gate holds (see above).</li></ul> |
| orchard_mill_town | **FAIL** (#6), route PASS | `o2a`, `o2b`, `g1`, `g4b`, `h2`, `h3` | <ul><li>Pit walk; 64 px hop out at x -6400.</li><li>Soltar on the gallery lowers the bridge. Walking it and double-jumping up the chasm lands on the windy gap's ledge (-6471.6, -1632).</li><li>Loft skip: #6. Loft and gallery hops: #5. Raised bridge: #7.</li></ul> |
| orchard_inn (door) | PASS | `o2b` | <ul><li>Prompt from x -6699 (moving left).</li><li>Arrives at (60144, 12288) with `fade` 0.84 and `pmode` 4 during the trip.</li><li>Back out at (-6704, -1248).</li><li>The upper floor was not climbed.</li></ul> |
| orchard_counterweights | PASS (partial) | `o7`, `h2` | <ul><li>Block top → drop column → out east onto the terraces' upper west hill (-5729, -1632) → off it onto the block (-5246, -1344). No softlock.</li><li>The lift puzzle itself was not run.</li></ul> |
| orchard_windy_gap | PASS (route), see #7 | `g3`, `g4a-c`, `g5a-b` | <ul><li>A fall drops into the mill town. Entered by the intended route (`g4b`).</li><li>**Vendaval crossing not achieved** in two attempts: running double jump from the ledge edge with the gale played facing west.</li><li>In `g5b` the gale pushes him to 457 px/s, but he slows to ~205. At ledge height he is at x -7049, 120 px short of the west floor. That is ~16 cells of carry, against the room header's "about 21.7".</li><li>Not explored further (puzzle scope). Flagged for a puzzle playtest, not filed.</li></ul> |
| orchard_leaf_path | PASS | `o2b`, `o2c` | <ul><li>Mill town → step (64) → hill (96) → off the west end → arena.</li><li>The westward route needs only single jumps. The way back east climbs 160 px onto the hill from the floor, so it needs the double jump.</li></ul> |
| orchard_arena | **FAIL** (#1) | `o2c`, `o3` | The barrier holds against walking and a single jump; the double jump from its top passes. |
| orchard_cliff_chimney | **FAIL** (#1, #3); PASS with wall climb | `o3`, `o3b`, `o4`, `o8a`, `o8c` | <ul><li>Wall climb: through the open barrier, the 3 100 px fall, wall jumps up the climb shaft over col 10 (feet 1496 at t 11.0), the pocket, then east.</li><li>The region cut into caldera_chimney_base is at feet x -10214.9.</li><li>Going back up the fall shaft, holding into the west wall stops under the row-69 overhang (feet 758). Stepping out and double jumping passes it, and that leads to #3.</li></ul> |

### Summer Caldera

| Room | Result | Timelines | Measured |
|---|---|---|---|
| village_cistern → caldera_cistern_bottom (region seam, down) | PASS with #4 | `c1` | <ul><li>Redoma on the slab (1005, 672) holds the pool off the shelf.</li><li>Shelf (1059, 800) → mouth → shaft → dais (945.7, 1728). The region cut is at feet 1300.</li><li>6.6 s hang on the ring (#4).</li></ul> |
| caldera_cistern_bottom | **FAIL** (#2) | `c3a`, `c4` | The walk west and east is fine (32 px steps by hop). The way back up is one-way: dais double jump peak 1487.6. |
| caldera_open_crater (bench) | PASS | `c3a`, `c3b0`, `c3b` | <ul><li>In-region switch at x -660.</li><li>Dropping into the bench pit and sitting: (-1264, 2208), `sit=t`.</li><li>Climbs out by three 128 px single jumps (peaks 16, 16 and 16 px over each step).</li><li>The cap crossing on row 33 was not timed. The pit is the safety net.</li><li>The climb to the lookout (rows 8-28) was not run.</li></ul> |
| caldera_seesaw | PASS | `c3b` | Onto the plank and off its west end; 32 px steps up to the dry moat (switch at x -3215). |
| caldera_dry_moat | PASS | `c3c` | The trough walk; pillar (64), rims (64), step (32); switch to bait at x -5140. |
| caldera_bait | PASS (hazard fair) | `c3d` | <ul><li>The brute hits once (hp 3 → 2, knockback to x -5623).</li><li>Sword swings kill it within ~7 s.</li><li>Walk on: the switch to the corridor is at x -6424.</li></ul> |
| caldera_long_corridor | PASS | `c3e` | Floor walk past the plate; block hop (32). |
| caldera_chimney_base | PASS | `o4`, `c3e` | <ul><li>Both seams cut: chimney → base at feet x -10214.9, base → chimney at -10268.</li><li>The pocket is a dead end without wall climb (#2).</li></ul> |
| caldera_temple_gate | PASS | `c4`, `c4b` | <ul><li>Step (64) → terrace (64) → plate opens the gate.</li><li>Roll + run east is stopped at x 2137.9.</li><li>Off the terrace, under it, to the arena (switch at x 2579.8) and back.</li></ul> |
| caldera_arena | PASS | `c4b` | Flat; the east wall is closed. |

## Seams

- **Region seams cut on one frame**, both ways where both ways exist:
  - canopy ↔ terraces (up by jump, down by the hole);
  - lake_chasm ↔ chasm_bridge;
  - cistern → Caldera (down only);
  - chimney ↔ chimney_base.
  No flip-flop on any walk or fall.
- **In-region seams switch once per crossing**, on all 15 crossings walked or fallen through:
  - terraces↔mill town, mill town↔leaf path, leaf path↔arena, arena↔chimney, terraces↔well;
  - chasm bridge↔terraces, counterweights→terraces, mill town↔windy gap;
  - Caldera: cistern bottom↔crater, crater↔seesaw, seesaw↔dry moat, dry moat↔bait, bait↔corridor,
    corridor↔chimney base, cistern bottom↔temple gate, temple gate↔arena.
- **Hop in place** (`h1`-`h4`): every floor 64-128 px under a horizontal seam switches up and back on a hop (#5).
  No floor on these routes straddles a seam, so the 2026-10-10 slab case did not recur.

## What screenshots and logs cannot show

- **Camera motion.** Whether the 0.45 s glides on the loft and gallery hops, and the double cut on the canopy
  branch, feel like a twitch or are acceptable at 60 fps. The 300 px up-and-back pan is measured. Its feel is
  inferred.
- **The 6.6 s shell hang (#4).** It reads in frames as a freeze in a falling pose. Whether a player thinks the
  game hung needs a human.
- **Wall-climb feel.** The climb is "hold into the wall, tap jump", with no kick-off. Getting past the
  chimney's overhang took a let-go-and-double-jump move a player may not find. That is inferred from inputs,
  not from playing.
- **Not judged:** input latency, audio, fight feel against the bait brute, and the weight of the long chimney
  fall.

## Aesthetics noted (not filed)

- **Orchard backdrops.** The rooms show the same pine forest as the woods, in grey. Design 04 §6 asks for
  hills with windmills and a windy sky.
- **The Caldera** draws no backdrop at memory 0.15. The crater "open to the sky" reads as a flat grey box.
- **The wall-climb barrier** is a flat purple placeholder rectangle.
- **The inn door's prompt** draws over the stone block that sits directly on top of the door (S24-31).
- **Above room tops.** When the camera yields above a room's top (leaf path hill, arena barrier, windy gap),
  the area above is a flat band with no backdrop. Ivo can sit over the HUD notes at the top-left
  (`arena_barrier_double_jump_over_the_wall.png`, middle frame).

## Not covered

- orchard_counterweights' lift puzzle.
- The windy gap's Vendaval crossing and alcove puzzle (one observation above).
- The leaf-path curtain alcove, the orchard well's Soltar + Enraizar catch, and the inn's upper floor.
- The crater lookout climb, the dry moat, seesaw and temple sanctum song puzzles, and the corridor alcove.
- A non-debug save.

## Ratings rationale

- **Fun 2** (inferred; needs a human):
  - The Orchards' main path (canopy → terraces → mill town → leaf path → arena) and the Caldera's walk are
    readable, with fair 64-160 px steps and one honest double-jump crest.
  - But three of the first things a curious player tries end a session: hop the barrier, play Redoma-first
    into the Caldera, climb the chimney's outer wall.
- **Fluidity 3** (measured in part): seam walks never stop Ivo and he is always in frame. Against that: the
  6.6 s mid-air hang on the Caldera's main entrance, and the up-and-back camera on four launch floors.
- **Aesthetics 2:** a consistent greybox, but the Orchards borrow the woods' backdrop, the Caldera has none,
  and the barrier is a placeholder.

## Re-verification (2026-10-10, ~01:30-02:25)

**Code under test.** The working tree on 5062946 with the coordinator's fixes:
- `RoomExit.has_left`;
- the out-of-every-room safety net in `Game`;
- `FrostShell._is_clear`;
- edits to orchard_arena, orchard_cliff_chimney, orchard_mill_town, orchard_windy_gap, village_cistern,
  caldera_cistern_bottom, village_mill, lake_well and lake_fishing_village.

`--import` at 01:27:51. No file changed after it. About 60 runs, timelines
`tools/playtest/scripts/traverse_orchards_caldera_rv_*.json` plus re-runs of the first session's timelines. No
`ERROR` apart from the leak report. The real save's md5 (`49ae7e28…`) was unchanged.

### Results per item

| Item | Result | Measured |
|---|---|---|
| (a) Hop check: crown, mill loft (row 0), windy launch ledge (row 3), canopy branch | **PASS** | No room change on any tap (0.05/0.1/0.2 s) or jump (0.45 s); peaks -1935.7, -1679.7, -1583.7, -1167.7 (`rv_h1-4`). |
| (a) Normal crossings switch once | **PASS** | <ul><li>Re-runs of `o1` (region cut at feet -1246.9), `o5`, `o5b` (lake_chasm cut both ways), `o2a`, `c3a` and `o4` (cut into caldera_chimney_base).</li><li>One switch each, no fade.</li></ul> |
| (b) Safety net, void search | **PASS, with a new problem** | <ul><li>No way out of the world found. The chimney climb now stops under the ceiling (`o8c`, feet -1450 until the end).</li><li>New problem: a plain double jump above any open room top runs the hazard beat. Leaf path hill, orchard_well one-way and threshold bridge deck: `fade` peaks at 0.93-0.98, then Ivo is put back (`rv_n1-3`).</li><li>`bugs/the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top`, medium.</li></ul> |
| (c) Redoma downward exit | **PASS** | <ul><li>Redoma on the terraces crown, then two drops, the second 340 px from the centre: falls through the ring with no held sample (`rv_s1`).</li><li>The cistern route itself cannot be run (item 6).</li></ul> |
| 1. orchard_arena lintel | **PASS** | Never stands on the barrier; double jumps peak at feet -1450 under the overhang; never west of x -10164 (`rv_a1`). |
| 2. orchard_cliff_chimney ceiling, and the route down | **PASS** | <ul><li>Wall climb stops under row 0 (`o8c`).</li><li>The way back up reaches the top step (-10567, -1184) (`rv_o9`).</li><li>The route down to caldera_chimney_base works (`o4`).</li></ul> |
| 3. Mill loft: no skip; Soltar route | **FAIL** | <ul><li>No skip: double jumps from the yard peak at -1322, under the inn roof (`rv_l1_45/60/75`).</li><li>But the Soltar route fails. From the lowered bridge's end (-6343.7, -1344), the jump is capped at feet -1481.9 by the counterweights' floor (-1536) and drops to the pit (`rv_l2`).</li><li>`bugs/the-mill-loft-is-unreachable-from-the-lowered-drawbridge`, medium.</li></ul> |
| 4. Drawbridge 6 cells, inside the mill town; Soltar lowers it; launch ledge row 3 → windy ledge, no song | **PASS** | <ul><li>The bridge lowers and is walked to its end.</li><li>From the row-3 one-way, a double jump lands on the windy gap's east ledge (-6459, -1632), switching once (`rv_w1`).</li></ul> |
| 5. Windy gap: no crossing without Vendaval; with Vendaval; the puzzle | **PASS, with precision notes** | <ul><li>**Without the song**, 0 of 5 cross. Every second press from +0.55 to +1.35 s falls into the mill town; at ledge height x -6952..-6986 (`rv_w2a`, `rv_w4_*`).</li><li>**With Vendaval** played facing west, only a second press at +1.2 s lands: 3 of 3, at x -7239..-7247, 7-15 px past the floor's edge (-7232). +0.55 and +0.9 s fall short (`rv_w2b`, `rv_w3_*`).</li><li>**The puzzle works only with the gale played from the floor under the shelf** (`rv_w7`). The cocoon slides from col 3 to the plate, the gate rises, and Ivo walks into the alcove (-7628).</li><li>From the shelf it does not work. Ivo can stand at most ~70 px west of the cocoon (the col 0 wall), which is inside the gale's 48 px still eye and its ramp, so the cocoon never moves (`rv_w5` ×3, `rv_w6`).</li></ul> |
| 6. Cistern two-way | **FAIL (high)** | <ul><li>**Climb:** dais → C14 → C10 → C6 → C2 → V22 → V18 with normal presses (closed loop, `rv_c1`). V18 → V15 is impossible.</li><li>**Descent:** Redoma, the shelf, the mouth, and Ivo lands on V15 (972, 864). He can go no lower (`c1`, `rv_c2`).</li><li>**Cause:** V13 (row 13, cols 7-9) and V15 (row 15, cols 10-13) meet corner to corner with 32 px between them, and Ivo is 54 tall. The shaft is closed both ways, so the Caldera's Redoma entrance is gone.</li><li>`bugs/the-village-cistern-shaft-is-sealed-by-its-new-ledges`.</li></ul> |
| 7a. Lake entrance: trail → step → ledge → bench stub | **PASS** | <ul><li>Trail (160) → step (96) → ledge (0, the region switch happens on standing, at x 2944) → stub (-96) → sits on the bench (2640, -96) (`rv_k1`).</li><li>The barrier passage stays blocked: in `rv_k2` Ivo is stopped at x 2870 on the trail, and single jumps reach no ledge.</li></ul> |
| 7b. Fishing village well: three 3-row climbs | **FAIL (high)** | <ul><li>The squall (now 352 px tall) covers the climb.</li><li>Walking in from the notch misses the catch and lands on the chamber floor, pinned west.</li><li>Walking back to the niche works. 0 of ~45 jumps from the niche land on the 3-cell catch, and placed on the catch, Ivo is blown off in 0.5 s (`rv_k3-k11`).</li><li>The only exit without Redoma is dying in the water column.</li><li>`bugs/the-fishing-village-well-squall-blows-ivo-off-the-climb-out`.</li></ul> |

### Bug status after this re-verification

- **Resolved:**
  - `the-orchard-arena-barrier-is-jumped-over-into-the-cliff-chimney`
  - `wall-climb-leaves-the-world-over-the-cliff-chimneys-west-wall`
  - `leaving-a-redoma-shell-downward-catches-ivo-on-its-ring`
  - `a-hop-from-a-floor-just-below-a-seam-swaps-the-room-up-and-back`
  - `the-mill-loft-is-reached-by-double-jump-without-soltar`
  - `the-raised-mill-drawbridge-stands-through-the-windy-gap`
- **Still open:** `a-redoma-first-player-is-trapped-in-the-summer-caldera`. The climb is blocked at V18, and the
  entrance itself is now closed.
- **New, ranked:**
  1. high: `the-village-cistern-shaft-is-sealed-by-its-new-ledges`
  2. high: `the-fishing-village-well-squall-blows-ivo-off-the-climb-out`
  3. medium: `the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top`
  4. medium: `the-mill-loft-is-unreachable-from-the-lowered-drawbridge`
- **Precision notes, not filed:**
  - The windy gap's Vendaval crossing works only with the second press at ~+1.2 s, with 7-15 px to spare.
  - Logico 2 needs the gale played from below the shelf.
  - The cistern's 128 px ledges clear by ~15 px with an apex steer.
  These are inferences from input windows; a human pass would tell whether they read as fair.

Ratings are unchanged: fun 2, fluidity 3, aesthetics 2. Seam feel improved (no hop swaps), but two entrances are
now broken (the cistern and the fishing well) and the safety net fades the screen on legitimate jumps.

## Re-verification 2 (2026-10-10, ~02:40-03:20)

**Code under test.** The working tree on 5062946 with the second round of fixes:
- `Game` ignores a body above an open room top, and the camera yield is limited to the rooms in reach (`camera.gd`);
- edits to village_cistern, lake_well, orchard_mill_town and orchard_windy_gap.

`--import` at 02:37:17. Nothing changed after it. About 45 runs, timelines
`tools/playtest/scripts/traverse_orchards_caldera_rv2_*.json` plus re-runs of `rv_n1-3`. No `ERROR` apart from the
leak report. The real save's md5 (`49ae7e28…`) was unchanged.

| Item | Result | Measured |
|---|---|---|
| 1. Cistern shaft (row-15 ledge moved to row 16), climb and descent | **FAIL** | <ul><li>V13/V16 now have 64 px, but V16 (row 16) and V18 (row 18) meet corner to corner at x 960 with 32 px.</li><li>**Descent:** Redoma, shelf, mouth → V16 → V18 (908, 960), then blocked at x 950 by V16's face (`rv2_c2`).</li><li>**Climb:** dais → … → V22 works; V22 → V18 is impossible in 14 closed-loop passes (`rv2_c1`).</li><li>Not a softlock: V18 → V16 works through a 10 px window (`rv2_c3`).</li><li>The shell exit downward (V16 → V18) does not hang.</li><li>Fix: move V18 down to row 19.</li></ul> |
| 2. Fishing village well | **PASS** | <ul><li>**Base kit:** walking off the notch lands on the catch (1563.9, -1440), then up to the notch (1526.6, -1536), then the village floor (1436.1, -1632). No wind on the way (`rv2_k1`).</li><li>**Redoma puzzle:** Redoma by the pool, down the held-out column; Soltar inside the shell drops the reeds and Ivo reaches the alcove (x 1324) (`rv2_k2_1650`).</li><li>**Control:** 30 px west, outside the shell, the squall breaks Soltar (`rv2_k2_1620`).</li></ul> |
| 3. Safety net | **PASS** | <ul><li>No fade and no pull-back on the leaf path hill, orchard_well one-way or threshold bridge double jumps.</li><li>The void case still respawns. Wall climb over bloom_hollow's open-topped west wall (the world's edge) → fade 0.91 → back on firm ground (-6931.9, 288), twice (`rv2_v2`).</li><li>Camera: where nothing touches the room from above (threshold bridge), Ivo is wholly out of the frame's top for ~1.05 s of the double jump, and only the HUD shows. Elsewhere the frame follows (visible 1.00). Needs a human eye.</li></ul> |
| 4. Mill loft | **PASS** | <ul><li>**Soltar route:** from the lowered bridge's end, a double jump lands on the one-way loft (2 of 2: x -6106, -6046; y -1536), and the room becomes orchard_counterweights.</li><li>**No skip:** without Soltar, all 4 attempts (roof and row-3 one-way, second presses +0.55 and +0.75) fall short.</li><li>The raised bridge stops him at x -6458 and does not rise above the room's top.</li></ul> |
| 5. Windy gap (20 cells) | **PASS, with a timing note** | <ul><li>**Vendaval:** crosses with the second press at +1.0 s (x -7195.5 at ledge height) and +1.2 s (-7239.3). Falls short at +0.55 s (-7092, 76 px short) and +0.8 s (-7133, 35 px short).</li><li>**No song:** 0 of 3 cross.</li><li>**Other songs' pulses:** none crossed, with second presses at +0.55 and +1.2 s. Soltar best reached -6997, Chuva -7098, Enraizar -6987.</li><li>**Lógico 2 from the shelf:** with the cocoon at col 6, the gale (Ivo west of it) slides it onto the plate and the gate rises (`rv2_w4`, frames `rv2_windy_gap_shelf_gale_moves_cocoon.png`).</li></ul> |

**Bug status after re-verification 2:**
- Resolved:
  - `the-fishing-village-well-squall-blows-ivo-off-the-climb-out`
  - `the-out-of-room-safety-net-fires-on-a-double-jump-above-an-open-room-top`
  - `the-mill-loft-is-unreachable-from-the-lowered-drawbridge`
- Still open: `the-village-cistern-shaft-is-sealed-by-its-new-ledges` (the pinch moved) and
  `a-redoma-first-player-is-trapped-in-the-summer-caldera`.

**New notes, not filed:**
- **Vendaval timing.** Crossing with Vendaval needs a late second press (≥ +1.0 s). A habitual +0.5 s second press
  falls 35-76 px short. Whether that is learnable is for a human.
- **Camera yield over open tops.** The frame now holds still above an open top with nothing above, and a
  double jump there leaves the frame for ~1 s.
- **Climbable world edges.** bloom_hollow's west wall is an open-topped world edge that wall climb gets over. The
  safety net catches it, so it is not a void any more.

## Re-verification 3 (2026-10-10, ~03:12-03:30): the cistern shaft

Working tree on 5062946 with the cistern shaft re-laid, `--import` at 03:11:29; nothing changed after it. About 15 runs, timelines `tools/playtest/scripts/traverse_orchards_caldera_rv3_*.json`. No `ERROR` apart from
the leak report. The real save's md5 (`49ae7e28…`) was unchanged.

| Item | Result |
|---|---|
| Full climb dais → … → V22 → V19 → V16 → V13 → mouth → Redoma → shelf → slab, normal presses | **PASS** |
| Descent from the mouth to the dais | **PASS** |
| Redoma-first escape, start to finish (no double jump, no wall climb, after sitting on the crater bench) | **PASS** |

- **Climb** (`traverse_orchards_caldera_rv3_c1_caldera_dais_climb_to_village_cistern_slab.json`, closed loop;
  the same inputs with no double jump: `..._rv3_e4_redoma_first_climb_dais_to_slab_no_double_jump.json`):
  - Ivo stands on, in turn: dais (1728) → C14 (1050, 1600) → C10 (922, 1472) → C6 (999, 1344) → C2 (922, 1216) →
    village_cistern (one cut at t 7.41) → V22 (974.5, 1088) → V19 (908, 992) → V16 (995, 896) → V13 (921, 800).
    Presses are 0.45 s; the dais-to-C2 steps use an apex steer, the last three the direction held from take-off.
  - Then Redoma. V13 cannot reach the shelf directly (the slab caps the hop), so Ivo drops into the mouth onto V16
    (1001, 896), jumps with right held onto the shelf (1065, 800), and jumps left onto the slab (975.7, 672).
    hp 3 throughout.
- **Descent** (`..._rv3_c2_village_cistern_redoma_descent_to_dais.json`):
  - Redoma on the slab → shelf (1059, 800) → V16 (972, 896) → V19 (908, 992) → V22 (1014, 1088) → C2
    (908, 1216, one cut into the Caldera) → C6 (1014, 1344) → C10 (908, 1472) → C14 (1020, 1600) → dais
    (908, 1728).
  - It alternates walk-offs: left, right, left, and so on. There is no airborne hang leaving the shell, and hp
    stays 3.
- **Redoma-first escape, start to finish** (kit: roll, FREEZE, BELL_JAR; no double jump, no wall climb):
  - Square → hop the curb into the well → beam (940.6, 416) (`..._rv3_e1_*`).
  - Slab → descent → dais (`rv3_c2`).
  - West to the crater bench (`..._c3a_*`).
  - **Sits on the crater bench** (`sit=true`), climbs out of the pit and walks back to the dais (802.7, 1728)
    (`..._rv3_e3_redoma_first_crater_bench_back_to_dais.json`).
  - Climbs to the slab with no double jump (`rv3_e4`).
  - Slab → beam row 5 (990, 544) → beam row 1 (937.9, 416) → inner pillar (876.2, 288, in village_square) →
    the square (`..._rv3_e5_redoma_first_slab_beams_to_square.json`).
- Frames: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/rv3_redoma_first_escape_cistern_climb.png`.

**Bug status:** `the-village-cistern-shaft-is-sealed-by-its-new-ledges` and
`a-redoma-first-player-is-trapped-in-the-summer-caldera` are resolved. No bug from this session remains open.

## Re-verification 4 (2026-10-10, ~03:36-03:50): the safety-net and camera-reach review fixes

`--import` at 03:35:59; nothing changed after it. 10 runs; no `ERROR` apart from the leak report. The real save's
md5 was unchanged.

| Item | Result | Measured |
|---|---|---|
| 1. Drop across a seam above two open tops (`bugs/the-safety-net-fires-when-ivo-drops-across-a-seam-above-two-open-tops`) | **PASS** | <ul><li>Leaf path row-3 one-way → double jump west over the col-0 wall (peak -1707.2): no fade; lands in orchard_arena (-9265.2, -1248).</li><li>Leaf hill, orchard_well and threshold bridge double jumps: no fade, no pull-back.</li></ul> |
| 2. The hazard beat holds Ivo (`bugs/ivo-stays-live-through-the-out-of-room-hazard-beat`) | **PASS** | <ul><li>Void case over bloom_hollow's west wall: held at vy +40 from t 3.15 to 3.75 with left held; the jump at 3.40 is ignored.</li><li>Put back at (-6931.9, 288).</li><li>Control returns during the fade-in, as with water.</li></ul> |
| 3. Camera reach (`bugs/the-camera-reach-is-a-bounding-box-and-shows-the-void-over-an-open-top`) | **PASS** | <ul><li>Leaf hill: the frame stays in the room (centre y ≥ -1356); Ivo is out of the frame's top ~1.35 s.</li><li>Where a room is above (crown, canopy branch) or across the seam (lake ledge), visible stays 1.00.</li><li>The square → mill glide has no pop (smooth 73k-218k-5k per-frame change).</li></ul> |

**Feel note** (for a human): over any open top with nothing above, a double jump now takes Ivo out of the top of a
still frame for 1.0-1.55 s (threshold bridge, leaf path, orchard_well). That is the intended trade for not showing
the void.
