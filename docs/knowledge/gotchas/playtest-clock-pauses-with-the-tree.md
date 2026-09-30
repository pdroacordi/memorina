---
id: gotchas/playtest-clock-pauses-with-the-tree
type: gotcha
title: A playtest timeline's t stops during a performance - it is unpaused time
status: active
tags: [playtest, harness, pause, performance, timeline]
related: [architecture/played-pulses-hold-in-a-pause]
created: 2026-09-30
updated: 2026-09-30
source_files:
  - tools/playtest/playtest_runner.gd
  - tools/playtest/README.md
---

## Summary

The runner counts `_elapsed` in `_process` and pauses with the tree, so the ~7 s a
performance freezes the world do not count. A song's pulse appears about 1.6 s after its
last note in `t`. A timeline that waits in `t` "for the performance" idles in the world,
and a song's effect runs out while it waits - the first Soltar-then-Vendaval run looked
like a game bug for exactly this reason.
