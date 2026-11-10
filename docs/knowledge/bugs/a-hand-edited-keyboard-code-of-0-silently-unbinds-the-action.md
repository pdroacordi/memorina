---
id: bugs/a-hand-edited-keyboard-code-of-0-silently-unbinds-the-action
type: bug
title: The settings file accepts any int as a keyboard code; jump=0 (or any non-key) silently leaves the action with no key
status: fixed
severity: low
tags: [settings, rebinding, config-file, validation, keyboard, ui-07]
related: [systems/settings]
created: 2026-11-10
updated: 2026-11-10
source_files:
  - globals/settings/game_settings.gd
  - globals/settings/binding_rules.gd
---

## Summary

Loading `[keyboard]` validates pad codes against `PAD_BUTTONS`, but it accepts any int as a key except
-1 (`NONE`). A code of 0, a negative number or a value that is not a `Key` passes `BindingRules.valid`.
The action then gets a key event that matches nothing.

## Symptom

Found in the UI-07 review. Hand-edit `settings.cfg` to `[keyboard] jump=0`. No warning is printed.
Jump, and `map_zoom_in` with it, stop answering the keyboard, and the Keyboard page shows an empty name.

## Root cause

- `globals/settings/game_settings.gd:66` accepts `code is int and code != NONE`.
- `globals/settings/binding_rules.gd:63-66`: `reserved()` rejects out-of-set codes only on the pad.
- `KeyBindings.event_for(0, KEYBOARD)` gives a key with keycode, physical keycode and label all
  `KEY_NONE`, which `InputEventKey.action_match` never matches.

## Fix

Fixed 2026-11-10 (UI-07 fix round). `BindingRules.reserved` refuses a keyboard code `<= KEY_NONE` or one `OS.get_keycode_string` cannot name, so `valid` fails and the loaded `[keyboard]` overrides drop with the existing warning; a capture can never assign one either.

Regression tests: `game_settings_test` `test_a_keyboard_code_that_is_no_key_drops_the_keyboard_overrides` (0, -5 and 1 << 30 load the default Z), `binding_rules_test` `test_a_keyboard_code_that_is_no_key_is_refused`.

Originally proposed: Have `reserved()` (or `valid()`) also refuse a keyboard code `<= 0`, and any code for which
`OS.get_keycode_string` is empty. The device's overrides then drop with the existing warning.

## Prevention

A `game_settings_test` case: `[keyboard] jump=0` loads the default Z with a warning.
