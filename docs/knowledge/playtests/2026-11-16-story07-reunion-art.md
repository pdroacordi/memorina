---
id: playtests/2026-11-16-story07-reunion-art
type: playtest
title: STORY-07 the reunion with its own art - the daughter waits at the window with her back to the room, turns, runs at 112 px/s with the run clip, and the talk takes over; no error
status: active
build: 9c6ba2cb + the uncommitted STORY-07 step 12 tree (the daughter's `run` and `window` clips, `CutsceneWalk.run`, `LocomotionStats.run_speed`, the `Waiting` rest at x 400)
area_tested: "world restored, all four guardians restored, the opening heard. tools/playtest/scripts/story07_reunion_art.json (story07_walk_home_reunion.json plus a 0.25 s burst from 22 to 29.25 s): lighthouse_top to the house door by teleports and on foot, Up, the reunion scene, its talk, then Up on her."
tags: [story-07, return, reunion, daughter, cutscene, art, playtest]
related: [architecture/story-07-epilogue, playtests/2026-11-16-story07-walk-home-reunion, systems/story, systems/cutscenes]
created: 2026-11-16
updated: 2026-11-16
ratings: { fun: 0, fluidity: 4, aesthetics: 4 }
screenshots:
  - 2026-11-16-story07-reunion-art/a01_window.png
  - 2026-11-16-story07-reunion-art/a02_she_turns.png
  - 2026-11-16-story07-reunion-art/a03_run.png
  - 2026-11-16-story07-reunion-art/a04_run.png
  - 2026-11-16-story07-reunion-art/a05_first_line.png
  - 2026-11-16-story07-reunion-art/a06_after.png
---

# STORY-07: the reunion with its own art

One windowed run, its own `APPDATA`. No SCRIPT ERROR; the only engine output is the usual "resources still in use at exit".

## What changed against `playtests/2026-11-16-story07-walk-home-reunion`

- **The window** (`a01_window`): at x 400, straight under the window, she stands with her back to the room, on tiptoe, arms up toward the sill, and the loop rises and settles. She now reads as waiting at the window, not standing by the table. The window hangs high (its sill at y 200, her fingertips at about y 240), so she reaches toward it rather than leaning on it.
- **The turn** (`a02_she_turns`): she faces Ivo and drops to her standing strip on one frame, then the "!".
- **The run** (`a03_run`, `a04_run`): the run clip plays from her first step; she leans forward with her braid flying. Measured from the log: x 351.6 at 25.55 s to x 242 at 26.56 s, about 110 px/s (`run_speed` 112), against 64 px/s for the old walk. She covers the 160 px in about 1.5 s and stops exactly on `Marks/Reunion` (x 240).
- **After it** (`a05_first_line`, `a06_after`): the talk and the rest (`Reunited`, standing, facing him) are unchanged.

## Notes

- The run now ends about 0.6 s sooner, so the timeline's fixed Z presses drift. The last Z (44.6 s) landed after the talk had closed and made Ivo jump (`line_6 ... land`). This is a timeline artefact, not a defect; `story07_reunion_art.json` keeps the presses as they were.
- At zoom 1 her run passes in front of the chair and the hearth; she is drawn over both, as an actor should be.

## What frames cannot show

The feel of the run's speed against the 0.8 s hold and the "!" (whether 1.5 s across the room reads as eager or rushed), and all audio.
