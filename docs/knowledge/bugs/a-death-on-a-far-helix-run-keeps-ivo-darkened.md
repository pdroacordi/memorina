---
id: bugs/a-death-on-a-far-helix-run-keeps-ivo-darkened
type: bug
title: Ivo dying on a far helix run keeps DepthLook's far shade for the whole death beat
status: resolved
severity: low
tags: [helix, stair, depth-look, death, sprite]
related: [systems/helix-stair, systems/life-benches-death]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/components/depth_look.gd
---

## Summary

`DepthLook` writes `self_modulate` from `near` and `far_shade` every step, and only
`Player._show_depth()` (player.gd:317) updates those values. The death branch of
`_process_motion` returns at player.gd:270-276, before `_show_depth()`, so the release in
`_on_health_died` (player.gd:947) never reaches the look.

## Symptom

Found in review of WORLD-26 (2026-10-11). Reasoned from the code. When Ivo is killed on a far run
(`near` 0, `far_shade` 0.7), the corpse falls down the shaft and plays the death clip at 70%
value until the fade.

## Fix

Reset the look when the rider is released: call `_show_depth()` from `_on_health_died` after
`_rider.release()`, or set `near = 1.0` there.

## Prevention

A look driven by pushed values needs a push on every path that ends the state, including early
returns.

## Resolution

Fixed 2026-10-11 (WORLD-26). `Player._on_health_died` calls `_show_depth()` after releasing the rider. Test: `player_helix_test.test_a_death_while_riding_restores_his_look`.

Moot since the rotating-helix revision (2026-10-11): `DepthLook` and the far runs are gone, so Ivo is never darkened on the stair. A death now holds the corpse on its tread; the world swap frees it (`player_helix_test.test_a_death_holds_the_corpse_on_its_tread`).
