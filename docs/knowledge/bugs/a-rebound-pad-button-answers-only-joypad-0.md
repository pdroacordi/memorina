---
id: bugs/a-rebound-pad-button-answers-only-joypad-0
type: bug
title: A rebound pad button (and Reset to defaults) answers only joypad 0; a pad on any other device id loses the action
status: fixed
severity: high
tags: [settings, rebinding, input, inputmap, joypad, device, ui-07]
related: [systems/settings, systems/input, gotchas/a-new-inputevent-is-not-for-all-devices]
created: 2026-11-10
updated: 2026-11-10
source_files:
  - globals/settings/key_bindings.gd
  - globals/settings/settings.gd
---

## Summary

`KeyBindings.event_for` builds the pad event with the engine's default `device = 0`. The project's
events use `device = -1` (all devices), so after a rebind the action answers only the pad with id 0.

## Symptom

Found in the UI-07 review. Steps: connect a pad that Godot numbers 1, for example with Steam Input's
virtual pad, a second pad, or a pad reconnected while another holds id 0. In Settings > Pad, bind Jump
to Y. Jump, and `map_zoom_in`, which follows it, no longer answer that pad; the Y of pad 0 still works.
Reset to defaults has the same effect, because it writes its events through the same function. Every
boot with a saved `[pad]` override applies it the same way. Tests and playtests send events with
device 0, so neither catches it.

## Root cause

- `globals/settings/key_bindings.gd:84-86`: `InputEventJoypadButton.new()` has `device == 0` (measured
  4.7.2), and `event_for` never sets it.
- `InputMap` matches an event only when the action event's device is -1 or equals the incoming event's
  device. Measured: a device-1 press does not match a device-0 action event.
- `globals/settings/settings.gd:156,160` (`_replace`) puts that event in place of the project's -1 event,
  for the rebindable action and for its zoom follower.

## Fix

Fixed 2026-11-10 (UI-07 fix round). `KeyBindings.event_for` sets `device = KeyBindings.ALL_DEVICES` (-1) on the key and the button it builds, so every event `Settings` writes (a rebind, its zoom follower, Reset to defaults, a saved override at boot) answers every device, as the project's events do.

Regression test: `tests/globals/settings/settings_test.gd` `test_a_rebound_and_a_reset_event_answer_every_device` (a device-1 Y press is `jump` and `map_zoom_in` after binding jump to Y; every rebindable and follower event is device -1 after the rebind and after both resets).

Originally proposed: In `event_for`, set `device = -1` (`InputMap.ALL_DEVICES`) on both the key and the button.
The keyboard event currently defaults to device 16; the project's keys use -1 too. Better still,
`_replace` can duplicate the event it replaces and change only its code, so every other field of the
project event is kept.

## Prevention

Add a `settings_test` case: bind on the pad, then assert that a device-1 `InputEventJoypadButton` press
`is_action` the rebound action, and assert `device == -1` on every event after `reset_bindings`.
