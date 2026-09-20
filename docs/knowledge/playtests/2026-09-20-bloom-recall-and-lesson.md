---
id: playtests/2026-09-20-bloom-recall-and-lesson
type: playtest
title: Bloom Guardian - the recall prompt, the full-note call sheet and the staged lesson, driven state by state
status: active
build: 37e64ce (+ the QTE-phase / cinematic commit that follows this entry)
area_tested: Bloom Guardian fight, home_village/bloom_hollow - QTE prompt, call-and-response, lesson cinematic
tags: [guardians, qte, recall, call-and-response, lesson, hud]
related: [playtests/2026-09-20-bloom-guardian-call, architecture/guardian-fight-phase-machine]
created: 2026-09-20
updated: 2026-09-20
ratings: { fun: 3, fluidity: 3, aesthetics: 4 }
screenshots:
  - screenshots/2026-09-20-bloom-recall-and-lesson/01_qte_prompt_2.png
  - screenshots/2026-09-20-bloom-recall-and-lesson/02_qte_recalled.png
  - screenshots/2026-09-20-bloom-recall-and-lesson/04_call_answering_0.png
  - screenshots/2026-09-20-bloom-recall-and-lesson/09_lesson_1.png
  - screenshots/2026-09-20-bloom-recall-and-lesson/10_lesson_2.png
---

## What was tested

A fight cannot be scripted on a fixed clock (lucidity opens whenever the fifth hit lands,
and a late answer costs the run - see the previous entry's third iteration), so this
session drove the states directly from a throwaway scene: launch Ivo and open the
airborne recall, press the prompted key; then two lucidity cycles (hits through the
hurtbox, draw, six notes at 0.5 s) into the lesson. Windowed, real rendering; the
throwaway scene was deleted afterwards. Note for the next agent: pace such scripts on
`physics_frame`, not `process_frame` - an uncapped window renders far above 60 Hz and
the hurtbox i-frames never expire between "16 frames".

## Findings

- The recall prompt reads as a QTE now: "Lembre-se!" banner, medallion, the bound key
  ("Z") blinking, a ring draining with the real-time window (`01_qte_prompt_2.png`);
  on the press the key turns pressed and green with the ring (`02_qte_recalled.png`).
  It only opened once Ivo was airborne, as intended for a double jump.
- The call sheet shows all six notes; answering lights them on the call sheet while
  Ivo's own sheet fills beside him (`04_call_answering_0.png`).
- The lesson is staged: letterbox bars, dimmed world, "Você aprendeu a tocar" and the
  title (`09_lesson_1.png`), the sheet lighting as the track plays (`10_lesson_2.png`).
  In these frames the dim still darkened Ivo and the guardian; the cinematic layer was
  moved under the creature pass right after, so the two are spotlit instead.
- Not judged here: the telegraph's readability in motion, the hit-stop's weight, or
  whether the scheduled recall (every 3 moves) lands at a sensible moment in a live
  fight - all need a human pass with the pad in hand.

## Ratings rationale

- fun 3: the moment-to-moment loop now has legible beats (telegraph, prompt, answer),
  but a real fight has not been played end to end since the balance changes.
- fluidity 3: no hitches; unchanged from stills.
- aesthetics 4: the prompt and the lesson card are the first parts that look
  intentional; the guardian's `lucid`/`restored` clips are still idle frames.
