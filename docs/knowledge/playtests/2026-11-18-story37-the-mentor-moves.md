---
id: playtests/2026-11-18-story37-the-mentor-moves
type: playtest
title: STORY-37 - the mentor breathes and gestures while he talks at the lantern (tilt on "Guardo.", lower on "Guardava.", hold-out on "Muitas mãos."), at reading pace and with Z mashed every 0.1 s
status: active
tags: [story-37, story, mentor, lighthouse, lantern, staged-strip, line-gesture, dialogue, breath, seam]
related: [architecture/story37-the-mentor-moves-while-he-talks, bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1, playtests/2026-11-17-story34-mentor-at-the-lantern, systems/story, systems/dialogue]
created: 2026-11-18
updated: 2026-11-18
build: 676f62c7 + uncommitted STORY-37 tree (art and scene 07:45, imported 07:46; runs 08:03-08:09, no source changed during them)
area_tested: "frost_edge/lighthouse_top, the mentor_gift talk (pt_BR, zoom 1.5, frame_lift 64)"
ratings: { fun: n/a, fluidity: 3, aesthetics: 3 }
source_files:
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
  - scenes/world/story/line_gesture.gd
  - resources/dialogue/story/mentor.tres
  - assets/sprites/world/story/mentor/holding_breathe.png
  - assets/sprites/world/story/mentor/tilt.png
  - assets/sprites/world/story/mentor/lower.png
  - assets/sprites/world/story/mentor/hold_out.png
  - tools/playtest/scripts/talk_reader_driver.gd
  - tools/playtest/scripts/story37_mentor_talk_setup.json
---

## Summary

All three gestures play on their own line with the top box open and the keeper whole below it. Every planned cut is
pixel-exact: turn to Holding, Holding to each gesture, and each gesture back to Holding. Mashing Z every 0.1 s leaves
nothing stuck: he ends in the Stasis grey, and only `Stasis` is visible.

One defect: the breath and the tilt redraw most of the figure between frame 0 (the exact still) and frame 1 (the PixelLab
drawing). The breath therefore shimmers twice a cycle instead of only rising and falling
(`bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1`).

## What was tested

- `talk_reader_driver.gd`, extended this session. It prints a `[strip]` line with the visible `Props/Mentor` child, its
  clip and frame on every change. `STRIPSHOT=1` takes a shot one frame after each change; `MASH=<s>` taps Z while the talk
  blocks Ivo. Timeline: `story37_mentor_talk_setup.json`, which is `mentor_gift.json`'s spawn with Left held 0.6-1.2 s.
- **r1, reading pace:** Z 1.0 s after each line finishes typing, choice 0. Every strip frame was shot.
- **r3, mash:** READ 0.1 plus a Z every 0.1 s.
- **r2 started no talk** (Left 0.5 s stopped Ivo at x 11728.4, short of the zone edge 11720). It was discarded and re-run
  as r3 with a longer walk.
- Pixel diffs were taken in a crop around the keeper (window x 400-690, which excludes Ivo), as counts of window px
  differing by more than 20.

## Findings

- **Timings (r1, runner `t`):**

  | Line / beat | Strip | Box |
  |---|---|---|
  | "Guardo." 11.73 | Tilting 11.73-12.82 (f0 1 2 1 0), then Holding | open until 13.00 |
  | "Guardava. Guardava." 14.61 | Lowering 14.61-16.21 (lowest 15.01-15.70), then Holding | open the whole time |
  | "Muitas mãos. Nenhuma guardou." 21.88 | HoldingOut 21.88, at its hold from 22.28 until the gift | open until 24.03 |
  | Gift | EmptyHand from 24.03 | closed |
  | Stasis | cross-fade 33.51-35.13, then `Stasis` only | |

  Each gesture starts on the frame its line appears. The tilt ends 0.18 s before the box closes. The lower ends while
  the line is still on screen. The talk was unchanged otherwise: control returned at 40.98 (STORY-34 third run: ~40.9).
- **(1) Gestures visible with the box open:**
  - The top box's bottom edge is at window y ~335, and the keeper's hood starts just under it. No gesture rises above his
    resting head. Ivo is whole.
  - Tilt (`01_tilt_on_guardo_box_open.png`, `04_tilt_sequence.png`): the mask and shoulders lean forward toward Ivo and
    back. It reads as a nod.
  - Lower (`02_lower_on_guardava_box_open.png`, `05_lower_sequence.png`): the flute hand sinks from his chest to about
    his waist, holds ~0.7 s and rises. It is clear, and most of it plays while "Guardava." is still typing.
  - Hold-out (`03_hold_out_on_many_hands_box_open.png`): the arm extends level toward Ivo. In the lantern's 0.05 grey,
    the brown flute (clear in the source, `hold_out.png` frame 3) is desaturated to a grey curl on the hand. The pose
    reads as "offering something", but not clearly "the flute". This is subjective.
- **(2) The breath (defect, medium):** see `07_breath_cycle_frame0_differs.png` and
  `08_holding_breathe_source_frames_0_to_3.png`.
  - Frames 1-3 differ from each other only by the breath: the mask goes down 2 art px over the exhale, and the shoulders
    and hem shift 1 px.
  - Frame 0 is the old still. Its robe stripes, mask and snow flecks sit 1 art px to the side of the PixelLab frames, and
    its shading is drawn differently.
  - On screen, 0 <-> 1 changes 8208 px, against 2766 for 1 -> 2 and 1872 for 2 -> 3. That step happens twice per 1.75 s
    breath, when frame 0 shows for its 0.375 s.
  - From stills this is a shimmer at the end of each exhale, on top of a breath that does read as a slow rise and fall.
    Whether it reads as jitter at speed needs a human; at 1.5 px per art px it may be faint.
  - The tilt has the same jump on its first frame (15546 px), the lower and hold-out less so (14874 / 16494, but those
    frames also move the arm).
  - Bug filed: `bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1`, with the source-sheet
    numbers for all five strips. `raise.png`'s matched frame 0 (568 vs 300) is the control.
- **(3) Cuts:**
  - Turn f5 -> Holding f0: 0 px in the keeper's crop.
  - Holding f0 -> Tilting f0: 12 px (one sparkle at the crop's edge).
  - Holding -> Lowering f0: 0 px (only the box opening, at the top edge).
  - Holding -> HoldingOut f0: 0 px.
  - Tilt and lower end -> Holding f0: 0 px.
  - Not new, but now visible next to the hold-out: Playing's last `play` frame (flute at his mouth) cuts to Holding f0
    (flute at his chest) at 21.87, 17406 px, one frame before "Muitas mãos." opens (`06_phrase_to_hold_out_to_empty_hand.png`,
    frames 1-3). It predates STORY-37 (STORY-11's phrase release). It reads as a snap because the hold-out starts on the
    very next frame.
  - Hold-out -> EmptyHand at the gift (24.03): the arm snaps from held out back up to his chest, as planned until STORY-35
    animates the hand-over. The box closes and the gift's spring disc floods the frame within ~0.2 s, so the snap is
    seen for about one disc frame.
- **(4) Mashing Z every 0.1 s (r3):**
  - "Guardo." lasted 0.26 s. The tilt played on through the box-closed `MentorPause` and released to Holding at 7.23.
  - "Guardava." lasted 0.26 s. `MentorPhrase` stood Playing in over Lowering at its lowest frame (8.49): the hand jumps
    from his waist to his chest on the raise's first frame (`09_fast_press_lower_cut_to_raise.png`). This happens only on
    a fast press and just before the pulse's colour flood. Low severity, and expected by the plan.
  - "Muitas mãos." lasted 0.38 s. The gift cut HoldingOut at frame 2 to EmptyHand.
  - The cross-fade to Stasis ran 16.73-18.13. Afterwards `[strip]` showed only `Stasis` until the run ended at 61 s: no
    gesture strip, Holding or EmptyHand remained visible. Control returned at 22.78 in the silence hold's bars, with him
    grey, flute down (`10_fast_press_ends_in_stasis.png`). No errors in either run's log beyond the usual exit leak lines.
- **Not judgeable from frames:** whether the breath at 1.5 px per art px is felt as life or as jitter in motion, whether
  the tilt's 0.6 s hold lands on the word, and audio (none was added).

## Ratings rationale

- **Fun n/a:** a story talk.
- **Fluidity 3, inferred from frame timings and diffs:** gestures sit on their words and every planned seam is exact,
  but the breath loop has a frame-0 redraw twice a cycle, and the phrase-to-Holding snap now leads straight into the
  hold-out. Down from 4 until the strips' frame 0 is re-registered. Needs a human look at speed.
- **Aesthetics 3:** the tilt and the lower read well at talk zoom with the box open. The hold-out's flute is lost in the
  grey, and the frame-0 redraw makes the robe's inner shading swim.

## After this run (2026-11-18)

The frame 0 to frame 1 redraw was fixed before the commit by `tools/art/lock_to_still.py` (`bugs/the-mentors-new-strips-redraw-the-figure-between-frame-0-and-frame-1`, now fixed): the breath's 0→1 step changes 302 px instead of 2510. Frame 0 of every strip is unchanged, so the cuts measured here still hold; the new breath was checked by frame diffs, not by a second windowed run.
