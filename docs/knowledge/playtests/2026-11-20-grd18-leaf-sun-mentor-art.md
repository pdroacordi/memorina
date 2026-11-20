---
id: playtests/2026-11-20-grd18-leaf-sun-mentor-art
type: playtest
title: GRD-18 drawn move strips for the Leaf, the Sun and the mentor - most poses match their boxes; the pounce landings play in mid-air, the Sun's embers rise from its back, its claw box opens a frame early, and two recoveries pop
status: active
build: 7c1434aa + uncommitted GRD-18 working tree (Sun and mentor strips and scenes); nothing under scenes/, resources/, assets/ or globals/ changed after this session's --import at 13:32
area_tested: "orchard_arena (Leaf), caldera_arena (Sun), lighthouse_top (mentor): each GRD-18 move forced 1-3 times against a still god-mode Ivo, every physics frame drawn and logged"
ratings: { readability: 3, aesthetics: 3 }
tags: [guardians, grd-18, art, animation, hitbox, autumn, summer, mentor, playtest]
related: [systems/guardians, bugs/the-sun-claw-box-opens-one-frame-before-its-raked-paw-is-drawn, bugs/the-sun-embers-and-mentor-seeds-leave-from-the-guardians-back-not-its-mouth-or-hand, bugs/the-sun-and-mentor-pounce-landing-frames-play-in-mid-air, playtests/2026-11-18-grd15-leaf-feel, playtests/2026-11-19-grd16-sun-feel, playtests/2026-11-19-grd17-mentor-feel]
created: 2026-11-20
updated: 2026-11-20
source_files:
  - tools/playtest/scripts/guardian_art_check_driver.gd
  - scenes/characters/guardians/autumn_guardian/autumn_guardian.tscn
  - scenes/characters/guardians/summer_guardian/summer_guardian.tscn
  - scenes/characters/guardians/mentor_guardian/mentor_guardian.tscn
  - scenes/characters/guardians/spawns/lob/lob.gd
---

## Summary

A look-and-feel check of the GRD-18 strips, not a balance pass. The drawn poses match their boxes for the Leaf's
claw, blades and scatter, the Sun's second claw, bite, shafts and roar, and the mentor's glide (box x 20..78 against a
drawn hand of 74-82 px), hail and thorn row. No sprite jumps on a flip, floats on the ground, sinks into the floor, flickers,
or shows a wrong strip. The defects:
- **The pounce landing frames play in mid-air.** Sun: 0.167 s early, 72 px up. Mentor: 0.117 s early, 61 px up.
  The mentor's box also has no limb drawn on its trailing half after touchdown
  (`bugs/the-sun-and-mentor-pounce-landing-frames-play-in-mid-air`).
- **The Sun's embers sit on its back**, about 90 px behind the drawn mouth. The mentor's seed pods appear at its hip
  (`bugs/the-sun-embers-and-mentor-seeds-leave-from-the-guardians-back-not-its-mouth-or-hand`).
- **The Sun claw's box opens one physics frame before the raked paw is drawn**
  (`bugs/the-sun-claw-box-opens-one-frame-before-its-raked-paw-is-drawn`).
- **Two seams pop:** the mentor's glide recovery and the Sun's charge wind-up into its strike.

The Leaf dive's landing frame is 0.05 s early, which is minor.

## Method

`tools/playtest/scripts/guardian_art_check_driver.gd`, new this session: a `-s` driver around the runner. It writes
`GuardianAI._next` with `comfort_distance` 0 and `recall_after_attacks` 0 whenever the guardian is idle in pressure,
so each listed move is thrown in turn, link-only moves included. Ivo stands still, topped up at hp 1.

`Engine.max_physics_steps_per_frame = 1`, so every physics state is drawn. The game runs at ~6 fps of real time, but
nothing is timed in real time (no scripted inputs). Phase times below are physics frames / 60. A first Leaf run without it
(`leaf1`) drew one frame per ~10 physics steps and skipped poses; it is not used.

The driver logs a line on every change of phase, strip, frame, box or airborne state, and every physics frame in the
air. It shoots the next frame (the viewport lags one), with the live box (red) and Ivo's hurtbox (cyan) drawn on by a
Pillow sheet script. Timelines: the `guardian_bot_{autumn,summer,mentor}.json` setups, max 500 s, `APPDATA` redirected per
run and checked by a headless probe. Runs: `leaf2` (claw, blades, scatter, dive x2), `sun1` (claw, second claw, bite, spit,
shafts, pounce, charge, roar x1), `men1` (glide, hail, thorn row, seeds x2, pounce x2), `men2` (pounce x3 with Ivo
teleported to x 11420, the open floor).

## Leaf

| Move | Observed | Verdict |
|---|---|---|
| Overhead claw | Wind-up: 0 then 2 (arm straight up). Strike: 1, 4 at 0.083 (the arm swung across, about 90 px up, no box), 5 at 0.183 with the box (hand ahead at head height), 7 at 0.25 (claws on the floor ahead, box x 20..100), 6 at 0.4. | The hit lands where art is drawn: at 101.8 px Ivo is hit on frame 7, by the claws on the floor (`leaf_claw_strike_boxes.png`). On frame 5 the drawn hand reaches about 8 px past the box's 84 px front, toward Ivo's head (art without a hit, the lenient side). |
| Overhead claw wind-up | Frame 0 shows the arm low and forward, its hand at about 100 px, level with Ivo's chest. | Low-confidence readability note: for the first 0.2 s the wind-up looks like a reach already at Ivo, before the arm goes up (`leaf_claw_windup_to_recovery.png`, first tile). |
| Leaf throw | 0, 1, 3 (cocked high), then 4, 5 at 0.15 (fling), 6 at 0.35. The blades appear at the hand's height, ahead of the feet, at 0.2-0.44. | Matches (`leaf_blades.png`). |
| Scatter | 3, 5, 7 (apart) by 0.1, hidden 0.15-0.45 exactly, then back at 64 px behind Ivo as 7, 5, 3. The leaf swirl marks the spot through the hide. No shield disc floats while hidden. | Matches, and it reforms facing Ivo. The sweep that follows hits on attack_1 4 with the arm at Ivo (`leaf_scatter_and_sweep.png`). |
| Dive | 2 held through the rise (0.05-0.35), 3 the hang, 4 (arms flung up) from 0.75 through the fall, box from 0.85, 5 (landing crouch) at 0.95, touchdown at 1.0, 6 at 1.05. | The landing frame shows 3 physics frames (0.05 s) early, about 20 px up (`leaf_dive_landing.png`): barely visible, low severity. The reviewer's doubt was right in direction, not in size. Frame 4 reads as a hang, not a dive, during the 0.2 s fall (as the systems entry says). |

## Sun

| Move | Observed | Verdict |
|---|---|---|
| Claw | Wind-up 1, 3 (paw high). Strike 4, 5, 6, then 7 (paw raked to the floor, 124 px reach) through the box. | **The box opens on frame 6** for one physics frame: the box key is 0.1666666, the frame key 0.167. Ivo's hit landed on that frame with the paw drawn up by the head (`sun_claw_box_opens_on_raised_paw.png`, middle tile; bug filed). From the next frame, the paw on the floor meets the box. |
| Second claw | 1, 3 (reared, other paw high), 4, 5, 6 at 0.15 (paw down on Ivo), box 0.167-0.333 on frame 6. | Matches (`sun_second_claw_and_bite.png`, top two rows). |
| Bite | 0, 1 wind-up; 2, 3 at 0.05 with the box, 4 at 0.15 (lunged, jaws at Ivo), 5 at 0.3. | Matches: the hit lands on frame 4 with the jaws on Ivo. The wind-up's lowered head differs little from the idle (feel note, low confidence). |
| Ember spit | Wind-up 0, 1, 3 (head up and back); strike 4, 5, 6, 7 (head whipped low). | The pose reads, but **each ember sits on the lion's back**, about 80 px up at its feet x, about 90 px behind the drawn mouth, through its 0.4 s warning, then rises from there (`sun_ember_from_back.png`; bug filed). |
| Sun shafts | 0, 2 wind-up; 3, then 4-7-4 looping every 0.15 s from 0.15, 7 at 2.7; recovery 8, 9. | The reared lion is held for the whole 2.85 s with no wrong frame, and the shafts light ahead in order (`sun_shafts_rear.png`). |
| Pounce | 2 from 0 (on the floor until 0.267), 3 in the air from 0.3, **4 (the flat landing pose) from 0.70 at 72 px up**, 5 at 0.80 at 30 px up, touchdown 0.867, 6 at 0.95. | The landing pose floats for 10 frames over Ivo, who is hit at 0.783 while the body is 38 px up (`sun_pounce_landing_pose_in_air.png`; bug filed). The brief's "landing frame at touchdown ~0.7 s" does not hold: touchdown is at 0.85-0.87. |
| Charge wind-up | `charge_windup` 0, 2, 3 (crouched low, head forward), then the GRD-04 `attack_2` 0. | **Pops**: from the low crouch the lion stands up for `attack_2` 0-5 (0.5 s in place) before it lunges (`sun_strip_seams.png`, first row; the run frames 213.1 and 215.4 in `sun_charge_and_roar_pinned.png`). The new wind-up is undone by the old strike's first half second. Medium confidence that it reads as a hitch at speed. |
| Roar wind-up | `roar_windup` 0, 1, 2 (head under the mane), then `attack_3` 2 (reared). | A big pose change, but it is the rear itself, not a pop. The pinned run (Ivo against the wall, overlapped by the lion) is not good for judging the box. |

## Mentor

| Move | Observed | Verdict |
|---|---|---|
| Glide | Wind-up 0, 1; strike 2, 3 at 0.15, box 0.2-0.4 on frames 3 and 4 (flung low), 5 at 0.4. | The box fits the drawn hand: the art's leftmost pixel in the box's rows is 74 px out on frame 3 and 82 on frame 4, against the box front at 78 (`mentor_glide_hit.png`). |
| Glide recovery | `recover_1` is the GRD-06 `attack_1` 9, 11. | **Pops**: from `glide` 5 (lying along the floor) to `attack_1` 9 (standing upright) in one frame, held 0.25 s (`mentor_glide_recovery_pop.png`). High confidence; the glide's own frames 6-7 (getting up) are unused. |
| Hail call | 2, 3 (arm straight up), 4 at 0.45, then back and forth 3, 2, 3, 4 with each icicle; recovery 5, 6, 7. | Reads; the raised arm is one thin column (`mentor_hail.png`). |
| Thorn row kneel | 0, 1 bend; 2-5 kneeling, hand flat ahead; the row's warning starts under the hand. | Matches (`mentor_thorn_row_and_seeds.png`, top two rows). |
| Seed cast | 0, 1, 2 (arm raised back), 3, 4 at 0.1 (cast forward), 5. | The pose matches its contract, but the pods appear at the mentor's hip on the far side of the body, not at the hand (same cause as the embers; bug filed). |
| Pounce | 0 (wind-up), 1 (strike start, on the floor until 0.1), 2, 3 (the pale robe streaks in the air), **4 from 0.60 at 61 px up**, touchdown 0.717, 5, 6 at 0.8. | The robe's pale streaks read in the air. The landing pose is drawn 7 frames early, over Ivo (`mentor_pounce_landing.png`). On frames 5-6 every drawn limb near the floor is on one side; the box's other (trailing) half is empty, and that is where `PAST_IVO` leaves Ivo (bug filed). Recovery 6-7 draw a crouched figure in dark wisps that reads as a smudge more than a body (feel note). |

## Not reproduced / checked clean

- No `mir` flip happened mid-move. The sprite never moved vertically on the ground (feet y constant to 0.1 px on every
  grounded frame), and nothing flickered: no frame repeats or alternates outside the keyed sequences.
- A key scan of every Leaf, Sun and mentor clip found one frame key that lands less than one physics frame after a box
  edge: the Sun claw's.
- The scatter's hide is exactly 0.15-0.45 (frames 9 and 27 of the strike), with the shield hidden too.

## What screenshots cannot show

- Feel at speed: these runs drew every physics frame at ~6 real fps. Whether the pounce float (7-10 frames), the
  charge stand-up (0.5 s) and the glide pop register at 60 fps is inferred from frame counts, not seen. A human playtest
  should confirm.
- Camera motion and audio were not judged.
- Only a still Ivo was used. Hits by moving or jumping Ivos (for example the mentor's empty trailing half) are inferred
  from the box and art geometry, plus one open-floor frame.
