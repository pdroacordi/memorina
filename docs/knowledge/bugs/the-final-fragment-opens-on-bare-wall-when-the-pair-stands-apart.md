---
id: bugs/the-final-fragment-opens-on-bare-wall-when-the-pair-stands-apart
type: bug
title: The final fragment's opening frames the pair's midpoint at zoom 2, so after most victories neither the mentor nor Ivo is on screen
status: fixed
severity: medium
tags: [cutscene, camera, final-fragment, finale, story-42]
related: [playtests/2026-11-18-story42-final-fragment, architecture/story42-the-final-fragment, systems/cutscenes, systems/guardians, playtests/2026-11-01-grd06-restoration]
created: 2026-11-18
updated: 2026-11-18
source_files:
  - resources/cutscene/story/final_fragment.tres
  - resources/cutscene/cutscene_camera.gd
---

## Summary

`final_fragment.tres` opens with `CutsceneCamera [mentor, ivo]`, offset (0, -56), zoom 2, 1.0 s. `CutsceneCamera`
frames the mean of the targets' feet at a fixed zoom, and the zoom-2 view is 320 game px wide. When the final call
closes, the mentor and Ivo usually stand much farther apart than that, so the camera pushes in on the empty wall
between them. That wall is the last image of the fight for the ~2.2 s before the paper fade.

## Symptom

- **Victory path** (STORY-42 playtest, `guardian_fight_bot_driver.gd` + BOT_GOD, pt_BR): RESTORED at bot t 68.8 with
  Ivo at x 11558 and the mentor 465 px west (x ~11093). The frame settles on centre (11325, -1304) at zoom 2, which
  spans x 11165..11485. Both figures are outside it from about t 69.5 to the paper at ~72.
  `screenshots/2026-11-18-story42-final-fragment/victory_to_fragment_pair_out_of_frame.png`.
- **Replay path** (`FinalFragment` trigger, Ivo at the hatch, x 12048, the mentor at ~11600): the same thing happens
  with the centre at (11824, -1304). `fallback_prelude_frames_bare_wall.png`.

Before STORY-42 this could not show: `world_restoration` starts with a fade to black and `CutscenePlace` steps, so the
pair is moved under the cover. The fragment reused the restoration's frame (the plan's "the restoration's frame")
without the placing that makes that frame valid.

## Fix direction

Any of these:
- place the pair (the restoration's two `CutscenePlace` steps) under the paper, and drop the push-in;
- frame only the mentor, the subject of the victory;
- pick a zoom that fits both: zoom 1 holds pairs up to ~600 px apart.

Placing them under black before the fade would also hide the victory pose. Framing the mentor alone is the smallest
change that keeps the beat. Check the replay path too: Ivo arrives by the hatch, 450 px from the mentor.

## Fix (2026-11-18, before the STORY-42 commit)

The opening camera step frames the mentor alone (`targets [mentor]`, offset (0, -56), zoom 2): the fragment is his, and he stands where the fight left him, so he is always in frame whatever the distance to Ivo.

## Fixed (2026-11-18)

The opening `CutsceneCamera` now targets `[mentor]` alone, at zoom 2 (`final_fragment.tres`, uncommitted, 11:34).
Verified on the replay path: the frame centres on (11600, -1304), with the mentor whole and centred until the paper
(`playtests/screenshots/2026-11-18-story42-final-fragment/r2_opening_frames_the_mentor.png`). The victory path uses the
same single target, so the distance no longer matters, but it was not re-run.
