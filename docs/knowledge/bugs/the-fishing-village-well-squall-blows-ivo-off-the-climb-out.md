---
id: bugs/the-fishing-village-well-squall-blows-ivo-off-the-climb-out
type: bug
title: In lake_well, the squall (now 352 px tall) blows Ivo off the 3-cell catch ledge and out of every jump from the niche - a base-kit player who falls into the fishing village well cannot climb out
status: resolved
severity: high
tags: [world-05, frozen-lake, well, squall, wind, softlock, base-kit]
related: [playtests/2026-10-10-traversal-orchards-caldera, bugs/the-fishing-village-well-has-no-way-out, playtests/2026-10-09-traversal-woods-lake, systems/air, systems/world, architecture/water-two-projections]
created: 2026-10-10
updated: 2026-10-13
source_files:
  - scenes/world/rooms/frozen_lake/contents/lake_well.room
  - scenes/world/rooms/frozen_lake/contents/lake_fishing_village.room
---

## Summary

The new climb out of the fishing village well is three 96 px steps:
1. niche floor (row 6, -1344) → catch one-way (row 3, cols 9-11: x 1568..1664, y -1440);
2. catch → notch (the well's row 0 at cols 6-7, -1536);
3. notch → village floor (-1632).

The well's squall (`well_squall`, 420 px/s westward, gusty; its height grew from 320 to 352 px, so it covers
y -1600..-1248) covers all of it.
- **The catch is only 96 px wide.** Standing on it, Ivo is blown off west within ~0.5 s. A jump from the niche
  is carried west of it before he lands.
- **Walking in from the notch misses the catch.** He drops past its west end onto the row-5 chamber floor
  (-1376), and the squall pins him against the west wall.

The only way out without Redoma is to die in the water column at cols 16-18 and respawn at the last bench.

## Symptom

Working tree on 5062946, `--import` 01:27:51. Kit: roll only (base kit).
- **Falling in** (`traverse_orchards_caldera_rv_k3_fishing_well_fall_and_climb_out.json`): walking east off the
  village floor from x 1430, Ivo lands on the chamber floor and drifts to (1349, -1376).
- **Back to the niche** (`..._rv_k5_fishing_well_walk_east_then_climb.json`): walking east without jumping works
  in lulls. He is in the niche (1612.8, -1359 → 1654, -1344) by t 3.7-4.0.
- **Up from the niche:** 0 landings on the catch in about 45 jumps across four input patterns. Every jump ends
  on the chamber floor at x 1340-1500.
  - `..._rv_k6_*`, `..._rv_k7_*` (right held, 20 jumps every 1.6 s);
  - `..._rv_k8_*` (varied timing; one run drifted east, fell in the water and died, then respawned at the new
    game start);
  - `..._rv_k10_*` (12 straight jumps with returns, random spacing).
- **Placed on the catch** (`..._rv_k11_fishing_well_catch_to_notch_to_floor.json`) at (1600, -1440): blown
  onto the chamber floor at (1382, -1376) by t 1.5, before the first jump.
- Frames: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/rv_fishing_well_squall_blows_ivo_off_the_catch.png`.

## Impact

High. This re-opens `bugs/the-fishing-village-well-has-no-way-out`. The Lake is open to the base kit (Memorina
only), the mouth (192 px) is easy to fall into, and the climb out is in the squall's reach. Escaping by dying
costs three hits in the water column, and it only returns the player to a bench outside the well if they rested
at one.

These are inferences from inputs: a human with perfect lull timing might manage it, and I did not find a lull
long enough in ~45 tries.

## Fix

Options:
- Keep the climb-out out of the squall: shrink the squall box back so its top is below the catch (y > -1408), or
  move the catch and notch out of its x range.
- Or widen the catch (6+ cells) and give the niche and catch a wind shelter (a lip on the catch's west end).
- Or put the catch where a fall from the mouth lands on it (under x 1536..1568 too).

## Prevention

Run the base-kit climb-out with the room's wind active, from both landing spots (catch and chamber floor).

## Resolution (2026-10-10, re-verified)

The squall is back to [416, 192] (box y -1440..-1248), and the catch is a full one-way floor (row 3, cols 1-12:
x 1312..1696, y -1440). Working tree on 5062946 with the coordinator's second round of fixes, `--import` at 02:37:17; nothing changed after it.
- **Climb out with the base kit**
  (`traverse_orchards_caldera_rv2_k1_fishing_well_fall_catch_notch_floor.json`).
  - Ivo walks east off the notch and lands on the catch (1563.9, -1440).
  - One jump up through the mouth (col 8) with a left steer: the notch (1526.6, -1536).
  - One jump left: the village floor (1436.1, -1632).
  - No `brace` sample and no drift on the catch. The rooms switch lake_well → lake_fishing_village at t 4.06.
  - Frames: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/rv2_fishing_well_catch_to_floor.png`.
- **The Redoma puzzle still works** (`..._rv2_k2_fishing_well_redoma_then_soltar_reeds_1650.json`).
  - Redoma on S13-15 by the pool; drop down the held-out pool column to the chamber floor (1877.9, -1248),
    hp 3.
  - Inside the shell, in the squall at x ~1650, Soltar completes and the reeds drop. Ivo walks into the alcove
    (x 1324).
  - Control (`..._1620`): 30 px further west, outside the shell, the Soltar performance is broken by the
    squall, and the reeds stop him at x 1388.
- Known and accepted (coordinator): Soltar on the reeds can also be played from the catch.

## Superseded (2026-10-13, WORLD-29)

The well mouth, the notch and the curbs are gone: lake_well's row 0 is closed and the fishing village reaches it by the
stairwell on its shore landing (col 3), a door pair with the hatch over the catch (col 9). No fall leads into the well.
From the bank, the step and one jump west still put Ivo on the catch with the base kit (`systems/world`, Known limits).
The timelines named above start from a layout that no longer exists.
