---
id: playtests/2026-11-17-story34-mentor-at-the-lantern
type: playtest
title: STORY-34 - the mentor at the lantern's lowered lamp, the approach, the turn, the two pauses, the stasis "…", the empty gallery and the four-restored lantern
status: active
tags: [story-34, story, mentor, lighthouse, lantern, cutscene, dialogue, dialogue-box, camera, fact-presence, guardian, finale, hatch, helix-stair]
related: [architecture/story34-mentor-at-the-lantern, bugs/the-mentors-lantern-talk-opens-the-top-box-over-his-face, bugs/the-mentor-approach-walks-ivo-back-east-and-he-talks-with-his-back-to-the-mentor, playtests/2026-10-16-story16-opening, systems/story, systems/cutscenes, systems/dialogue, systems/guardians]
created: 2026-11-17
updated: 2026-11-17
build: ab5a1642 + uncommitted STORY-34 tree (first run imported 16:47; second run re-imported after the approved art, the lamp raise and face_height 110)
area_tested: "frost_edge/lighthouse_top (the opening talk, the stasis, the four-restored arena), lighthouse_interior (the helix climb, the empty gallery, the hatch)"
ratings: { fun: n/a, fluidity: 4, aesthetics: 4 }  # first run 3; see Second run
source_files:
  - scenes/world/rooms/frost_edge/contents/lighthouse_top.room
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
  - resources/dialogue/story/mentor.tres
  - resources/cutscene/story/mentor_approach.tres
  - resources/cutscene/story/mentor_turns.tres
  - tools/playtest/scripts/mentor_gift.json
  - tools/playtest/scripts/story16_mentor.json
  - tools/playtest/scripts/story34_four_restored.json
  - tools/playtest/scripts/talk_reader_driver.gd
---

## Summary

The lantern talk plays in the designed order, and every beat is timed as data says: a 1.2 s silence plus 0.4 s around
the turn cut, and a 1.6 s box-closed pause after "Guardo.". The hatch is open, the gallery is empty, and with the four
restored the still keeper is gone, the guardian body stands at (720, 672) and the fight starts as the fade ends.

Two visual problems remain:
- At zoom 2 the top dialogue box covers the keeper from the waist up on every line (a bug, filed).
- The lowered lamp is cropped to its bottom ~12 px by the frame's top. It reads well only at zoom 1.

A run-in from the hatch reproduced "Ivo talks with his back to the mentor". It was fixed mid-session and re-verified.

## What was tested

pt_BR throughout. `APPDATA` was redirected per run.

Runs:
- `talk_reader_driver.gd` (new, a `-s` driver around the runner). It reads the talk like a player: Z 1.0 s after each
  line finishes typing, choice 0 ([Tocar de novo]). It logs every line, every visible `Props/Mentor` child with its alpha,
  and `MentorGuardian` visible/process_mode. It screenshots each line and each 0.2 s of a box-closed beat.
- Runs from the teleport spawn (11780, -1250) with a 0.5 s Left: fresh save, and the opening's talks heard
  (`story16_mentor` facts).
- A real arrival: the helix climb from the interior door, up through the joint to the attic, the hatch (interior 12,4,
  no `requires`), then up into the lantern at col 30. Done twice: once stopping just short of the auto talk, and once
  with Left held through it (the natural run-in), before and after the `mentor_approach` fix.
- `story34_four_restored.json` (new): the same climb with `restored_guardians` [0..3] and `mentor_gift` heard.
- `lighthouse_helix_climb.json` unchanged, and the re-timed `mentor_gift.json`, which was verified in order.

## Findings

- **Sequence and timing (measured, runner `t`):**

  | Event | t (s) |
  |---|---|
  | Approach starts | ~1.5 |
  | "Ei…" shows | 2.95 |
  | Box closes | 4.12 |
  | Holding (turn cut) | 5.31 |
  | "…Você veio pelo caminho longo." | 5.75 |
  | "Guardo." closes | 11.90 |
  | "Guardava. Guardava." | 13.51 |
  | Phrase (`Playing`) | 18.20-20.80 |
  | Gift (`EmptyHand`) | 22.93 |
  | Choice | 27.17 |
  | Stasis cross-fade | 32.39-34.00 |
  | "Se eu o quê?" | 34.45 |
  | Silence hold, then unblocked | 39.85 |
  | Up on him gives "…" | 42.07 |

  - The silence and the turn match the data (1.19 + 0.44 s), and the pause is 1.61 s.
  - The second run, with the earlier talks heard, matched within 0.03 s.
- **The approach** (`01_approach_lamp_mid_zoom.png`): from a stop just inside the zone, Ivo strolls ~70 px at 77 px/s
  while the camera zooms to 2, holds 0.6 s, then says "Ei…". It reads as deliberate.
  - Stopping 6 px short of the zone's east edge (world x 11720, which Ivo's 12 px `DoorSensor` must overlap) starts
    nothing. That is fine: a player keeps walking.
- **Run-in from the hatch with Left held** (`08_hey_back_turned_before_fix.png`):
  - Before 17:00 the talk started at x 11646, west of `ivo_near`. The approach walked him back east, and he said "Ei…"
    and every following line with his back to the keeper (`facing=1` for the remaining 30 s).
  - The same bug was filed in parallel by the reviewer
    (`bugs/the-mentor-approach-walks-ivo-back-east-and-he-talks-with-his-back-to-the-mentor`) and fixed with a
    `CutsceneFace` at 17:00:41.
  - Re-run after the fix (`09_hey_facing_after_fix.png`): one 0.25 s sample faces east while he steps 10 px back, then he
    faces west from "Ei…" on. The small step-back-and-turn reads like a shuffle in stills. Whether it looks natural in
    motion needs a human.
- **The turn** (`03_turn_cut_to_holding.png`): the AtLamp still (facing west, hand up) cuts to Holding (facing east)
  with the box closed. As a placeholder cut it is legible.
  - The keeper is drawn pale and near-white in the frost edge's grey, so the change reads mostly from the arm's side.
    The drawn `turn` strip will matter.
  - `at_lamp.png` and `turn.png` appeared in `assets/sprites/world/story/mentor/` during the session (16:52, 16:57),
    still unreferenced. Every run drew the placeholders.
- **Box placement over the mentor (bug):** the camera holds still at (11628, -1296), zoom 2, for the whole talk. That
  part is good: no pan between speakers.
  - The top box covers the keeper's face, hand and the lamp on every line, and clips Ivo's hair (`04_box_over_mentor.png`).
    He is seen only in the box-closed beats.
  - This is against "Caixa pela cabeça": `bugs/the-mentors-lantern-talk-opens-the-top-box-over-his-face`. The fix is
    `face_height` on the `t`, or a lifted frame.
- **The lowered lamp:**
  - At zoom 2 only the lamp's bottom ~12 game px shows at the top edge (`02_at_lamp_zoom2_lamp_cropped.png`). The raised
    hand is ~8 px under it, so "hand to the lamp" reads only as "hand to something at the edge of the frame".
  - At zoom 1 (the approach before the zoom lands, after the talk, the four-restored arena) it reads clearly as a dark
    cage lantern on a long chain over him (`07_stasis_lamp_zoom1.png`, `10_four_restored_arrival.png`).
  - Lifting the talk frame ~25-30 px would show the lamp, but it puts more of the keeper under a top box.
- **Pulses and stasis:** the phrase's winter disc and the gift's spring disc frame both figures at zoom 2
  (`06_phrase.png`). The 1.6 s stasis cross-fade is smooth in 0.04 s samples. The silence hold's bars frame `mentor_home`
  with Ivo in shot.
- **Pace (inferred from timing, not felt):** about 37 s from "Ei…" to control, with a reader who presses 1 s after
  typing. The three wordless beats (silence, turn, pause) total ~3.2 s, and none can be skipped by a press.
  - It reads slower and clearer than the gallery version: the turn now separates "Ei…" from his answer, and the pause
    separates "Guardo." from "Guardava.". It does not look padded, because each wordless beat carries a change on
    screen (the turn, the closed box).
  - However, during the pause the keeper is visible only from the waist down (the box is closed, but the frame crops
    nothing more), so it does not show what the pause is about. Needs a human playtest.
- **Stasis "…"** (`13_stasis_up_ellipsis.png`): walk left 0.15 s, Up, "…" shows at zoom 1. Correct.
- **Gallery and hatch** (`12_gallery_empty.png`): the middle gallery is empty, and no talk starts there. The helix climb
  passes the joint both ways as before, and the attic hatch takes Ivo up with no requirement.
- **Four restored** (`10_four_restored_arrival.png`, `11_four_restored_fight.png`):
  - `Props/Mentor` shows nothing (Gone). `MentorGuardian` is visible with `process_mode` 0, at (11600, -1248).
  - Ivo arrives on the hatch 256 px east of the body, inside the 560 px arena radius. The fight leaves DORMANT at t 20.43,
    the frame the fade reaches 0. The guardian closes in ~3.5 s, telegraphs at 23.9 and hits a standing Ivo at 24.9.
  - No talk opened. Untested: whether `mentor_stasis`'s Up prompt stays off over the body, because Ivo never stood at
    22,20 before being hit.
- **Timelines:** `mentor_gift.json` and `story16_mentor.json` were re-timed from the measured schedule (pt_BR; English
  text lengths differ). The original estimates fell out of step by the third line, because a Z during typing completes
  the line instead of advancing it.

## Ratings rationale

- **Fun n/a:** a story talk.
- **Fluidity 4, mostly inferred from timing:** every beat fires in order at its data time, with no stalls, no camera
  hitch and a still camera. The one stutter seen is the step-back-and-turn on a run-in, which needs a human look.
- **Aesthetics 3:** the zoom-1 composition is the best this scene has had (keeper, lamp and Ivo in one frame). At zoom 2,
  where the talk spends its time, the box hides the keeper and the frame hides the lamp, and the turn is still a cut.

## Second run (2026-11-17, after the coordinator's lantern changes)

Re-imported, then re-ran on the new tree:
- `talk_reader_driver.gd` with 0.07 s bursts through the box-closed beats;
- the re-timed `mentor_gift.json` (every frame in order);
- the hatch run-in with Left held;
- `story34_four_restored.json`.

The changes under test:
- the approved `at_lamp.png` on AtLamp, with the flute overlay at (687, 558);
- the 6-frame Turning strip in `mentor_turns.tres`;
- the lamp raised 20 px (y 428);
- `face_height` 110 on both lantern talks.

- **The turn in motion** (`r2_01_turning_strip_5.28_to_6.33.png`, frames at 5.28 / 5.50 / 5.65 / 5.87 / 6.01 / 6.16 /
  6.33): Turning runs 5.32-6.31 (0.99 s). The arm lowers from the lamp, he faces front, then he turns east with the flute.
  It reads as a turn, not a cut.
  - **No jump at the end:** between the last Turning shot (6.16-6.23) and Holding (6.31-6.33), the only pixels that change
    are in Ivo's column (bbox x 504-560, his idle).
  - **A small pop at the start:** the first Turning frame changes ~60 art px around the raised hand and flute against
    AtLamp + overlay (diff bbox x 168-224, y 64-136 window px, 5.28 → 5.32). Frame 0 of the strip and the at_lamp still +
    overlay do not quite agree at the hand. It is low severity and barely visible at 6 fps.
- **Timing:** everything after "Ei…" is now 1.0 s later, because the strip is longer than the old 0.4 s cut. Holding
  arrives at 6.31, "…Você veio pelo caminho longo." at 6.75, and control returns at ~40.9. `mentor_gift.json` and
  `story16_mentor.json` are re-timed (+1.0 s after the first Z), with shots across the turn.
- **Box placement: fixed.** Every line of `mentor.tres` now opens the bottom box (`r2_03_bottom_box_face_visible.png`).
  The keeper's face, mask and raised hand stay visible above it, and Ivo's head and shoulders show at its top edge.
  - The trade: the floor and Ivo below the chest are under the box.
  - For the stasis "…" (zoom 1, `r2_04_stasis_bottom_box_zoom1.png`) the bottom box hides Ivo except a tuft of hair, and
    the keeper's legs. It is a one-line look, so acceptable.
  - `bugs/the-mentors-lantern-talk-opens-the-top-box-over-his-face` is marked fixed.
- **The lamp at zoom 2: no longer shows at all.** Max brightness in the top 60 window rows over the lamp's columns drops
  from 193 (the lamp's bottom sliver, first run) to 92-117 (wall only); see `r2_02_at_lamp_no_lamp_at_zoom2.png`. The
  20 px raise moved it out of the talk frame. The keeper's hand now reaches to the top edge of an empty frame. At zoom 1
  the lamp reads as before (`21_up_on_him`, the arena).
- **Facing:** the hatch run-in with Left held still faces the keeper from "Ei…" on: one `facing=1` sample during the
  step back, then 33 of 33 samples `facing=-1`.
- **Four restored:** unchanged. The keeper is gone, the body is at (11600, -1248), DORMANT → PRESSURE as the fade ends,
  and no talk opens.
- **Ratings after the second run:** fluidity 4, aesthetics 4. The box no longer hides him, and the turn is drawn. The
  lamp, now out of the zoom-2 frame, is what still costs the "hand to the lamp" image.

## Third run (2026-11-17, zoom 1.5 and `frame_lift` 64)

The user chose "Zoom 1,5 e quadro mais alto", so `mentor.tres` now runs at zoom 1.5 with `Dialogue.frame_lift` 64. I ran
after the coordinator's gate import (no `--import` of my own), using `talk_reader_driver.gd` with a new `CAMLOG=1` per-frame
`[cam]` line (screen centre and zoom). The beat timings are unchanged from the second run, within 0.04 s.

- **Frame:** it eases in over ~0.8 s to (11628, -1359.5) at zoom 1.5 and holds there, unchanged, for the whole talk (3.07 to
  36.9). There is a small y wobble on the way in: -1332 → -1320 → -1359, over ~0.4 s.
- **Box: back at the top.** With the frame lifted, the keeper's eyes sit below `TOP_BOX_BOTTOM`, so `DialogueBoxSide.place`
  picks the top box again (`r3_01_zoom15_lift_top_box_keeper_whole.png`). That works here:
  - **The keeper is whole.** His hood top touches the box's bottom edge (window y ~338 against ~335), and his face, raised
    hand and robe are clear below it.
  - **Ivo is whole**, face included, with ~10 world px of floor under his feet.
- **The lamp:**
  - **Box closed (the silence, the turn, the pause, the phrase, the gift):** it is in frame and centred above the raised
    hand (`r3_02_zoom15_lamp_over_hand_box_closed.png`). The "hand to the lamp" image finally reads at talk zoom.
  - **During lines:** the top box covers the lamp body. Only its chain and cap show above the box.
- **Release: not clean** (`bugs/the-mentor-silence-release-eases-to-a-look-ahead-frame-then-cuts-96-px-to-ivo`). After
  `mentor_silence`'s zoom-2 hold, the frame eases 0.8 s toward x 11560 (Ivo plus a -96 px look-ahead), then cuts 96 px to
  x 11656 in one frame at t 41.70. The first and second runs' 0.5 s samples show the same jump, so it predates this change.
  - The ease from the talk's 1.5 into the silence's zoom 2 (36.9-38.2) has no step.
- **Uneven pixels at 1.5** (`r3_03_zoom15_uneven_pixels_ivo_4x.png`, Ivo's head at 4x): art pixels alternate between one
  and two game pixels wide.
  - Horizontal run lengths through the sprites go from clean multiples of 2 at zoom 2 (2, 4, 8, 12, 16) to 1/2/6/12 at 1.5.
  - In a still at normal size it reads as slightly lumpy outlines on Ivo's face and the keeper's mask edge, noticeable only
    on a close look.
  - The frame holds still for the whole talk, so no crawl was seen. Any crawl would show only during the 0.8 s eases;
    stills cannot judge that.
- **Ratings unchanged** (fluidity 4, aesthetics 4). The lamp and the whole keeper are gained. The 96 px release cut costs
  fluidity until it is fixed.
