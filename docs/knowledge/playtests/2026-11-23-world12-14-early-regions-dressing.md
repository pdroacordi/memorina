---
id: playtests/2026-11-23-world12-14-early-regions-dressing
type: playtest
title: WORLD-12/13/14 early-region dressing - every dressed room toured; the held movers freeze and sway in a pulse as decided, the woods movers run; the fields' gust is a 33 px/s snow effect a crossing player never feels; the canopy drop lands soft; two hanging moss float
status: active
build: 7c725ee5 + uncommitted WORLD-12/13/14 dressing (one --import at session start; nothing under scenes/ resources/ assets/ globals/ tools/art changed after it)
area_tested: "all 19 dressed rooms of threshold, frost_edge and spring_woods at authored memory; the four held movers in the grey and in a FREEZE pulse; ferns and hanging moss at 0.4; the threshold blizzard under FieldsStillMemory vs the bridge; the orchard_terraces hole drop onto woods_canopy's blossom heap"
ratings: { readability: 4, aesthetics: 3 }
tags: [props, world-12, world-13, world-14, world-41, threshold, frost-edge, spring-woods, ambient-motion, greyhush, air, soft-landing, playtest]
related: [systems/props, systems/air, bugs/woods-deep-hanging-moss-floats-under-its-ledge, bugs/the-threshold-field-tree-and-a-wayshrine-snow-heap-overhang-their-step-edges, bugs/the-threshold-fields-memory-hold-stills-nothing-because-the-wheat-was-built-as-a-still, gotchas/a-hand-placed-memory-source-slows-the-region-weather-under-it, playtests/2026-11-20-world15-17-guardian-regions-dressing]
created: 2026-11-23
updated: 2026-11-23
source_files:
  - scenes/world/rooms/threshold/contents/
  - scenes/world/rooms/frost_edge/contents/
  - scenes/world/rooms/spring_woods/contents/
  - scenes/world/rooms/threshold.tscn
  - scenes/world/environment/props/ambient_motion.gd
  - scenes/world/environment/weather/region_wind.gd
---

## Summary

The dressing reads at game size in all three regions. Nothing covers a door, a bench, a slot, a teacher or a jump
line, and each region shows the right season band: winter frost on the threshold and the frost edge, spring in the
woods. The board's movers behave as decided:

- The wheat, the scarecrow's sleeve, the pennant and the torn sail hold their frame in the grey and sway at full speed
  inside a FREEZE pulse.
- The ferns and the hanging moss run at the woods' 0.4.

The open bug from the review (movers built as stills) is fixed.

- **Gust:** in threshold_fields the blizzard is a snow effect only. The first gust comes about 41 s after entering the
  region and peaks at 33 px/s. That is below the 60 px/s at which Ivo braces and the 90 px/s ground deadzone, so a
  player crossing the room feels nothing.
- **WORLD-41:** the canopy drop lands soft every time it lands on the heap.

Defects:

- Two hanging moss in woods_deep float 24 px under their ledges (bug filed).
- The hollow tree's shelf fungus reads as small ledges.
- The canopy heap is drawn much narrower and lower than its soft zone.

## What was tested

- **Tours.** A scratch `world.py` read every room's `.room` grid, its contents `Props` and the region origins. It tiled
  each room into 640x360 views and teleported Ivo onto the floor nearest each view that holds a prop. That gave 55
  views over three runs, plus two short passes facing west for the props the look-ahead had cut (the bridge
  milestone, the shore's rope coil and barrel, the cliffs' storm lantern, the lighthouse railing, bloom_hollow's west
  vines).
- **The probe.** A scratch `-s` probe (`dprobe.gd`) kept hp topped up. Every 100-200 ms it logged each on-screen
  `AmbientMotion` (frame, memory sampled at the prop), plus `landed`/`hard_landed` with impact speed and, for the
  gust runs, the region gust clock, strength, `wind_at` and `Airflow` at the feet.
- **Movers.**
  - Fields from (5080, 220): 12 s idle, then FREEZE (`known_songs` [0]).
  - lighthouse_base (11184, -868) and frost_shore (9440, 284): 5 s idle, then FREEZE at each.
  - Woods: woods_edge's ferns, woods_deep's two moss and its root-mound ferns, ~6 s each.
- **Gust.**
  - Fields: 108 s from a fresh world build. The scripted walk stopped at the first one-cell step (x 4789), so this
    run is a standing measurement.
  - Control: 72 s at threshold_bridge (0.3, no hold).
  - A straight 0.4 s jump in the calm and at the peak, in each room.
- **WORLD-41.** Ivo dropped through orchard_terraces' hole three ways (`log` every 0.1 s, `trace`):
  - A: walk off the west edge and release.
  - B: run right through it with the direction held.
  - C: teleported straight above the heap at the terraces' floor height.
- `prop_grounding_test` and `region_prop_placement_test` pass (7/7).

## Findings

**Defects**

- **woods_deep's hanging moss floats** (`bugs/woods-deep-hanging-moss-floats-under-its-ledge`). Both clumps are hung
  from the bottom of an `=` cell, but a ledge is drawn only ~10 px deep, so there is a ~24 px gap of sky. The placement
  test checks cells, so it passes. `woods_deep_hanging_moss_floats.png`, `..._crop.png`, `woods_deep_hanging_moss2_floats_crop.png`.
- **woods_hollow_tree's shelf fungus reads as a ledge.** Each `ShelfFungus` is a flat pale sliver standing out of the
  heartwood wall at about Ivo's head height in a climbing shaft, the shape of a tiny one-way plank. The board says
  "Nothing drawn invites a jump onto it". The knots (rings) and the resin streaks read as wood; the fungus does not.
  `hollow_tree_shelf_fungus_reads_as_ledge.png`.
- Already filed and still visible: the field tree and the wayshrine's `SnowHeap` overhang their step edges
  (`bugs/the-threshold-field-tree-and-a-wayshrine-snow-heap-overhang-their-step-edges`).

**WORLD-41 soft landing: works**

| Drop | Lands at | Impact | Signal | Notes |
|---|---|---|---|---|
| A walk off, release | (-4323, -864) | 866 px/s | `landed` | in the zone; 11 px west of the heap's drawn pixels |
| C straight over the heap | (-4272, -864) | 849 px/s | `landed` | on the heap |
| B direction held | (-4199, -1021) | 653 px/s | `landed` | on the launch branch; the heap is never reached |

- Both heap landings exceed `hard_land_speed` (800), so the `n` zone is what makes them soft: no `hard_landed`, no
  recovery lock.
- The 0.75 s LAND clip still plays, as it does after any landing.
- **The heap is a small mark for a big catch.** The zone is 160 px wide (x -4352..-4192, the whole west part of the
  hole). The drawn heap is about 75 px wide and ~15 px tall, and the grass in front hides half of it. A straight drop
  lands on bare grass beside it. A 380 px fall onto a low pink tuft does not read as "deep enough to land in".
  `canopy_drop_soft_landing_beside_heap.png`, `canopy_blossom_heap_low.png`.
- The region title "Bloom Woods" plays over the landing: expected, since the drop is a region change.

**The held movers** (probe numbers, not frames)

| Mover | Memory outside the pulse | Frame changes outside the pulse | In the FREEZE pulse (memory 1.0) |
|---|---|---|---|
| Scarecrow sleeve, WheatTall3/4, WheatShort2/3 (fields) | 0.15 | 0 in 12 s | ~3 per s for ~14 s, then frozen again |
| Flagpole pennant (lighthouse_base) | 0.05 | 0 in 9 s | ~6 per s for ~13 s |
| MastSnapped sail (frost_shore) | 0.05 | 0 in 9 s | ~6 per s for ~13 s, then frozen |
| Ferns, Ferns2 (woods_edge, woods_deep) | 0.40 | ~1.2-1.5 per s | not tested |
| HangingMoss, HangingMoss2 (woods_deep) | 0.40 | ~1.2-1.5 per s | not tested |

- The motion is visible in frames: a pixel diff over the scarecrow and the east wheat changes 240-300 and ~1200 pixels
  per 0.25 s in the pulse, and 0 in the grey (`fields_movers_grey_then_pulse_flipbook.png`).
- The moss sway is subtle (the strand tips shift 1-2 art px), and so is the ferns' (a frond tip).
- **Contract note.** `systems/props` says "Every frame 0 is the approved still, so a frozen mover shows the approved
  picture". That is not what plays. Each mover's per-position `phase` decides its frame at load, and a pulse leaves it
  wherever it stopped. Logged at load: scarecrow frame 2, wheats 0/1/3, sail 4, pennant 0; after the pulse, sail 1 and
  scarecrow 3. "Frozen mid-sway" holds; "shows the approved still" does not. Either the sentence or the phase rule
  should change.

**Gust in threshold_fields** (`RegionWind`, from a world build in the threshold, which restarts the calm the same way
walking in from the village does)

| | threshold_fields (0.15, held) | threshold_bridge (0.3, control) |
|---|---|---|
| First gust after entering | starts ~41 s, peak 47-65 s, ends ~72 s | starts ~21 s, peak 24-33 s, ends ~36 s |
| Next gust | not reached in 108 s (clock at 16.3 of ~18) | ~57 s |
| Peak air at Ivo | 33 px/s | 66 px/s |
| Standing Ivo | does not move or brace | does not move; braces (`brace_stand`) |
| Straight jump drift at the peak | 39 px west | 82 px west |

What a player crossing the room feels: **nothing.** At 192 px/s the 1920 px field takes 10-15 s with its step jumps,
and the first gust is 40 s away. A player who lingers, watching the scarecrow, meets a gust only after ~40 s:
- the snow turns into horizontal streaks, about as dense as on the bridge;
- Ivo neither braces nor slides, because 33 px/s is under both the 60 px/s brace and the 90 px/s ground deadzone;
- a jump drifts ~40 px.

The bridge next door, at 66 px/s, makes him brace. So the fields read as "a blizzard that does not touch him": the
streaks say wind, and Ivo does not answer them. That fits the stopped-time fields; whether it reads as intended or as
odd needs a human playtest. `fields_gust_calm_vs_peak_no_brace.png`, `bridge_gust_calm_vs_peak_brace.png`.

**Room by room** (judged against the board's tables)

- **threshold_fields:**
  - The scarecrow (winter rags, crow on its arm) and the frost-grey uncut wheat read as a frozen harvest. In the pulse
    the scarecrow's rags turn brown and the wheat pale gold-white.
  - The cart and sheaves sit by the dip; the dip is bare. Fences west of the knoll and east of the house.
  - The second crow on the east fence's last post is a dark wedge on a pale post and reads well enough.
  - `fields_scarecrow_grey.png`, `fields_scarecrow_pulse.png`.
- **threshold_farmhouse:** STORY-02's meal is kept. The pot on the hearth, the coat and hat by the door, the churn and
  the shelf all read. The onions and herbs on the beam are low-contrast against the plaster, hard to read at 1x.
- **threshold_bridge:**
  - The parapet stubs at both deck ends and the fallen masonry on the ravine floor read.
  - The milestone stands on the west road. The look-ahead hides it whenever Ivo faces east from the bridge, so it is
    seen only walking west or entering.
  - The snowy rock and dead shrub are clear of the boar.
- **threshold_icefall_foot:** frost-moss patches on the shaft walls, not the board's icicles. They read as frost on
  rock (low; a wording deviation).
- **threshold_ravine_cave:** the roots hang from the earth ceilings, and the sack is beside the cache, not on it. The
  earth rubble on the mound is pale and snowy and reads as a snow heap more than earth.
- **threshold_wayshrine:** the shrine reads at 1x (pitched roof, figure). The bench and its prompt are clear.
  `wayshrine_bench_clear.png`.
- **frost_shore:**
  - The figurehead is a whole stone gull sitting on top of the rock spur. It reads as a statue, not as the "half-buried
    bow carving" the concept review asked for. That is a judgement for the user.
  - The anchor is pale and thin over the dark crab at col 26, and is not confused with it.
  - Rope coil, barrel and kelp rock at the west end; the torn sail by the breaker.
  - `bridge_milestone_and_shore_figurehead.png`.
- **frost_wreck_hold:**
  - The hammock is a bright white crescent hooked under the upper planks.
  - The cargo net is a pale white grid on a post beside the barrels. It is the most contrasting thing in the hold and
    reads more like a gate or a fence panel than a net.
  - The letter's slot and the plank lines are clear. `wreck_hold_cargo_net_and_hammock.png`.
- **frost_cliffs:** very sparse, as the board intended. Snow heaps sit in the step corners, gull nests are small pale
  vees, and the cairn stands at the top. The bench cave holds a blanket, a crate and the storm lantern on the west
  wall, and the bench is clear.
- **lighthouse_base:**
  - The fog bell's post, the oil cans and the coal bin by the door (off the door), and the flagpole west of the front.
  - The railing stands at the lookout's east end, and the lookout slot is clear.
  - In the pulse the red pennant is crisp. `frost_pennant_and_sail_grey_vs_pulse.png`.
- **woods_edge:**
  - The trunk base behind the hut rises out of the top edge and gives woods_crown its tree.
  - The chopping block, log stack and saw horse stand by the hut. The thrush's perch, the bench and the birdhouse are
    clear, with the blossom tree east of the bench. `woods_edge_bench_and_blossom_tree.png`.
- **woods_hut:** hearth and kettle, bed with furs, table, axe rack, snowshoes, coat and jar shelf are all legible. The
  songbook slot on the loft is clear.
- **woods_deep:**
  - Fungus on the west wall face, and ferns, mushrooms, a stump and a fallen log on the mound.
  - The moss floats (above). No trunk bases, as `systems/props` records.
- **woods_canopy:** the blossom tree and the bush; the nest by the cache. The heap is covered above.
- **woods_root_caves:** the roots hang only from earth (none on the stone columns), and the mushrooms and ferns are
  small. The room still reads mostly bare.
- **woods_pond:** cracked mud and stranded lily pads in the dry basin, and dead reeds on the rim. No log or plank
  competes with the puzzle log.
- **bloom_hollow:** the floor line is bare. The east wall's vines read. The west vines' leaves vanish against the green
  backdrop, so only three pink flowers show. Their top 24 px is above the camera's clamp, and the HUD's note icons sit
  over them.
- **woods_hollow_tree:** the knots read as wood under each knot ledge's wall end. The fungus is covered above.
- **woods_crown:**
  - The trunk's top is hidden in the leaf clusters, and the branch's blossom clusters touch its underside.
  - Where `TrunkSection2` meets `TrunkSection` (room y ~442) a horizontal seam crosses the trunk: the moss on its west
    side jumps, and a dark line shows. `crown_trunk_section_seam.png`.

**Grey as stopped time.** At 0.05 (frost edge) and 0.15 (the fields) the props are near-white silhouettes on a grey
sky. They keep their shapes and sit still, and a pulse floods them with colour and motion at once. That is the clearest
"stopped time" read of any region so far. At the woods' 0.4 the colours are muted, not grey, and the slow sway fits a
half-remembered spring.

## What this cannot judge

Stills and logs cannot show how the slow woods sway feels in motion, or whether the windless streaking snow over the
fields reads as eerie or as a mistake. They also cannot show whether a player notices the heap before the drop. These
need a human playtest. No sound was checked.

## Ratings rationale

Readability 4: nothing covers a gameplay cell, and the guardians, teachers, slots and benches read through every
dressed view. Points come off for the fungus that looks like ledges and the low heap. Aesthetics 3:
- for: the grey fields and the frost edge are strong;
- against: the floating moss, the trunk seam, the statue-like figurehead, the gate-like cargo net and the sparse root
  caves.

Fun and fluidity are not rated: this session judged stills and logged numbers, not play.
