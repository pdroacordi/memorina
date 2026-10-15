---
id: gotchas/json-numbers-are-floats-so-array-has-an-int-misses-them
type: gotcha
title: JSON numbers parse as float, and Array.has(int) and `int in array` do not match a float element
status: active
tags: [gdscript, json, array, float, int, playtest, rooms]
related: [systems/pickups, systems/rooms]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - tools/playtest/playtest_runner.gd
  - scenes/world/rooms/maps/entity_params.gd
---

## Summary

`JSON.parse_string("[0, 1]")` gives an Array of floats. On that array, `a.has(0)` and `0 in a` are false and `a.has(0.0)` is true. Array lookup does not treat int and float as equal, even though `0 == 0.0` is true in an expression.

## Details

- Measured headless on Godot 4.7.2 (STORY-02 review, 2026-10-15): `typeof(a[0])` is 3 (`TYPE_FLOAT`), `has(0)` is false, `has(0.0)` is true and `0 in a` is false.
- This hits every JSON input that lists ids: playtest timelines (`known_songs`, `skills`, `owned_items`, ...) and `.room` `[entities]` params (`item: 0`, `arrive_facing: 1`).
- Two safe ways to read it:
  - convert each element (`int(id)`), as the runner's `known_songs` loop does;
  - test both forms, as `owned_items` does (`owned.has(item) or owned.has(float(item))`).
- `.room` params are converted by type in `EntityParams`. A test that reads the raw parsed params, like `room_files_test`'s item check, has to accept `TYPE_FLOAT` as well.

## Gotchas / pitfalls

- The same trap applies to Dictionary keys and `match`. Measured on 4.7.2: `{0: "x"}.has(0.0)` is false, and `match 0.0` skips an int pattern `0:`. Convert before you compare.
