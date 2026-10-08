---
id: gotchas/a-typed-loop-variable-fails-on-a-freed-object
type: gotcha
title: A typed `for` variable or typed local given a freed object errors on the assignment, before any is_instance_valid() check runs
status: active
tags: [typing, free, for-loop, dictionary, is-instance-valid]
related: [gotchas/a-freed-object-in-a-deferred-call-fails-its-typed-argument, bugs/a-root-catch-on-a-freed-platform-errors-before-its-validity-check]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/memory/song_effects/roots/root_grower.gd
---

## Summary

`for body: Object in dict.keys():` with a freed object among the keys stops the function with
`SCRIPT ERROR: Trying to assign invalid previously freed instance.` on the `for` line. The loop
body never runs, so an `is_instance_valid(body)` inside it cannot catch the case. The same
error comes from `var o: Object = freed`.

## Details

Measured in 4.7.2 headless (2026-10-08) with a minimal `-s` script: a `Node` used as a
Dictionary key, then `free()`d.

- `for body: Object in d.keys():` errors on the `for` line and leaves the function.
- `for body in d.keys():` (untyped) and `var v: Variant = d.keys()[0]` assign without error,
  and `is_instance_valid()` returns false.
- `var o: Object = d.keys()[0]` errors like the typed loop.
- A freed object compared to `null` (`_room == null`) is true, and `if freed:` is false.

## Gotchas / pitfalls

- Any typed slot (a typed loop variable, a typed local, a typed parameter, see
  `a-freed-object-in-a-deferred-call-fails-its-typed-argument`) checks the instance on
  assignment. Code that iterates possibly-freed objects to prune them must read them untyped,
  or key the collection by `get_instance_id()`.
- The typed form looks safe because the `is_instance_valid()` guard is right there. It is
  never reached.
