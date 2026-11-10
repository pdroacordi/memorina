---
id: bugs/settings-rows-measure-12-px-so-reset-to-defaults-sits-on-the-status-line
type: bug
title: Settings rows measure 12 px, not 11, so the Keyboard and Pad pages' Reset to defaults row shares the status line's band
status: fixed
severity: low
tags: [settings, layout, status-line, rebinding, ui-07]
related: [systems/settings, playtests/2026-11-10-ui07-settings, bugs/a-binding-refused-by-ui-accept-shows-the-raw-key-action-ui-accept]
created: 2026-11-10
updated: 2026-11-10
source_files:
  - scenes/ui/settings/settings_screen.tscn
  - scenes/ui/settings/binding_row.gd
  - scenes/ui/settings/setting_row.gd
  - scenes/ui/menu/menu_theme.tres
---

## Summary

`systems/settings` sets rows to 11 pack px so that eleven rows (31..152) end above the status line at
y 154. The rows lay out 12 px tall, so the eleventh row, Reset to defaults, spans 151..163 and its text
sits on the same band as the status text.

## Symptom

Found in the 2026-11-10 playtest. On the Keyboard or Pad page, any status message (reserved, used by,
swapped) prints beside "Reset to defaults", about 2 pack px lower than it, as if it were that row's value
(`playtests/screenshots/2026-11-10-ui07-settings/a20_reserved_status.png`, `a24_refused_z.png`,
`b08_refused_pt.png`).

Measured in a 1280x720 window (4 window px per pack px):
- Row text pitch: 48 window px (Jump 140..159, Attack 188..203, ..., Reset 620..639), i.e. 12 pack px.
- Status text: 628..647. It overlaps the Reset text's rows by 12 window px (3 pack px).
- Horizontally they do not touch yet. In English the Reset text ends at x 355 and the status text starts
  at x 460. In pt_BR "Restaurar o padrão" ends at ~380 and "Já usada em Pular" starts at 515. A longer
  pt_BR message, centred in 272 px ("Já usada em Nota da esquerda"), leaves roughly 50 window px.

A live probe in the running game (`tools/playtest/scripts/ui07_settings_probe_driver.gd`) printed
`h=12.0` for every `BindingRow`, the Reset `Button` and every `SettingRow`. Pages start at y 31 with
`separation = 0`, and `Status` sits at (24, 154), 272x10.

## Root cause

`BindingRow.HEIGHT` (11) is a `custom_minimum_size`, a floor and not a cap. The button's own minimum height is
12, so 12 wins. The 12 is the `InkButton` font's line height plus the empty stylebox margins: the likely
cause, not confirmed line by line.

## Fix

Fixed 2026-11-10 (UI-07 fix round). The cause was the InkButton style's 1 px top and 2 px bottom content margins over the 8 px font's 9 px line. `SettingRow.compact` gives every Settings row (value rows, binding rows, Reset) one shared `StyleBoxEmpty` with 4 / 1 / 4 / 1 margins for normal, hover, pressed, hover_pressed and disabled, so a row is 11 px. Eleven rows from y 31 end at 152, above the status line at 154. `menu_theme.tres` is unchanged.

Regression test: `settings_screen_test` `test_the_last_row_ends_above_the_status_line_in_every_language` (after layout, every page's last row is 11 px and ends at or above `Status.position.y`, in en and pt_BR).

Originally proposed: Either make the rows 11 px for real (e.g. a Label-based row or a theme constant that fixes the
line height), or move the status line below the last row. 11 x 12 = 132 ends at 163, so moving it needs
~10 px of the panel's bottom margin, which the frame does not have.

## Prevention

A `settings_screen_test` case that asserts the last row's rect ends above `Status.position.y` on both
device pages, in both languages, instead of trusting the authored `HEIGHT`.
