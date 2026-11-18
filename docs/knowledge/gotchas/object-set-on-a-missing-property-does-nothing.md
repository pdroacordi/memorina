---
id: gotchas/object-set-on-a-missing-property-does-nothing
type: gotcha
title: Object.set() with a property name that does not exist does nothing and reports nothing, so a test poking a renamed private var silently stops testing
status: active
tags: [gdscript, testing, gdunit, reflection, footgun]
related: [systems/guardians, architecture/grd-12-guardian-fight-engine]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - tests/scenes/characters/guardians/guardian_facing_test.gd
---

## Summary

`obj.set(&"name", value)` returns nothing and prints nothing when `name` is not a property of `obj`. `obj.get(&"name")`
returns `null`. When a refactor moves or renames a private var, every test that pokes it through `set()` keeps passing,
but it no longer arranges what it claims.

## Details

- GRD-12 moved `GuardianAI._cooldown` into `GuardianMoveClock`. `guardian_facing_test.gd:43` kept
  `ai.set(&"_cooldown", 5.0)`, which did nothing, so the flinch test ran with no cooldown held. GRD-13 found this and
  changed it to `(ai.get(&"_clock") as GuardianMoveClock).call(&"_cool", 5.0)`.
- `call()` with a missing method does raise an error, so a test reaching private state through a method fails loudly
  when the method moves.

## Gotchas / pitfalls

- Prefer a public test seam or `call()` over `set()` for private state.
- If `set()` must stay, assert the write landed: `assert_that(obj.get(&"name")).is_equal(value)` right after it.
- `Object.set` is also typed-lenient: a value of the wrong type is likewise dropped without an error.
