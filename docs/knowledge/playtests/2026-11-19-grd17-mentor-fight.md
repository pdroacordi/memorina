---
id: playtests/2026-11-19-grd17-mentor-fight
type: playtest
title: GRD-17 mentor fight on the engine - bot and dodging-driver runs to the victory, held stage-0 and stage-2 runs, and a pressure under the dissonance veil
status: done
tags: [grd-17, guardian, mentor, finale, playtest, bot]
related: [systems/guardians, architecture/grd-06-final-battle, architecture/grd-12-guardian-fight-engine, gotchas/scripted-presses-timed-in-real-ms-collapse-at-a-low-frame-rate, playtests/2026-11-19-grd16-sun-fight]
created: 2026-11-19
updated: 2026-11-19
area_tested: "lighthouse_top (the mentor): whole bot fight to RESTORED; the dodging driver to RESTORED with and without god mode; stage 0 and stage 2 held for 200-420 s; a mixed two-track window and the pressure after it under the veil"
source_files:
  - tools/playtest/scripts/guardian_fight_player_driver.gd
  - tools/playtest/scripts/guardian_fight_bot_driver.gd
  - resources/characters/guardians/mentor/mentor_stats.tres
---

# GRD-17 mentor fight

One Godot window at a time; the run script refuses to start while another Godot process runs, `APPDATA` is redirected per run and checked with a headless `OS.get_user_data_dir()` probe, and both drivers print the median real ms per frame every 600 frames. **Every run below had a median of 5-6 ms per frame** (the worst 600-frame sample 6 ms); none was discarded. Timeline: `guardian_bot_mentor.json` (the four restored, `mentor_wakes` seen, jump, roll and wall climb owned, every song known), 200 s for the bot and a 420 s copy for the driver. Numbers are from the final kit (systems/guardians, "The mentor's fight (GRD-17)") unless a run says otherwise.

The dodging driver (extended for the mentor) backs out of the sweep string and the glide (pinned, it jumps them late in their wind-up), backs out of the slam (pinned, jumps from the raised arm) and jumps its ice wave, steps out of each icicle's glint, jumps the thorn row, steps out of the pounce's shadow (toward the take-off is allowed, the body being in the air), steps between the seeds' patches. It never double jumps, rolls or pogoes. It answers each call with the phrase the call shows: the winter call, the revelation (whose notes are mixed by design until it shatters), the first track of a two-track window, then each final phrase. New options: `PL_WEST_PAD=96` (the lantern's floor starts 96 px inside its `Arena`), `PL_BODY_CLEAR=40` (the mentor is 36 px wide), `PL_ANSWERS=<n>` (stop answering after n windows: holds the fight at a stage), `PL_MIX=1` (mix the first two-track window), `PL_SHOT_FROM=<s>`.

## The flow

Every full run went: pressure (stage 0), the winter window answered, relapse, pressure (stage 1), the revelation (shattered by its 5 s real clock before the call had finished sounding: the driver's notes come after it), pressure at stage 2 with the spring's moves, a two-track window answered on the winter track, the two final phrases, RESTORED, the final fragment. A failed winter window (the held stage-0 runs: 5 in 200 s) was winter again every time and the stage stayed 0.

## Bot (`BOT_GOD=1`)

| run | restored | hits | causes (move current when hit) |
|---|---|---|---|
| `bot1` (first kit, margin 96) | 67.7 s | 5 | slam 2, glide 1, sweep 1, icicles 1 |
| `bot2` (final) | 68.5 s | 6 | slam 1, its ice wave 1, icicles 1, sweep 1, pounce 1, contact 1 |

The bot attacks and never dodges, so each window opens after 6-20 s of pressure. The winter answer, the revelation (its freeze frame), the two-track answer and both final phrases all happened; the final fragment followed.

## Dodging driver to the victory

| run | restored | hits | stage 0 (busy, idle mean/max) | stage 1 | stage 2 |
|---|---|---|---|---|---|
| `pl2` (god, before the driver's west pad) | 118.0 s | 0 | 66 %, 1.05/1.27 s | 67 %, 0.70/0.78 | 70 %, 0.85/2.42 |
| `g1` (god) | 124.5 s | 1 (glide, pinned at the west step) | 63 %, 1.04/1.43 | 70 %, 0.96/1.70 | 73 %, 0.82/1.72 |
| `mix2` (god, `PL_MIX=1`) | 152.2 s | 1 (a mixed note) | 65 %, 1.05/1.45 | 67 %, 1.01/1.52 | 74 %, 0.67/1.58 |
| `ng2` (no god) | 116.7 s | 0 | 69 %, 0.87/1.25 | 61 %, 0.76/0.79 | 69 %, 0.98/2.42 |
| `ng3` (no god) | 123.6 s | 0 | 64 %, 1.18/1.38 | 64 %, 1.00/1.70 | 68 %, 1.02/2.90 |
| `ng1` (no god, before `PL_BODY_CLEAR`) | died 65.9 s | 3 (icicles 2 at the west step, contact 1) | 69 %, 0.86/1.43 | 71 %, 0.76/1.13 | - |

Strings per stage in the full runs are short samples (5-17 a stage): stage 0 the sweep, glide, slam and hail about evenly (top share 29-40 % on 5-7 strings; 30 % over 43 in the held run), stage 1 adds the hail twice, stage 2 every move. The longest idles (2.4-2.9 s) are at stage 2; their cause was not traced (a held floor move or a long walk-in at 60 px/s are the candidates).

## Stages held (god mode)

| run | stage | pressure | busy | idle between moves | strings (top share) | hits |
|---|---|---|---|---|---|---|
| `s0b` (`PL_ANSWERS=0`) | 0 | 118.4 s | 68 % | mean 0.71 s, max 1.53 | 43: slam 13, sweep 8, glide 8, hail 8, sweep>glide 6 (30 %) | 6: icicles 5, ice wave 1 |
| `s2b` (`PL_ANSWERS=2`) | 2 | 268.7 s | 79 % | mean 0.50 s, max 2.45 | 96: hail twice 17, slam 14, thorn row 13, glide 13, seeds 12, pounce twice 10, sweep>glide 9, sweep 7, pounce 1 (18 %) | 11: icicles 7, contact 2, thorn row 1, ice wave 1 |

No string is over 35 % of a stage, no two-move cycle came three times running and no three-move order came round more than twice running, in any run. Every move fired at stage 2.

## Under the dissonance veil (`mix2`)

`PL_MIX=1` committed the first two-track window to the winter track and played the spring's next note three times: three `call_mixed`, one note of damage, the window drained and failed, and the pressure ran 30 s (93-124 s) under the veil at about 0.7 before the next window. Screenshots at 106-109 s: the seeds' landing marks (light lines in a dark rim) and the thorn patches read through the grey static over the lantern's pale stone; the floor warnings stand over the floor's grass fringe. The veil stays up through that pressure because nothing clears it until the next window or the victory (GRD-06 behaviour, unchanged here).

## What changed because of these runs

- `pl1` (before `PL_WEST_PAD`): the driver did not know the lantern's floor starts at x 96 of the room and backed into the west step again and again: 16 hits in 110 s, all pinned there. Driver fix, not a kit change.
- `s2` (margin 144): 29 hits in 273 s at stage 2; 6 were the pounce. Three hit an Ivo pinned on the west floor: the landing was clamped 144 px off the `Arena`'s edge and its box overlapped him by 1 px. The mentor's `lucidity_leap_margin` is 160 now (lands at x 160..992 of the room) and the box is x -30..30: `s2b` had no pounce hit. The other pounce hits were the driver refusing to step toward the guardian out of the shadow; it may now (the body is in the air).
- The pounce has a 128 px landing shadow (`test_the_pounce_shadow_covers_its_reach`), as the checklist asks of every leap.

## Open

- Icicles are most of the driver's hits (5 of 6 at stage 0, 7 of 11 at stage 2): it steps out of each glint but often has nowhere it accepts to step to between the mentor's body and a wall. A human steps 24 px, double jumps over the mentor or pogoes; the driver does none of these.
- The revelation peaks on its real-time clock (5 s) before the call finishes sounding (2.2 s lead-in plus six notes at 0.55 s), so a player never plays a note into it unless the call is short. Unchanged GRD-06 timing; worth a look with the revelation's art.

## Fix round (2026-11-19, after the feel pass)

What changed: a floor runner ends where it stops; an inside spawn hit pushes Ivo away from the guardian that threw it; the revelation's clock starts at its window (4 s) and its judge never fails a note after the first; steeper stages (`walk_scale`, `recovery_scale`, engine); the slam's reach up 33, over the 32 px west step; equally tall overhead picks drawn by weight; a third far winter move (the frost wave); `lucidity_leap_distance` 360 (systems/guardians, "The mentor's fight"). Every run below had a median of 5-6 ms per frame. Still-Ivo and forced-stage runs use the feel pass's driver (`scratchpad/feel17/drv.gd`, `FV_STAGE` now reading the stage table, walk and recovery scales included).

| measure | before (feel pass, first report) | after |
|---|---|---|
| pinned at the west step, single jump from the raised arm (`FV_SLAM=jump`, 6 slams) | 6 of 6 hit by the parked wave | 0 of 6, twice |
| a still Ivo's 3rd hit, stage 0 / 1 / 2 (forced) | 8.95 / 8.65 / 8.22 s | 8.63-9.13 / 7.23-8.76 (4 runs) / 6.35-8.97 s (3 runs; 6.9-7.6 with `recent_strings` 1) |
| winding up or striking (T+S), still Ivo, stage 0 / 1 / 2 | 47 / 50 / 57 % | 47-49 / 52-60 / 68-70 % |
| T+S, dodging driver held at stage 0 / 1 / 2 (forced, 125-197 s) | 46-51 / 46-54 / 57-64 % | 47 / 56 / 69 % |
| longest idle between moves at stage 1 / 2 | 2.65 / 2.91 s | 1.35 / 1.27-1.35 s (stage 0: 1.72, unchanged on purpose) |
| bot (`BOT_GOD`) | restored 68.5 s, 6 hits | restored 74.8 s, 9 hits (`bot8`) |
| driver to the victory, god | 118.0-152.2 s, 0-1 hits | 238.7 s, 13 hits (`g7`; icicles 7, the sweep 4, seeds 2) |
| driver, no god | 2 of 2 restored (116.7, 123.6 s), 0 hits; the feel pass 2 of 4 | 0 of 2: died 57.2 s (stage 1) and 109.1 s (stage 2), 3 hits each, icicles 2 and contact 1 each; with the previous step's data also 0 of 2 (108.7, 126.1 s) |
| the revelation | closed 5.00 s after its call, never a window | the window opens; the driver's three mixed notes shatter it (`g3`: mixed at 85.8, 86.2, 86.7 s, then pressure; `g3` ran the intermediate tuning) |

No string was over 35 % of a stage and no order repeated more than twice running in the final runs (`g7`, `ng14`, `ng15`, the stage 0 and 1 holds). Two loops were found and fixed on the way: with `far_walks_in` off the far pick cycled two or three far moves (glide and hail 5 times, frost wave and hail 19 times running), and the overhead branch took equally tall moves in array order (hail, thorn row, pounce 9 times running against a driver on the west step; frost wave, hail, thorn row 3 times in the last stage-2 hold before the weighted tie-break).

Open:
- A still Ivo's third hit at stage 2 is 6.35-8.97 s, not reliably under 6.5. Cooldown and recovery are both cut (x0.35, x0.7); what is left is the move mix (the hail twice and the pounce twice are 3-3.8 s strings worth one note) and the telegraphs.
- The dodging driver now dies without god mode in both final runs, nearly always to icicles near the west wall, where it refuses the steps a human takes (24 px toward the mentor, a double jump over him).
