---
id: bugs/a-hit-from-inside-pops-you-straight-up
type: bug
title: Standing inside a guardian got you hit twice, because the shove was vertical
status: fixed
severity: high
tags: [combat, knockback, hitbox, feel, guardians]
related: [features/lucidity-leap]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/combat/hitbox/hitbox.gd
  - scenes/characters/ivo/ivo.tscn
---

## Summary

`Hitbox` knocks its target along `global_position.direction_to(target)`. For someone
standing BESIDE the box that is a clean shove sideways. For someone standing INSIDE it -
a guardian that has just landed on Ivo - the offset between the two centres is almost
entirely vertical, so the knockback is too: he pops straight up, lands back in the same
box, and is hit again the moment his i-frames lapse.

## Symptom

User: "when the boss jumps on me, i am kinda inside of the boss, and i get hit twice
before I can get out." Measured, standing dead centre in the Bloom Guardian with its
contact box live: hit at 0.00 s, still only 29 px away at 1.10 s, hit again.

## Root cause

Two halves, and the first guess (raise the i-frames) only addresses the smaller one. The
i-frames were already 0.6 s; what failed was the escape. The shove's horizontal component
was near zero, and even after forcing a floor on it the first fix was still only half
sideways - a 380 px/s knockback moved the body 29 px, not even clear of the bulk that
threw it.

## Fix

- Under `INSIDE_PUSH_X` (0.5) of sideways, the target counts as standing inside, and the
  push becomes decisively sideways - `Vector2(side, clamp(away.y, +/-INSIDE_PUSH_Y))` -
  toward whichever side they already lean, or the box's own facing when dead centre.
  `knockback_lift` is what gets them off the floor; the shove does not need the height.
- Ivo's `knockback_time` 0.18 -> 0.3 and `knockback_damping` 6.0 -> 4.0, so the impulse
  is allowed to carry; his hurtbox's `invulnerability_time` 0.6 -> 0.85; the guardians'
  contact knockback 380 -> 460.
- Being hit now calls `WorldFreeze.hit_stop()` as landing a hit already did, and every
  `Character` flashes `hurt_flash_color` (the guardians' flash moved up to the substrate
  as `Character.flash`, so there is one implementation).

Measured after: one hit in four seconds from dead centre, and he lands clear.

## Prevention

A knockback direction derived from two centres has no answer for the case where the two
centres are the same place. Any formula of the form "away from X" needs to say what it
does when the target is ON X. And when a hit "does not feel like enough", check what
distance it actually moves the body relative to the thing that threw it before reaching
for the damage or the i-frames.
