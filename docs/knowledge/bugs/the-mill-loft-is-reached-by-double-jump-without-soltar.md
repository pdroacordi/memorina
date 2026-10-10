---
id: bugs/the-mill-loft-is-reached-by-double-jump-without-soltar
type: bug
title: orchard_mill_town's stone loft, "beyond every jump" behind the Soltar drawbridge, is reached by a running double jump from the yard's east edge with a late second press
status: resolved
severity: low
tags: [world-05, wind-orchards, gate, double-jump, soltar, drawbridge, sequence-break]
related: [playtests/2026-10-10-traversal-orchards-caldera, bugs/the-raised-mill-drawbridge-stands-through-the-windy-gap]
created: 2026-10-10
updated: 2026-10-10
source_files:
  - scenes/world/rooms/wind_orchards/contents/orchard_mill_town.room
---

## Summary

The room's header says the drawbridge reaches "the stone mill loft, nine rows above the yard and beyond every
jump". The loft (S46-51, top y -1472) is 224 px above the yard floor (top y -1248) and 192 px east of the yard's
east edge (x -6400). A running double jump from that edge lands on it when the second press comes 0.65-0.75 s
after the first. An early second press peaks too soon and falls short.

## Symptom

HEAD 5062946, imported 00:23:06. `tools/playtest/scripts/traverse_orchards_caldera_g1_mill_loft_double_jump_from_*.json`.
Kit: double jump and roll. Take-off at x -6402 (west) or -5830 (east). Presses: first 0.45 s, second 0.4 s.

| Side | 2nd press after | Peak feet | Result |
|---|---|---|---|
| west | 0.45 s | -1481.5 at x -6269.8 | falls into the pit at (-6147.9, -1184) |
| west | 0.55 s | -1481.9 at x -6260.2 | falls into the pit |
| west | 0.65 s | -1481.5 at x -6231.4 | **on the loft at (-6100.4, -1472.1)** |
| west | 0.75 s | -1481.9 at x -6212.2 | **on the loft at (-6100.4, -1472.1)** |
| east | 0.45 / 0.55 s | -1449.6 / -1453.6 | hits the loft's east face |

Frame: `playtests/screenshots/2026-10-10-traversal-orchards-caldera/mill_loft_reached_without_soltar.png`.

## Impact

Low. The loft leads only up through the floor mouth into orchard_counterweights' lower chamber. The lift
there still needs the right load (Soltar), and the chamber is a dead end the player can drop out of. Nothing
after the bridge is skipped. Still, the room is authored as a song gate and a jump opens it, with 9.5 px of
spare height.

## Fix

Raise the loft one row (y -1504, 256 px above the yard), or move it one or two cells east. Either way, re-check
the counterweights' mouth and the bridge's `length_cells`. Or shorten the yard so the take-off is further away.

## Prevention

Include late second presses (0.5-0.8 s) in reachability checks: the double jump's own launch height makes a
late press as high as an early one, and it peaks further out.

## Resolution (2026-10-10, re-verified)

The loft was raised to mill row 0 (top -1536, flush with the counterweights seam). Working tree on 5062946 with the coordinator's fixes, `--import` at 01:27:51; nothing changed after it.
- **No skip.** `traverse_orchards_caldera_rv_l1_loft_double_jump_no_soltar_{45,60,75}.json`: running double
  jumps toward the loft peak at feet -1322.5..-1322.8, because the inn roof (row 6, to x -6496) now caps the
  yard's east edge. All three fall into the pit.
- **New problem:** the Soltar route cannot reach the loft either.
  `bugs/the-mill-loft-is-unreachable-from-the-lowered-drawbridge`.
