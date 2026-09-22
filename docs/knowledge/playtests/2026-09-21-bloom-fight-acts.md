---
id: playtests/2026-09-21-bloom-fight-acts
type: playtest
title: Bloom and Frost - contact damage, the mandatory recall, the staged call and the relapse, driven state by state
status: active
build: 4b782fc + the round-4 guardian change (contact / recall gate / relapse / staged call)
area_tested: Bloom Guardian (home_village/bloom_hollow) full arc; Frost Guardian (frost_edge/lighthouse) opening acts
tags: [guardians, qte, recall, call-and-response, relapse, hud, camera, greyhush]
related: [playtests/2026-09-20-bloom-recall-and-lesson, bugs/recall-move-range-exceeds-hitbox-reach, gotchas/sprite-frame-out-of-bounds-on-clip-switch, architecture/guardian-fight-phase-machine]
created: 2026-09-21
updated: 2026-09-21
ratings: { fun: 4, fluidity: 3, aesthetics: 4 }
screenshots:
  - screenshots/2026-09-21-bloom-fight-acts/01_contact.png
  - screenshots/2026-09-21-bloom-fight-acts/02_saturated.png
  - screenshots/2026-09-21-bloom-fight-acts/03_recall_prompt.png
  - screenshots/2026-09-21-bloom-fight-acts/05_call_lead_in.png
  - screenshots/2026-09-21-bloom-fight-acts/07_call_note_b.png
  - screenshots/2026-09-21-bloom-fight-acts/10_answered.png
  - screenshots/2026-09-21-bloom-fight-acts/12_relapse_drain.png
  - screenshots/2026-09-21-bloom-fight-acts/14_failed.png
  - screenshots/2026-09-21-bloom-fight-acts/19_lesson.png
  - screenshots/2026-09-21-bloom-fight-acts/f02_recall_prompt.png
  - screenshots/2026-09-21-bloom-fight-acts/f05_window.png
---

## What was tested

A throwaway scene (deleted afterwards) instanced `game.tscn`, teleported Ivo into each
arena and drove the fight through its real seams: stood him inside the guardian, landed
hits through `Hurtbox.receive_hit`, waited on `Player.recall_started`, pressed the
prompted key with `Input.parse_input_event`, drew and answered the call note by note,
answered wrong once, and read `GuardianFight` back after every step. Windowed, real
rendering, paced on `physics_frame`. Ivo was healed between cycles because the script
parks him where the guardian walks into him (contact damage killed him on the first
attempt - the script's fault, and proof the contact hitbox works).

## Findings

- Contact hurts under pressure (`01_contact.png`: 3 -> 2 HP standing in the bulk) and
  not while lucid (`f05_window.png`: Ivo inside the Frost Guardian, unhurt).
- The recall is an act now: seven hits saturate with the skill unknown
  (`02_saturated.png`, the shield climbing to 0.54), the burst is thrown next, the prompt
  opens airborne (`03_recall_prompt.png`), and the press opens lucidity at once. The Frost
  charge does the same on the ground with Shift (`f02_recall_prompt.png`).
- The staged call reads as a moment: one sheet on the side away from the guardian, the
  world dimmed under the creature pass, the camera holding the pair, the guardian
  breathing to full colour on each note (`05_call_lead_in.png`, `07_call_note_b.png`).
  Without the well of forgetting (`Corruption` MemorySource, -0.75) none of the colour
  language showed in Bloom Hollow - the village baseline is 0.8 and a shield only lifts
  memory toward 1.
- The cure is legible: pips under the message, the first filling green on the answer
  (`10_answered.png`), the guardian holding bright and draining to its new rest
  (`12_relapse_drain.png`, 0.65 after one of two cycles); a wrong note reddens the sheet
  and snaps the colour back (`14_failed.png`), and the fight resumes angrier
  (hits_to_open 7 -> 8). Restoration after the last cycle goes straight into the lesson
  with the well lifting (`19_lesson.png`).
- Logged once per flinch: `Index p_frame = 5 is out of bounds` - pre-existing, see the
  gotcha.
- Not judged here: the counter's cadence, the contact knockback and the shake strength
  in a live fight; all are exports or `.tres` values.

## Ratings rationale

- fun 4: the fight has acts a player can read and plan around (touching costs, mashing
  is countered, the recall is coming, the cure is two answers away).
- fluidity 3: the arc runs without a hitch, but feel in motion still needs the pad.
- aesthetics 4: the call composition and the colour drain are the first moments that
  look staged; `lucid`/`restored` clips are still idle frames.
