---
id: gotchas/a-typed-array-of-an-inner-class-is-refused-from-another-script
type: gotcha
title: A typed array of an inner class built in another script is refused as the same type ("should be Array[Seat] but is Array[Seat]")
status: active
tags: [typing, typed-array, inner-class, class-name, parse-error]
related: [systems/backdrops]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - scenes/world/environment/backdrop/backdrop_seams.gd
  - scenes/world/environment/backdrop/backdrop_seam_room.gd
  - scenes/world/environment/backdrop/backdrop_cut.gd
---

## Summary

`static func cuts(seats: Array[Seat], ...)` in `BackdropSeams`, called from a test with an
`Array[BackdropSeams.Seat]`, failed to parse in Godot 4.7: `Invalid argument for "cuts()"
function: argument 1 should be "Array[Seat]" but is "Array[Seat]"`. Spelling the parameter
`Array[BackdropSeams.Seat]` inside the class did not help, and an inner class named `Seat` also
"hides a global script class" (the bench's `Seat`).

## Fix

Give a type that crosses scripts inside a typed array its own file and `class_name`
(`BackdropSeamRoom`, `BackdropCut`). Check the global class list before naming an inner class.
