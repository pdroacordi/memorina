---
id: gotchas/a-new-inputevent-is-not-for-all-devices
type: gotcha
title: An InputEvent made in code is for one device (a button is pad 0, a key is device 16); a project event is for all (-1)
status: active
tags: [input, inputmap, joypad, device, rebinding, settings]
related: [bugs/a-rebound-pad-button-answers-only-joypad-0, systems/settings, systems/input]
created: 2026-11-10
updated: 2026-11-10
source_files:
  - globals/settings/key_bindings.gd
---

## Summary

Measured in 4.7.2: `InputEventJoypadButton.new().device == 0` and `InputEventKey.new().device == 16`.
Events saved in `project.godot` carry `"device": -1`. `InputMap` matches an action event only when its
device is -1 or equals the incoming event's device, so a button added from code answers pad 0 alone.

## Details

- Probe: add a `JOY_BUTTON_Y` event made with `.new()` to an action. A device-1 press gives
  `is_action == false`; a device-0 press gives `true`.
- `InputMap.action_add_event` also drops an event equal to one the action already has. In the probe,
  two physical-Q keys added to one action leave one event.
- Tests and the playtest runner build their events with `.new()`, so they send device 0 or 16. They
  never see this mismatch.

## Gotchas / pitfalls

Any code that writes `InputMap` at runtime (rebinding, a reset) must set `device = -1`, or duplicate the
project event and change only its code.
