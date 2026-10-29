---
id: bugs/the-lucidity-leap-lands-outside-the-frame-so-its-land-clip-is-not-seen
type: bug
title: The lucidity leap lands outside the frame, so its new land clip is seldom seen
status: active
severity: low
tags: [guardians, lucidity, leap, camera, animation, grd-07]
related: [systems/guardians, features/lucidity-leap, playtests/2026-10-29-grd07-round2, playtests/2026-10-29-grd07-guardian-art]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/guardian_animation_resolver.gd
  - scenes/world/camera.gd
---

## Summary

Since GRD-07 the leap ends in a `leap_land` clip (Bloom 0.3 s, Frost 0.4 s). The guardian comes
down 440 px from Ivo while the camera still frames Ivo alone. The camera starts pairing only at
touchdown (`call_staged`). The land clip is over before the camera brings the guardian into view.
The user's complaint was "the jump animation must look better", so the new landing frames should be visible.

## Reproduction

`tools/playtest/scripts/guardian_fight_bot_driver.gd` with `guardian_bot_bloom.json` and
`guardian_bot_frost.json` (`BOT_GOD=1`), lucid burst every 0.1 s. The `[shot]` lines give the
guardian's screen x at touchdown (game px, view 0..640). The `[spr]` lines give the clip times.

| Leap | Touchdown screen x | Body half-width | `leap_land` seen |
|---|---|---|---|
| Bloom 1 (11.58 s) | 882 | 22 | no: the stag is fully off screen until ~12.1 s, and the clip ends 11.88 |
| Bloom 2 (33.12 s) | -42 | 22 | only its last ~0.2 s, sliding in |
| Frost 1 (12.49 s) | 882 | 60 | no: the clip ends 12.9 s and the golem enters at ~12.95 |
| Frost 2 (33.09 s) | -42 | 60 | an 18 px sliver, then half the body for the last ~0.2 s |
| Frost 3 (53.91 s) | 682 | 60 | a sliver, then the punch-forward frame half visible (54.05) |

Screenshot: `playtests/screenshots/2026-10-29-grd07-round2/bloom_leap_lands_off_frame.png`. The
call sheet is already up and Ivo stands alone. The stag walks in from the right edge in its lucid clip.

## Cause

The pairing waits for the landing (`features/lucidity-leap`: "only the landing stages the call"),
and the camera glide takes ~0.6 s. A pair 440 px apart fits the 640 px view (midpoint ±220,
plus a 60 px half-width = 280 < 320), so the cut is timing, not distance.

## Fix direction (not decided)

Either start the pair (or the glide toward the landing x) at take-off or at the apex, so the camera
arrives as the guardian comes down. Or hold `leap_land` until the guardian is inside the view. That
is a design call on `features/lucidity-leap`, so it is not a code-only fix.
