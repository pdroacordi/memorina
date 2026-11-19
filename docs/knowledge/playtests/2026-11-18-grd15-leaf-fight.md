---
id: playtests/2026-11-18-grd15-leaf-fight
type: playtest
title: GRD-15 Leaf fight on the engine - bot and dodging-driver runs; the hop was rebuilt to be walked under, the gust lost the guardian its sight, and jumps drew the hop until the dive came first
status: done
tags: [grd-15, guardian, autumn, leaf, playtest, bot]
related: [systems/guardians, bugs/the-leaf-gust-blows-ivo-out-of-the-guardians-sight-and-the-fight-stops, playtests/2026-11-18-grd12-engine-regression, playtests/2026-11-18-grd14-frost-fight]
created: 2026-11-18
updated: 2026-11-19
area_tested: "orchard_arena (Leaf Guardian): whole bot fight to RESTORED; the dodging driver to RESTORED, with and without god mode"
source_files:
  - tools/playtest/scripts/guardian_fight_player_driver.gd
  - resources/characters/guardians/autumn_guardian/autumn_guardian_stats.tres
---

# GRD-15 Leaf fight

Runs one window at a time, `APPDATA` redirected per run and checked with a headless `OS.get_user_data_dir()` probe. Bot: `guardian_fight_bot_driver.gd` with `guardian_bot_autumn.json` (double jump owned, wall climb not), `BOT_GOD=1`. Driver: `guardian_fight_player_driver.gd`, extended for the Leaf: it backs out of the sweep string (`PL_SWEEP=jump` jumps the sweeps late in their wind-up; pinned at a wall it always jumps them), double-jumps the claw when pinned, walks under the hop from 100 px out (away from closer, chosen once as it winds up), stands under the leaf blades on their way out and jumps one coming back once no other blade is still high over Ivo, steps out of the dive's shadow (through the guardian's x while it dives) and the scatter's swirl, and jumps an owned gust's floor blow. Numbers are from the final kit (systems/guardians, "The Leaf Guardian's fight").

## Bot

| run | restored | hits | causes |
|---|---|---|---|
| GRD-12 regression (old kit) | 87.8 s | 5 | - |
| GRD-15 final (`bot3`) | 86.8 s | 11 | sweep 3, gust 3, hop 3, dive 1, a blade between moves 1 |

The bot attacks and never dodges, so it opens each window in about 10 s of pressure. Its gust hits are the floor box at the far wall (it never climbs); the recall opened at the wall 6.6 s in and its press taught wall climb in the first gust.

## Dodging driver (`PL_GOD=1`, `pl11`)

| stage | pressure | busy | idle between moves | moves |
|---|---|---|---|---|
| 0 | 38.8 s | 67 % | mean 0.95 s, max 1.80 | hop 7, leaf blades 4, gust 2, sweep 1 |
| 1 | 31.0 s | 66 % | mean 0.93, max 2.80 | sweep 3, leaf blades 3, dive 3, gust 1, hop 1 |
| 2 | 26.2 s | 68 % | mean 0.81, max 2.19 | dive 3, gust 2, leaf blades 2, sweep 2, hop 1 |

Restored at 133.4 s with 2 hits: a hop thrown from about 100 px that landed on the driver walking under it, and a sweep the driver backed into from 83 px. No move was over 30 % of stage 1 or 2. At stage 0 a jump-happy player gets the hop and the blades in turn: he jumps the blades, the jump draws the hop (the overhead pick), and the hop does not follow itself. Earlier runs on the same kit showed the scatter (2 of 8 stage-2 strings in `pl8`, each followed by its sweep) and the full sweep, second sweep, overhead claw string (1-2 per run).

## Without god mode (`pl12`)

Ivo died at 13.8 s of stage 0 with 3 hits: a hop thrown while the driver was in the air jumping a blade, so it walked only 27 px of the 40 it needed to get out from under the landing; the teaching gust's floor blow, after the recall press gripped the wall and the driver slid back down into the band (it does not climb); and a sweep it backed into at 107 px, the box's edge. All three are the driver's limits (no wall climb, no reaction while airborne), but they show the Leaf's stage 0 punishes a player who is in the air when the hop comes: the board's "frantic" goal, at the cost of the first fight's margin. The Frost driver restored without god mode with 0 hits.

## Found and fixed

- **The hop could not be dodged by moving away** (`pl1`, `pl2`: 3 hits each). It was the legacy leap (impulse 375, 300 px/s) with boxes along the flight; it carried 240 px along the facing. Now a `LeapMotion` PAST_IVO, 8 px past, 110 px high, with only a landing box: walked under from 88 px out (`autumn_guardian_kit_test.test_the_hop_can_be_walked_under`).
- **The gust stopped the fight** (`pl7`): it left Ivo 930 px away at the far wall, beyond the 900 px sight, and the AI held mid-strike for the rest of the run. Sight is 1400 px (`bugs/the-leaf-gust-blows-ivo-out-of-the-guardians-sight-and-the-fight-stops`).
- **An owned gust drew every jump at stage 0** (`pl1`: 4 gusts at stage 0): its reach up was the default 96, the tallest stage-0 move. It is 24, what its floor box touches.
- **Jumps drew one move.** With the hop at 150 or the dive at 150, the tallest reaching move took 42-50 % of a stage (`pl3`: dive 5 of 12; `pl7`, `pl10`: hop 5 of 10). Both reach 96 now, as the Frost's icicle fall, so a jump past 96 px draws a far or weighted pick; between 28 and 96 the dive comes first and does not follow itself, so the hop answers the next jump.
- **The dive's shadow was too narrow for its diagonal** (the kit test: the diving body reached 106 px from the landing with the hang halfway across). The hang drifts 80 % of the way and the shadow is 128 px.
- **Driver only:** the blade jump waited for every blade to turn and came 15-20 px before the first one back (`pl3`: 5 hits); the hop's dodge flipped as the hop closed in; the claw's double jump released the first press after 0.2 s, a cut jump.

## Not fixed (for the user)

- **Pinned at a wall the overhead claw needs a double jump** (its box reaches 150 px; a single jump peaks at 141.5). The driver, jumping the second sweep from the wall, was still landing when the claw wound up and was hit 1-3 times per run before the final kit (`pl5`, `pl6`, `pl10`). A human can back off the wall during the sweeps, double jump over the scarecrow or pogo its head.
- **A cornered Ivo against the hop or the dive** must run out under it toward the guardian: both landings are clamped 96 px off the arena's edge, and the FightWall leaves no floor beyond them.

## What screenshots cannot show

- The blades read as small dark shapes over Ivo's head and low in front of him; their height reads, their spin does not at 2x.
- The dive's shadow is down 0.75 s before the dive: the driver stepped out of all six shadows in `pl11` (no dive hit).
- The scatter hides the body for 0.3 s; the swirl's leaves gather in a column 64 px behind Ivo and are visible in the grey.

## After the review and the feel pass (2026-11-19)

Fixes: `playtests/2026-11-18-grd15-leaf-feel` and the review's bugs (systems/guardians, "The Leaf Guardian's fight"). The
driver gained the feel pass's changes: the hop's direction fixed once per hop, `PL_CLIMB`, `PL_RECALL_DELAY`. Runs use
`PL_CLIMB=1`. Mix is by string (a link is part of its string).

| run | restored | hits |
|---|---|---|
| Leaf bot (`bot_autumn`, `BOT_GOD`) | 66.8 s | 7: sweep 3, hop 3 (two by its body), gust 1 |
| driver, god (`pl15`) | 133.0 s | 3: sweep 2 (backed into at 86 and 97 px), hop 1 (thrown from close, the driver turned away into it at the east wall) |
| driver, no god (`pl16`) | **143.0 s** | 2: sweep 1, hop 1 (pinned at the west FightWall, the driver chose "away") |
| Bloom bot (`BOT_GOD`) | 39.1 s | 5 |
| Frost bot (`BOT_GOD`) | 58.5 s | 5 (65.3 s with 7 after GRD-14) |

| stage (`pl15` / `pl16`) | busy | idle mean / max | strings |
|---|---|---|---|
| 0 | 65 % / 65 % | 0.93 / 2.02 s; 1.04 / 2.10 s | sweep 4, hop 4, blades 4, gust 1; sweep 6, blades 5, hop 5, gust 4 |
| 1 | 69 % / 68 % | 0.67 / 1.02; 0.87 / 1.75 | dive 3, hop 3, sweep 3, blades 2; dive 3, blades 2, hop 2, gust 1, sweep 1 |
| 2 | 72 % / 77 % | 0.80 / 2.78; 0.46 / 0.58 | hop 3, dive 3, blades 2, sweep 2, gust 2, scatter 1; dive 3, scatter 2, hop 2, sweep 2 |

- **The stage-0 loop is gone.** The sweep string is 31 % and 30 % of stage-0 strings (was 0 of 64); no string over 33 % at
  any stage. With `recent_strings` alone (`pl13`) stage 0 became a three-move cycle, blades, hop, gust, still 0 sweeps:
  the far pick only drew moves that reach a far Ivo. `far_walks_in` lets it draw the sweep and walk in.
- **Openings vary:** after the two lucidities, blades then dive and hop then blades (`pl15`); dive then gust and dive then
  scatter (`pl16`). Was gust then hop 6 of 6.
- **The teaching gust** hit 0 times in both runs (the answered recall is spared its blow).
- The no-god driver restores: the Leaf's first fight is dodgeable by a scripted player with walk, jump, double jump and
  climb.
