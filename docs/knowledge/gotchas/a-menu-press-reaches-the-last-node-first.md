---
id: gotchas/a-menu-press-reaches-the-last-node-first
type: gotcha
title: _input reaches the last node in the tree first, and a Button that unpauses on release passes that release to _unhandled_input
status: active
tags: [input, pause, menu, gui, button, input-order, set-input-as-handled]
related: [architecture/pause-menu-worldfreeze-reuse, bugs/player-input-edge-state-goes-stale-across-a-pause-menu, gotchas/input-action-press-does-not-reach-input-callbacks]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - scenes/ui/screens/screens.gd
  - scenes/ui/menu/menu_input.gd
  - scenes/characters/ivo/player_input.gd
  - globals/input_device.gd
---

## Summary

How the press that closes a menu reaches, or does not reach, the gameplay input that
the menu just unpaused. Measured in Godot 4.7.2 with a headless scratch project: a
pausable `World/PlayerInput`, then an ALWAYS `Control` with a menu `_input` node and a
focused `Button`.

## Details

- `_input` is dispatched in **reverse tree order**: the node added last gets the event
  first. The loop stops at the first `set_input_as_handled()`. `Screens` sits under
  `ScreenLayer`, the last child of `Game`, so `MenuInput` sees a press before
  `World/Player/PlayerInput` and before the `InputDevice` autoload. Moving `ScreenLayer`
  above `World` in `game.tscn` would let a closing B press (also roll) reach `PlayerInput`
  in the same dispatch, because the thaw has already run by then.
- A node that cannot process (paused) is skipped. It does not receive the event later
  either, so its edge and release state goes stale.
- A `Button` (default `ACTION_MODE_BUTTON_RELEASE`) acts on `ui_accept` only on the
  release. The press while paused only emits `button_down`. When `pressed` thaws the
  tree, the same release event continues to the `_unhandled_input` of the nodes that were
  just unpaused: the GUI did not accept it. It does not reach their `_input`, because that
  phase has already finished.
- Side effect of the first point: a handled press never reaches a later node's `_input`.
  `InputDevice` therefore listens on `get_tree().root.window_input` instead, which the
  window emits before dispatch whatever any node handles (measured 2026-10-02: a pad Start
  that opened the pause menu still switched the glyph set to Xbox).

## Gotchas / pitfalls

- `PlayerInput` reads `_input`, so A or Z on Resume (also jump) does not jump on resume.
  A gameplay reader moved to `_unhandled_input` would receive the release of every Resume
  press, for example as a jump cut.
- A menu that closes from its own `_input` must call `set_input_as_handled()` before
  anything earlier in the tree can see the event; `Screens._on_press` does.
