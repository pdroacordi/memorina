---
id: gotchas/headless-has-no-keyboard-layout
type: gotcha
title: The headless display server errors on keyboard_get_label_from_physical
status: active
tags: [headless, display-server, keyboard, layout, tests, glyphs, settings]
related: [systems/settings, systems/input]
created: 2026-11-10
updated: 2026-11-10
source_files:
  - scenes/ui/key_glyph/binding_names.gd
---

## Summary

`DisplayServer.keyboard_get_label_from_physical(code)` prints `ERROR: Not supported by this display server.` on every call under `--headless` (4.7.2, measured in the gdUnit run). A key name is drawn on every prompt refresh, so one suite printed it 400 times.

## Details

`BindingNames.key_text` checks `DisplayServer.get_name() == "headless"` and names the physical keycode itself (`OS.get_keycode_string`). On a real display it asks the layout, so an AZERTY player sees "A" where QWERTY has "Q". Tests that compare a key's name compare against `BindingNames.key_text(code)`, never a literal.
