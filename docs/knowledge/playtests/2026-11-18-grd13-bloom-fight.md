---
id: playtests/2026-11-18-grd13-bloom-fight
type: playtest
title: GRD-13 Bloom fight - twice as busy as before and every move is dodgeable with walk and a single jump, but stage 0 is lash-only, the dash loops off screen, and the floor warnings do not read
status: active
build: cb5416d6 (6159b81f landed mid-session, music only) + uncommitted GRD-13 working tree; "before" is a `git archive HEAD` export of cb5416d6 (pre-GRD-13 Bloom on the GRD-12 engine)
area_tested: "bloom_hollow: the Bloom Guardian fight from DORMANT to RESTORED, stages 0 and 1, played by a dodging driver"
tags: [guardians, bloom, grd-13, fight, difficulty, readability, fairness, playtest]
related: [systems/guardians, playtests/2026-11-18-grd12-engine-regression, playtests/2026-10-29-grd07-guardian-art, playtests/2026-10-29-grd07-round2, bugs/the-bloom-antler-dash-strands-it-beyond-every-other-move-and-it-dashes-back-from-off-screen, bugs/the-bloom-pounce-cannot-be-walked-under-or-jumped, bugs/bloom-spawn-warnings-are-lost-in-the-grass, bugs/the-bloom-overhead-branch-preempts-its-far-pick-by-weight, bugs/a-bloom-seed-pods-flight-crosses-the-gap-it-leaves-ivo]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - tools/playtest/scripts/guardian_fight_player_driver.gd
  - scenes/characters/guardians/guardian_ai.gd
  - resources/characters/guardians/bloom_guardian/
  - resources/characters/guardians/motion/dash_motion.gd
screenshots:
  - screenshots/2026-11-18-grd13-bloom-fight/dash_offscreen.png
  - screenshots/2026-11-18-grd13-bloom-fight/row_warn.png
  - screenshots/2026-11-18-grd13-bloom-fight/crack_zoom.png
  - screenshots/2026-11-18-grd13-bloom-fight/pods_full.png
  - screenshots/2026-11-18-grd13-bloom-fight/lash_string.png
---

## Summary

The fight is busier. Against the same dodging policy, the median idle gap fell from 1.6-2.0 s to 0.6-0.9 s. The
guardian is in a telegraph or strike for 45-51% of the pressure time, up from 31-35%. A standing Ivo now dies at 10.7 s
(HEAD 14.2 s). Every move can be dodged with walking and a single jump if the player reads it in time. A perfect-timing
driver won with 0 and 1 hits. One exception: the pounce cannot be walked under or jumped, only outrun. The fight
is frantic only in stage 1. Four things hold it back:
- **Stage 0 is lash-only at close range.** Every close pick is the lash, because the overhead branch fires on a 0.1 px
  height difference (evidence added to `bugs/the-bloom-overhead-branch-preempts-its-far-pick-by-weight`).
- **The antler dash loops, telegraphed off screen.** It opens stage 1 every time, and each dash forces another dash
  back (`bugs/the-bloom-antler-dash-strands-it-beyond-every-other-move-and-it-dashes-back-from-off-screen`).
- **The floor warnings do not read.** The thorn crack and the pod landing marks are lost in the grass
  (`bugs/bloom-spawn-warnings-are-lost-in-the-grass`).
- **The burst returns as a 0-damage launcher** every third move after the double jump is learned: 26-36% of all moves.

## Setup

- New harness piece, `tools/playtest/scripts/guardian_fight_player_driver.gd`. It is a `-s` driver around the runner, and
  the timeline only sets up. Timeline: `player_position` (-6560, 284), `skills: []` (no roll, no double jump),
  `"clock": "real"`, 110 s. The driver plays like a player:
  - In the guardian's idle and recovery, it swings twice, then backs off.
  - It backs off from lash-string telegraphs (`PL_LASH=stay` swings through them instead).
  - Thorn row: it jumps once the head is 0.12 s from Ivo.
  - Dash: it jumps 0.33 s into the strike, as the backstep ends.
  - Pods: it walks to a point 48 px from the landing spots, never through one.
  - Pounce: it walks away (`PL_POUNCE=under|jump` for the other options).
  - Burst: once the recall is learned, it backs off.
  - Recall and call: pressed and answered as the fight bot does.
  - Logs: `[st]` (phase, stage, move, T/S/R clock, link, hitbox) on every change, `[hit]` with what hurt, `[sp]` per spawn.
- Runs, one window at a time, `APPDATA` redirected per run and probed:
  - god: `god1b`, `god2` (pounce under), `god3` (pounce jump), `god4`;
  - `stay1` (lash string);
  - no god: `nogod1`, `nogod2`;
  - `pogo1`;
  - passive (40 s): main and HEAD;
  - HEAD no god: `nogod1`, `nogod2`.
- No file under `scenes/`, `resources/` or `globals/` changed after this session's `--import` (16:22).
- `god4` was cut at t 71.55: a real F10 key press from outside the timeline (the runner logged `source=not the
  timeline`) moved Ivo to the winter trial. Its data before that is used.

## (1) Frantic: idle between moves

Idle = end of a string's recovery to the next first-link telegraph. Same driver policy, no god:

| | Stage 0 median idle | Stage 1 median idle | Busy (telegraph+strike / pressure) | Moves | RESTORED |
|---|---|---|---|---|---|
| HEAD nogod1 / nogod2 | 1.96 / 1.57 s | 1.57 / 1.72 s | 34-35% / 31-32% | 7 / 6 | 46.3 / 45.0 s, 0 hits |
| main nogod1 / nogod2 | 0.90 / 0.77 s | 0.63 / 0.73 s | 45% / 48-51% | 22 / 24 | 73.9 / 87.5 s, 0 / 1 hit |
| passive (standing) | HEAD 2.82 s, main 0.71 s | - | HEAD 28%, main 41% | - | death HEAD 14.2 s, main 10.7 s |

The guardian rests about a third as long between moves. Most stage-1 gaps are 0.43-0.68 s, with longer ones (1.1-2.5 s)
only where it walks back across the arena after a dash. The fight runs longer than before (74-88 s against 45-46 s): the
driver spends its time dodging, and the dashes keep the guardian at the far wall, away from the sword.

## (2) Readable: wind-up start to hit

Logged telegraph start to the first live hitbox frame (main; HEAD in brackets):

| Move | Wind-up to hit (s) | Pose (placeholder frames) | Reads? |
|---|---|---|---|
| Lash | 0.45-0.56 (HEAD 0.67-0.70) | arm drawn back, vine | yes, if short (`lash_string.png`) |
| Back-lash (link) | 0.25-0.26 | one frame, nearly the idle stance | barely: 0.15 s, and it looks like the lash's last frame |
| Antler thrust (link) | 0.28-0.30 | drops to all fours, antlers lowered | yes: the silhouette change is the clearest cue in the kit |
| Burst | 0.78-1.09 (HEAD 0.82-1.04) | rearing | yes, but shared with the thorn row |
| Pounce / pounce again | 0.64-0.66 / 0.50-0.52 (HEAD 0.69-0.74) | crouch | yes |
| Thorn row | 0.45 telegraph + 0.2 + 0.4 crack = 1.05 to live | rearing (the burst's), then the crack | the pose is ambiguous, and the crack does not read (bug) |
| Seed lob | 0.5 + 0.1 + 0.4 + 0.7 = 1.7 to landing | leap crouch | the pods are 10 px grey squares; the landing marks do not read (bug) |
| Antler dash | 0.89-0.93 to box live, plus travel at ~1300 px/s | lowered antlers held 0.8 s, then backstep | close, yes; far, off screen in 5 of 5 shot runs (bug) |

## (3) Dodge with walk + single jump, and the punish after

| Move | Dodge that worked | Failed | Punish window |
|---|---|---|---|
| Lash string | walk away on the lash telegraph: out to 113-133 px by the hit, no hit in the back-off runs with room behind. Pinned at the west wall (pogo1, x -6997) it hit 3 of 3 times: there is no back-off room | standing: 1 hit per string, never more (HitGate) | 0.35-0.45 recovery + 0.6-0.7 cooldown; idle measured 0.43-0.9 s |
| Thorn row | a jump 0.11-0.12 s before the head arrives, during the crack or after, 11 of 11 | a jump pressed late or in an attack clip: 2 hits in god1b (driver errors) | 0.3 recovery, but the row is live 1.4 s, so the recovery is a trap |
| Antler dash | a jump 0.33 s into the strike: 18 of 19. The miss was from 107 px, where the dash arrives ~0.05 s after the backstep. Inferred: Ivo's ~0.7 s hang above 40 px allows a press from ~0.2 s before the backstep ends | - | 0.5 recovery at the far wall: unpunishable |
| Pounce | walk away through both telegraphs, 3 of 3 double pounces | walk under 0/2, jump 0/1 (bug) | 0.35 recovery |
| Seed lob | step 40-48 px off the middle spot, not through another, 3 of 3 lobs | walking through a spot: 1 hit (god3, driver) | 0.3 recovery, while the patches are live 1.0 s |
| Burst (after learned) | walk away: 0 launches in god4/nogod | - | 0.3; the burst does 0 damage |

## (4) Fairness

- **Unavoidable or nearly:**
  - The far dash's wind-up is off screen, and the stag is on screen ~0.25 s before contact. A player can only react to
    the stag entering, or learn the rhythm.
  - Pinned against a wall, the lash (range 104) and the double pounce (~370 px of room needed, inferred) have no dodge in
    the first fight's kit.
- **Spawns without warning:** none is unwarned in data (row 1.05 s, pods 1.7 s), but the two floor warnings are
  invisible in practice.
- **Double damage from one string:** none in 9 runs. In stay1, each lash-string hit cost one note, and the back-lash
  and thrust that followed hit nothing.
- **Spawns at lucidity:** every PRESSURE -> LUCIDITY logged `spawns_alive=0`, including god1b, where a thorn row was live 0.2 s
  before the cut. They are cleared.

## (5) Bugs: floating, sliding, stuck, clips

- No floating or sliding. Across the 4 analysed runs, the guardian's y stays at the floor outside the pounce, leap and lucid clips, and
  no idle clip moves it.
- The dash backstep slides 48 px on one held frame (by design for the placeholder).
- A recovery log line showed `gvx -1270`, but the position did not move (-6991.6 to -6992.0).
- Every move's clip played its documented placeholder frames (lash 2-5, back-lash 2,4,3,5, thrust burst 1-5 with the
  32 px step, dash 3/4 alternating).
- Nothing got stuck.

## The burst on the recall cadence after the double jump is learned

It feels wrong. After `skill_recalled`, `recall_after_attacks` 2 still forces the burst into every third slot. The burst is
`damage 0` with a 560 lift, so it is a free launch every few seconds. It was 5 of 14 stage-1 moves in nogod1 and 13 of 39
in pogo1. That is the most frequent move in the "frantic" stage, and it is the one with no threat: the rhythm becomes
"burst, X, burst, X". Suggestion: once the double jump is owned, give the burst its weight back, at a low value, and
damage 1, or drop the cadence.

## Ratings

- **Fun 3/5 (inferred):** stage 1 has real variety (lash, double pounce, thorn row, seed lob, dash) and short gaps.
  Stage 0 is lash-and-burst, and the dash ping-pong and the burst filler repeat.
- **Fluidity 3/5 (inferred from timing):** the move-to-move flow is tight (0.43-0.9 s gaps). The dash's cross-arena
  turn and the 0.8 s held antler pose break it up.
- **Difficulty 2/5 for a reader of the moves, 4/5 for a reactive player (inferred):** the perfect-timing driver took
  0-1 hits per fight. A standing player dies 25% sooner than before. A human's difficulty comes from the off-screen dash
  and the hidden floor warnings. That is unfair difficulty, not the Hollow Knight kind the user asked for.
- **Readability 2/5:** the lash, thrust, pounce and close dash read. The back-lash (0.15 s) barely reads. The thorn row
  and the burst share a pose. The crack, the pod marks and the far dash's wind-up do not read.

## What screenshots cannot show

Input latency, camera feel, audio and weight were not judged; this was played by a driver, not watched live. The dodge
windows are measured against a driver with frame-perfect knowledge, so "dodgeable" means "possible", not "comfortable".
The human-reaction claims (the far dash's ~0.25 s, the dash press window) are arithmetic from logged positions. The pogo
policy never landed a bounce, so this report says nothing about pogo as a dodge. A human playtest of stage 1 is needed
before tuning numbers.
