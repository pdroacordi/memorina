---
id: gotchas/a-gdscript-lambda-copies-a-local-it-captures
type: gotcha
title: A GDScript lambda copies a captured local of a value type when it is created; later writes to the local do not reach it
status: active
tags: [gdscript, lambda, signal, test]
related: [systems/guardians]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - tests/scenes/characters/guardians/guardian_ai_timeline_test.gd
---

# A GDScript lambda copies a captured local

Measured on 4.7.2 while writing `guardian_ai_timeline_test` (GRD-12). A signal handler written as a lambda that reads a local `int` counter (`var frame := 0`, then `frame += 1` each step) sees the value the counter had when the lambda was created: every event was stamped frame 0.

- Value types (`int`, `float`, `bool`, `Vector2`, `String`) are copied into the lambda at creation. Reference types (`Array`, `Dictionary`, `Object`) are shared, so appending to a captured array from the lambda works.
- Fix: read a member variable (`_frame`) or a shared container instead of a local.
- A test that connects lambdas to a node it reuses across cases connects them again on each case; build a fresh node per case (`_make_ai()` in the timeline test).
