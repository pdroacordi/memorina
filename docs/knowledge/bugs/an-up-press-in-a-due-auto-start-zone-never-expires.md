---
id: bugs/an-up-press-in-a-due-auto-start-zone-never-expires
type: bug
title: An Up press made where a Talkable's auto start is due but refused is neither spent nor ticked, so it outlives UP_BUFFER
status: fixed
severity: low
tags: [dialogue, input, buffer, door, player, story-08]
related: [systems/dialogue, architecture/doors-and-interiors, bugs/presses-made-while-sinking-fire-on-respawn]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/characters/ivo/player.gd
---

## Summary

FIXED 2026-10-15 (STORY-08 review, before commit). `Player._try_talk` ticks `_up_buffer` only when it finds no Talkable. If an auto start is due (`TalkComponent.auto_ready()` is not null) but the gates refuse it, the function returns without spending or ticking the buffer. A press meant to wait 0.1 s then waits for as long as the refusal lasts.

## Symptom

Ivo is in the reach of an `auto_start` Talkable whose delay has passed. He presses Up while the gates refuse the talk: airborne, rolling, attacking, in knockback, or with a recall armed. `_up_buffer` stays at `UP_BUFFER` frame after frame. If a door comes into his reach before the gates open, and he is still inside the Talkable's zone, `_try_door` runs first with that old press and takes or knocks the door. The press can be seconds old by then, against the documented "a press made just short of the door waits UP_BUFFER". If the gates open first, the auto start fires and `_drop_buffers()` clears the press, which hides the bug in the common case.

## Root cause

`scenes/characters/ivo/player.gd:596-613`. `by_press` is false whenever `auto_ready()` returns a Talkable. The tick `_up_buffer = maxf(_up_buffer - delta, 0.0)` runs only in the `talkable == null` branch. The refusal `if _talking or _input.blocked or not _free_for_up(on_floor): return false` returns before any buffer handling. The tick lived in `_try_door` (door null) before STORY-08 moved it here.

## Fix

Fixed 2026-10-15. `Player._process_motion` ticks `_up_buffer` every frame right after `_try_door` / `_try_talk` / `_try_board`, whichever ran; `_try_door` and `_try_talk` only spend it. Test: `player_talk_test.test_an_up_press_expires_while_a_due_auto_start_is_refused` (auto start due, Ivo blocked, Up pressed, the buffer is 0 after `UP_BUFFER`).

## Prevention

A `player_talk_test` case: auto start due, Ivo held airborne or `_recall` armed, Up pressed, then wait more than `UP_BUFFER` and assert `_up_buffer` reached 0 (or that a door brought into reach afterwards is not taken).
