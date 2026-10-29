---
id: bugs/a-pogo-on-the-frost-golems-head-stops-it-attacking
type: bug
title: Ivo pogoing on the Frost golem's head keeps it from attacking for 6-14 s; the slam never swats him
status: resolved
severity: medium
tags: [guardians, ai, frost, slam, pogo, escape, grd-07]
related: [systems/guardians, playtests/2026-10-29-grd07-guardian-art, bugs/the-frost-swipe-passes-over-ivo-standing-close-to-the-golem]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/guardians/guardian_ai.gd
  - resources/characters/guardians/frost_guardian/frost_slam.tres
---

## Summary

`systems/guardians` says Frost "has an answer overhead and uses it": the slam (`attack_height` 150)
swats a player bouncing above the golem. In play, a player who double-jumps onto the golem
and pogoes on its head gets no slam. Instead the golem walks away under him and throws no
move for 6-14 s. The only damage he takes is contact. This was not caused by GRD-07: it
happens the same way on HEAD (pack art).

## Symptom

`guardian_fight_bot_driver.gd` with `BOT_BOUNCE=1` and the setup `guardian_bot_frost.json` (20 s).
The bot walks under the golem, double-jumps (Z 0.3 s, then Z 0.35 s at +0.42 s) and pogoes
(down + attack) when falling more than 150 px above the golem's feet.

| run | build | golem moves after the opening swipe | longest gap with no move | slams thrown | hits taken (all moves + contact) |
|---|---|---|---|---|---|
| fbounce1 | GRD-07 | swipe 16.3, swipe 17.3 | 2.3 -> 16.3 s (14 s) | 0 | 19 |
| fbounce2 | GRD-07 | swipe 16.3, charge 19.7 | 1.6 -> 16.3 s | 0 | 19 |
| hbounce1 | HEAD | slam 8.6 (at dx 82, Ivo landed), charge 18.6 | 10.6 -> 18.6 s | 1, missed | 18 |
| hbounce2 | HEAD | swipe 4.0, charge 14.3, slam 18.8 | 4.9 -> 14.3 s | 1, missed | 20 |

Meanwhile the golem walks steadily east (x 5300 -> 5680 in fbounce1) while Ivo's hits on it
climb (0.13 -> 0.63). Nearly all of the hits taken are contact damage from landing on the body.
Ivo was kept alive by `BOT_GOD`, so without it he would die within a few bounces. The defect is
that the golem has no answer, not that the pogo is safe.

## Root cause

- `GuardianAI._update_reach` (guardian_ai.gd:183) marks the player as above reach as soon as
  he is higher than `_tallest_reach()`. For the golem that is the slam's 150 px. It releases
  only after 0.3 s below 0.8 x 150 = 120 px.
- The golem's body is 176 px tall. Ivo standing or bouncing on its head has his feet at 176
  px or more, so every pogo on it is "above reach" by construction. Between bounces he never
  spends 0.3 s under 120 px.
- While he is above reach and within `OVERHEAD_BAND` (64 px), `_update_escape` takes the
  movement. `_select_state` throws nothing while `_escaping` (guardian_ai.gd:153). Even when
  not escaping, `_in_range` requires `|dy| <= attack_height` (guardian_ai.gd:331), so the
  slam can never be chosen against him.
- The slam therefore only ever answers a jump that tops out under 150 px, which is a plain
  hop beside the golem, not a bounce off it.

## Fix

Fixed 2026-10-29. The user's decision: "O pogo é a brecha": the pogo is a valid way out of the golem's moves,
so the slam keeps `attack_height` 150. `GuardianAI.OVERHEAD_PATIENCE` (1.5 s): after that long with the player out
of reach overhead and no move thrown, the escape ends once its step-out lunge is done and he is outside
`overhead_band`, and `_in_range` ignores height (never while he is inside `overhead_band`), so the guardian walks
back in and throws where he will come down. Recorded in `systems/guardians`, "Fixes after the GRD-07 playtest and
review".

## Prevention

`guardian_ai_test.test_a_pogo_on_its_head_does_not_stop_its_moves`: Frost stats, a player 180-260 px above a fixed
x on a 0.5 s period; a move is telegraphed inside 4 s, from outside `overhead_band`.
