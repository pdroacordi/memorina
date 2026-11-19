---
id: bugs/a-hit-at-the-lanterns-west-wall-knocks-ivo-into-the-mentor
type: bug
title: An icicle aimed at Ivo always knocks him east, so at the lantern's west wall it throws him into the mentor, whose body hits him again as his i-frames end
status: fixed
severity: low
tags: [guardians, mentor, grd-17, knockback, icicle, contact, hitbox, fairness]
related: [systems/guardians, playtests/2026-11-19-grd17-mentor-feel, bugs/the-mentors-ice-wave-parks-at-the-lanterns-west-step-on-a-pinned-ivo]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - scenes/combat/hitbox/hitbox.gd
  - scenes/characters/guardians/spawns/falling_shard/falling_shard.gd
  - scenes/characters/guardians/guardian_body_contact.gd
---

## Symptom

At the lantern's west wall, one hit often costs two notes. An icicle, or the wave parked at the step
(`bugs/the-mentors-ice-wave-parks-at-the-lanterns-west-step-on-a-pinned-ivo`), hits Ivo at x 10987-11021. The knockback
(360-460 px/s, lift 120) carries him 45-57 px east, into the mentor's body standing 50-90 px away. The contact box hits
him **0.90 s later**, the moment his i-frames end. In 15 logs this happened **10 times in 134 hits**, every time at the
west wall: 6 after an icicle, 4 after a parked wave. A still or slow player loses 2 of 3 notes to one mistake.

A player can avoid the second hit: knockback control returns after 0.18 s (`Character.knockback_time`), and walking 36 px
out of the body takes ~0.19 s. The driver stood still in all 10 cases. So this is a trap, not an unavoidable hit.

## Root cause

`Hitbox._push_direction` (hitbox.gd:74-81) pushes along `sign(target.x - hitbox.x)` and falls back to `sign(scale.x)`
when the two are aligned. A `FallingShard` is aimed at Ivo's x (`aimed()`), so it lands aligned and always pushes him to
+x (east). At the east wall that pushes him into the wall. At the west wall it pushes him toward the open floor, where
the mentor stands. `GuardianBodyContact` holds the body harmless only for an Ivo whom the guardian's own move carried
onto him. It does nothing for an Ivo knocked into the body by a spawn.

## Fix

Fixed in GRD-17's fix round (2026-11-19). `Hitbox.thrower` (set by `GuardianSpawner.adopt` to the guardian) decides the
side of an inside hit: a hit landing nearly straight down on Ivo pushes him away from the guardian that threw it, not
along the box's own facing. Chosen over "no sideways push for a hit from above" because a vertical push lands Ivo back in
what hit him, the very thing `Hitbox._push_direction` exists to prevent (systems/guardians, "A hit carries you OUT of
what hit you"); the push keeps its strength and lift, only its side changes. A box with no thrower (a guardian's own
move box, any creature) is unchanged. Test: `hitbox_test.test_an_aligned_hit_pushes_away_from_its_thrower`.
The push's side changes only for a hit inside the box; `Character`'s knockback (`apply_knockback`, `knockback_time`, damping, i-frames) is untouched, and so is the push's strength and lift.

## Prevention

A combat test: an aligned falling shard must not push Ivo toward the guardian that threw it.
