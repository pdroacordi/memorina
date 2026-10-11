---
id: bugs/a-teleport-while-riding-is-undone-by-the-helix-rider
type: bug
title: Character.teleport while Ivo rides a helix stair leaves the rider holding him; the next step drives him back toward the stair
status: resolved
severity: low
tags: [helix, stair, teleport, debug, player]
related: [systems/helix-stair, systems/life-benches-death, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/world/debug/debug_trials.gd
  - scenes/characters/components/helix_rider_component.gd
---

## Summary

The rider is released in `arrive_at`, `sit`, `respawn` and on death (player.gd:947, 1090, 1113,
1151), but not in `teleport`, the single entry point for "every move that is not motion"
(character.gd:66-68). `DebugTrials` (F10, debug_trials.gd:37) teleports without going through
any of those four.

## Symptom

Found in review of WORLD-26 (2026-10-11). Reasoned from the code. Debug builds only today.

F10 on the bell tower stair places Ivo at the next trial, but `_rider.is_riding()` is still true.
The next step sets `velocity = (stair.feet_global(u) - position) / delta`, a jump of thousands of
px in one `move_and_slide`. He stops at the first collision on the way, far from both places,
and the rider pulls him again every step.

## Fix

Override `teleport(point)` in `Player` to call `_rider.release()` (and `_climb.release()`) before
`super(point)`. The four separate release calls then become redundant and can go.

## Prevention

A mode that writes velocity toward a target every step must end in the shared teleport path.

## Resolution

Fixed 2026-10-11 (WORLD-26). `Player.teleport` releases the climb and the rider before `super(point)`; the separate releases in `arrive_at`, `sit` and `respawn` are gone (`SitComponent.sit` calls `teleport`). Test: `player_helix_test.test_a_teleport_ends_the_ride`.
