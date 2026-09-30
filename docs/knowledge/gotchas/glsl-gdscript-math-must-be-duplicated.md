---
id: gotchas/glsl-gdscript-math-must-be-duplicated
type: gotcha
title: GDScript and GLSL cannot share code — MemoryFieldMath and greyhush_common.gdshaderinc are the same formulas written twice
status: active
tags: [shader, glsl, greyhush, duplication]
related: [architecture/memory-field-cpu-gpu-split]
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/world/memory/memory_field_math.gd
  - scenes/world/memory/greyhush_common.gdshaderinc
---

## Summary

`MemoryFieldMath.source_distance()`/`disc_influence()` (GDScript) and
`gh_shape_distance()`/`gh_influence()` (GLSL, in `greyhush_common.gdshaderinc`) implement
the identical falloff math. There is no mechanism to share the implementation across the
two languages — changing one without the other desyncs gameplay logic from what's drawn.

## Details

Every tunable reaches the shader as a uniform sourced from `MemoryFieldMath`'s constants —
never re-type a number directly into the shader. This at least keeps the *tunables* in
sync even when the *formula* has to be hand-mirrored.

## Why this trips people up

It looks like an obvious refactor target ("just call the GDScript function from the
shader") and it is not possible — Godot shaders are a separate compiled language with no
FFI into GDScript. The duplication is a deliberate, accepted cost, not an oversight.

## Prevention

Any change to the falloff/influence shape must touch both files in the same commit. When
reviewing a diff to either file, always check whether its counterpart file changed too —
if only one did, that's very likely a bug, not a completed change.
