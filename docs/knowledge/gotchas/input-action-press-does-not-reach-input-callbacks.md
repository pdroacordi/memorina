---
id: gotchas/input-action-press-does-not-reach-input-callbacks
type: gotcha
title: Input.action_press()/action_release() only set polled state — they never fire _input()
status: active
tags: [input, simulation, testing, footgun]
related: [architecture/character-controller-input-split]
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/characters/ivo/player_input.gd
  - tools/playtest/playtest_runner.gd
---

## Summary

`Input.action_press(action)` / `Input.action_release(action)` update the internal action
strength that `Input.is_action_pressed()` and `Input.get_axis()` poll. They do **not**
dispatch an `InputEvent` through the engine's normal input pipeline, so any code that
reacts inside `_input()`/`_unhandled_input()` via `event.is_action_pressed(...)` never sees
them fire. `Input.parse_input_event()` with a constructed `InputEventAction` does both —
it updates the same polled state AND drives `_input()`.

## Details

`PlayerInput._input()` (`scenes/characters/ivo/player_input.gd:64`) is exactly this split
in practice: `jump_pressed`, `roll_pressed`, `attack_pressed`, `draw_memorina_pressed`, and
every note signal are only ever emitted from `_input()`, checked via
`event.is_action_pressed("jump")` etc. `PlayerInput._get_direction()` (line 86), by
contrast, is a poll (`Input.get_axis("move_left", "move_right")`).

Discovered building `tools/playtest/playtest_runner.gd`: the harness used
`Input.action_press()`/`action_release()` to simulate input for an automated playtest.
Movement (`_get_direction()`, polled) worked. `jump`/`roll` (discrete, from `_input()`)
silently did nothing — no error, no warning, just a character that never left the ground on
a scripted "jump" step. It looked like the game had a bug; it was the simulation.

## Why this trips people up

The two APIs look interchangeable — both are named around "actions" and both are the
obvious first thing to reach for when scripting input. Nothing in the API surface signals
that one of them skips the event dispatch entirely.

## Prevention

Any code simulating input — a playtest harness, a gdUnit4 scene-runner test, a debug
macro — that needs to trigger a discrete, `_input()`-driven action (as opposed to only
reading a continuous polled property) must use `Input.parse_input_event()` with a real
`InputEventAction`, never `Input.action_press()`/`action_release()` alone. When in doubt,
default to `parse_input_event()` for everything — it's a strict superset of what
`action_press()`/`action_release()` cover.
