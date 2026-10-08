---
id: bugs/a-lowered-drawbridge-is-a-10-px-curb-on-its-own-bank
type: bug
title: A lowered drawbridge lies on top of the floor it is hinged on, so its 10 px plank is a curb Ivo cannot walk onto
status: fixed
severity: medium
tags: [drawbridge, release, soltar, collision, trials, pzl-07]
related: [playtests/2026-10-07-redoma-then-soltar-in-the-squall, systems/weight-presence-release]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - scenes/world/interactables/drawbridge/drawbridge.gd
  - scenes/world/rooms/trials_winter/contents/winter_trial.room
---

## Summary

The `D` entity hinges at its cell's bottom centre, which is the floor surface. When lowered,
the plank's 10 px box sits on top of the bank. Ivo walking at it stops against the plank's
end, and he has to jump to get on the bridge. The same curb is on the far bank.

## Symptom

Winter trial puzzle 2 (PZL-07), both before and after the SquallMemory change, in every
solution run (`tools/playtest/scripts/song_bell_jar_release_squall.json`):

- After Soltar lowers the bridge, Ivo walks right with right held and stops at x 1638.0,
  `vel (0, 0)`, `state=brace`. In the old-build run with no jump he stayed there 3.6 s
  (t 15.8-19.4). He never got onto the plank.
- A jump clears it. On the plank Ivo stands at y 5989.9, against 6000.0 on the bank.
- Walking left from the far bank, he stops at x 2012 against the plank's other end.
- Screenshots: `playtests/screenshots/2026-10-07-redoma-then-soltar-in-the-squall/curb_at_the_hinge_3x.png`
  and `solution_braced_at_the_curb.png`.

## Root cause

`drawbridge.gd` `_ready`: the plank box is `Vector2(length, 10)` at
`Vector2(length * 0.5 * side, -5)`, so it spans y -10..0 relative to the hinge. The legend
anchors `D` at its cell's bottom centre (`room_legend.tres`, `docs/maps/README.md` "D -
Drawbridge"), which is the floor's top. Lowered, the plank lies 10 px proud of the bank
from the hinge (x 1648) to the bank's edge (1664), and again over the first 16 px of the far
bank (1984-2000). `CharacterBody2D` has no step-up, so a 10 px lip is a wall to walking.
This is the first room to place a `D`, so no earlier playtest met it.

## Fix

Fixed 2026-10-07: the plank's collider, rider sensor and sprite sit below the hinge (`drawbridge.gd`), so the lowered plank's top is flush with its bank. Verified with `song_bell_jar_release_squall.json`: Ivo walks past the hinge (x 1648) on the floor.

Options that were considered:

- Hang the plank below the hinge (box at y 0..10), so its top is flush with the floor. It
  then overlaps the two banks' tiles by 16 px each, which an `AnimatableBody2D` tolerates.
- Or anchor the hinge 10 px lower in the legend.

Either way, the raised plank must still stand on the bank as a wall.

## Prevention

A walkable song platform needs its top flush with the floor it joins. A trial test can
assert that the lowered plank's top equals the floor row's top, the way
`winter_trial_test` already checks the span (`test_the_bridge_spans_the_chasm`).
