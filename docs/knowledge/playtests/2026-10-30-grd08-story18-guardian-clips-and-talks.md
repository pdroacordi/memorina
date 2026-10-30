---
id: playtests/2026-10-30-grd08-story18-guardian-clips-and-talks
type: playtest
title: GRD-08 + STORY-18 - every performance clip plays at its moment and perform animates through the lesson; the talks are verbatim, but the Bloom bark covers the stag and the first talk's zoom hides both guardians
status: active
build: d2bebe3 + uncommitted GRD-08/STORY-18 working tree (no file under scenes/resources/assets/globals changed after this session's --import)
area_tested: "spring_woods/bloom_hollow (Bloom, Ivo from -6560), frozen_lake/lake_frost_arena (Frost, Ivo from 5130): whole fights to RESTORED, the lesson, both first talks and the repeatable talk"
tags: [guardians, grd-08, story-18, bark, balloon, talk, dialogue, lesson, animation, playtest]
related: [systems/guardians, systems/dialogue, architecture/guardian-performance-and-talks, bugs/the-bloom-bark-balloon-falls-under-the-call-slot-onto-the-stags-body, bugs/the-first-guardian-talks-zoom-hides-the-guardian-behind-the-dialogue-box, bugs/perform-end-plays-after-the-camera-has-left-the-guardian, bugs/the-lucidity-leap-lands-outside-the-frame-so-its-land-clip-is-not-seen, playtests/2026-10-29-grd07-round2]
created: 2026-10-30
updated: 2026-10-30
ratings: { fun: 3, fluidity: 3, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/bloom_lucid_enter_and_empty_leap_frame.png
  - screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/bloom_bark_first_landing_sequence.png
  - screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/bloom_bark_covers_the_stag.png
  - screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/frost_barks_above_the_head.png
  - screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/bloom_play_song_and_relapse.png
  - screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/bloom_perform_animates_in_lesson.png
  - screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/frost_perform_and_after_lesson.png
  - screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/bloom_talks.png
  - screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/frost_talks.png
  - screenshots/2026-10-30-grd08-story18-guardian-clips-and-talks/bloom_prompt_and_zoomed_talk.png
---

## What was tested

Four whole fights with a new driver, `tools/playtest/scripts/guardian_fight_talk_driver.gd`. It is the GRD-07 fight bot
plus `[bark]` logging, lesson shots and a talk script. The timelines were `guardian_bot_bloom.json` and
`guardian_bot_frost.json` with max_duration 260, `BOT_GOD=1`, locale en, each run with its own `APPDATA`:

| Run | Answers | Gesture | Result |
|---|---|---|---|
| bloomA | both right | HOLD (Take the blossom) | RESTORED 43.1 s, lesson to 104.6 s |
| bloomB | first wrong (2nd note) | LET (Let it fall) | RESTORED 62.4 s |
| frostA | first window left to lapse | HOLD (Close your hand) | RESTORED 92.1 s |
| frostB | first wrong | LET (Open your hand) | RESTORED 86.7 s |

Clip timings come from the `[spr]` texture/frame log. Bark timings, text, row count and box rect come from `[bark]`.
Visibility comes from `[shot]` guardian screen positions (game px, view 0..640).

## 1. Clips at their moments: PASS (with two staging notes)

All 13 lucid moments, both lessons and all relapses follow the resolver table:

- **lucid_enter** starts on the phase change (Bloom 8.73 s, Frost 9.69 s), 4 frames, before `leap`'s crouch.
  One `lucid` frame shows between them (Bloom 0.067 s, Frost ~0.017 s). It is invisible at speed, so it is not filed
  (`bloom_lucid_enter_and_empty_leap_frame.png`, first row).
- **play_song** runs from the first call note to the window (Bloom 13.71-17.07, Frost 14.66-17.96; 23 frame changes
  per call). Both read as a guardian holding a flute to its mouth: the stag a wooden pipe, the golem an ice one
  (`bloom_play_song_and_relapse.png` top two rows; `frost_barks_above_the_head.png` last tile).
- **relapse** plays (5 frames, 0.75 s, then idle) after a right answer, after a wrong one (bloomB 18.01 s,
  frostB 19.18 s) and after the window lapsed (frostA 24.30 s, window 17.99-24.30). It reads as a hunched flinch
  (`bloom_play_song_and_relapse.png` bottom row).
- **perform** animates through the lesson's freeze. It has 308 frame changes from 43.19 to 104.53 s (Bloom) and
  493 from 92.16 to 190.49 s (Frost), about one per 0.2 s. In the frames the pose changes: the stag sways and tilts
  the pipe, and the golem raises and lowers its flute (`bloom_perform_animates_in_lesson.png`,
  `frost_perform_and_after_lesson.png`). It is not frozen.
- **perform_end then restored**: Bloom 104.64-105.20 then `restored` from 105.42; Frost 190.59-191.18 then from
  191.40. **Both play off screen.** The pair is released at `performance_finished`, the camera glides back to Ivo,
  and the guardian is at screen x -7 to -97 by the second frame of the clip
  (`bugs/perform-end-plays-after-the-camera-has-left-the-guardian`).
- During Frost's lesson push-in the golem stands at the left edge (x ~56), and its crown is cut by the top of the
  frame from ~145 s on (`frost_perform_and_after_lesson.png`). This is a note, not filed.

## 2. Bark balloons: FAIL for Bloom placement, PASS for Frost, text and timing

- **One per lucid moment, and the retry after a failure.** Bloom (right answers): LUCID_0 and LUCID_1. Bloom with a
  wrong first answer: LUCID_0, RETRY "Again. Before it closes.", then LUCID_1. Frost: "…Cold.", "…Again." (after
  the wrong answer and also after the lapse), "You. …Small. Moving.", then "That song. Take it. Before I hold it.".
  The stutter marks are stripped. Every text matches design 05 word for word.
- **Rows and duration:** 1 or 2 rows (LUCID_0 Bloom and LUCID_2 Frost are 2), 2.15-2.20 s on screen. The text is the
  menu pixel font, legible at 1x (`bloom_bark_covers_the_stag.png`).
- **Closes at the first call note:** on all 13 barks the CLOSED line has the same timestamp as `play_song` frame 0.
- **Never over the call sheet, never over Ivo**: the slot avoidance works in every frame looked at.
- **Bloom: the balloon covers the stag, 5 of 5.** Both sides overlap the centred slot, so it falls "under the slot"
  to y 172-230, below the head anchor. Only antlers and hooves show, with the tail pointing into the chest
  (`bugs/the-bloom-bark-balloon-falls-under-the-call-slot-onto-the-stags-body`, `bloom_bark_covers_the_stag.png`).
- **Frost: correct.** The box sits above the golem's crown, the tail on its head, and the sheet stands aside
  (`frost_barks_above_the_head.png`).
- **The landing (GRD-09):** the first leap of each fight lands off screen (Bloom x 886, Frost x 867-883). The bark
  opens then, clamped to the screen edge, pointing at nothing. The guardian is fully in frame only +0.71 s (Bloom) and
  +0.95-1.05 s (Frost) into the bark's 2.16 s. Later landings come in within ~0.2 s. Before touchdown the frame shows
  Ivo alone for ~1.5 s (`bloom_lucid_enter_and_empty_leap_frame.png` 10.0-11.5 s,
  `bloom_bark_first_landing_sequence.png`). Evidence added to
  `bugs/the-lucidity-leap-lands-outside-the-frame-so-its-land-clip-is-not-seen`.

## 3. Pacing: inferred only, 3/5

Measured: phase change to the answer window takes 8.3 s on every moment. The breakdown is lucid_enter 0.6, leap
~2.2 (of which ~1.5 s shows Ivo alone), bark 2.16, then the call 3.3 s. The Bloom fight is now 43 s, against 40 s
before (GRD-07), which is the extra 1.5 s on each of 2 moments. Inference, not observation:
- The 2.2 s lead-in is right for Bloom's two-row line (37 characters, ~17 characters per second). On the first
  bark, though, 0.7 s of it is spent with the stag off screen or under the balloon.
- For Frost's one-word lines ("…Cold.", "…Again.") 2.2 s of a still golem probably reads as a beat of silence.
  That suits the "loose words" voice, but four of them per fight add 6 s.
- The longer drag is the empty frame during the leap, not the bark.

A human playtest is needed to judge whether 8 s between the last hit and the first note feels like suspense or a
wait. Audio (the call, the groan) cannot be judged here.

## 4. After restoration: PASS for the flow, FAIL for framing

- **Up prompt:** the `look_up` glyph stands over the restored guardian's head, once Ivo is in reach and after each
  talk ends (`bloom_prompt_and_zoomed_talk.png` right). It hides while a talk runs. During the zoom's ease-out after
  the first Frost talk it briefly sits at the top edge of the frame (`frost_talks.png` 434).
- **First talk:** the plate reads "Bloom Guardian" / "Frost Guardian" with the guardian portrait, and Ivo's lines
  have his portrait. All lines match design 05 EN word for word, both gesture options in both fights:
  - "Take it. It won't last." → [Take the blossom] "Hold it gently. It goes anyway." / [Let it fall] "Yes. That is
    how it comes back.";
  - "Take. It melts in a hand." → [Close your hand] "Yes. Hold. …It still goes." / [Open your hand] "Water. Good.
    Let it run.".
  The choices show under the question line, with the focused one in red.
- **Repeatable:** a second Up gives "The woods are loud again. I like it." / "The ice talks at night. I let it."
  (one restored guardian, so no variant). It is unzoomed and frames both bodies.
- **The first talk's zoom 2 hides the guardian.** The box at the top covers the stag's head and the golem from the
  hips up for all six lines and the gesture, and the golem's crown also leaves the frame
  (`bugs/the-first-guardian-talks-zoom-hides-the-guardian-behind-the-dialogue-box`, `bloom_talks.png`, `frost_talks.png`).

## 5. Errors: PASS

No script errors and no asserts (the GRD-08 startup duration asserts held) in any of the 4 runs. The only lines are
exit-time leaks ("4 resources still in use", "5 ObjectDB instances") and the existing `lake_chasm.room` invalid-UID
warning, present in every run.

## What screenshots cannot show

Audio (the guardian's octave-down call, the relapse groan, the lesson track against `perform`'s 0.2 s loop), input
feel and the camera glide's smoothness. The bot reads lines at ~1 s after typing, faster than a person. The
readability verdict is from the frames, not from timing a real reader.
