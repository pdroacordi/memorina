---
id: bugs/perform-end-plays-after-the-camera-has-left-the-guardian
type: bug
title: perform_end and the first restored loop play after the camera has glided back to Ivo, off screen
status: resolved
severity: low
tags: [guardians, animation, camera, lesson, grd-08]
related: [systems/guardians, playtests/2026-10-30-grd08-story18-guardian-clips-and-talks, bugs/the-lucidity-leap-lands-outside-the-frame-so-its-land-clip-is-not-seen]
created: 2026-10-30
updated: 2026-10-30
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/guardian_animation_resolver.gd
  - scenes/world/camera.gd
---

## Summary

The guardian unstages its call on `performance_finished`, so the pair frame is released on the same
frame `perform` hands over to `perform_end` (one-shot, 4 x 0.2 s). The camera then glides back to Ivo,
who stands 440 px away. In the 0.6 s the clip lasts, the guardian slides off the left edge: Bloom is
wholly off screen after the first ~0.1 s, and Frost shows a sliver (its flute tip). The bow-out
GRD-08 drew for the lesson's end is not seen, and neither is the first `restored` loop, until the
player walks back.

## Reproduction

`tools/playtest/scripts/guardian_fight_talk_driver.gd`, `guardian_bot_bloom.json`, `BOT_GOD=1`. `[spr]`:
`bloom_perform` 43.19-104.53 s, `bloom_perform_end` 104.64-105.20, `bloom_restored` from 105.42.
`[shot]` guardian screen x: 58 at 104.64, -7 at 104.76, -44 at 104.89, -75 at 105.01, -93 at 105.13
(half-width 22). Frost (`guardian_bot_frost.json`, run frostA): `perform_end` 190.59-191.18, screen x 58 then -71
by 190.98 (half-width 60).

Screenshot: `playtests/screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/frost_perform_and_after_lesson.png`
(last tile, run frostB at 185.52 s, 0.27 s after its lesson ended: Ivo alone, the golem's flute tip at the left edge).

## Fix direction (not decided)

Hold the pair (or the lesson's frame) until `perform_end` has played, then release. Or start `perform_end`
during the track's ring-out, before `performance_finished`. Either is a staging call, close to GRD-09.

## Fix (2026-10-30)

`Guardian._on_lesson_finished` no longer unstages. It sets `_bowing`; `_after_move` unstages once the driver is past
`perform` and no longer holding `perform_end` (read before that frame's resolve, so `perform` is still current on the
frame the lesson ends). The pair frame therefore holds through the bow-out, and the camera glides back to Ivo as
`restored` starts. No timer, `WorldFreeze` writer or input reader: the clip is the clock, and a paused tree holds the
frame with it. `guardian_performance_animation_test` asserts nothing unstages on `performance_finished` and that
`call_unstaged` comes once, with `perform_end` finished.

Re-run: Bloom `perform_end` 102.48 s, unstaged 103.27 s, guardian at screen x 56-90 throughout; Frost `perform_end`
164.22 s, unstaged 165.04 s, guardian at x 549-581. Screenshots: `fix_round_bloom.png` (middle row),
`fix_round_frost.png` (middle left), in `playtests/screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/`.
