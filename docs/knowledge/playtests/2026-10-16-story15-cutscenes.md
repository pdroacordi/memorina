---
id: playtests/2026-10-16-story15-cutscenes
type: playtest
title: STORY-15 - the daughter goes to bed after the failed song, watched and skipped
status: active
build: STORY-15 uncommitted
area_tested: "village_house (the song, its guitar beat, the lowered guitar, the daughter_to_bed cutscene, the pause menu's Skip scene)"
tags: [story-15, cutscene, actor, letterbox, camera, skip, opening]
related: [systems/cutscenes, systems/story, systems/screens, architecture/cutscenes-are-data-played-between-two-rest-states]
created: 2026-10-16
updated: 2026-10-16
ratings: { fun: 3, fluidity: 4, aesthetics: 3 }
screenshots:
  - screenshots/2026-10-16-story15-cutscenes/w_00_holding_out.png
  - screenshots/2026-10-16-story15-cutscenes/w_01_guitar.png
  - screenshots/2026-10-16-story15-cutscenes/w_02_silence.png
  - screenshots/2026-10-16-story15-cutscenes/w_03_s00.png
  - screenshots/2026-10-16-story15-cutscenes/w_04_s01.png
  - screenshots/2026-10-16-story15-cutscenes/w_05_s02.png
  - screenshots/2026-10-16-story15-cutscenes/w_06_s03.png
  - screenshots/2026-10-16-story15-cutscenes/w_07_s04.png
  - screenshots/2026-10-16-story15-cutscenes/w_08_s05.png
  - screenshots/2026-10-16-story15-cutscenes/w_09_s06.png
  - screenshots/2026-10-16-story15-cutscenes/w_10_s08.png
  - screenshots/2026-10-16-story15-cutscenes/w_11_s10.png
  - screenshots/2026-10-16-story15-cutscenes/w_12_s12.png
  - screenshots/2026-10-16-story15-cutscenes/w_13_s13.png
  - screenshots/2026-10-16-story15-cutscenes/w_14_s16.png
  - screenshots/2026-10-16-story15-cutscenes/w_15_s19.png
  - screenshots/2026-10-16-story15-cutscenes/w_16_z_after.png
  - screenshots/2026-10-16-story15-cutscenes/k_00_scene_running.png
  - screenshots/2026-10-16-story15-cutscenes/k_01_pause_with_skip.png
  - screenshots/2026-10-16-story15-cutscenes/k_02_skip_focused.png
  - screenshots/2026-10-16-story15-cutscenes/k_03_after_skip.png
  - screenshots/2026-10-16-story15-cutscenes/k_04_after.png
---

# STORY-15: the daughter goes to bed, watched and skipped

Two windowed runs of the real game (`tools/playtest/playtest_runner.tscn`), en, owning nothing, with `daughter_errand` and `baker_errand` heard; Ivo placed at x 140 in village_house and walked west 0.35 s into the song's talk.

- **Watched:** `tools/playtest/scripts/story15_daughter_to_bed.json` (22 s): the song, the guitar beat (five notes, three dead presses), "[Lower the guitar]", the hum, "…", then the scene, frames every 0.5 s.
- **Skipped:** `story15_daughter_to_bed_skip.json` (`"clock": "real"`): the same up to the scene; Escape 0.8 s into it, Down to "Skip scene", Z.

## What the frames show

- **Before the scene** (`w_00`..`w_02`): the talk starts as Ivo reaches its east edge (x 107.6, `auto_delay` 0), so he stands east of her; she holds the guitar out at x 84 by the bed's foot, and stands in at x 90 during the guitar beat. His sprite overlaps hers by a few px.
- **The scene** (`w_03`..`w_15`, about 7.8 s): the bars slide in (36 px each); the frame holds still (a one-screen interior at zoom 1 cannot pan); she lowers her eyes (`w_04`), turns her back on Ivo (`w_07`), walks west to the bed (`w_08`), crouches in front of its middle (`w_09`, `w_10`), kneels and lies down onto the mattress with her head on the pillow (`w_11`, `w_12`); the frame eases in to zoom 2 (`w_13` mid-tween shows the uneven pixels of a non-integer zoom), clamped at x 160 so the bed is at the frame's left (`w_14`); after the hold the bars close and the frame eases back to Ivo (`w_15`).
- **The hand-over** (`w_12` → `w_16`): the actor's last frame and the InBedTurned child are the same pixels; no pop was visible between the scene's last frame and the rest after it. The talk resumed and ended (`blocked=false` at 20.5 s); `daughter_song` heard.
- **Skipped** (`k_00`..`k_04`): the pause menu grows by one entry and shows "Skip scene" between Resume and Quit to title (`k_01`); focused (`k_02`) and pressed, the menu closes and the next frame shows her in bed, the bars gone and the frame back on Ivo at zoom 1 (`k_03`). The first skipped run eased the frame back from the landed zoom-2 close-up, a flash of the end; a skip that ends the scene now cuts back.

## What screenshots cannot show

- The walk's feel: 32 px at 32 px/s, the 6-frame loop at 8 fps; in the frames her feet stay on the floor and she ends exactly on the mark (the actor teleports the last 2 px or less).
- Timing reads as calm, close to doc 06's "a câmera segura um instante"; whether 1.5 s of hold is right is the user's call.
- No sound marks the scene: the hum ended before it, and there is no music system yet (the default, 2026-10-16).

## Issues

1. **Crowded at the bed's foot.** Ivo (x ~107), the girl (x 84..90) and the bed's foot (x 80) overlap a little; the room has 96 px between the wall and the door for the bed, her and him.
2. **The crouch reads as kneeling in front of the bed**, not as sitting on its edge (the user's note on `sit.png`: "It reads as a low crouch"); the lie-down starts from the clip's kneel (frame 3) so it follows the crouch.
3. **The close-up is clamped** to the room's left edge at zoom 2; a wider room or a smaller zoom would centre her.
4. One early run of the watched timeline ended in the song trials: something sent `debug_trials` (F10) twice during the guitar beat. It did not happen again in four runs of the same keys; unexplained. The runner now prints a `[playtest] debug_trials` line for every such press. The first run with it (after review, 2026-10-16) caught three: `F10`, `InputEventKey`, device 16, not echo, not sent by the timeline, window focused, at t 5.82, 7.10 and 7.85, none at a timeline key's time. The timeline's own events carry device 0, so these came from the OS keyboard while the playtest window had focus: something outside the game pressed F10, not the runner or the game. The next run was clean. Distrust a run whose log has a `debug_trials` line.

Ratings: fun 3 (the moment finally reads), fluidity 4, aesthetics 3 (the crouch and the crowding).
