---
id: playtests/2026-11-18-grd15-leaf-feel
type: playtest
title: GRD-15 Leaf fight, independent feel pass - busier and readable, but a dodging player gets a two-move blades/hop loop for all of stage 0, the west lintel makes the overhead claw undodgeable, and a prompt answer to the gust recall is punished
status: active
build: d47c80da + uncommitted GRD-15 working tree (no file under scenes/ or resources/ changed after this session's --import; no commit landed during the session)
area_tested: "orchard_arena: the Leaf Guardian from DORMANT to RESTORED, stages 0-2; dodging driver with and without god mode, jumping the sweeps, passive, pogo, recall press delays; jump height under the west lintel"
ratings: { fun: 3, fluidity: 3, difficulty: 3, readability: 3 }
tags: [guardians, autumn, leaf, grd-15, fight, difficulty, readability, fairness, recall, wall-climb, playtest]
related: [playtests/2026-11-18-grd15-leaf-fight, playtests/2026-11-18-grd14-frost-feel, playtests/2026-11-18-grd13-bloom-fight, systems/guardians, bugs/the-orchard-arenas-west-lintel-caps-ivos-jump-at-74-px-so-the-leaf-claw-cannot-be-dodged-there, bugs/a-prompt-answer-to-the-leaf-gust-recall-slides-ivo-back-into-its-floor-blow, bugs/the-leaf-dive-aims-at-ivos-airborne-feet-and-ends-in-the-air, bugs/the-orchard-arenas-west-lintel-overlaps-a-scarecrow-placed-at-the-96-px-margin, bugs/the-scattered-leaf-guardian-still-takes-sword-contact-so-a-pogo-bounces-off-thin-air]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - tools/playtest/scripts/guardian_fight_player_driver.gd
  - resources/characters/guardians/autumn_guardian/
  - scenes/characters/guardians/autumn_guardian/autumn_guardian.tscn
  - scenes/world/rooms/wind_orchards/contents/orchard_arena.room
---

## What was tested

This pass is independent of the implementer's `2026-11-18-grd15-leaf-fight`. Runs went one window at a time. Each run's
`APPDATA` pointed at its own scratch folder, checked first with a headless `OS.get_user_data_dir()` probe. No run logged a
key press from outside the timeline. Timeline: `guardian_bot_autumn.json` (double jump owned, wall climb not; the first
gust teaches it), and 13 s / 70 s copies.

Driver: a session copy of `guardian_fight_player_driver.gd` with three changes:
- The hop's walk direction is fixed when its strike starts. The shipped driver recomputes "toward" every frame. Once the
  scarecrow passed over him, Ivo turned and walked back into the landing box (`god1`, t 4.4).
- `PL_CLIMB=1`: once wall climb is owned, through the gust's strike it holds into the nearest wall and taps jump every 0.5 s.
- `PL_RECALL_DELAY=<ms>`: wait this long after the recall opens before pressing.

| run | settings | result |
|---|---|---|
| `god1` | shipped policy, god | restored 133.5 s, 4 hits (hop by the driver's turn-back, teaching gust, sweep x2 while mid-swing) |
| `ng1` | no god, climb | **restored 128.8 s, 1 hit** (a sweep backed into from 67 px) |
| `sj1` | no god, climb, `PL_SWEEP=jump` | died at 111 s: overhead claw under the west lintel, hop at the wall x2 (a stale driver choice) |
| `pas1` | passive, god, 258 s | never left stage 0 (no damage dealt): the AI's own mix |
| `pogo` | `PL_POGO=1`, god, 70 s | 0 pogo hits landed (driver limit, as for Bloom): pogo not judged |
| `rc300`, `rc1800` | teaching gust only, press 0.36 s / 1.8 s after the recall opens | hit / not hit |
| `lintel` | double jump at five x by the west wall | peak 74 px under the lintel |

## Frantic: tempo per stage (dodging runs)

| stage | busy (telegraph+strike) | +recovery | idle gap mean / max | moves (`god1`, `ng1`, `sj1`) |
|---|---|---|---|---|
| 0 | 51-54 % | 66-67 % | 0.91 / 1.50 s | hop 23, leaf blades 17, gust 6, **sweep 0** |
| 1 | 55-62 % | 71-77 % | 0.73-0.78 / 1.02 s | dive 9, sweep 5 (one full string), gust 5, hop 3, blades 3 |
| 2 | 59-66 % | 76-78 % | 0.55-0.62 / 1.02 s | dive 7, scatter 4, sweep 4 (one full string), hop 5, gust 4, blades 2 |

The escalation is real and measured: the idle gap falls from 0.9 to 0.6 s, and by stage 2 a move is winding up or striking
two thirds of the time. That is the "frenético" the user asked for. Stage 0 has no variety for a dodging player, though:

- **The stage-0 loop.** In every dodging run (`god1`, `ng1`, `sj1`, `pogo`: 4 of 4), stage 0 settled into leaf blades,
  hop, leaf blades, hop, a 4.8 s cycle repeated 5-8 times (`sj1`: 16 of 18 strings). The sweep string, the Leaf's signature,
  was thrown **0 times in 64 stage-0 strings**. Two rules cause it. Jumping a returning blade makes the hop the overhead pick.
  Walking under or away from the hop leaves Ivo ~150 px off, past the 114 px far band, so the far pick is the blades
  (or the gust). The passive run shows the stage's real mix when nobody jumps: sweep 49, hop 21, blades 16, gust 6 of 92,
  with 18 full sweep, second sweep, claw strings. The fight the user sees in stage 0 depends on how they dodge, and dodging
  well gives the dullest version. This is the implementer's "a jump-happy player gets the hop and the blades in turn",
  quantified: it is the whole stage, not a tendency.
- **Every pressure after a lucidity opens with gust, then hop** (6 of 6). The lucidity leap leaves Ivo ~459 px away. Walking
  in, the guardian passes the band where only the gust (range 256) reaches, so the far pick is the gust with no roll. The
  gust leaves Ivo at a wall, far away, and the hop follows.

## Readable

Wind-up to the first live hitbox, measured over all runs (scaled s): sweep 0.47-0.56, second sweep 0.40, overhead claw
0.50-0.52, hop 1.09-1.13, dive 1.30-1.33, gust 2.87-2.93. Scatter: the body is gone 0.15-0.45 s into the strike, and
the sweep that follows has its own 0.4 s wind-up.

- **Leaf blades** (`blades_returning_low.png`): three small grey rectangles with a dark rim. They read well enough at 2x, but
  against the grey sky they are low contrast. The out (centre 72 px, over Ivo's head) and back (centre 14 px) heights read in
  sequence. A still frame cannot show the spin.
- **Dive** (`dive_hang_and_shadow.png`): the shadow is a bright outlined bar with a comb under it, 0.75 s before the dive.
  It reads more like a UI meter than a shadow, but it is unmissable. 0 of 15 dives hit. The hang drifts toward Ivo, so the
  diving body comes down steep. Its leaf skirt reaches past the shadow's edge and brushes an Ivo standing just outside, with
  no hit. That looks like a near miss the game forgave.
- **Scatter** (`scatter_hidden_swirl.png`): the wind-up is the gust's reaching arm (the same strip), so for 0.4 s it can be
  taken for a gust. The vanish is clean, with no sprite left behind in any frame. The swirl is a column of leaf squares over
  the same bar as the dive shadow, and it marks the reform spot from the strike's start. The reformed body overlaps an Ivo
  standing at 64 px (its claw over his head) without a hit. 0 of 4 scatter sweeps hit.
- **Overhead claw**: its wind-up shows both arms held forward at head height. That is distinct from the sweep's low arm, but
  it does not read as "raised high". The strike frames show the claw sweeping low along the floor. A player who jumped two
  sweeps sees a third low swipe coming, and the box that reaches 150 px up is not what the art shows.
- **Hop and dive** share the leap wind-up. The dive's shadow lands 0.45 s later and tells them apart.
- **Gust floor blow** (`gust_floor_blow_after_prompt_press.png`): at the far wall the stream is a few grey dashes on the
  floor. Nothing marks the 2.0 s instant the box opens.

## Dodgeable

With walking, a single jump and the double jump, every move was dodged in play, except as listed below. The best evidence is
`ng1`: no god mode, restored with 1 hit, against the implementer's `pl12` death at 13.8 s. Both of `pl12`'s main causes were
driver artefacts: the hop's per-frame "toward" (above), and no climbing after the teaching press. Punish windows: the hop's
0.35 s and the dive's 0.6 s recoveries were punished by the driver (`autumn_hurt` after both). The sweep's 0.35 s recovery
was not reached from the back-off distance.

The pogo was not judged: the driver's pogo landed 0 hits in 70 s, as in the Bloom pass.

## Fairness

- **The overhead claw is undodgeable at the west wall** (`bugs/the-orchard-arenas-west-lintel-caps-ivos-jump-at-74-px-so-the-leaf-claw-cannot-be-dodged-there`,
  high). The lintel caps any jump at 74 px for x <= ~-10140. The documented pinned answer, a double jump over 150 px, peaks
  at 74 there (`claw_under_west_lintel.png`, `claw_hits_at_74px_cap.png`). The gust blows Ivo to that wall whenever the
  scarecrow is east of him. In `sj1`, 9 of 36 wind-ups and both claws came with Ivo under it.
- **A prompt answer to the teaching gust is punished** (`bugs/a-prompt-answer-to-the-leaf-gust-recall-slides-ivo-back-into-its-floor-blow`,
  medium). Pressed 0.06 or 0.36 s after the prompt: grip, slide, hit as the floor box closes. Pressed at 1.8 s: no hit.
  Keeping climbing avoids it.
- **The hop when Ivo is in the air.** In the loop above, the hop is picked because Ivo jumped a blade. Its wind-up always
  starts with a blade still returning (`blade@-4`, `blade@46` at the hop's telegraph). The landing box opens 1.1 s after the
  pick, and Ivo is back on the floor 0.6-0.7 s after a blade jump. That leaves ~0.4 s to choose under or away, which is
  tight but fair. Stage 0 is not too harsh for a human with the double jump. It is monotonous. Cornered, the hop must be run
  under toward the scarecrow. The landing is clamped so that its box (front 68 px, landing 71 px off the FightWall stop)
  covers a still Ivo at the wall.
- No move cost two notes, and hits were always more than 1 s apart. No live wind-up started off screen. The only off-screen
  guardian frames are the gust's floor blow with Ivo blown to the far wall, which is by design. Every PHASE change logged
  `spawns_alive=0`, so lucidity clears the blades, shadows and swirls.

## The wall-climb recall

Answerable: the recall opened at the wall 0.9-1.1 s into the first gust in every run (x -9003, the east wall), and one press
taught wall climb. The gust carried Ivo across the arena from every distance it was thrown (60-250 px, including to the far
west wall at 924 px). The fight never stalled: the longest idle gap in the dodging runs was 1.5 s, so the 1400 px sight fix
holds. The recall's blow is the bug above. With climbing, the owned gust was never a hit in 6 gusts, at either wall. At the
west wall the climb stays under the lintel at ~71 px, which is still above the 32 px band.

## Bugs and checks

- Floating, sliding, stuck: none. Hop, dive and scatter always ended at y -1248.0/-1248.1, and no body moved during
  recovery.
- Scarecrow invisible after a scatter: no. The sprite is back at 0.45 s every time.
- `bugs/the-leaf-dive-aims-at-ivos-airborne-feet-and-ends-in-the-air` (reviewer, found by reading the code): not reproduced in
  15 dives. Evidence was added to the entry.
- After Ivo's death (`sj1`, 111 s) the scarecrow went on and threw a full claw string 2.8 s later, during the fade. Cosmetic,
  not filed.

## Ratings (inferred from logs and frames, not felt)

- **Fun 3/5.** Stages 1-2 are busy and varied (6 moves, 0.6 s gaps). Stage 0 is a two-move loop for anyone who dodges well,
  and stage 0 is half the fight's pressure time (38-45 of 98-104 s).
- **Fluidity 3/5.** Wind-ups chain into each other with no stalls. The placeholder strips (the claw reusing the gust strip,
  the hop and dive sharing the leap) make the transitions read as reused poses.
- **Difficulty 3/5.** A scripted dodger with walk, jump, double jump and climb restores with 1 hit. A human will be slower to
  react but can read every tell. The two unfair spots (west-wall claw, prompt gust) are where a human dies, not where the
  design means them to.
- **Readability 3/5.** The dive shadow and the scatter swirl are strong. The blades are grey on grey. The claw's art does not
  show its 150 px reach. The gust's floor blow has no tell of its own.

## What screenshots cannot show

Input latency, the weight of the hop's landing, whether the 0.48 s sweep feels fast or cheap, and audio. Every "fair" above is
measured from a scripted policy with perfect reaction. A human playtest should confirm the hop's ~0.4 s decision window after
a blade jump and how the stage-0 loop feels.
