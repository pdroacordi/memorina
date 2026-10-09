---
id: gotchas/glsl-floor-division-modulo-can-return-the-divisor
type: gotcha
title: A GLSL floored modulo written as v - n * floor(float(v) / float(n)) can return n (not 0) at exact multiples, because shader float division may be off by up to 2.5 ULP; GDScript's posmod never does
status: active
tags: [shader, glsl, modulo, precision, texelfetch, backdrop]
related: [gotchas/glsl-gdscript-math-must-be-duplicated, systems/backdrops]
created: 2026-10-08
updated: 2026-10-08
source_files:
  - scenes/world/environment/backdrop/backdrop_layer.gdshader
  - scenes/world/environment/backdrop/backdrop_math.gd
---

## Summary

GLSL and the Vulkan SPIR-V environment allow `x / y` to be off by 2.5 ULP. Drivers commonly
compile it as `x * rcp(y)`. For `v = k * n`, the quotient can come out just under `k`, so
`floor()` gives `k - 1` and the "modulo" returns `n`. That is one past the last valid index.
The GDScript twin (`posmod`) is exact, so the two disagree at that value.

## Details

- `backdrop_layer.gdshader` `wrap()` uses this form for `repeat_x` columns and `REPEAT` rows.
  An output of `n` makes `texelFetch` read column `n` (out of range, undefined) or row
  `strip_h`, which is row 0 of the next season's band.
- The result is exact when `n` is a power of two, because `rcp(2^m)` is exact. Every current
  wrap is safe for that reason: `pine_woods` repeats only along x, at width 1024, and uses no
  `REPEAT` rows. A 346-row legacy strip set to `REPEAT`, or any non-power-of-two width with
  `repeat_x`, is exposed.
- Not observed on hardware. It is a spec allowance, and drivers differ.

## Gotchas / pitfalls

- Clamp the result after the float path: `if (r >= n) r -= n; if (r < 0) r += n;`. Or
  require power-of-two strips in the art contract and in `BackdropLayer.problems()`.
- Integer `%` is not a fix on its own: GLSL leaves it undefined for negative operands.
