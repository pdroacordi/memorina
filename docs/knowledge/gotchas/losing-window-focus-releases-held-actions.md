---
id: gotchas/losing-window-focus-releases-held-actions
type: gotcha
title: When the game window loses focus, Godot releases every pressed action, including ones a script injected
status: active
tags: [input, focus, parse-input-event, playtest, harness, windows]
related: [gotchas/input-action-press-does-not-reach-input-callbacks, playtests/2026-10-07-empty-house]
created: 2026-10-07
updated: 2026-10-07
source_files:
  - tools/playtest/playtest_runner.gd
---

## Summary

On Windows, Godot calls `Input.release_pressed_events()` when its window is deactivated.
An action held through `Input.parse_input_event()` is released the same way a real key is,
with no release step in the timeline.

## Details

- Observed in two playtest runs on 2026-10-07. A timeline held `move_left` from t 10.9 to
  18.8, and Ivo stopped at t ≈ 14 in `idle` with zero velocity. A second Godot window (a
  concurrent playtest) had just opened. Later presses worked normally.
- The engine cause is inferred, not traced: the Windows display server releases pressed
  events on deactivation. The symptom matched exactly, and re-sending the press fixed it.
- Workaround in a timeline: re-send `pressed: true` every 0.25 s for the length of a hold,
  with a single release at the end. A stall of up to ~0.25 s can still occur.

## Gotchas / pitfalls

- This applies to any automated input driver, not only the playtest runner. A run that
  "randomly" stops walking is a focus change until proved otherwise.
- A person playing is unaffected in practice: releasing keys on alt-tab is the intended
  behaviour.
