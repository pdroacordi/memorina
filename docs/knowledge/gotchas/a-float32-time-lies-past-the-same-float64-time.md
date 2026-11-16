---
id: gotchas/a-float32-time-lies-past-the-same-float64-time
type: gotcha
title: A time stored in a PackedFloat32Array lies just past the same time as a float, so an inclusive bound misses it
status: active
tags: [gdscript, float, precision, audio, footsteps, testing]
related: [systems/sound-effects]
created: 2026-11-16
updated: 2026-11-16
source_files:
  - resources/audio/step_clock.gd
  - tests/resources/audio/step_clock_test.gd
---

## Summary

A `PackedFloat32Array` stores 32-bit floats; a GDScript `float` is 64-bit. `0.4` as float32 is
0.4000000059604645, so `contact <= position` is false when `position` is the float `0.4`. A contact
read at exactly its own time is missed, and counted one frame later.

`StepClock` counts contacts in `(after, upto]` with both bounds moved by `EPSILON` (0.00001 s), so a
contact counts exactly once, on the read that reaches it.

## Details

Found 2026-11-16 by `step_clock_test.test_crossing_a_contact_counts_it_once`: `advance(RUN, 0.4, ...)`
with a contact of `0.4` returned 0. In play the AnimationTree position is rarely an exact contact time,
so the miss would only shift a step by a frame; a test written on the exact values fails.

## Gotchas / pitfalls

- Moving only the upper bound counts a contact twice: once on the read that reaches it and again on the
  next, whose lower bound is the same 64-bit value. Move both.
- The same holds for any time list exported as `PackedFloat32Array` (song note cues, contact times)
  and compared with a `float` position.
