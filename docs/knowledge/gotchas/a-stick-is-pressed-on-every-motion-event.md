---
id: gotchas/a-stick-is-pressed-on-every-motion-event
type: gotcha
title: event.is_action_pressed() is true for EVERY joystick motion event past the deadzone, not only the first - a press signal from a stick must be an edge
status: active
tags: [input, gamepad, joystick, deadzone, player-input, signals]
related: [gotchas/input-action-press-does-not-reach-input-callbacks, architecture/character-controller-input-split]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - scenes/characters/ivo/player_input.gd
  - globals/input_device.gd
---

## Summary

A button sends one pressed event and one released event. A stick sends a stream of
`InputEventJoypadMotion` while it moves, and `event.is_action_pressed(action)` is true for
every one of them whose strength is past the action's deadzone (motion events are never
echoes, so `allow_echo` does not help). A discrete signal emitted on `is_action_pressed`
for an action bound to a stick therefore fires again on every wiggle of a held stick.

Found in review (2026-10-02): `look_down` gained a stick binding, and `PlayerInput`
emitted `look_down_pressed` on every motion event, so a player holding the stick down who
pressed a button to stand up from a bench was sat straight back down - another rest,
another save, every enemy woken - by the next motion event.

## The rule

A press signal for an action that has an axis binding is the EDGE, tracked by the input
node itself: `PlayerInput._down_held`, updated on every `event.is_action("look_down")`.
That works in both directions because `InputEventJoypadMotion.action_match` MATCHES a
motion on the same axis in the opposite direction and reports it as not pressed - a flick
from down straight to up lets go of down even if no event near the centre arrived
(`input_glyphs_test.gd`, `test_a_held_stick_asks_to_sit_once`).

Continuous state (`look_direction`) is unaffected: it is polled through `Input.get_axis`.

## Related

`InputDevice` has the mirror problem for device switching: it counts a motion as picking
the pad up only past `STICK_THRESHOLD`, so drift never flips the prompts. And a motion
event is the pad as much as a button is - `PlayerInput.glyph_set_for` classified it as the
keyboard until Codex's review caught it (moving the stick flipped every prompt to keys).
