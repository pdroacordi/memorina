---
id: bugs/presses-made-while-sinking-fire-on-respawn
type: bug
title: A jump, roll, attack or draw pressed while Ivo sinks is held for the whole sink and fires on the first frame after respawn
status: fixed
severity: medium
tags: [water, hazard, respawn, input-buffer, player, landing]
related: [bugs/a-second-fall-during-the-respawn-clear-sinks-forever, bugs/roll-iframes-hide-the-water-so-the-pool-floor-becomes-safe-ground]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/components/jump_component.gd
  - scenes/characters/components/landing_component.gd
---

## Summary

The sink branch at player.gd:249-251 returns before any `tick_timers` runs. `PlayerInput`'s
signals still reach the buffers (`_jump.buffer_jump`, `_roll.buffer_roll`,
`_attack.buffer_attack`, `_memorina.buffer_toggle`), so a press made during the sink goes
into a buffer that never ages. `respawn()` (player.gd:855) clears none of these buffers,
and on the first frame back on the bank the buffered press is performed. Players mash
jump when they fall into water.

## Symptom

Found in review of 84ada2e. Reasoned from the code.

- Jump pressed while sinking: Ivo jumps the moment he is placed on the bank, facing the
  water, while the screen is still black. With a direction held, this is the quickest
  way back into the pool (bugs/a-second-fall-during-the-respawn-clear-sinks-forever).
- Roll pressed while sinking (with ROLL unlocked): on respawn he rolls toward the water,
  hidden from it for 0.58 s
  (bugs/roll-iframes-hide-the-water-so-the-pool-floor-becomes-safe-ground).
- Draw pressed while sinking: the Memorina comes out on respawn.
- Same root cause, different state: `_landing.sample_fall_speed` is not called while
  sinking, so `_last_fall_speed` keeps the speed he hit the water at. `check_landing`
  still runs in `_after_move`. If that speed was 800 px/s or more, the next touchdown
  counts as a hard landing, with `hard_landed` dust and a 0.75 s lockout. The touchdown
  is the pool floor, or the bank after `respawn()` if he never reached the bottom.
  `respawn()`'s `cancel_recovery()` runs before that landing, so it does not prevent it.

## Root cause

The sink branch skips the per-frame ticks, and `respawn()` resets only velocity,
knockback and recovery. Any state that only those ticks age survives the sink unchanged.

## Fix

Not fixed. `respawn()`, or a `clear_buffers()` on each component, should drop the buffers
and reset the landing sample (`_was_on_floor = true`, `_last_fall_speed = 0`). A better
fix: `_sink_motion` keeps the timers ticking and only refuses to act on them.

## Prevention

When a motion branch returns early from `_process_motion`, list every timer the normal
path ages and decide, for each one, whether it keeps ticking. A `SinkComponent` that owns
"what sinking suspends" would make that list explicit.

## Resolution (2026-09-23)

`Player._tick_input_timers()` runs every frame, sinking or not, so a press made under water expires there; `_sink_motion` samples the fall speed, so the plunge is never remembered as a hard landing. `Game` also holds the sink `hazard_sink_hold` (0.25 s) before fading, per the playtest.
