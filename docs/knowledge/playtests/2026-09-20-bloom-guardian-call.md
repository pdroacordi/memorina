---
id: playtests/2026-09-20-bloom-guardian-call
type: playtest
title: Bloom Guardian fight through a full call-and-response, after the blur / dropped-note / call-HUD fixes
status: active
build: 8300ad9 (+ uncommitted fixes committed right after this entry)
area_tested: Bloom Guardian fight, home_village/bloom_hollow
tags: [guardians, call-and-response, memorina, hud]
related: [bugs/creature-pass-bilinear-blur, bugs/memorina-notes-dropped-while-previous-rings, bugs/off-centre-sprite-sheet-jumps-on-flip, architecture/guardian-fight-phase-machine]
created: 2026-09-20
updated: 2026-09-20
ratings: { fun: 2, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-09-20-bloom-guardian-call/03_call_listen.png
  - screenshots/2026-09-20-bloom-guardian-call/05_answering.png
  - screenshots/2026-09-20-bloom-guardian-call/06_answered.png
  - screenshots/2026-09-20-bloom-guardian-call/08_later.png
---

## What was tested

`tools/playtest/scripts/bloom_guardian_call.json` with Ivo spawned at x=3075 (Bloom
Hollow): run right 3.7 s, then alternate short steps and sword swings until five hits
open the lucidity window, draw the Memorina, play SPROUT (DOWN LEFT DOWN RIGHT DOWN UP)
at 0.5 s per note, then let the fight resume. Three timeline iterations were needed:
holding "right" runs Ivo through the guardian (bodies do not collide) and standing still
never reaches it, because the guardian parks at its longer move's range (150 px), outside
sword reach. A human steps in; the timeline now does too.

## Findings

- Sprites are crisp after the `CreatureMask` filter fix (`03_call_listen.png`); before
  it, guardians and Ivo were visibly softer than the tiles.
- The new `GuardianCallHud` reads clearly: "Ouça…" with the four revealed notes lighting
  as the guardian sounds them (`03_call_listen.png`), then "Responda na Memorina" with the
  time bar draining and the answered notes lighting on the call sheet while Ivo's own sheet
  shows what he played (`05_answering.png`). The two sheets are now visibly different roles.
- A correctly played phrase at a natural tempo is accepted (`06_answered.png`: bar cleared,
  all six notes on Ivo's sheet). Confirmed bug fixed: `bugs/memorina-notes-dropped-while-previous-rings`.
- Balance: the flower killed Ivo (3 HP) within seconds of pressure resuming
  (`08_later.png`). Cooldowns raised (lash 1.2→1.8 s, burst 2.2→3.0 s) after this run; still
  worth a human pass. Ivo also cannot heal, so a three-cycle Frost fight is likely too hard.
- The guardian walks into Ivo during its approach and the two overlap while he answers
  (`05_answering.png`); an approach stop distance a little larger than the melee range
  would look better.
- The lucid tremble (shield 0.3↔1.0) is invisible in the home village at baseline 0.8 —
  everything is coloured anyway. It will read in Frost Edge (0.2).

## Ratings rationale

- fun 2: the loop works, but the pressure phase is a slow walk-and-poke against a guardian
  that parks at range, and one mistake after the answer is a death. Needs tuning before it
  is enjoyable.
- fluidity 3: no hitches; the transition into the call is abrupt (the guardian just stops).
  Camera feel and input latency cannot be judged from stills.
- aesthetics 3: crisp now; the tinted call sheet is distinct; the guardian's `lucid` and
  `restored` clips are still idle frames, and there is no per-hit sound.
