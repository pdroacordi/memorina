---
id: gotchas/gdunit-runs-from-the-editor-are-not-headless
type: gotcha
title: gdUnit4 tests started from the editor's panel run with DisplayServer "Windows", not "headless"
status: active
tags: [gdunit, tests, headless, display-server, save, editor]
related: [bugs/the-title-test-erases-real-debug-slots-when-the-suite-runs-from-the-editor, bugs/the-playtest-runner-adopts-the-legacy-save-before-going-memory-only, systems/life-benches-death]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - globals/boot_policy.gd
  - addons/gdUnit4/src/core/command/GdUnitCommandTestSession.gd
---

## Summary

`DisplayServer.get_name() == "headless"` is true only for the CLI command with `--headless`. A suite started
from the editor's GdUnit panel runs on the editor's debug binary with a real display server, so any
"headless means test" check treats it as a player's session.

## Details

- `GdUnitCommandTestSession.gd:106` (debug run) uses `EditorInterface.play_custom_scene(GdUnitTestRunner.tscn)`, which opens a normal windowed game.
- Line 111 (normal run) starts the editor executable with `--no-window --path <project> res://addons/gdUnit4/src/core/runners/GdUnitTestRunner.tscn`.
- Godot 4.7.2 has no `--no-window` mode. It passes the flag through, and `DisplayServer.get_name()` returns `"Windows"`. Measured 2026-10-06 with `--no-window -s probe.gd`; `OS.get_cmdline_args()` was `["--no-window", "-s", "res://probe.gd"]`.
- Both launches are debug builds (`OS.is_debug_build()` is true), so `BootPolicy` begins debug slot 1 from `user://`.
- The runner scene path is in `OS.get_cmdline_args()` for the `--no-window` launch, so it can be detected the way `playtest_runner.tscn` is.

## Gotchas / pitfalls

- An autoload that decides "test or player" from the display server is wrong for every editor-launched test run.
- Any suite that calls a `SaveSystem` writer (`delete_slot`, `begin_slot`, `rest_at`, `commit`, `record_death`) without first calling `SaveSystem.use_memory_only()` or `begin("", true)` writes the developer's debug save when it runs from the panel.
- `--no-window` in old docs and addons is a Godot 3 flag. In Godot 4 it does nothing.
