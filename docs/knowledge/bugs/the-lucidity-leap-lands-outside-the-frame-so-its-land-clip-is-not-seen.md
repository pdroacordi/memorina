---
id: bugs/the-lucidity-leap-lands-outside-the-frame-so-its-land-clip-is-not-seen
type: bug
title: The lucidity leap lands outside the frame, so its new land clip is seldom seen
status: resolved
severity: low
tags: [guardians, lucidity, leap, camera, animation, grd-07]
related: [systems/guardians, features/lucidity-leap, playtests/2026-10-29-grd07-round2, playtests/2026-10-29-grd07-guardian-art, playtests/2026-10-30-grd09-leap-framing]
created: 2026-10-29
updated: 2026-10-30
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/guardian_animation_resolver.gd
  - scenes/world/camera.gd
  - scenes/characters/ivo/player.gd
  - scenes/world/game.tscn
  - tests/scenes/characters/guardians/guardian_leap_framing_test.gd
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

## Fix direction (decided 2026-10-30)

Either start the pair (or the glide toward the landing x) at take-off or at the apex, so the camera
arrives as the guardian comes down. Or hold `leap_land` until the guardian is inside the view. That
was a design call on `features/lucidity-leap`. The user chose "Câmera na decolagem" (2026-10-30).

## Also seen in the GRD-08/STORY-18 playtest (2026-10-30)

STORY-18's bark opens on `lucid_landed`, so the first bark of each fight opens while the guardian
is still off screen. The balloon is clamped to the screen edge with its tail pointing at nothing.
Measured from `[shot]` positions (0.25 s resolution): the guardian is fully on screen only +0.71 s
(Bloom) and +0.95-1.05 s (Frost) into the 2.16 s bark, against +0.2 s for every later bark. Before
the landing, the frame holds only Ivo for ~1.5 s (leap apex to touchdown). Details:
`playtests/2026-10-30-grd08-story18-guardian-clips-and-talks`.

## Fix (GRD-09, 2026-10-30)

The camera pairs at take-off; the call is still staged at the landing. `Guardian._begin_lucidity_leap` calls
`_frame()` -> `Player.frame_call(self)` -> `call_framed`, and `game.tscn` connects `call_framed` (not
`call_staged`) to `GameCamera.frame_pair`. `stage_call` calls `frame_call` too (a no-op when already framed), so a
timed-out leap still pairs. `_unstage()` releases when framed or staged, so a call abandoned mid-leap releases the
frame. The 0.8 s pair blend ends inside the ~1.7 s flight, and the midpoint follows the guardian's x, so the frame
stops on the touchdown frame with the guardian at screen x ~80 or ~552.

The apex is not framed. The frame blends x only. Fitting the 340 px rise plus the body would need a zoom near 0.65,
which shows past a one-screen arena's room clamp. The guardian still leaves through the top for ~0.7 s (feet above
screen y 0) and drops back in where it lands.

Test: `guardian_leap_framing_test` (Bloom, Frost: framed while leaping, staged when grounded, whole body inside
`view_rect()` at touchdown; an abandoned leap releases). With the take-off frame removed, Bloom lands 251 px outside.

Evidence (`playtests/2026-10-30-grd09-leap-framing`, `guardian_fight_talk_driver.gd`, `BOT_GOD=1`,
`BOT_LUCID_MS=100`, 5 leaps):

| Leap | Take-off -> touchdown | Guardian x over the arc | Touchdown x (Ivo x) | Feet above the top |
|---|---|---|---|---|
| Bloom 1 | 9.19 -> 10.92 | 78..337 | 80 (538) | 9.64-10.34 |
| Bloom 2 | 31.21 -> 32.94 | 282..554 | 552 (92) | 31.67-32.37 |
| Frost 1 | 10.63 -> 12.36 | 345..556 | 556 (90) | 11.10-11.81 |
| Frost 2 | 32.99 -> 34.71 | 86..348 | 89 (548) | 33.45-34.15 |
| Frost 3 | 55.45 -> 57.17 | 295..551 | 551 (93) | 55.90-56.61 |

The guardian's whole body is inside 0..640 in x in every shot of every arc. `leap_land` plays in frame on all five
landings. Every bark opens with the guardian on screen (bark `g=` x 78, 554, 556, 86, 545) and its tail at the head.
Screenshots: `playtests/screenshots/2026-10-30-grd09-leap-framing/`.
