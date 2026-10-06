---
id: bugs/the-playtest-runner-adopts-the-legacy-save-before-going-memory-only
type: bug
title: A windowed playtest-runner session renames user://save_debug.tres to save_debug_1.tres before the runner switches SaveSystem to memory only
status: fixed
severity: low
tags: [playtest, save, slots, legacy, harness, safety]
related: [architecture/save-slots-and-the-boot-swap, systems/life-benches-death, playtests/2026-10-02-title-and-slots]
created: 2026-10-02
updated: 2026-10-06
source_files:
  - globals/save_system.gd
  - globals/save_slots.gd
  - tools/playtest/playtest_runner.gd
---

## Summary

`SaveSystem._ready()` calls `SaveSlots.adopt_legacy()` before any scene runs. The playtest runner calls
`SaveSystem.use_memory_only()` only in its own `_ready`, which comes later. A windowed (debug) runner
session therefore moves the player's pre-slot save into debug slot 1. The runner is documented as never
touching a player's save.

## Symptom

Reproduced 2026-10-02 (UI-05 playtest), with `APPDATA` redirected to a scratch dir:
- seeded `user://save_debug.tres` (headless, through `ResourceSaver`);
- ran `res://tools/playtest/playtest_runner.tscn` with `example_walk_jump_roll.json`, windowed, debug build;
- afterwards the dir held `save_debug_1.tres` (563 bytes) and no `save_debug.tres`.

No data is lost: the content moves, and the runner's later `begin("", true)` writes nothing. But a
session run without the redirect migrates the user's real save. That is the default way the
`godot-playtester` agent and the `godot-playtest` skill have run the harness.

## Root cause

- `globals/save_system.gd` `_ready()`: when not headless, `_slots = SaveSlots.new(PATH, debug)`, then
  `_slots.adopt_legacy()`, then `begin_slot(1, ...)` (debug, no `--title`).
- `globals/save_slots.gd` `adopt_legacy()`: `DirAccess.rename_absolute(legacy, slot 1)` if slot 1 is
  absent.
- `tools/playtest/playtest_runner.gd` `_ready()` calls `SaveSystem.use_memory_only()`. Autoloads are
  ready before the main scene, so this comes too late for the adoption.

## Fix

Fixed 2026-10-06. `SaveSystem._ready` asks `BootPolicy.decide(headless, debug, OS.get_cmdline_args(), OS.get_cmdline_user_args())` before it touches `user://`.
- A run whose engine arguments name `playtest_runner.tscn` is `Session.MEMORY`, like a headless run.
- The slots then have no directory, so `adopt_legacy()` and every read and write do nothing.

Evidence:
- `boot_policy_test` covers both spellings of the runner scene.
- A windowed debug runner session (`example_walk_jump_roll.json`) over a seeded `save_debug.tres` left the file in place with the same md5 (`bf6f86f4…`) and created no slot file.

## Prevention

Until fixed, every windowed harness or driver run redirects `APPDATA` to a scratch dir. Pick a fresh
folder per run, and print `OS.get_user_data_dir()` first to confirm the redirect. Record the md5 of
the real save before and after the session.
