---
id: bugs/a-down-press-made-while-sinking-sits-ivo-on-respawn
type: bug
title: A down press made while Ivo sinks is held as _sit_requested and sits him on the first frame after respawn
status: fixed
severity: low
tags: [bench, sit, water, hazard, respawn, input-buffer, player]
related: [bugs/presses-made-while-sinking-fire-on-respawn, bugs/sitting-is-not-gated-on-a-guardian-fight]
created: 2026-10-01
updated: 2026-10-01
source_files:
  - scenes/characters/ivo/player.gd
---

## Summary

This is the same class of bug as `bugs/presses-made-while-sinking-fire-on-respawn`,
reintroduced for the sit press. `look_down_pressed` sets the bool `_sit_requested`
(player.gd:235). Only `_try_sit` clears it, and the sink branch returns before `_try_sit`
runs (player.gd:292-295). Unlike the jump, roll, attack and draw buffers, this request
has no timer that ticks while sinking, so a down press made under water survives the
whole sink.

## Symptom

Reasoned from the code. Latent on today's maps, because no bench is within reach of a
hazard: downtown's bench is at column 8 and its pool at 44, the lighthouse has no water,
and the summer trial has no water.

When a bench does sit next to water, the sequence is:

1. Ivo falls in beside the bench.
2. The player presses down while he sinks.
3. `respawn()` puts him back on the bank, which is within the seat's reach.
4. On the first physics frame he sits by himself, and `sat_down` rests and saves.

The player never chose that rest. It also commits the save.

## Root cause

`_sit_requested` is a one-shot flag that is never expired. It is cleared only when
`_try_sit` runs, and `_try_sit` is skipped while sinking. A request flag that outlives the
frame it was made in is a buffer without a timer.

## Fix

Fixed 2026-10-01 with the first option: the sink branch of `_process_motion` clears
`_sit_requested`, and so does `respawn()`. A buffered timer would also expire it, but a
sit is a deliberate gesture made standing at a bench; the flag only has to survive until
the next physics frame, and nothing but sinking skips that frame.

## Prevention

Every new discrete-input request on `Player` either goes through a buffer that
`_tick_input_timers` ticks, or is cleared wherever `_process_motion` returns early
(sinking, dead).
