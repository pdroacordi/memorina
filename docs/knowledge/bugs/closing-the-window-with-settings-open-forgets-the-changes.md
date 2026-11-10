---
id: bugs/closing-the-window-with-settings-open-forgets-the-changes
type: bug
title: Closing the window (X, Alt+F4) while Settings is open forgets every change of that visit
status: fixed
severity: low
tags: [settings, commit, quit, wm-close-request, ui-07]
related: [systems/settings]
created: 2026-11-10
updated: 2026-11-10
source_files:
  - globals/settings/settings.gd
  - scenes/ui/settings/settings_screen.gd
---

## Summary

`Settings.commit()` runs only from `SettingsScreen.close()`. Nothing handles
`NOTIFICATION_WM_CLOSE_REQUEST`, so a window close while the screen is open quits without writing.

## Symptom

Found in the UI-07 review. Steps: on the title, open Settings, pick Português, set Music to 3, click the
window's X. On the next boot the game is in the OS language with Music at 10. The changes applied live,
so the player saw them take effect.

## Root cause

- `scenes/ui/settings/settings_screen.gd:98` is the only caller of `Settings.commit()`.
- No script in `globals/` or `scenes/` handles `NOTIFICATION_WM_CLOSE_REQUEST` (grep). Godot's default
  auto-accept quit ends the tree without closing the screen.

## Fix

Fixed 2026-11-10 (UI-07 fix round). `Settings._notification` calls `commit()` on `NOTIFICATION_WM_CLOSE_REQUEST`. `commit` writes nothing without a disk (MEMORY sessions) and nothing when unchanged.

Regression test: `settings_test` `test_a_window_close_writes_what_changed` (a temporary directory on the autoload's private file, Music set to 3, the notification sent; the file holds music=3).

Originally proposed: In `Settings` (an autoload, always in the tree), handle `NOTIFICATION_WM_CLOSE_REQUEST` and
call `commit()`. That is safe: `commit` writes nothing without a disk, and nothing when the settings are
unchanged.

## Prevention

A `settings_test` case that sends `NOTIFICATION_WM_CLOSE_REQUEST` to `Settings` with a temporary disk
and asserts the file was written.
