---
id: bugs/the-mentor-guardian-hits-a-still-ivo-1-8-s-after-the-awakening-hands-back-control
type: bug
title: After mentor_wakes the guardian advances at once, telegraphs 0.8 s and lands a hit 1.8 s after control returns, while the frame is still zooming out
status: fixed
severity: medium
tags: [guardian, fight, cutscene, pacing, mentor, lighthouse, story-38]
related: [playtests/2026-11-17-story38-the-keeper-wakes, architecture/story38-the-keeper-wakes, architecture/grd-06-final-battle, systems/guardians, systems/cutscenes]
created: 2026-11-17
updated: 2026-11-17
source_files:
  - resources/cutscene/story/mentor_wakes.tres
  - scenes/characters/guardians/guardian.gd
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
---

## Summary

STORY-38 exists because "a luta poderia demorar um pouquinho pra começar para o jogador poder assimilar o que está
acontecendo" (user, 2026-11-17). The scene gives that time, but the fight then starts at full speed. The scene leaves Ivo
on `ivo_stand`, 104 px from the body. On the first frame of PRESSURE the guardian walks at him and telegraphs while the
camera is still zooming out. A player who let go of the controls during the scene takes the first hit 1.8 s after control
returns.

## Symptom

Per-frame probe (`tools/playtest/scripts/story38_keeper_wakes_probe_driver.gd`), times from the frame the fight leaves
DORMANT (the scene's end, the body's first frame):

| Run | Guardian moves | Bars gone | Zoom back to 1 | Telegraph | Swing | Hit (Ivo standing) |
|---|---|---|---|---|---|---|
| `story38_keeper_wakes` | +0.02 s | +0.40 s | +0.77 s | +0.80 s | +1.36 s | +1.80 s |
| `story38_keeper_wakes_skip` | +0.03 | (cut) | (cut) | +0.79 | +1.34 | +1.77 |
| `story38_keeper_wakes_retry` (2nd attempt) | +0.03 | +0.40 | +0.77 | +0.80 | +1.35 | +1.78 |

The first telegraph starts on the frame the zoom lands. Screenshots: `06_first_telegraph_0_8s.png`, `07_first_hit_1_8s.png`.

## Why it matters

Reaction time is not the problem: 0.8 s of telegraph is the fight's normal tell. The problem is that the tell begins
before the player has seen the whole room at zoom 1. During the scene's cutscene bars the player is a viewer, and the hit
lands within two seconds of becoming a player again. That is the "não espera" moment the user wanted to soften, moved
two seconds later.

## Fix

Fixed 2026-11-17 (uncommitted). New `GuardianStats.opening_hold` (scaled seconds, default 0; `mentor_stats.tres` 1.5). `GuardianFight.begin()` arms it and `GuardianFight.tick()` counts it down, so the pure fight still owns the clock. `is_opening()` holds meanwhile, and `opening_ended` fires once when the hold runs out or a hit cuts it short. `Guardian._on_player_entered` sets `_ai.active = not _fight.is_opening()`, and `Guardian._on_opening_ended` turns the AI on. The other four guardians are unchanged. Tests: `guardian_fight_test` (`test_the_opening_hold_runs_out_on_the_fight_clock`, `test_a_hit_ends_the_opening_hold`, `test_no_opening_hold_by_default`) and `mentor_wakes_test.test_the_fight_opens_with_the_guardian_idle` (the AI stays off and the body still for 1.4 s, then acts). Not yet re-measured in a playtest.

Verified in a playtest 2026-11-17 (second run of `playtests/2026-11-17-story38-the-keeper-wakes`). From the fight's first frame, the body first moves at +1.55 s, telegraphs at +2.29-2.32, swings at +2.87 and hits a still Ivo at +3.30. That held in the played, skipped, jump-entered and retried scenes, against +0.02 / +0.80 / +1.36 / +1.80 s before the fix. The ending of the hold by a hit was not exercised in play.

## Fix direction (for the owner; not tried)

- Hold the body in its idle for ~1.5-2 s after the fight leaves DORMANT (or until the zoom-out is done plus ~1 s) before
  its first approach or move. `GuardianStats` has no opening delay today; a per-fight `opening_hold` would serve any
  guardian entered from a scene.
- Or end the scene with Ivo further from the body (more than the move's reach plus one approach step).
- Do not fix it by lengthening the scene: the scene's own pacing is about right (see the playtest).
