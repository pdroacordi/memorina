---
id: bugs/a-second-fall-during-the-respawn-clear-sinks-forever
type: bug
title: Walking back into the water while the respawn fade is still clearing leaves Ivo sinking for ever, with no control and no respawn
status: fixed
severity: high
tags: [water, hazard, respawn, fade, async, softlock, game]
related: [bugs/roll-iframes-hide-the-water-so-the-pool-floor-becomes-safe-ground, bugs/presses-made-while-sinking-fire-on-respawn, gotchas/a-killed-tween-never-emits-finished]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/game.gd
  - scenes/characters/ivo/player.gd
  - scenes/world/fade.gd
---

## Summary

`Game._on_player_fell_into_hazard` ignores a fall while `_respawning` is true, and
`_respawning` stays true until `to_clear()` has finished. That is about 0.53 s after
`Player.respawn()` has handed control back. If Ivo is taken by water again in that
window, `Player` has already set `_sinking` and emitted `fell_into_hazard`, but nobody
answers it. He sinks to the floor of the pool and stays there with no input, for good.

## Symptom

Found in review of 84ada2e. Reasoned from the code, not captured in the engine.

1. Run right, off the bank, into the Downtown pool. Keep holding right, as anyone does.
2. `SafeGroundTracker` last recorded Ivo as soon as both foot probes (±10 px) were on the
   bank, so `respawn()` puts him about 10 px from the lip, facing the water.
3. On the first physics frame after `respawn()` he accelerates right, drops about 18 px
   (surface_inset 8 + hazard_depth 4 + the hurtbox's 6 px above the feet), and is back
   in the Hazard within roughly 0.3 s. The screen is still clearing.
4. `Player._on_hazard_touched` (player.gd:838) takes a second HP, sets `_sinking` and
   emits. `Game` returns at game.gd:66-67. Nothing ever calls `respawn()`.

A jump pressed during the sink fires on the first frame after respawn
(bugs/presses-made-while-sinking-fire-on-respawn), which makes this more likely.

## Root cause

- game.gd:65-78: the guard assumes that while a beat is running, any new fall is the
  same fall. After `respawn()` it is not.
- player.gd:838-851: `Player` commits to sinking before it knows whether the signal will
  be answered. The request (`_sinking`) and the answer (`_respawning`) are two independent
  flags, and nothing keeps them in step.

## Fix

Not fixed. Two parts are needed:

- Let a fall after `respawn()` start a new beat. For example, clear `_respawning` (or a
  "fall answered" flag) at the moment `respawn()` is called, not after `to_clear()`.
  Alternatively, keep Ivo's control locked until the clear has finished.
- If a new beat can overlap the old one, watch the trap in `Fade`: a new `to_black()`
  kills the running `to_clear()` tween, and a killed tween never emits `finished`
  (gotchas/a-killed-tween-never-emits-finished). The old coroutine would then hang at
  game.gd:77 and never reset `_respawning`. Either `Fade` hands out an awaitable that
  always resolves, or `Game` tags each beat with a generation counter so a stale
  coroutine can exit.

## Prevention

A guard that drops a signal while busy must be checked against the emitter: if the
emitter has already changed its own state, dropping the signal strands that state. An
assert in `Game` would catch this case:
`assert(not _player.is_sinking() or _respawning)` in `_physics_process`.

## Resolution (2026-09-23)

Each fall is its own beat: `Game._hazard_beat` counts falls, and an older beat that wakes to find a newer one stops. `Fade.to_black()`/`to_clear()` now return `Fade.faded`, emitted by every fade that lands, so an awaiter whose tween was killed resumes when the replacing fade does (gotchas/a-killed-tween-never-emits-finished). Verified in-engine (`water_hazard_refall.json`): three falls in a row while the screen cleared - two respawns, the third killed him at 0 HP; never stuck.
