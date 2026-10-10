---
id: bugs/the-village-cistern-shaft-is-sealed-by-its-new-ledges
type: bug
title: village_cistern's new shaft ledges at row 13 (cols 7-9) and row 15 (cols 10-13) meet corner to corner with 32 px between them - the shaft is closed both ways, so the Redoma route into the Caldera no longer exists
status: resolved
severity: high
tags: [world-05, summer-caldera, home-village, cistern, softlock, progression, redoma, level-design]
related: [playtests/2026-10-10-traversal-orchards-caldera, bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera, bugs/leaving-a-redoma-shell-downward-catches-ivo-on-its-ring]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/home_village/contents/village_cistern.room
---

## Summary

The fix for `bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera` added ledges to the dry shaft. Two of
them leave no passage between them:
- **V13** (row 13, cols 7-9: x 864..960, y 800..832) is the pocket floor under the slab;
- **V15** (row 15, cols 10-13: x 960..1088, y 864..896) is under the mouth.

They share the corner x 960 with only 32 px of air between V13's underside and V15's top. Ivo is 54 px tall. Cols
7-9 are covered by V13, and cols 10-13 by V15 plus the pillar, so neither a fall nor a climb gets through.

## Symptom

Working tree on 5062946, `--import` 01:27:51.
- **Down** (`traverse_orchards_caldera_c1_village_cistern_redoma_drop_to_caldera.json`,
  `..._rv_c2_village_cistern_redoma_descent_ledge_to_ledge.json`):
  - Redoma on the slab, then the shelf, then west into the mouth. Ivo lands on V15 at (972.1, 864) at t 8.31.
  - Holding left, he stays at x 972.1 with `state=run` and velocity 0: V13's east face blocks his upper body.
  - Holding right, he stops at x 1014 against the pillar.
  - He can only jump back up to V13 or the shelf. Nothing below V15 is reachable.
  - Frame: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/rv_cistern_shaft_sealed_by_ledges_13_and_15.png`.
- **Up** (`..._rv_c1_caldera_dais_climb_to_village_cistern.json`, closed loop, 11 passes):
  - Dais → C14 → C10 → C6 → C2 → V22 → V18 works with normal presses.
  - From V18's east end, every jump stops at feet 886.9, capped by V13. Against V15's face, he falls back to V18.

## Impact

High. The Caldera is reachable only through the chimney (wall climb), and Redoma no longer opens it. Design 04
§2: "A Caldeira exige o Lago (Redoma) ou o Pomar (escalada)". A player who walks into the mouth with Redoma
stands on V15 in a pocket. They can still climb back out (V13 or shelf → slab, while the shell holds the water),
so it is not a softlock.

## Fix

Re-space the pair so that their corner has at least ~64 px of clearance and both columns stay open. Two options:
- **V15 one row lower** (row 16, top 896). Then the corner clearance is 832 → 896 = 64 px. The climb becomes
  V18 (960) → V15 (896), 64 up, then V15 → V13 (800), 96 up. The fall drops from V13's east edge past V15.
- **V13 only at cols 7-8.** That leaves a 32 px column at col 9, with V15 at col 10: tight for a 22 px body.

Then re-run the climb (`rv_c1`) and the descent (`rv_c2`).

## Prevention

A `room_files_test` rule: two ledges diagonal to each other must leave at least 64 px (two rows) between the
upper one's underside and the lower one's top, or be ≥ 2 columns apart.

## Re-verification 2 (2026-10-10, ~02:40): still open, the pinch moved down one pair

The row-15 ledge moved to row 16 (cols 10-11 plus the pillar: x 960..1088, y 896..928). V13/V16 now have 64 px.
But V16 and **V18** (row 18, cols 7-9: x 864..960, y 960..992) now meet corner to corner at x 960, with 32 px
between V16's underside (928) and V18's top (960). Working tree on 5062946 with the coordinator's second round of fixes, `--import` at 02:37:17; nothing changed after it.
- **Descent** (`traverse_orchards_caldera_rv2_c2_village_cistern_redoma_descent.json`):
  - Redoma, the shelf, the mouth, then V16 (972, 896), then a drop west onto V18 (908, 960).
  - Walking east from V18 stops at x 950 against V16's face, so V22 and everything below cannot be reached.
  - Frame: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/rv2_cistern_pinch_moved_to_ledges_16_and_18.png`.
- **Climb** (`..._rv2_c1_caldera_dais_climb_to_village_cistern_slab.json`, closed loop, 14 passes):
  - Dais → C14 → C10 → C6 → C2 → V22 works.
  - V22 → V18 fails every time. Rising at x ≥ 971 the head meets V16 (feet 982 at best, while V18's top is 960).
    Steering west earlier puts the head under V18's corner (feet 1043.6, then a fall to C2).
- **Not a softlock:** from V18, a jump with right held climbs back onto V16 (994, 896). The head meets V13 at
  feet 886, which leaves a 10 px window above V16's top (`..._rv2_c3_cistern_v18_back_up_to_v16.json`).
- **Shell exit:** the drop V16 → V18 leaves the Redoma disc downward (V18 is ~305 px from the centre) with no
  hang.

**Fix:** shift V18 down one row as well (row 19, top 992 → 64 px under V16), or move V16 one column east. Then
check V18 → V22 (the next corner, 96 px) and the climb V22 → V18 (it then needs 96 px).

## Resolution (2026-10-10, re-verification 3)

The shaft was re-laid with ledges three rows apart, so every corner has 64 px:
- V22 (row 22, cols 10-11);
- V19 (row 19, cols 8-9, now a one-way `=`);
- V16 (row 16, cols 10-11);
- V13 (row 13, cols 7-9).

Working tree on 5062946 with the cistern shaft re-laid, `--import` at 03:11:29; nothing changed after it.
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

Precision note: the corners leave about 10 px. V19 → V16 and V16 → V13 work by pressing into the next ledge's
face while rising and sliding over the top, which a held direction does by itself.
