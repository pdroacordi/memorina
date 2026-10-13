---
id: bugs/the-baked-wheel-and-gear-hitch-at-their-loop-seam
type: bug
title: RotationBake assumed one symmetry period returns the still, so the water wheel and the mill gear jumped at their loop seam every 1.25 s
status: resolved
severity: medium
tags: [art, props, rotation, bake, ambient-motion, world-11]
related: [systems/props, architecture/props-and-ambient-life]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - tools/art/rotation_bake.gd
  - tools/art/bake_rotation.gd
  - tests/tools/art/rotation_bake_test.gd
---

## Summary

The bake turned the still by `period * i / count` for 12 frames and played them in a loop, so frame 0 had to equal the
still turned by one period. A Codex wheel is not exactly 8-fold symmetric, so it did not: the wrap from frame 11 to 0
changed far more pixels than a normal step. The squared frame also put the pivot half an art px off the still's centre
when its sides had different parity (the wheel is 54x51 art px).

Measured in game px per step (WORLD-11 review, 2026-10-13): the wheel's wrap 4,992 against a median of 3,432 (ratio
1.45); the gear's 1,512 against 728 (2.08). At 9.6 fps that is a visible jump every 1.25 s.

## Fix (2026-10-13)

`RotationBake.turned` reads every output point back into the first sector `[0, period)` of its source angle, so the
still is drawn from one sector repeated `360 / period` times. A turn by one period maps every point to the same source
point, and the loop closes by construction. The pivot is the still's own centre (half-integer for an odd side), not
the padded square's. `bake_rotation.gd` prints every step's changed pixels and the wrap ratio, and `rotation_bake_test`
bakes a lopsided still and holds its wrap step within 1.2 times the median step. After re-baking: the wheel's wrap is
4,304 against 4,176 (1.03), the gear's 792 against 736 (1.08). Each step now changes a little more than before, because
the sectors are redrawn from one.
