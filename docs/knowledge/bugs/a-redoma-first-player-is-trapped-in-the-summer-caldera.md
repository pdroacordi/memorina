---
id: bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera
type: bug
title: The Caldera's two exits both need wall climb, so a player who drops in through the village cistern with Redoma (the order design 04 allows) can never leave
status: resolved
severity: high
tags: [world-05, summer-caldera, softlock, progression, cistern, chimney, wall-climb, redoma, sequence]
related: [playtests/2026-10-10-traversal-orchards-caldera, bugs/the-orchard-arena-barrier-is-jumped-over-into-the-cliff-chimney, bugs/leaving-a-redoma-shell-downward-catches-ivo-on-its-ring, systems/world]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/home_village/contents/village_cistern.room
  - scenes/world/rooms/summer_caldera/contents/caldera_cistern_bottom.room
  - scenes/world/rooms/wind_orchards/contents/orchard_cliff_chimney.room
---

## Summary

Design 04 section 2: "A Caldeira exige o Lago (Redoma) ou o Pomar (escalada)". The Redoma route (village
cistern → dry shaft → `caldera_cistern_bottom`) is a one-way drop, as `systems/world` notes. The Caldera's
other exit is the cliff chimney's bottom pocket, and from the Caldera side the pocket's west wall is 288 px
high. That is out of the double jump's reach (270). No other room of the region has an exit. A player with
Redoma and without wall climb (Lake before Orchards) is confined to the nine Caldera rooms. Wall climb is the
autumn guardian's gift in the Orchards, which they can no longer reach. Once they rest at the crater bench
(the region's only bench), death returns them inside too.

## Symptom

HEAD 5062946, imported 00:23:06. Kit: double jump, roll, FREEZE, BELL_JAR, ROOT, RAIN (`skills [0, 2]`).

- **The way in works** (`tools/playtest/scripts/traverse_orchards_caldera_c1_village_cistern_redoma_drop_to_caldera.json`).
  Ivo plays Redoma on the slab, walks to the shelf and into the mouth, and drops to the dais at (945.7, 1728).
  The region cut happens at feet 1300.
- **The shaft back up** (`..._c3a_cistern_bottom_west_to_crater_bench.json`): a double jump from the dais peaks
  at feet 1487.6. The shaft starts at 1408 and the village cistern lies 600 px above that.
- **Through the Caldera to the chimney pocket**:
  - `..._c3a` (crater bench, sit), `..._c3b0`, `..._c3b`, `..._c3c`, `..._c3d` (the bait brute is fought and
    killed, 1 hp lost) and `..._c3e`.
  - In `..._c3e` the region cut into orchard_cliff_chimney is at feet x -10268. In the pocket (floor 1824),
    two double jumps against col 10 peak at feet 1583.2 and 1590.8, and col 10's top is 1536.
  - `chimney_floor_no_wall_climb_stuck.png`, right frame.
- **The east end**: `..._c4b_temple_terrace_down_to_arena_and_back.json`. caldera_arena's east wall is closed.

## Root cause

Design and level layout. Both exits climb more than 270 px: the cistern shaft ~1000 px, the chimney pocket wall
288 px (then 3 100 px of chimney). Only the arena side (Orchards → Caldera) has a gate
(`bugs/the-orchard-arena-barrier-is-jumped-over-into-the-cliff-chimney`). The cistern side has none, and Redoma
is the only key it asks for.

## Fix

Pick one (a design call, so it needs the user):
- **A way back for the Redoma route.** Options:
  - A one-way shortcut from the Caldera up to the village. Design 02 §6.1 shortcuts fit: a lift or a rope
    opened from below.
  - Lower the chimney pocket's wall (col 10) by one row or more, so the double jump drops the player into
    the chimney. The chimney itself still needs wall climb, so this alone only moves the trap.
- **Gate the cistern on wall climb as well.** For example, a barrier at the mouth that `has_wall_climb.tres`
  opens. Then "Redoma ou escalada" becomes "Redoma e escalada" for that entrance: a change to design 04 §2.
- **Give the Caldera a third exit** that needs only the Lake's kit.

## Prevention

A progression check on the world graph: for every entrance and every kit that can use it, an exit must exist
for the same kit.

## Re-verification (2026-10-10): not resolved, the climb is blocked

Fix under test: stone ledges zigzag up `caldera_cistern_bottom` (rows 14, 10, 6, 2) and `village_cistern` (rows
22, 18, 15, 13). Working tree on 5062946 with the coordinator's fixes, `--import` at 01:27:51; nothing changed after it.

`traverse_orchards_caldera_rv_c1_caldera_dais_climb_to_village_cistern.json` uses a closed-loop take-off
correction, with 7 passes plus 4 more. Normal 0.45 s presses, apex steer, and the direction held from take-off
for the last two steps.
- **Passes:** dais (1728) → C14 (1600) → C10 (1472) → C6 (1344) → C2 (1216) → V22 (1088) → V18 (960). The
  128 px steps clear by ~15 px with an apex steer.
- **Stops at V18 → V15.** Every attempt from V18's east end rises to feet 886.9: the head is under V13's
  underside (832). The body also meets V15's west face (x 960, y 864..896) and falls back to V18.
- **Cause:** V13 (row 13, cols 7-9) and V15 (row 15, cols 10-13) are diagonal neighbours. Their shared
  corner at x 960 leaves 32 px between V13's bottom (832) and V15's top (864), and Ivo is 54 px tall.
  Directly above V18, V15 also caps the column (64 px).

The same pair seals the shaft from above: `bugs/the-village-cistern-shaft-is-sealed-by-its-new-ledges`. Until
that is fixed, nobody enters the Caldera through the cistern, so this trap cannot happen. But the way back the
fix intended does not exist yet either.

## Re-verification 2 (2026-10-10, ~02:40): still open

Working tree on 5062946 with the coordinator's second round of fixes, `--import` at 02:37:17; nothing changed after it. The climb from the dais now stops at V22 → V18, at the V16/V18 corner
(`bugs/the-village-cistern-shaft-is-sealed-by-its-new-ledges`, re-verification 2). The descent also stops on
V18, so the Redoma route into the Caldera is still closed in both directions.

## Resolution (2026-10-10, re-verification 3)

Working tree on 5062946 with the cistern shaft re-laid, `--import` at 03:11:29; nothing changed after it. The Caldera's Redoma entrance is now two-way, and a player with only the Lake's kit gets out, even after
resting at the crater bench.
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
