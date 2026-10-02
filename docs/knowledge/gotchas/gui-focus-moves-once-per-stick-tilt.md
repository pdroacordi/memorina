---
id: gotchas/gui-focus-moves-once-per-stick-tilt
type: gotcha
title: GUI focus navigation moves once per stick tilt through Input, and not at all through Viewport.push_input
status: active
tags: [input, gamepad, joystick, gui, focus, menu, headless, testing]
related: [gotchas/a-stick-is-pressed-on-every-motion-event, playtests/2026-10-02-pause-menu, architecture/pause-menu-worldfreeze-reuse]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - scenes/ui/menu/menu_input.gd
  - tools/playtest/playtest_runner.gd
---

## Summary

In Godot 4.7.2 the engine's own `ui_up`/`ui_down` focus navigation treats a left-stick tilt
as one press: a stream of `InputEventJoypadMotion` past the 0.5 deadzone moves focus once,
and the stick must return under the deadzone before it moves again. A script that reads
`event.is_action_pressed("ui_down")` itself still sees every motion event
(`gotchas/a-stick-is-pressed-on-every-motion-event`).

## Details

Measured with a headless probe (a `SceneTree` script, five stacked `Button`s, focus on the
first), 2026-10-02:

- `Input.parse_input_event()` of axis 1 values 0.25, 0.45, 0.65, 0.85, 1.0, 0.95, 1.0: focus
  moved once, at 0.65. Then 0.0, 0.7, 1.0, 0.0, 0.8, 0.0: one move per crossing of the
  deadzone (B1 to B2 at 0.7, B2 to B3 at 0.8).
- `get_root().push_input()` of the same motion events: focus never moved. A key event
  (`KEY_UP`) through `push_input` did move it.

So a menu built from `Button`s and the default focus neighbours needs no edge code of its
own for the stick. `MenuInput._page_edge` still needs its edge, because it reads `ui_left`/
`ui_right` from the event itself.

## Gotchas / pitfalls

- A headless test that drives a menu with `Viewport.push_input()` concludes "the stick does
  nothing". Use `Input.parse_input_event()`, which is also what the playtest runner uses.
- The pause menu has only two entries, so in-game screenshots cannot show a double move
  (focus has nowhere further to go). A screen with three or more entries (notebook tabs,
  settings) is where a regression would show.
