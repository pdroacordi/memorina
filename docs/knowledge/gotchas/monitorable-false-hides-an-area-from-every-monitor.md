---
id: gotchas/monitorable-false-hides-an-area-from-every-monitor
type: gotcha
title: An Area2D with monitorable = false is invisible to EVERY monitoring area, so i-frames keyed as Hurtbox:monitorable also hide the body from hazards and triggers
status: active
tags: [area2d, monitorable, hurtbox, i-frames, animation, physics]
related: [bugs/roll-iframes-hide-the-water-so-the-pool-floor-becomes-safe-ground, gotchas/animationtree-reset-track-overwrites-script-writes]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/combat/hurtbox/hurtbox.gd
  - scenes/characters/ivo/ivo.tscn
---

## Summary

`monitorable` does not target only the areas that want to hurt you. Setting it to false
hides the area from every other area's `area_entered` and `get_overlapping_areas()`.

The project uses `Hurtbox:monitorable = false` as Ivo's i-frames, keyed in three clips:
`roll` (the whole clip), `hurt` (the first 0.333 s) and `death`. During those windows Ivo
does not exist for ANY area that detects hurtboxes. That hides him from Hitboxes, which is
the intent. It also hides him from `HazardZone`, whose doc says it ignores i-frames.

## Details

- Script-side i-frames (`Hurtbox.grant_invulnerability`, a timer) can be ignored by a
  receiver, and `receive_hazard` does ignore them. Clip-side i-frames (`monitorable`) are
  enforced by the physics server before any script runs, so no receiver can see through
  them.
- If the areas still overlap when monitorable goes false and then true again, the change
  is reported as an exit followed by a fresh enter on the next flush. A clip that
  flickers `monitorable` therefore turns one contact into several. Ivo's `hurt` clip
  does this in water, and the `_sinking` guard absorbs the extra report.
- A trigger that means "the body is HERE" (water, a kill plane, a room) should detect
  the CharacterBody2D with `body_entered`. A clip never keys the body's collision.

## Gotchas / pitfalls

`RESET` owns `Hurtbox:monitorable`
(gotchas/animationtree-reset-track-overwrites-script-writes), so a script cannot turn it
back on to let a hazard through. Change what the hazard detects instead.
