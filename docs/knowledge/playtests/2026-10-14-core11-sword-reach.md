---
id: playtests/2026-10-14-core11-sword-reach
type: playtest
title: CORE-11 - every swing reaches 12 px further at the same height, the brute's combo and running opener land from further, and both guardians still pace outside the swing
status: active
build: 0128b8d + uncommitted CORE-11 (before = a git archive of main 0128b8d)
area_tested: "home_village street (x 470, floor y 288) for the stills; Brute Shadow in summer_caldera/caldera_bait (x -5776, floor y 1824); Bloom Guardian in spring_woods/bloom_hollow; Frost Guardian in frozen_lake/lake_frost_arena"
tags: [combat, ivo, sword, reach, smear, hitbox, brute-shadow, guardians, core-11]
related: [features/ivo-sword-attacks-from-key-poses, systems/guardians, systems/animation, playtests/2026-10-11-core09-retune]
created: 2026-10-14
updated: 2026-10-14
ratings: { fun: 3, fluidity: 3, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-14-core11-sword-reach/before_after_widest_frames.png
  - screenshots/2026-10-14-core11-sword-reach/sheet_hit_frames_and_boxes.png
  - screenshots/2026-10-14-core11-sword-reach/before_s1_slash.png
  - screenshots/2026-10-14-core11-sword-reach/after_s1_slash.png
  - screenshots/2026-10-14-core11-sword-reach/before_s2_chop.png
  - screenshots/2026-10-14-core11-sword-reach/after_s2_chop.png
  - screenshots/2026-10-14-core11-sword-reach/before_s3_air_slash.png
  - screenshots/2026-10-14-core11-sword-reach/after_s3_air_slash.png
  - screenshots/2026-10-14-core11-sword-reach/before_s4_running_slash.png
  - screenshots/2026-10-14-core11-sword-reach/after_s4_running_slash.png
  - screenshots/2026-10-14-core11-sword-reach/before_s5_running_backhand.png
  - screenshots/2026-10-14-core11-sword-reach/after_s5_running_backhand.png
  - screenshots/2026-10-14-core11-sword-reach/before_s6_pogo.png
  - screenshots/2026-10-14-core11-sword-reach/after_s6_pogo.png
  - screenshots/2026-10-14-core11-sword-reach/before_brute_running_slash_far.png
  - screenshots/2026-10-14-core11-sword-reach/after_brute_running_slash_far.png
  - screenshots/2026-10-14-core11-sword-reach/after_brute_slash.png
  - screenshots/2026-10-14-core11-sword-reach/after_brute_chop.png
  - screenshots/2026-10-14-core11-sword-reach/after_bloom_slash.png
  - screenshots/2026-10-14-core11-sword-reach/after_bloom_second_pounce_rolled.png
  - screenshots/2026-10-14-core11-sword-reach/after_frost_swipe_misses.png
  - screenshots/2026-10-14-core11-sword-reach/after_frost_punish_chop.png
---

## What was tested

Every timeline ran windowed twice, on a `git archive` of main (before) and on the change (after), with `"trace": true` where a foe is in play. Verdicts rest on the traces (foe offset, hp or hit progress, Ivo's hp).

- `core11_swing_stills` (new): standing slash and chop, air slash, running slash and backhand, pogo, each captured at its widest frame (the log confirms the clip time: slash 0.183 s = frame 2, chop 0.100 = frame 6, air 0.183 = frame 2, running 0.267 = frame 3 and 0.183 = frame 7, pogo 0.267 = frame 3).
- `core11_brute_running_reach` (new): the CORE-09 running opener with the first attack pressed 0.06 s earlier, from further out.
- `core09_brute_running_opener`, `core09_brute_dodge_and_punish`, `core09_bloom_exchange`, `core09_frost_exchange`, unchanged.

## Findings

- **The swings read longer and keep his style.** `before_after_widest_frames.png`: the slash's leading smear now sweeps past the blade tip to 60 px, the chop, running and air crescents end 12 px further forward, and none rises higher over his head. The pogo streak runs 6 px deeper. Body, face, poses and timing are the same frames. `sheet_hit_frames_and_boxes.png` shows each hit frame with its keyed box, old above new.
- **A running slash lands from 62.8 px.** `core11_brute_running_reach`: after, swing 1 hit the brute at 62.8 px at t 2.054 (hp 5 -> 4) and the backhand at 44.8 (4 -> 2). Before, the same inputs could not touch it at 62.8 (reach 53); the hit came 0.06 s later at 53.2 px, as Ivo ran in. `before_/after_brute_running_slash_far.png`.
- **The brute parks further and the combo still lands both swings.** `core09_brute_dodge_and_punish`: the slash hit at 55.5 px (was 47.5) and the chop at 63.6 (was 55.6); the second combo hit at 46.7 and 54.8 (were 38.7 and 46.9). The brute stops at its new 57 px and swing 1's 60 px/s shove leaves it inside the chop. Ivo took no damage in either build; the step-back dodge of its 89 px swing is unchanged.
- **The CORE-09 running opener is unchanged** (hits at 53.2 and 32.4 px, hp 5 -> 4 -> 2 in both builds): Ivo was already inside both reaches when each window opened.
- **Bloom's comfort point is outside the longer swing.** `core09_bloom_exchange`: both pounces were rolled under in both builds and Ivo ended at full hp. In its cooldown it now paces at 128-135 px (was 111-118), and the scripted step-in landed the slash at 86.3 px (was 70.1). Its far-side hurtbox is 109.5 px from Ivo's longest swing, inside the 114 comfort distance.
- **Frost: the punishing chop now lands.** `core09_frost_exchange`: after the dodged swipe, the slash hit at 64.5 px in both builds; the chop hit at 75.7 px after and whiffed before (the golem gives ground as Ivo steps in); the third swing at 80.9 px landed in both. Hits 3 of 8 (was 2). Stepping out to 143.9 px dodged the counter-swipe in both, Ivo at full hp. With `comfort_distance` 165 the golem gives ground under 115.5 px, so it backs away sooner during a punish; the longer reach still catches it.
- **The pogo against a foe was not exercised.** A pogo timeline over the brute landed on the 96 px tunnel's ledge above it, and the Bloom Guardian steps out from under a falling Ivo, as designed. The pogo's depth is asserted by `ivo_sheet_test` (box 0..28 below the feet, equal to the streak) and shown in `before_/after_s6_pogo.png`.
- **`ivo_2x_attacks` no longer tests anything.** Its spawn (0, 5990) leaves Ivo in `attack_fall` with velocity 1000 and an unchanged position in both builds: the trial floor is not under it. Its stills are of the fall attack, so this report uses `core11_swing_stills` instead.

## After the review: give ground is its own distance

Review found that at 0.7 x the new comfort distances (Bloom 80, Frost 115.5) the give-ground threshold sat above the lash's and the swipe's ranges (72, 110), so the guardian would back off after each of those moves. `GuardianStats.give_ground_distance` now sets it: Bloom 70, Frost 101.5 (the pre-CORE-11 thresholds). Re-run:

- `core09_bloom_exchange`: same pounce cadence (telegraphs at 1.23 and 5.13 s, as on main). During its cooldown Bloom drifts in to 68.7 px instead of holding at 86, so the scripted step-in lands slash and chop (hits 0.14 -> 0.29, 2 of 7; 1 on main and before the fix). Both pounces rolled under, Ivo at full hp.
- `core09_frost_exchange`: identical to the pre-fix run (it gives ground during Ivo's punish at 64-81 px, inside 101.5; hits 3 of 8; counter dodged).
- `core11_frost_cadence` (new; Ivo walks in and stands): swipes at 1.10 and 4.88 s and the charge at 8.06 s, the same as main; each swipe's knockback carries Ivo to 164-185 px, outside both thresholds. In the last cooldown it paces at 170 px (147 on main), the larger comfort distance.
- The user decided on the two judgement points (2026-10-14): "keep +12 px and the hitbox as is".

## Ratings rationale

- **Fun 3.** Every fight keeps its loop and Ivo now reaches 12 px further. The brute parks further and Bloom and Frost pace further, so the step-in costs as much as before; the gain shows where the AI does not set the distance: a running opener, a chop on a retreating golem. Whether that is enough "bigger" needs a human hand.
- **Fluidity 3.** No stuck states or new flips in the traces. Swing timing and windows are unchanged, so latency is as before.
- **Aesthetics 4.** The arcs are wider sweeps of the same crescents in the same palette. On the cream village walls the white smear has less contrast, as before.

## What screenshots cannot show

How the extra 12 px feels in the hand, and whether the box leading the bare blade by up to 24 px on the running backhand's strike frame (blade to 28 px, box to 52; the smear follows a frame later) reads as a hit that lands before the steel touches.
