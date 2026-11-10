---
id: bugs/a-binding-refused-by-ui-accept-shows-the-raw-key-action-ui-accept
type: bug
title: A binding that ui_accept or ui_cancel refuses shows "Used by ACTION_UI_ACCEPT" on the status line
status: fixed
severity: medium
tags: [settings, rebinding, i18n, translations, status-line, ui-07]
related: [systems/settings, bugs/a-rebound-pad-button-answers-only-joypad-0, playtests/2026-11-10-ui07-settings]
created: 2026-11-10
updated: 2026-11-10
source_files:
  - scenes/ui/settings/settings_screen.gd
  - globals/settings/binding_rules.gd
  - i18n/translations.csv
---

## Summary

`BindingRules.assign` can name `ui_accept` or `ui_cancel` as the blocking action. The status line then
translates `ACTION_UI_ACCEPT` or `ACTION_UI_CANCEL`, and neither key is in `translations.csv`, so the
raw key shows in both languages.

## Symptom

Found in the UI-07 review. Steps: Settings > Keyboard, accept Note up, press Space or Enter. The status
line reads "Used by ACTION_UI_ACCEPT" ("Já usada em ACTION_UI_ACCEPT" in pt_BR). Map or Notebook on
Enter, Space or keypad Enter show the same. On the pad it shows when the only conflict left is a fixed
action, for example Notebook to A after Jump and Note down have moved off A.

Confirmed in the running game by the 2026-11-10 playtest
(`playtests/2026-11-10-ui07-settings`). After Jump was rebound to Space, Map -> Z and Map -> Enter both
showed "Used by ACTION_UI_ACCEPT" (`playtests/screenshots/2026-11-10-ui07-settings/a24_refused_z.png`).
The text also stays on the status line after Esc cancels the capture (`a26_capture_cancelled.png`).

## Root cause

- `globals/settings/binding_rules.gd:96` returns `REFUSED_TAKEN` with `other = conflicts[0]`. When the
  only holder that conflicts is fixed, that is `ui_accept` or `ui_cancel`.
- `scenes/ui/settings/settings_screen.gd:280` writes `tr(BindingRow.action_key(result.other))`, which is
  `"ACTION_" + "UI_ACCEPT"`.
- `i18n/translations.csv` has `ACTION_*` keys only for the ten `REBINDABLE` actions.
- `settings_text_fit_test.gd:52` measures `SETTINGS_BIND_TAKEN` only with those ten keys, so the gap
  was never rendered.

## Fix

Fixed 2026-11-10 (UI-07 fix round). `ACTION_UI_ACCEPT` ("Confirm" / "Confirmar") and `ACTION_UI_CANCEL` ("Back" / "Voltar") are in `translations.csv`, so the status line names a fixed holder. The status also clears when a capture is cancelled and when the focus leaves a row.

Regression tests: `settings_screen_test` `test_a_refusal_by_ui_accept_names_it` (keyboard Note up -> Space shows "Used by Confirm", no `ACTION_`), `test_cancelling_a_capture_and_leaving_a_row_clear_the_status`; `settings_text_fit_test` measures `SETTINGS_BIND_TAKEN` with every action in `BindingRules.GROUPS`, the fixed two included.

Originally proposed: Add `ACTION_UI_ACCEPT` ("Confirm" / "Confirmar") and `ACTION_UI_CANCEL` ("Back" / "Voltar"),
or a dedicated "used by the menu" text. Include both in the fit test's `SETTINGS_BIND_TAKEN` loop.

## Prevention

A `settings_screen_test` case that captures keyboard Note up, emits Space, and asserts the status line
contains no `ACTION_` substring. Generally: a text key built by string concatenation needs a test over
every value its input can take, not only the common ones.
