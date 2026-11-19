---
id: bugs/the-scattered-leaf-guardian-still-takes-sword-contact-so-a-pogo-bounces-off-thin-air
type: bug
title: While the Leaf scatter hides the scarecrow, its Hurtbox stays monitorable, so Ivo's sword still connects - a pogo bounces and every swing hit-stops and shakes the camera on an invisible body
status: resolved
severity: medium
tags: [guardians, autumn, leaf, grd-15, blink, intangible, hurtbox, monitorable, pogo, hit-stop, reset-track]
related: [systems/guardians, architecture/grd-12-guardian-fight-engine, gotchas/animationtree-reset-track-overwrites-script-writes, gotchas/monitorable-false-hides-an-area-from-every-monitor]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - scenes/characters/guardians/autumn_guardian/autumn_guardian.tscn
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/ivo/player.gd
  - scenes/combat/hitbox/hitbox.gd
---

## Summary

The scatter (`autumn_scatter.tres`, `attack_8`) hides `Sprite2D` for 0.15-0.45 s and `GuardianMover.is_intangible()`
covers the same span. The engine refuses the hit only in script: the `Hurtbox` stays monitorable. Ivo's sword still
connects with the hidden body. A pogo bounces off empty air, and every connect fires `Player.hit_landed`, which runs
`WorldFreeze.hit_stop` and a camera shake.

## Symptom

Found in the GRD-15 review by reading the code. To reproduce at stage 2: stand next to the scarecrow and swing, or pogo
on its head, while it scatters. Between 0.15 and 0.3 s it is gone from its spot, and between 0.3 and 0.45 s it is gone
from 64 px behind Ivo. The swing hit-stops and shakes the screen, and the pogo bounces as if it hit something. The
guardian takes no hit and does not flash.

## Root cause

- `autumn_guardian.tscn`: `Animation_RESET` keys `Hurtbox:monitorable` true (track 3). `Animation_attack_8` keys only
  `Sprite2D:visible` (false at 0.15, true at 0.45), not `Hurtbox:monitorable`.
- `guardian.gd:396` `_on_hit_received` returns early while `_mover.is_intangible()`. That runs after the contact, so
  the attacker's side has already reacted.
- `hitbox.gd:65-70`: `connected` is emitted for every touch on a hurtbox, and `hit_landed` for every touch on a hurtbox
  that is not invulnerable. The guardian's `Hurtbox` is neither invulnerable nor hidden.
- `player.gd:1747-1750` `_on_hitbox_connected` emits `hit_landed` (`game.tscn` sends it to `WorldFreeze.hit_stop` and
  `Camera2D.shake`) and, for `CTX_POGO`, calls `_pogo.try_bounce()`.

## Fix

Fixed in GRD-15 (2026-11-19). `Animation_attack_8` keys `Hurtbox:monitorable` false at 0.15 s and true at 0.45 s, the
same span as `Sprite2D:visible` and the blink's `fade` around `at` 0.3. `RESET` keeps owning the property, so the key
is the animation system's way to change it; no script writes it. Ivo's sword no longer connects with the hidden body:
no hit-stop, no shake, no pogo bounce. Test: `autumn_guardian_kit_test.test_the_scatter_shows_where_it_reforms_before_it_sweeps`
(the clip's `Hurtbox:monitorable` is false at the blink and true after the body is back). The rule for any later blink
move is in `systems/guardians`, "The scatter".

The `GreyhushShield` disc stays drawn while the body is hidden: a note for GRD-18.

## Options considered

Not fixed. Key `Hurtbox:monitorable` false in `attack_8` at 0.15 and true at 0.45, matching `Sprite2D:visible` and the
blink's `fade`. `RESET` already owns the property, so the key is the animation-system way to change it. Extend
`autumn_guardian_kit_test.test_the_scatter_shows_where_it_reforms_before_it_sweeps`: the clip's `Hurtbox:monitorable` is
false at `blink.at` and true after `back`, like the sprite. Any later blink move must do the same, because the engine's
`is_intangible()` gate does not cover the attacker's side.

## Prevention

"Intangible" has to cover both sides of a contact: the guardian refusing the hit, and the attacker never connecting.
When a clip hides the body, it also keys the hurtbox unmonitorable over the same span.
