---
id: playtests/2026-11-18-grd14-frost-feel
type: playtest
title: GRD-14 Frost fight, independent feel pass - busy and readable in its wind-ups, but the swipe string never plays against a dodger, the far charge's charge-back is a landing trap, the charge skid hurts a rolled Ivo, and the pogo has 26 px under the ceiling
status: active
build: ab5d12d8 + uncommitted GRD-14 working tree (no file under scenes/, resources/, globals/, assets/ changed after this session's --import at 20:06)
area_tested: "lake_frost_arena: the Frost Guardian from DORMANT to RESTORED, stages 0-2; no-roll/no-double-jump Ivo, wall-pinned Ivo, roll owned (jump and roll answers), the roll recall at delayed presses, single- and double-jump pogo"
ratings: { fun: 3, fluidity: 3, aesthetics: 3, difficulty_reader: 2, difficulty_human: 4, readability: 3 }
tags: [guardians, frost, grd-14, fight, difficulty, readability, fairness, pogo, recall, playtest]
related: [playtests/2026-11-18-grd14-frost-fight, playtests/2026-11-18-grd13-bloom-fight, systems/guardians, bugs/the-frost-charge-back-after-a-far-charge-hits-ivo-as-he-lands-from-jumping-it, bugs/the-frost-charge-skids-onto-ivo-harmlessly-and-its-body-hurts-the-instant-its-recovery-ends, bugs/the-frost-slam-jump-window-closes-before-the-fists-fall, bugs/the-frost-arena-ceiling-leaves-26-px-over-the-golems-head-so-a-pogo-bounce-falls-back-into-contact, bugs/a-single-guardian-move-can-cost-two-notes-through-its-contact-box]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - tools/playtest/scripts/guardian_fight_player_driver.gd
  - resources/characters/guardians/frost_guardian/
  - scenes/characters/guardians/frost_guardian/frost_guardian.tscn
---

## What was tested

This session played the fight independently of the implementer's `2026-11-18-grd14-frost-fight`, with its own policies
and analysis. Runs went one window at a time. Each run's `APPDATA` pointed at its own scratch folder, checked first with a
headless `OS.get_user_data_dir()` probe. No run logged a key press from outside the timeline (`source=not the timeline`).
Driver: a session copy of `guardian_fight_player_driver.gd` (`pin_driver.gd`) with these additions:
- `PL_PIN=west`: hold the wall and jump instead of backing off. `PL_SLAM_LEADS` / `PL_SWIPE_LEADS` set the take-off
  sweeps, `PL_CHARGE_AT` a fixed charge jump. It walks through the golem's body in the charge's recovery.
- `PL_LEARNED=1`: the stock driver never sets `_learned` when the roll is seeded through `skills`, so it ignores every
  owned charge (`rolljump`, discarded except as "a player who never reacts").
- `PL_RECALL_DELAY`: delay the recall press.
- `PL_PG=1`: a closed-loop double-jump pogo.
- `PL_DROP_OFFS`: stand at an offset from the body drop's landing.
- `[dmg]`: logs `struck`. `gsx`/`psx` in `[st]`: screen x of the golem and Ivo.

| run | Ivo | policy | result |
|---|---|---|---|
| god1 | no roll, no double jump | stock dodging, god | RESTORED 215.1 s, 2 hits |
| nogod | no roll, no double jump | stock dodging | RESTORED 192.3 s, 1 hit (no god needed) |
| passive | no roll, no double jump | stands, answers the recall | dead at 9.97 s |
| pinw / pinw2 / pinsweep | no roll, no double jump | wall-pinned, god | 30 / 9 / 7 hits; pinw2 RESTORED 144.3 s |
| rolljump2 / rollroll | roll owned | owned charge jumped / rolled, god | RESTORED 193.6 s, 1 hit / not restored in 240 s, 2 hits |
| rec600 / rec1100 | no roll | recall pressed 0.6 / 1.1 s real after it opens | no hit / hit |
| pogo1, pg2, pg3 | single / double jump | pogo | see (3) |
| dropoff | no roll | body drop offsets, god | 2 charge-back hits; only 1 body drop |

## Findings

### (1) Frantic

Busy = telegraph + strike as a share of the pressure. "+R" adds the recovery, as the implementer's figure does. Idle is
from a string's recovery end to the next first-link wind-up.

| stage | median idle | busy (T+S) | busy +R | moves per minute |
|---|---|---|---|---|
| 0 | 0.75-0.90 s | 45-48 % | 69-70 % | ~21 |
| 1 | 0.62-0.73 s | 52 % | 74 % | ~22 |
| 2 | 0.60 s | 55-58 % | 77-78 % | ~22 |

- The punish window after a string (recovery plus idle) is 1.1-1.3 s after a swipe, 1.27-1.44 after a slam or the icicle
  fall, 1.4 after the body drop and 1.5-1.8 after a charge.
- A standing Ivo dies at 9.97 s. The GRD-12 pre-rebuild Frost killed him at 14.3 s; Bloom (GRD-13) at 10.7 s.
- **The swipe string never plays against a player who dodges.** 0 of ~80 swipes chained in the dodging runs. Backing
  off ends it, and a jump lifts Ivo above the second swipe's 96 px reach when the link is judged. The 9 second swipes
  seen (pinw) all followed a first swipe that had already hit. The full swipe, second swipe, slam string never appeared
  in 14 runs, so the most "Hollow Knight" feature of the kit is invisible to a good player.
- **Stages 1-2 lean on the icicle fall:** 30-53 % of moves (god1 39 / 38 %, rolljump2 44 / 35 %, nogod 30 / 33 %,
  rollroll 53 %). The longest run of one move was 3 icicle falls. No loop.

### (2) Readable

Wind-up start to the first live hitbox frame, all runs:

| move | to hit | pose (placeholder) | reads? |
|---|---|---|---|
| swipe | 0.69-0.75 s | arm back, then raised | yes (any jump during the wind-up clears it) |
| second swipe | 0.45-0.48 | arm low behind | only seen after a hit |
| slam | 0.79-0.82 | both fists up (`slam_windup.png`) | yes, but the jump window closes ~0.1 s after the full pose (bug) |
| charge | 1.15-1.24 to box live, plus travel | lean | yes; the teaching charge's prompt reads (`recall_teach.png`) |
| charge-back | 0.49-0.50 | none: skid and turn | the sprite flips on its first frame (`flip=false` at once), so it reads as a snap, not a turn |
| icicle fall | 0.55 per icicle | both fists up | the same raised-fists opening as the slam, but the opposite answer (keep moving, not jump in place) |
| body drop | 1.43-1.50 to the landing box | leap crouch, then the shadow | the shadow reads well (dark bar plus a light line) |

- **Icicle glint:** a white block with a dark rim, forming at the ceiling row along the frame's top 30 px
  (`icicle_glint.png`). Visible, but about 200 px above where the eye is.
- **Icicle floor mark:** light-blue ticks over the floor's white snow fringe (`icicle_floor_mark.png`). For its first
  ~0.2 s it looks like the fringe. From ~0.3 s it is taller and reads, and it lies under Ivo's feet, partly hidden by
  him. Not lost like Bloom's crack, but weak.
- **Charge-back with no telegraph:** it is visible only as the golem stopping and turning while Ivo is still in the air
  from the first charge.
- **Off screen:** 1 of 21 charge-backs began with the golem half off screen (god1 t 175.04: g.x 626 of 640).
  Ivo sat at x 416 behind the camera's ~96 px look-ahead (`charge_back_offscreen.png`). The kit's on-screen rule (range
  + 60 ≤ 320) assumes a centred camera. In rolljump2, all 59 wind-ups started fully on screen.

### (3) Dodgeable with walk + single jump + pogo

- **Swipe:** jump at or before its strike's first frame (12 jumps 0-0.10 s early: 11 clear, the 12th a lost press). 0.05 s
  after the first frame: hit 4 of 4.
- **Slam:** walking out works. Jumping: take-off 0.15-0.35 s before the strike cleared it 8 of 8, 0.10 s 19 of 20, 0.05 s
  0 of 1 (`bugs/the-frost-slam-jump-window-closes-before-the-fists-fall`; the measured jump clears 104 px only 0.30-0.92 s
  after take-off).
- **Ice wave / landing shock:** the row rule jumped every one. 0 hits.
- **Icicles:** walking clears them: 0 hits in 55 falls (165 icicles) in the free runs. At the wall (pinw2), 2 hits: the golem stood
  83 px away, so the only side step was toward it, and 3 re-aimed icicles need back-and-forth steps.
- **Body drop:** stepping out away from the golem works. The 3 body-drop hits in the free runs (god1 128.01, rolljump
  134.69, pinw2 107.04) all came as the driver stepped toward the golem from inside or at the edge of the shadow, under
  the falling body (`body_drop_near_side.png`). Computed from the parabolic path (72 px apex) and the two capsules, the
  falling body touches a standing Ivo up to ~75 px from the landing on the side it comes from. The shadow's half width
  plus Ivo is 56 px, so the warning understates that side by ~20 px. This is computed, not cleanly observed: the
  controlled `dropoff` run drew only one body drop. At the wall the landing is clamped 64 px from the wall face (96 from
  `arena_bounds`, which includes the wall row). The shadow then covers a pinned Ivo's feet, though standing still is
  safe by ~5 px (`body_drop_at_wall.png`).
- **Charge (no roll, the teaching charge):** see (5). **Owned charge, jumped:** fists 0 hits. A far charge is followed by
  a close charge-back that hit 5 of 5 times (`bugs/the-frost-charge-back-after-a-far-charge-hits-ivo-as-he-lands-from-jumping-it`).
  **Owned charge, rolled:** fists 0 hits in 18 rolls. Rolling in the charge's direction ends inside the golem's skid
  (`bugs/the-frost-charge-skids-onto-ivo-harmlessly-and-its-body-hurts-the-instant-its-recovery-ends`).
- **Wall-pinned charge:** jumping at the natural time (strike s 0.54) landed Ivo inside the stopped golem as its
  recovery ended: 8 contact hits in pinw. Jumping early (s 0.15) and walking through the body: 0 of 13.
- **Pogo:**
  - Single jump: impossible. Apex 141.5 px against a 176 px head; 32 tries, 0 strikes.
  - Double jump: 2 pogo strikes in ~50 jumps, each followed by contact within 0.45 s. The arena's ceiling stops Ivo's
    feet at 201.9 px, 26 px over the head (`pogo_ceiling.png`;
    `bugs/the-frost-arena-ceiling-leaves-26-px-over-the-golems-head-so-a-pogo-bounce-falls-back-into-contact`).
  - "O pogo é a brecha" does not hold in this arena.
- **Jump spam:** hopping toward the golem every 1.7 s (pogo1) took 0 hits in 90 s and dealt 0 damage.

### (4) Fairness

- **Hard to avoid:**
  - the close charge-back after a far charge, for a jump-only answer;
  - the charge skid ending on a rolled or pinned Ivo (the passive run died to it);
  - the last ~0.1 s of the slam wind-up;
  - inferred: the body drop's near side.
- **Off-screen wind-up:** 1 of 21 charge-backs.
- **Missing warning:** the charge-back, by design.
- **Two notes from one string:** once. A body drop hit in its fall and again in its recovery 0.99 s later
  (`bugs/a-single-guardian-move-can-cost-two-notes-through-its-contact-box`).
- **Spawns at lucidity:** every PRESSURE -> LUCIDITY in every run logged `spawns_alive=0`.

### (5) The roll recall

- The teaching charge was answered in every run that pressed.
  - The recall opens 0.27-0.43 s into the strike and the world slows to `time_scale` 0.20.
  - Presses 0-0.6 s real after it opens were never hit by the fists.
  - At 1.1 s real the fists hit at 0.995 s real (the answerable window is about 1 s real). The prompt stayed armed, and
    the press 0.1 s later still taught the roll (`skill_recalled` after the hit). It reads oddly: hit, then "learned".
- "A pressed roll is never hit by that charge" holds for its box, but not for its body. In the passive run Ivo rolled away
  (162 px), the golem's recovery skid carried it onto him, and its contact took his last note 17 ms after the recovery
  ended.

### (6) Floating, sliding, stuck, clips

- No floating: the golem's y stays at the floor outside its leaps.
- The charge recovery slides ~90 px on held frames 12-13 (the skid). The charge-back holds still through its skid and
  turn, as documented.
- Nothing got stuck. Every move played its documented placeholder frames (`[spr]`).
- The lucidity leap peaks 333 px up, above the 256 px ceiling row (`through_ceiling`, GRD-09, not in scope).
- Exit-only: one `Playback can only happen when a node is inside the scene tree` from `memorina_voice.gd:64`
  `_play_mistake`, when the run's timer quit the game mid-lucidity.

## Ratings rationale

- **Fun 3/5 (inferred):** stages 1-2 mix five moves with ~0.6 s gaps, and the wind-ups have weight. But the string
  never shows for a good player, the icicle fall is a third to half of every later stage, and the pogo has no room.
- **Fluidity 3/5 (inferred from timing):** move to move is tight. The charge-back snaps rather than turns, and the charge
  skids 90 px on two held frames.
- **Difficulty 2/5 for a reader, ~4/5 for a human (inferred):** the dodging driver won without god mode, with 1 hit. A
  human's difficulty comes mostly from the traps above (charge-back on landing, skid contact, the slam's last 0.1 s,
  the body drop's near side), which is unfair difficulty rather than the requested "estilo hollow knight" kind.
- **Readability 3/5:** swipe, slam, charge and body drop read clearly. The slam and the icicle fall share the
  raised-fists opening with opposite answers. The charge-back has no tell. The icicle floor mark blends into the snow
  fringe for its first ~0.2 s.
- **Aesthetics 3/5:** placeholder frames, not judged as art (GRD-18).

## What screenshots cannot show

Input latency, camera feel, audio and weight were not judged. Every number comes from a driver with frame-perfect
knowledge: "dodgeable" means possible, not comfortable. Human reaction claims (the ~1 s recall window, ~0.1 s after the
slam pose, the 0.2 s re-jump after landing) are arithmetic from logged times and a traced jump curve. The body drop's
near-side reach is computed, not seen in a controlled run. A human playtest of stages 1-2 with roll owned is needed
before tuning.
