---
id: playtests/2026-11-18-grd14-frost-fight
type: playtest
title: GRD-14 Frost fight on the engine - bot and dodging-driver runs; the slam and the owned charge looped until they stopped following themselves; the charge-back follows every owned charge after the review
status: done
tags: [grd-14, guardian, frost, playtest, bot]
related: [systems/guardians, bugs/the-frost-charge-recall-opened-as-its-fists-already-touched-ivo, bugs/a-prompt-roll-on-a-frost-charge-thrown-from-170-220-px-runs-out-of-grace-before-the-fists-arrive, playtests/2026-11-18-grd12-engine-regression, playtests/2026-11-18-grd13-bloom-fight]
created: 2026-11-18
updated: 2026-11-18
area_tested: "lake_frost_arena (Frost Guardian): whole bot fight to RESTORED; the dodging driver to RESTORED"
source_files:
  - tools/playtest/scripts/guardian_fight_player_driver.gd
  - resources/characters/guardians/frost_guardian/frost_guardian_stats.tres
---

# GRD-14 Frost fight

Runs one window at a time, `APPDATA` redirected per run and checked with a headless `OS.get_user_data_dir()` probe. Bot: `guardian_fight_bot_driver.gd` with `guardian_bot_frost.json`, `BOT_GOD=1`. Driver: `guardian_fight_player_driver.gd`, extended for Frost: it backs out of the swipe string and the slam, jumps the ice wave and the landing shock with the row rule, steps out of an icicle's glint by 24 px and the body drop's shadow by 72 px (never into the golem's body), and jumps an owned charge's fists from its timing (`PL_CHARGE=jump|roll`). `PL_GOD=1`, on a copy of the timeline with `max_duration` 240. Numbers below are from the final kit (after the GRD-14 review: the charge-back turns after passing Ivo, a jump clears the slam, the roll's recall is timed by the lunge).

## Bot

| run | restored | hits | causes | moves |
|---|---|---|---|---|
| GRD-12 regression | 66.2 s | 8 | - | swipe, slam, charge, swipe |
| GRD-14 final | 60.1 s | 7 | swipe 3, icicle 2, slam 1, contact 1 | stage 0 slam, swipe, charge (the roll); stage 1 icicle fall 1, swipe 2; stage 2 icicle fall 2, swipe 1 |

The bot attacks and never dodges, so it opens each window in about 8 s of pressure: few moves per stage. Its icicle hits are glints it stood in; its contact hit came when an icicle's knockback threw it into the body. The recall opened 0.27 s into a charge thrown from 63 px (0.25 s before the fists) and the roll came 0.06 s later.

## Dodging driver

| stage | pressure | busy | idle between moves | moves |
|---|---|---|---|---|
| 0 | 40.8 s | 69 % | mean 0.92 s, max 1.13 | swipe 6, slam 4, charge 4 |
| 1 | 60.7 s | 75 % | mean 0.69, max 0.82 | icicle fall 8, swipe 8, slam 3, charge 2 (charge-back 2) |
| 2 | 69.7 s | 79 % | mean 0.60, max 0.75 | icicle fall 10, swipe 5, charge 4 (charge-back 4), slam 3, body drop 2 |

Restored at 208.7 s with 2 hits: an owned charge whose fists caught the driver's late jump (96 px up; its timing rule, not the game) and the body drop's body, when the driver stepped toward the golem out of the shadow. The charge-back followed 6 of 6 owned charges from stage 1; each started 19-239 px from Ivo, on screen, and ended 48 px past him. No swipe chained: the driver backs out of every swipe wind-up.

## Found and fixed

- **The slam looped**: the wave makes Ivo jump, the jump lifts him past the other moves' reach up, and the overhead branch picked the slam (150 px up then) again: 16 slams in a row at stage 1, 39 at stage 2. `frost_slam.repeats` false.
- **The owned charge looped**: it runs about 300 px past Ivo, where at stage 0 only the charge reaches him, so the far pick chose it again: 69 charges in 238 s. `frost_charge.repeats` false.
- **The roll recall opened with the fists already on Ivo**: `bugs/the-frost-charge-recall-opened-as-its-fists-already-touched-ivo`, then `bugs/a-prompt-roll-on-a-frost-charge-thrown-from-170-220-px-runs-out-of-grace-before-the-fists-arrive`. The recall now opens 0.25 s before the lunge reaches Ivo.
- **The charge-back rarely followed** (at the wall: 0 of 6 owned charges from stage 1 in a 1280 px arena). After the user's "Turn after passing Ivo (Recommended)" it chained in 1 of 9: the link was judged with Ivo still in the air from jumping the fists, above its 96 px reach up. `attack_height` 200. With a 0.45 s telegraph the golem then slid about 90 px on and began the second charge 284 px from Ivo, off screen; the link now has no telegraph and holds the golem still through its skid and turn.

## After the feel playtest's fixes (2026-11-18)

Fixes from `playtests/2026-11-18-grd14-frost-feel` (`systems/guardians`, "The Frost Guardian's fight"): the charge-back's held 0.5 s wind-up, the body that spares a carried-onto Ivo and the skid that stops short of him, the slam's fists-only box and early pose, the shorter contact capsule for the pogo, one note per move, distinct slam and icicle wind-ups, the icicle mark, the second swipe's step-in, the icicle and swipe weights, the 150 px shadow, a teaching blow's hit closing the recall, `PL_LEARNED`.

| run | restored | hits | notes |
|---|---|---|---|
| bot (`BOT_GOD`) | 65.3 s | 7: swipe 3, charge 2, slam 1, body drop 1 | 3 of 4 swipes chained into the second swipe and the slam |
| driver (`PL_GOD`) | 186.7 s | 1: a swipe while backing off | charge-back after 6 of 8 owned charges from stage 1, 0 hits by it |
| driver, no god | 167.5 s | 0 | |
| driver, `PL_SWIPE=jump` | 180.6 s | 0 | 0 of 13 swipes chained: a jumped swipe ends the string (an earlier weight set) |

Dodging driver, per stage (moves counted per strike, links included):

| stage | pressure | busy | idle mean / max | mix |
|---|---|---|---|---|
| 0 | 41.9 s | 70 % | 0.85 / 1.10 s | swipe 53 %, slam 27 %, charge 20 % |
| 1 | 60.1 s | 77 % | 0.72 / 0.78 s | charge 27 %, icicle fall 23 %, charge-back 18 %, swipe 18 %, slam 14 % |
| 2 | 47.4 s | 79 % | 0.58 / 0.66 s | swipe 33 %, body drop 28 %, icicle fall 11 %, charge 11 %, charge-back 11 %, slam 6 % |

Stage 0 has three moves and the owned charge never follows itself, so the swipe is half of it. The swipe chain rate against this driver is 0 of 18: it backs out of every swipe wind-up for its whole length.

## What screenshots cannot show

Camera feel and latency were not judged; these runs are numbers. In the frames the icicle's glint reads as a white square on the cave's dark rock, and the floor warnings stand over the grass.

## Independent feel pass (2026-11-18)

A separate playtester session judged this kit with its own policies: no roll and no double jump, wall-pinned, roll owned,
delayed recall presses, and the pogo. See `playtests/2026-11-18-grd14-frost-feel`. It filed five bugs:
- the far charge's close charge-back hits Ivo as he lands from jumping the fists;
- the charge's recovery skid ends on a rolled or pinned Ivo, and its contact resumes at once;
- the slam's last ~0.1 s of wind-up is not jumpable;
- the arena ceiling leaves 26 px over the golem's head for a pogo;
- one body drop cost two notes through its contact box.
