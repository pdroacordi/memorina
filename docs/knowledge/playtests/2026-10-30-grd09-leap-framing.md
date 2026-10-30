---
id: playtests/2026-10-30-grd09-leap-framing
type: playtest
title: GRD-09 - the camera pairs at the leap's take-off, so every landing, land clip and first bark is in frame
status: active
build: 551fd44 + uncommitted GRD-09 working tree (guardian.gd, player.gd, game.tscn)
area_tested: "spring_woods/bloom_hollow (Bloom, Ivo from -6560), frozen_lake/lake_frost_arena (Frost, Ivo from 5130): whole fights to RESTORED and the talks"
tags: [guardians, grd-09, lucidity, leap, camera, bark, playtest]
related: [systems/guardians, features/lucidity-leap, bugs/the-lucidity-leap-lands-outside-the-frame-so-its-land-clip-is-not-seen, playtests/2026-10-30-grd08-story18-guardian-clips-and-talks]
created: 2026-10-30
updated: 2026-10-30
screenshots:
  - screenshots/2026-10-30-grd09-leap-framing/bloom_leap_1.png
  - screenshots/2026-10-30-grd09-leap-framing/frost_leap_1.png
---

## Setup

`tools/playtest/scripts/guardian_fight_talk_driver.gd` with `guardian_bot_bloom.json` and `guardian_bot_frost.json`
(`max_duration` 260), `BOT_GOD=1`, `BOT_LUCID_MS=100` (new driver env: lucid-burst shots every 0.1 s). The driver
now also logs `SIG call_framed` and shoots a `framed` frame. Both runs reached RESTORED and both talks. The only
error in the logs is the engine's exit-time resource count.

## Findings

- **The frame pairs at take-off.** `call_framed` fires 1.05 s after LUCIDITY opens (the `lucidity_delay`), and
  `call_staged` fires 1.72 s later, on touchdown.
- **The guardian stays in frame in x for the whole arc.** On all 5 leaps its whole body (Bloom half-width 22,
  Frost 60) is inside 0..640 in every shot. It lands at screen x 80, 552, 556, 89 and 551, with Ivo at the other
  edge (92-548). Before the fix, landings were at x 882 or -42.
- **The land clip is seen.** The camera stops moving on the touchdown frame, so `leap_land` (dust, the Frost
  punch-forward frame) plays in view on every landing (contact sheets, rows 2-3).
- **The bark points at the guardian when it opens.** Bark `g=` x is 78, 554, 556, 86 and 545. The tail reaches
  the head from the first frame the balloon is drawn. The driver's `bark_open` shot is one frame behind, so the
  balloon shows in the next shot.
- **The empty frame is shorter but not gone.** Ivo is alone in frame only while the guardian is above the top:
  feet above screen y 0 for ~0.7 s around the apex (Bloom 9.64-10.34, Frost 11.10-11.81). Before, this lasted
  ~1.5 s plus the off-screen landing. The camera pans toward the landing side during that time, so the frame
  keeps moving. Framing the apex would need a zoom near 0.65, which shows past the one-screen arenas.

## Camera feel (inferred from the `[shot]` positions, not watched)

The glide starts with the jump, so the pan reads as following the leap rather than reacting to the landing. The
pan ends on the touchdown frame, together with the landing shake.
