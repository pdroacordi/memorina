---
id: bugs/settings-test-fails-when-the-players-debug-settings-file-exists
type: bug
title: settings_test fails, and GdUnit skips the rest of the suite, whenever the player's user:// holds settings_debug.cfg
status: resolved
severity: medium
tags: [settings, tests, gdunit, user-data, boot-policy, headless]
related: [systems/settings, architecture/save-slots-and-the-boot-swap, bugs/closing-the-window-with-settings-open-forgets-the-changes]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - tests/globals/settings/settings_test.gd
  - globals/settings/settings.gd
  - globals/settings/settings_file.gd
  - globals/boot_policy.gd
---

## Summary

`settings_test.test_a_headless_run_has_no_disk_and_writes_no_file` (`settings_test.gd:20-25`) asserts that
`user://settings_debug.cfg` and `user://settings.cfg` do not exist. A headless GdUnit run has the same `user://` as the
player: `%APPDATA%/Godot/app_userdata/memorina`, where a real debug run writes `settings_debug.cfg`. The test therefore
measures the player's folder, not the run. No code reads the file. The headless `Settings` has no disk and leaves the
file alone.

## Symptom

Reproduced 2026-11-11 (TECH-12 review, Godot 4.7.2) with the player's file present (`[audio] master=9 ...`,
`[display] fullscreen=true`, `[general] language="en"`):

```
settings_test.gd > test_a_headless_run_has_no_disk_and_writes_no_file FAILED
  Expecting: 'false' but is 'true' at settings_test.gd:25
Statistics: 1 test cases | 1 failures            <- 8 of the suite's 9 cases never ran
```

With `APPDATA` pointed at an empty directory, all 9 cases pass. `notice_watcher_test` did not fail: 17 of 17 passed with
the player's file present, both alone and in the full `res://tests` run. Nothing in it touches settings, so a failure
reported there needs its own repro.

## Root cause

- What the test is about behaves correctly. `Settings._ready` (`settings.gd:32-39`) asks
  `BootPolicy.decide(headless=true, ...)`, gets `MEMORY`, builds `SettingsFile.new("", ...)`. `read()` returns null
  without opening anything (`settings_file.gd:27`), and `commit()` returns at `has_disk()` (`settings.gd:120`).
- What the test checks is the folder instead. Line 25 is
  `FileAccess.file_exists(Settings.PATH.path_join(SettingsFile.file_name(debug)))`, run for both debug values. That
  is a stat of the player's real `user://`, the only access to it in the run. It passes only on a machine where the game
  has never run in debug, so it fails on the developer's own machine.
- The GdUnit CLI stops a suite at its first failure, so the eight binding and volume cases after it never ran either.
  The suite's coverage was lost silently.

## Fix

Fixed 2026-11-11 (TECH-12 fix round). The case now asserts that `Settings` has no disk and that `Settings._file.path()` is
empty, and that each `user://settings*.cfg` has the same existence flag and modified time after `set_volume` and `commit()`
as before (a stat only; the file is never opened). With `-c` all 9 cases run and pass, both with a scratch `APPDATA` and
with the player's real `user://` holding `settings_debug.cfg` (its modified time stayed 07:56:07.161).

Proposed before the fix: assert what the run did, not what the folder holds.

- Check the private file is diskless: `assert_bool(Settings.has_disk()).is_false()` (already there) and
  `assert_str(Settings._file.path()).is_empty()`.
- For the "writes no file" half, snapshot each `user://settings*.cfg` (existence and `FileAccess.get_modified_time`,
  or `FileAccess.get_md5`) before `set_volume` + `commit`, and assert both are unchanged after. A player's file then
  passes untouched, and a write would still fail the test.
- Reading only the modified time or hash of an existing file is the same stat-level access the current test already
  makes. If even that should be avoided, keep only the `_file.path()` assertion.

## Prevention

A test never asserts that a file absent from `user://` stays absent, because a real run of the game writes there.
Tests that need disk use a directory of their own, as `test_a_window_close_writes_what_changed` and
`settings_file_test` do. Run the suite once on a machine with a played debug session before trusting a "no file"
assertion.
