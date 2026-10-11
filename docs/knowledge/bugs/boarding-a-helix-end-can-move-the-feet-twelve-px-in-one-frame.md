---
id: bugs/boarding-a-helix-end-can-move-the-feet-twelve-px-in-one-frame
type: bug
title: Boarding a helix end snaps the feet up to 12 px in one frame, not the 6 px the end zone's comment promises
status: resolved
severity: low
tags: [helix, stair, boarding, velocity, sensor]
related: [systems/helix-stair, playtests/2026-10-11-bell-tower-helix]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/world/interactables/helix_stair/helix_stair.gd
  - scenes/characters/components/helix_rider_component.gd
---

## Summary

The comment on `HelixStair.END_SIZE` (helix_stair.gd:11-12) says the 12 px zone moves the feet
"at most half its width". But the zone is found by Ivo's `ClimbSensor`, which is also 12 px wide,
so the two overlap while the feet are up to 12 px from the end. The first ride step sets
`velocity = (feet(0) - position) / delta` (helix_rider_component.gd:91), which covers the whole
gap in one frame.

## Symptom

Found in review of WORLD-26 (2026-10-11). Reasoned from the geometry. The playtest measured at
most 6 px, but only for walking in from the door. If Ivo stops 11 px left of the foot (the player
releases short and he slides into the sensor overlap) and Up is pressed, his sprite jumps 11 px
right in one frame (about 660 px/s). Down at the head, pressed from the landing, does the same
leftward.

## Fix

Either size the boarding test so the allowed snap is what the comment says (for example, require
`absf(body.x - end.x) <= 3` in `end_pressed_into`), or start `u` at the path point nearest the
feet and ease the remaining gap over a few frames.

## Prevention

An overlap between two areas is bounded by the sum of both half-widths, not by one of them.

## Resolution

Fixed 2026-10-11 (WORLD-26). `HelixRiderComponent.board_reach` (6 px): `end_pressed_into` skips an end whose x is farther from the feet, so the first ride step moves them 6 px at most; `HelixStair.END_SIZE`'s comment says why. Test: `helix_rider_component_test.test_an_end_beyond_board_reach_boards_nothing`.
