---
id: bugs/the-sun-guardians-roar-never-fires
type: bug
title: The Sun Guardian's roar (attack_range 88) is never thrown, because the claw takes over the pick from 118 px and the charge beyond 174
status: fixed
severity: low
tags: [guardians, summer, ai, move-selection, reach, pre-existing]
related: [systems/guardians, playtests/2026-11-18-grd12-engine-regression, playtests/2026-10-30-grd04-autumn-summer-fights]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - scenes/characters/guardians/guardian_ai.gd
  - resources/characters/guardians/summer_guardian/summer_roar.tres
  - resources/characters/guardians/summer_guardian/summer_claw.tres
  - resources/characters/guardians/summer_guardian/summer_guardian_stats.tres
---

## Summary

`summer_roar.tres` is one of the lion's three moves ("rears, 150 px high, then slams", `systems/guardians`). It never
fired in any bot or passive run. The bug is pre-existing: the HEAD export without GRD-12 behaves the same.

## Symptom

GRD-12 regression playtest, 2026-11-18. `guardian_fight_bot_driver.gd` ran `guardian_bot_summer.json` 4 times: two
whole fights (`BOT_GOD=1`) and two 40 s `BOT_PASSIVE=1` runs, on the working tree and on the HEAD export. That gave
about 45 strikes: 30 charges, 10 claws and 0 roars. `grep roar` finds nothing in any log. No earlier playtest mentions
seeing it.

## Root cause (from code reading; not instrumented)

`GuardianAI._refresh_next()` calls `_situational_pick()` every tick, and it overrides the weighted pick:

- When Ivo stands on the same floor, `above` is +0.1 (Ivo's feet at y 1823.9, the lion's at 1824.0), so the
  "reaches up" branch runs. It picks the in-range move with the greatest `attack_height`.
- The claw (range 118) is in range from 118 px. The roar (range 88, height 150) is not in range until 88 px. So once
  the lion closes to 118 px with the roar as `_next`, the claw replaces it and telegraphs at once. Logged claw
  telegraphs start at dx 95-114.
- Beyond `comfort_distance * COMFORT_FAR` (134 * 1.3 = 174 px), the "longest" branch picks the charge (range 300).
- The roar can therefore only start if Ivo crosses from more than 118 px to under 88 px within one tick. The lion's
  own spacing (comfort 134, give ground 96) keeps him outside 88.

The 0.1 px is the trigger. When feet are level to within a float step, the "player is above" branch should not
apply. Supporting evidence: in `guardian_ai_timeline_test`, where the scripted Ivo stands exactly level (y 0, the
body's y, between hops) and sweeps x at up to ~300 px/s, the lion does throw the roar (`tests/fixtures/guardians/guardian_ai_timeline.json`, summer `T2@471`). In play he stands
0.1 px higher and the roar never comes.

## Options at filing

Choose one:

- Give the overhead branch a threshold, e.g. `above > attack_height_of_the_lowest_move * 0.5` or a few px, so that
  standing level falls through to the weighted pick.
- Give the roar a range the lion actually lets Ivo into (≥ 118).
- Let `_situational_pick` keep a `_next` that is still approaching its range.

Re-check Bloom and Frost after any change to `_situational_pick`, because their passive move order depends on it
(`playtests/2026-11-18-grd12-engine-regression`).

## Fix

Fixed 2026-11-18 by the same change as `bugs/the-bloom-overhead-branch-preempts-its-far-pick-by-weight`: the overhead
branch runs only above the lowest reach up of the lion's moves (96), so an Ivo 0.1 px above its feet no longer hands the
pick to the claw. A roar picked by the weighted roll is kept while the lion closes from 118 px and thrown inside 88.

Test: `guardian_ai_test.test_the_sun_roar_is_kept_for_a_player_a_hair_above` (summer stats, roar chosen, Ivo 0.1 px up:
nothing thrown at 100 px, the roar at 80). The Sun golden changed only at `T0@908` (the claw where the charge was); its one roar (`T2@471`) was there before, so the test above is the evidence. Not measured in
a Sun bot fight in this change.

## Prevention

`guardian_ai_timeline_test` (`_ivo_at`) missed this because its Ivo stands exactly level. A variant with Ivo's feet 0.1 px
above the guardian's, as `move_and_slide` leaves them, plus an assertion that every authored move is thrown at
least once, would catch it.
