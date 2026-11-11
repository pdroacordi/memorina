---
id: gotchas/gdunit-cli-skips-a-suites-remaining-cases-after-its-first-failure
type: gotcha
title: GdUnitCmdTool is fail-fast by default; a failing case hides every later case of its suite (-c runs them)
status: active
tags: [gdunit, tests, cli, fail-fast]
related: [bugs/settings-test-fails-when-the-players-debug-settings-file-exists, gotchas/gdunit-runs-from-the-editor-are-not-headless]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - addons/gdUnit4/src/core/runners/GdUnitTestCIRunner.gd
---

## Summary

`GdUnitTestCIRunner._ready` calls `_executor.fail_fast(true)` (`GdUnitTestCIRunner.gd:107`). From the command line
(`GdUnitCmdTool.gd`, the project's documented test command), a suite therefore stops at its first failing case, and
its later cases are neither run nor counted. The next suites still run. `-c` / `--continue` turns this off.

## Details

Measured 2026-11-11 (Godot 4.7.2, vendored gdUnit4): `settings_test` has 9 cases. With its first case failing, the
report reads `Statistics: 1 test cases | 1 failures`, and the "Executed test cases" total counts only that one case.
The other 8 cases never ran, and nothing in the report flags them as skipped.

## Rule

When a run fails, read its counts as a lower bound: rerun the failing suite with `-c` before concluding that only one
case is broken. A fix round that turns a first case green can surface failures that were hidden behind it.
