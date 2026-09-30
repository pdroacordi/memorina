---
id: bugs/ice-front-leaps-dead-columns
type: bug
title: An ice front jumps over a column nothing remembers whenever one frame's advance crosses more than one column boundary
status: fixed
severity: medium
tags: [water, freeze, ice, memory, off-by-one, frame-rate]
related: [bugs/water-swell-flattened-by-spread]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/world/interactables/freezable_water/ice_front.gd
  - tests/scenes/world/interactables/freezable_water/ice_front_test.gd
---

## Summary

`IceFront._grow_fronts` checks the memory of only the NEXT column, then moves the front by
`step * rate` in one go. At default tuning, `step` is 1.33 columns per 60 fps frame, so a
front sitting late in a column lands two columns on and never reads the rate of the one it
skipped. The rule "ice needs living water, a front stops dead where nothing is remembered"
(design 03 §6.3) then depends on the frame rate and on where the fractional front happened
to be.

## Symptom

Found in review (commit 643088b) and measured headless with the real class: 48 columns,
column width 2, default `IceProfile`, origin 24, one column at rate 0, 120 frames at 1/60 s.
With the dead column at 28, 30 or 31 the far bank stays open water, which is correct. With
it at **29 or 33, column 47 ends up solid**: the front crossed the dead column. The dead
column itself stays at 0 ice, so the bridge has a 2 px hole that collision treats as soft.
`test_a_front_stops_at_dead_water_and_resumes_when_it_wakes` passes only because its dead
column (30) happens to sit where the front's floating-point phase stops cleanly.

## Root cause

`ice_front.gd:161-163` (the right front; the left front at `:158-160` is the mirror image):
`crossing_right = floor(_right) + 1` is the only column whose rate is read, then
`_right += step * rates[crossing_right]`. If `frac(_right) + step * rate >= 2`, `_right`
passes `crossing_right + 1` without that column's rate ever being read. A lower frame rate
or a hitch (a larger `delta`) makes the jump longer, so any dead column in the path can be
skipped.

## Fix

Not fixed yet. Suggested fix: spend the step one column at a time.

```gdscript
func _advance_right(budget: float, rates: PackedFloat32Array) -> void:
	while budget > 0.0:
		var next := int(floor(_right)) + 1
		if next >= _ice.size():
			_right = float(_ice.size() - 1)
			return
		var rate := rates[next]
		if rate <= 0.0:
			return
		var to_boundary := float(next) - _right
		var move := minf(budget * rate, to_boundary)
		_right += move
		budget -= move / rate
```

The left front uses the mirror image. `budget` is `grow_speed / column_width * delta`.

## Prevention

Add a test that sweeps the dead column across every index past the origin, and also runs
at 30 fps and at a single 0.1 s hitch. Assert that the column beyond the dead one never
becomes reached. A single hand-picked index cannot prove a rule about arbitrary positions.

## Fix

Fixed in c45784b (2026-09-22): `_advance_front` spends the step one column at a time, stopping at the first column with rate 0. `test_no_dead_column_is_ever_leapt` puts the dead column at every index at 60, 30 and 10 fps.
