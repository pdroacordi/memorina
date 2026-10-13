---
id: bugs/one-swing-hits-the-brute-twice-when-its-shove-carries-it-out-and-back
type: bug
title: One running swing hits the Brute Shadow twice when its knockback carries it out of the box and back
status: resolved
severity: medium
tags: [combat, hitbox, hurtbox, brute-shadow, ivo, knockback, reach]
related: [systems/guardians, architecture/ivo-at-2x, bugs/a-hit-from-inside-pops-you-straight-up]
created: 2026-10-13
updated: 2026-10-13
source_files:
  - scenes/combat/hitbox/hitbox.gd
  - scenes/combat/hurtbox/hurtbox.gd
  - scenes/characters/enemies/brute_shadow/brute_shadow.tscn
  - scenes/characters/ivo/ivo.tscn
---

## Summary

`Hitbox` deals damage on every `area_entered`, so a target that leaves the box and comes
back while the box is still monitoring is hit again. Only the target's hurtbox
`invulnerability_time` stops this, and the brute's is 0. CORE-10 raised the running
swing 1 box 4 px (`ivo.tscn:1744`, (20, -53) -> (20, -57)) to follow the steel. Against the
brute's rounded hurtbox top that cut its reach from about 56 px to about 53, which is
less than the distance swing 1's shove carries the brute. The brute now slides out and
walks back in inside the same 0.1667 s window.

## Symptom

Playtest `tools/playtest/scripts/core09_brute_running_opener.json` (running slash then
backhand on `bait_brute`). On HEAD: hp 5 -> 4 at t=2.117 (swing 1), 4 -> 2 at t=2.429
(swing 2), 3 damage in total. With CORE-10: 5 -> 4 at t=2.113 at dx -53.2, then the brute is pushed
to dx -56.1 (t=2.173), comes back to -53.6, and is hit again at t=2.239 (4 -> 3, inside
swing 1's window 2.113-2.279). Swing 2 then takes it 3 -> 1, 4 damage in total.

## Root cause

- `hitbox.gd:30` `_on_area_entered` calls `_hit` on each entry. Nothing records that this
  activation already struck the hurtbox. The window is the clip's `Hitbox:monitoring`
  keys. A window is not a swing as far as the hitbox can tell.
- The brute's `Hurtbox` (`brute_shadow.tscn:576`) leaves `invulnerability_time` at the
  default 0. The guardians use 0.2 s, which covers every 0.1667 s sword window, so they
  never showed it.
- Sampled reach of running swing 1 against the brute hurtbox (capsule r 19, h 46 at
  (0, -25)): HEAD 56.1 px (57.0 with the 1.7 px knockback lift), CORE-10 53.1 (54.5). The
  shove's 56.1 px peak was inside the old box and is outside the new one. Swing 2 is
  unchanged at about 58.9.

The box placement itself is right: the steel in frames 2-3 spans y -76..-38, and the keys
match it. The defect is the hitbox's missing once-per-activation rule, which any
re-entry exposes. That also covers a brute walking back into an edge contact, and the 0.25 s pogo
window against the guardians' 0.2 s i-frames.

## Fix

Applied 2026-10-13. `Hitbox.strikes_once` (export, default false): an entry by a hurtbox
already struck since monitoring last turned on is ignored (`_struck`, by instance id). The
set clears on any physics frame with `monitoring` off; every Ivo clip keeps it off for at
least 5 frames between windows, and clearing on the rising edge would depend on whether
`area_entered` arrives before this node's `_physics_process`. Ivo's `Hitbox` sets it in
`ivo.tscn`. It is opt-in, not the default for every non-continuous hitbox, because the
brute's `CollisionHitbox` (contact damage) monitors permanently: a once-per-activation rule
there would hit Ivo once and never again. `tests/scenes/combat/hitbox/hitbox_test.gd`:
two entries in one window land one hit, a window with monitoring off between lands a
second, and a hitbox without `strikes_once` hits on every entry. Re-run of
`core09_brute_running_opener`: the opener deals 3 again (see the commit's playtest).

## Prevention

A hit window is defined by `monitoring` keys, but `area_entered` fires once per entry, not
once per window. Any hitbox that should hit once per swing has to track that itself and must not
rely on the target's i-frames. When a hitbox key moves, re-measure reach against every
target's hurtbox, including its rounded caps. Also compare that reach with the distance
the swing's own knockback moves the target. If the target can leave and come back within
the window, it gets hit twice.
