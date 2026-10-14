---
id: gotchas/gdunit-await-millis-never-resumes-while-the-tree-is-paused
type: gotcha
title: gdUnit's await_millis never resumes while the tree is paused, so a test that waits under a pause hangs the whole run
status: active
tags: [tests, gdunit, pause, await, timer]
related: [systems/region-title, systems/songs-and-the-memorina, gotchas/time-scale-zero-stops-delta-particles-and-time]
created: 2026-10-14
updated: 2026-10-14
source_files:
  - tests/scenes/ui/region_title/region_title_test.gd
---

## Summary

`await await_millis(ms)` in a `GdUnitTestSuite` waits on a timer that stops with a paused tree. A test that pauses the tree (directly or through `WorldFreeze.freeze()` / `hold()`) and then waits with `await_millis` never resumes. gdUnit reports no timeout: the run sits on `STARTED` until it is killed.

## Details

Found writing `region_title_test.test_a_paused_tree_stops_it` (UI-10, 2026-10-14). The suite printed the test as STARTED and the headless runner idled until the process was stopped by hand.

To wait while paused, use a timer that processes always and ignores the time scale:

```gdscript
await get_tree().create_timer(1.5, true, false, true).timeout  # process_always, not physics, ignore_time_scale
```

`ignore_time_scale` matters under a hold, where `Engine.time_scale` is 0 (`gotchas/time-scale-zero-stops-delta-particles-and-time`). Unpause before going back to `await_millis`.

## Gotchas / pitfalls

- Pause through `WorldFreeze`, never `get_tree().paused =` in a test: the verify-gates scan allows only `world_freeze.gd` to write it. Free the `WorldFreeze` node after `thaw()`; its `_exit_tree` resets the clock anyway.
- A test node's own mode decides whether the node under test pauses. Set the node under test to `PROCESS_MODE_PAUSABLE` explicitly when the game relies on it inheriting PAUSABLE.
