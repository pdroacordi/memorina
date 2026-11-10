---
id: gotchas/translation-changed-reaches-every-node-before-set-locale-returns
type: gotcha
title: TranslationServer.set_locale delivers NOTIFICATION_TRANSLATION_CHANGED to every node in the tree before it returns
status: active
tags: [i18n, locale, translation, notification, settings, retranslate]
related: [systems/settings, architecture/settings-screen, systems/screens]
created: 2026-11-10
updated: 2026-11-10
source_files:
  - globals/settings/settings.gd
  - scenes/ui/pause_menu/pause_menu.gd
  - scenes/ui/settings/settings_screen.gd
---

## Summary

Measured on 4.7.2 (headless, `tests/scenes/ui/settings/retranslate_test.gd`): right after `TranslationServer.set_locale("pt_BR")`, with no frame awaited, the open pause menu's entries, a `ConfirmPanel` body, the Settings tabs and the code-built Settings rows already show the new language. The notification is synchronous and reaches nodes that are hidden and nodes built in code.

## Details

- A script that sets a static text from a key does it in `_retranslate()`, called from `_ready` and from `_notification(NOTIFICATION_TRANSLATION_CHANGED)` behind `is_node_ready()`. The guard matters: the notification can arrive before `_ready` (a node entering the tree), when `@onready` vars are still null.
- Code that reads translated text right after `set_locale` (a row refreshing its value) sees the new texts already.
- Texts translated as they show (dialogue lines, barks, notices) need nothing; they take the new language at their next show.
