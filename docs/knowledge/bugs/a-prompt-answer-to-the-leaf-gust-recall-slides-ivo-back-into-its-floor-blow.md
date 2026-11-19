---
id: bugs/a-prompt-answer-to-the-leaf-gust-recall-slides-ivo-back-into-its-floor-blow
type: bug
title: Answering the Leaf gust's wall-climb recall at once makes Ivo grip, slide and land back in the gust's floor blow; only a late press (or a second climb) is spared
status: resolved
severity: medium
tags: [guardians, autumn, leaf, grd-15, grd-04, recall, wall-climb, gust, fairness, teaching, playtest]
related: [playtests/2026-11-18-grd15-leaf-feel, bugs/the-gust-recall-grip-with-nothing-held-outlives-the-push-and-the-escape-time, systems/guardians]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - resources/characters/guardians/autumn_guardian/recall_wall_climb.tres
  - resources/characters/guardians/autumn_guardian/autumn_gust.tres
  - scenes/characters/ivo/player.gd
---

## Summary

The teaching gust blows Ivo to the wall about 0.9 s into its 2.4 s strike, and the recall opens there (time slowed to
0.2). The prompt asks for one jump press. Pressed promptly, that jump grips the wall for `RECALL_ESCAPE_TIME` (0.9 s
from the press), then Ivo slides down. He reaches the floor box's 32 px band in its last frames (2.0-2.4 s) and takes
the hit. A press near the end of the 2 s window is spared. The first use of the skill the fight teaches is punished for
answering quickly.

## Symptom

GRD-15 working tree on d47c80da, `orchard_arena`. The driver presses the recall's action after a set delay and does
nothing else (it is in the air, so it does not jump the blow):

| run | press after the window opened (real ms) | Ivo at the floor box | result |
|---|---|---|---|
| `god1` | ~56 | sliding, 26 px up at 2.36 s | hit |
| `rc300` | 361 | 52 px up at 2.0 s, 26 px at 2.4 s | hit as the box closed (`clock=R`) |
| `rc1800` | 1816 | 60 px up at 2.0 s, 43 px at 2.4 s | no hit |
| `ng1` (press, then hold into the wall and tap jump every 0.5 s) | ~56 | 200 px up | no hit |

Frame: `playtests/screenshots/2026-11-18-grd15-leaf-feel/gust_floor_blow_after_prompt_press.png` (Ivo sliding down the east
wall into the band; the floor stream is a few grey dashes).

The implementer's no-god run (`playtests/2026-11-18-grd15-leaf-fight`, `pl12`) lost a note the same way and put it down to
the driver not climbing. A human who answers the prompt and then lets go of the controls gets the same hit.

## Why the tests pass

`player_recall_test` checks the grip just after the press, not where Ivo is when the floor box opens 1.1-1.5 s later.

## Fix

Fixed in GRD-15 (2026-11-19), engine-wide: an answered recall is never punished by the move that asked for it.
`Guardian._on_skill_recalled` sets the move `Hitbox.spared` to Ivo's hurtbox while a recall move is swinging, and
`_on_attack_finished` clears it; `Hitbox._hit` refuses the spared hurtbox. The rest of the string (contact, spawns) is
unchanged. A press at 0.06, 0.36 or 1.8 s is spared the floor blow; a sweep is never spared
(`guardian_recall_answer_test`). The Bloom burst teaches at 0 damage, and the Frost charge's grace already covered a
pressed roll, so their recall tests pass unchanged.

## Options considered

Choose one:
- Make the escape grip last until the gust's floor box closes (start it at the press, end it at the move's end).
- Open the recall later (nearer 2.0 s), so a prompt press keeps Ivo above the band through it.
- Keep the behaviour, but teach it: the lesson text or the prompt says to keep climbing.
