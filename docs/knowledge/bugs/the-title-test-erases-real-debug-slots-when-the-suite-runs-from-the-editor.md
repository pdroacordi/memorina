---
id: bugs/the-title-test-erases-real-debug-slots-when-the-suite-runs-from-the-editor
type: bug
title: Running TitleTest from the editor's GdUnit panel deletes user://save_debug_1.tres and save_debug_2.tres
status: fixed
severity: medium
tags: [save, slots, tests, gdunit, boot-policy, safety]
related: [bugs/the-playtest-runner-adopts-the-legacy-save-before-going-memory-only, gotchas/gdunit-runs-from-the-editor-are-not-headless, architecture/save-slots-and-the-boot-swap, systems/life-benches-death, systems/screens]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - globals/boot_policy.gd
  - globals/save_system.gd
  - globals/save_slots.gd
  - scenes/ui/title/title.gd
  - tests/scenes/ui/title/title_test.gd
---

## Summary

`BootPolicy` keeps only headless runs and the playtest runner off the disk. If the suite is started from the
editor's GdUnit panel, the run is not headless. `TitleTest` then drives the real `SaveSystem.delete_slot`
and `begin_slot` against the developer's debug slots.

## Symptom

Found in the pre-push review of b2ce006..4c86b66 by tracing the code. Not executed against a real save.
- The editor's GdUnit panel launches `GdUnitTestRunner.tscn` either with `--no-window` (`GdUnitCommandTestSession.gd:111`) or through `EditorInterface.play_custom_scene` (debug mode, line 106).
- Under `--no-window`, `DisplayServer.get_name()` is `"Windows"`, not `"headless"`. Measured with Godot 4.7.2 (`gotchas/gdunit-runs-from-the-editor-are-not-headless`).
- `test_erasing_the_last_save_returns_to_main_with_continue_greyed` confirms Erase on slot 2. That calls `SaveSystem.delete_slot(2)`, which removes `user://save_debug_2.tres`.
- `test_buttons_pressed_while_leaving_erase_and_overwrite_nothing` confirms Overwrite on slot 1. That calls `SaveSystem.delete_slot(1)` and then `SaveSystem.begin_slot(1, true)`, so `user://save_debug_1.tres` (the slot a debug build boots into) is gone.
- Faking the saves with `_saves([...])` does not help, because `Title` still asks `SaveSystem` to act on the slot number.

The headless command in CLAUDE.md is safe: there `SaveSlots.dir` is empty and every delete does nothing.

## Root cause

- `globals/boot_policy.gd:16` `decide()` returns `Session.MEMORY` only for `headless` or `_runs_the_runner(args)`. A non-headless gdUnit runner is neither, so a debug build gets `Session.SLOT_1`.
- `globals/save_system.gd:30` then builds `SaveSlots.new(PATH, debug)`, so `delete_slot` / `begin_slot` reach `user://`.
- `scenes/ui/title/title.gd:74` and `:85` call `SaveSystem.delete_slot(slot)`. `tests/scenes/ui/title/title_test.gd` never calls `SaveSystem.use_memory_only()` and relies on headless mode (its own comment at line 54: "headless: all empty").

## Fix

Fixed 2026-10-06, both options:
- `BootPolicy.RUNNER_SCENE_FILES` holds `playtest_runner.tscn` and `GdUnitTestRunner.tscn`; either on the command line gives `Session.MEMORY`. `boot_policy_test.test_the_gdunit_runner_is_memory_only_from_the_editor` covers both editor launches (`--scene` from `play_custom_scene`, and the `--no-window` child process).
- `TitleTest.before()` calls `SaveSystem.use_memory_only()`, so the suite is safe even under a launcher the policy does not know.

## Prevention

- "Headless" is not a stand-in for "a test run". The safety check has to identify the runner, not the display server.
- The life-benches-death contract says the suite never touches a player's save, but nothing enforces it for editor-launched runs.
- Until fixed, run the suite only with the headless command from CLAUDE.md.
