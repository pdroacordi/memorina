---
id: playtests/2026-09-20-harness-shakedown
type: playtest
title: First verified run of the tools/playtest capture harness (Ivo, open-air spawn)
status: active
build: 8300ad9
area_tested: Ivo's basic movement/jump/roll on the default game.tscn spawn point (no guardian, no specific feature — this is a harness shakedown, not a feature evaluation)
tags: [harness-verification, movement, jump, roll]
related: [gotchas/input-action-press-does-not-reach-input-callbacks]
created: 2026-09-20
updated: 2026-09-20
ratings: { fun: 0, fluidity: 0, aesthetics: 0 }
screenshots:
  - screenshots/2026-09-20-harness-shakedown/00_spawn.png
  - screenshots/2026-09-20-harness-shakedown/01_after_walk.png
  - screenshots/2026-09-20-harness-shakedown/02_mid_jump.png
  - screenshots/2026-09-20-harness-shakedown/03_after_roll.png
---

## What was tested

Not a feature evaluation — this session existed to verify `tools/playtest/playtest_runner.gd`
actually works end to end, following the request to prove the new Godot skills/tooling
function rather than just exist on paper. Godot binary located at
`D:\Godot_v4.7.2-stable_win64.exe` (not on PATH; found by filesystem search). Ran
`tools/playtest/scripts/example_walk_jump_roll.json` against `scenes/world/game.tscn`
twice: once with the harness as originally written, once after fixing the input-simulation
bug it exposed (see below).

## Findings

- **Harness bug, found and fixed**: the first run showed identical character position and
  pose across all four screenshots — movement, jump, and roll all appeared to do nothing.
  Root cause: the harness used `Input.action_press()`/`action_release()`, which only sets
  the state `Input.is_action_pressed()`/`get_axis()` poll, and never dispatches an
  `InputEvent` — so `PlayerInput._input()`, which is what actually fires `jump_pressed`/
  `roll_pressed`, never saw the simulated presses. Fixed by switching to
  `Input.parse_input_event()` with a constructed `InputEventAction`. Filed as
  [gotchas/input-action-press-does-not-reach-input-callbacks](../gotchas/input-action-press-does-not-reach-input-callbacks.md)
  since it's a general Godot behavior, not specific to this harness.
- **Confirmed after the fix**: `01_after_walk.png` shows Ivo having walked left across
  most of the visible screen (continuous polled input, `move_left`). `02_mid_jump.png`
  shows him airborne mid-jump with the jump pose — visibly distinct from the grounded pose
  in `00_spawn.png`/`03_after_roll.png` (discrete `_input()`-driven action). This confirms
  the harness can drive both continuous and discrete gameplay input and capture the result.
- **Separate, harmless observation**: Ivo's `game.tscn` spawn point sits immediately against
  a pit/wall — the very first (pre-fix) run's screenshots looked like a movement bug for
  this reason alone, independent of the input-simulation issue. Worth knowing when writing
  future timelines: don't assume `move_right` will produce visible movement from the
  default spawn without checking the level geometry first.
- **Frame-capture timing**: also fixed, before this run, a related issue where
  `get_viewport().get_texture()` returns the previous frame's render when read synchronously
  — the harness now awaits two `process_frame` signals before capturing. Not separately
  confirmed by a dedicated before/after screenshot, but no stale/blank frames were observed
  in either run.

## Ratings rationale

No fun/fluidity/aesthetics rating is given (`0` in `ratings` is a placeholder, not a score)
— this session verified the *tool*, not the *game*. A real playtest of a specific feature
(a guardian fight, the Memorina sequence, a seasonal pulse) with an actual rated evaluation
is still pending and should be a separate entry.
