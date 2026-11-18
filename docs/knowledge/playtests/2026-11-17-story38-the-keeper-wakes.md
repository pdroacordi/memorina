---
id: playtests/2026-11-17-story38-the-keeper-wakes
type: playtest
title: STORY-38 - the still keeper at the lamp, the wordless awakening (walk, silence, turn cut, cross-fade, wrong raise), the hand-over to the guardian body, the grey wall, the skip, a death and retry, and the opening before the four
status: active
tags: [story-38, story, mentor, lighthouse, lantern, cutscene, guardian, finale, fight-wall, camera, letterbox, pacing, fact-presence]
related: [architecture/story38-the-keeper-wakes, bugs/the-keeper-wakes-frame-hides-ivo-and-the-keeper-below-the-waist, bugs/the-mentor-guardian-hits-a-still-ivo-1-8-s-after-the-awakening-hands-back-control, bugs/the-mentor-silence-release-eases-to-a-look-ahead-frame-then-cuts-96-px-to-ivo, playtests/2026-11-17-story34-mentor-at-the-lantern, systems/cutscenes, systems/guardians, systems/story]
created: 2026-11-17
updated: 2026-11-17
build: 36a74534 + uncommitted STORY-38 tree, imported 19:33:42; no file under scenes/resources/assets/globals/tools/playtest changed after it (checked 19:46)
area_tested: "frost_edge/lighthouse_top: the four-restored lantern from the col-36 hatch, mentor_wakes played and skipped, the fight's first seconds, the col-35 grey wall, a death at the guardian and the return from the frost_cliffs bench; the opening talk before the four (mentor_gift, and a run-in from the new hatch)"
ratings: { fun: n/a, fluidity: 4, aesthetics: 4 }  # second run; first run 3/3 (placeholders, cropped frame, 1.8 s first hit); fluidity inferred from timings
source_files:
  - resources/cutscene/story/mentor_wakes.tres
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
  - scenes/world/rooms/frost_edge/contents/lighthouse_top.room
  - tools/playtest/scripts/story38_keeper_wakes.json
  - tools/playtest/scripts/story38_keeper_wakes_skip.json
  - tools/playtest/scripts/story38_keeper_wakes_retry.json
  - tools/playtest/scripts/story38_wall_holds.json
  - tools/playtest/scripts/story38_keeper_wakes_probe_driver.gd
  - tools/playtest/scripts/mentor_gift.json
---

## Summary

Everything the plan promises works. The keeper stands grey at the lamp with his back to the hatch. The zone starts the
scene. The keeper and the body are never both drawn and never both missing (0 violations over ~2,900 probed frames in
six runs). The fight leaves DORMANT one frame after the scene ends, never before. The grey wall closes on that frame and
holds Ivo even against a wall climb. The skip lands the same end. After a death the lantern is back to the still keeper,
and the scene plays again in full. The opening talk before the four is unchanged.

The scene's own pacing is about right: 3.35 s on the mark, 4.8 s in all. Two things undo the "time to take it in":

- **The fight hits a still Ivo 1.8 s after control returns** (bug). The guardian walks at him on the first frame, and the
  first telegraph starts as the zoom-out lands.
- **The frame shows only the top half of the scene** (bug). The zoom-1.5 frame is raised 128 px under letterbox bars, so
  Ivo is cut at the waist and the keeper at the knees through the whole scene.

The turned keeper is never held either: the turn cut and the cross-fade start on the same frame.

## How it was run

- Godot 4.7.2, windowed, APPDATA redirected per run. The new `story38_keeper_wakes_probe_driver.gd` is a `-s` driver around
  the runner. It prints one `[p]` line per rendered frame on any change: the visible `Props/Mentor` children with alpha and
  strip frame, the body's `visible`/`process_mode`/phase/telegraph/swing/x, `FightWall.is_closed()`, the playing
  cutscene, Ivo, and the camera centre and zoom (`CAM=1`). `KILL=<s>` kills Ivo. A 40-line `inv.py` checked the invariants
  on those lines.
- Runs:
  - `story38_keeper_wakes` (twice, plus once under the probe);
  - `story38_keeper_wakes_skip`;
  - `story38_wall_holds` (new: all skills, run east, jump, double jump, wall-climb for 8 s);
  - `story38_keeper_wakes_retry` (new: seated at `frost_cliffs_bench`, teleport to the hatch, the scene, stand and die,
    respawn, teleport back, the scene again; run twice);
  - `mentor_gift` (before the four);
  - a scratch variant of it starting on the new hatch and running west.
- The runner's `t` is game time (`clock` default). The skip run uses `"clock": "real"`.
- Fixed in `story38_keeper_wakes.json`: the shot times now land on the measured beats. Its first draft photographed "the
  first telegraph" 2.5 s after it happened and "the turn" 0.6 s before it.

## Timeline (game s, `story38_keeper_wakes`, identical within 0.02 s across runs)

| t | Beat | Notes |
|---|---|---|
| 0.0 | On the hatch (x 12048) | `StillAtLamp` drawn, body `visible=false`, `process_mode` 4, wall open (`01_keeper_still_at_lamp`) |
| 2.22 | Zone crossed at x 11822 | `mentor_wakes` starts; bars in 0.6 s, zoom 1 → 1.5 over 1 s, Ivo walked at pace 0.4 (76.8 px/s) |
| ~3.7 | Ivo on `ivo_stand` (11704) | facing west; 0.5 s silence + 1.0 s on the keeper's back |
| 5.23 | Turn (placeholder cut) | `Stasis` facing east for exactly one frame, then the cross-fade starts on the next |
| 5.23-5.92 | Cross-fade Stasis → `GuardianStill` | 0.7 s; the two silhouettes don't align, so mid-fade is a double exposure |
| 5.92-7.05 | `RaisingWrong` f0..f4 | f1 at 6.07, f2 6.27, f3 6.37, f4 6.62; ends on the body's idle frame |
| 7.046 | Scene ends | staging empty and body visible on the same frame; phase DORMANT |
| 7.052 | Fight PRESSURE, wall closed | next frame |
| 7.05-7.81 | Zoom 1.5 → 1, bars gone by ~7.45 | centre eases (11711, -1376) → (11602, -1332), then a 6 px step to 11608 at 7.85 |
| 7.85 | First telegraph | body walked 11600 → 11646 since 7.07 |
| 8.42 | Swing | |
| 8.85 | Ivo hit (hp 3 → 2) | knocked to x 11771 |

## Findings

### Works

- **Keeper before the scene:** grey, at the lamp, hand raised, back to the hatch. No body, no wall
  (`01_keeper_still_at_lamp`).
- **Hand-over is clean:** the strip's last frame and the body's first frame are the same pose at the same place
  (`04_raise_and_handover_crops`, panels 5-6; the pixel diff there is the zoom starting, not the pose). There is no
  frame with both and none with neither. `inv.py` found 0 violations in `p1`, `sk1`, `wall`, `death3` and `retry`.
- **The fight never starts early.** It is DORMANT (body absent) through every scene frame, and PRESSURE on the frame after
  the end, in all five scene plays.
- **The wall holds.** It closes on the fight's first frame (Ivo is 296 px west of it, so "clear" holds). With double jump
  and wall climb, Ivo climbs its face to the ceiling (y -1770, under the row-2 roof) and stays at x 11988.9 for 6 s. He
  never passes (`09_wall_holds_climb`). The curtain reads as a dithered grey column, full height (`08_wall_closed_off_frame`).
- **Skip:** Escape → Pular cena → Z at 5.5 s lands the same end. The body appears, PRESSURE and the wall closed on the next
  frame, and the camera cuts straight to the zoom-1 frame (`10_skip`).
- **Death and retry:** the third hit kills Ivo at ~22 s. He respawns seated at the bench at ~23.5 with the lantern rewound:
  `StillAtLamp`, no body, wall open. Back at the hatch, the scene plays again from the zone (29.71) with identical beats
  (`11_retry_scene_again`). The awakening costs ~4.8 s per attempt, plus the ~1.5 s walk from the hatch.
- **Before the four:** `mentor_gift` plays as in STORY-34: approach, "Ei…", the turn strip, the talk, the gift, the stasis,
  the silence, "…". `mentor_wakes` never starts, the body stays absent and the wall stays open (`12_before_four_opening`).
  Running in from the new col-36 hatch (x 12048, `move_left` held 2.5 s) also starts `mentor_approach` at x 11647 and
  stops Ivo at 11656 facing west.
- **Camera release:** the STORY-39 96 px cut does not show here. Ivo faces the guardian, so the ease ends at his
  look-ahead point (11608) with only a 6 px step at 7.85 and an 11 px vertical dip during the zoom. That is mild.

### Problems

1. **The fight's first hit lands 1.8 s after control returns**
   (`bugs/the-mentor-guardian-hits-a-still-ivo-1-8-s-after-the-awakening-hands-back-control`). The same +0.02 / +0.80 /
   +1.36 / +1.80 s (move, telegraph, swing, hit) showed in the played, skipped and retried scenes. The telegraph starts on
   the frame the zoom-out lands, 0.4 s after the bars are gone. This works against the user's ask. The scene gives the
   player time to see who the guardian is, but none to become a player again before the first swing.
2. **The scene's frame cuts both bodies at the waist**
   (`bugs/the-keeper-wakes-frame-hides-ivo-and-the-keeper-below-the-waist`, `02_frame_hides_legs`). Zoom 1.5, centre 128 px
   above the feet, and 24-world-px bars: the bottom bar starts 32 px above the floor. The cracking and the raise play on
   half a figure, and Ivo is a head and shoulders in the corner. The talk frame this was copied from had no bars.
3. **The recognition beat has no length (design note, not filed).** The keeper turns (the cut to `Stasis`) and starts
   fading into the guardian on the same frame (`03_turn_cut_and_crossfade_crops`, panels 2-4). The face Ivo knows, looking
   at him, is never on screen at rest. The user's sentence is about exactly that recognition: "ele não espera encontrar o
   guardião que antes ele conversava agora agressivo". A 0.6-1.0 s hold on `Stasis` before the crack would carry it. The
   approved `StillTurning` strip would also give the turn its own 1.0 s. Today the 1.5 s of waiting is spent on his back,
   and the turn costs nothing.
4. **The wall closes off screen (pacing note).** It closes at x 12000. The zoom-1 frame's right edge after the release is
   x ~11928, so the player never sees "the grey walls close". They find it only by running back to the hatch. If the
   closing is meant as the signal that the fight began, the release frame could include it, or a sound must carry it
   (sound not verified here).
5. **Placeholders read weakly (expected).** At this size the keeper's `Stasis` and the guardian's idle are nearly the same
   grey robed figure. The cross-fade shows as a short double exposure, and `RaisingWrong` as one odd frame (f1, the hand
   at the head) between idles. The art contracts are what will make "the grey breaking" readable. Judge the cross-fade
   duration again when they land.

### Not a problem

- The pause menu's intent during the skip run says "De volta à vila." The timelines seed `mentor_gift` but not
  `elder_return`, so that is a seeding artefact, not STORY-38.

## Pacing verdict (inferred from timings, not felt)

- Walk 1.5 s, silence and the keeper's back 1.5 s, turn plus crack 0.7 s, raise 1.1 s: about 3.35 s on the mark,
  matching the user's "about 3 s".
- At the slow walk and with the bars, that reads as long enough to notice something is wrong.
- What is missing is distribution and aftermath:
  - put some of the back-hold into a hold on the turned keeper;
  - give 1.5-2 s of guardian idle after the bars before the first move.
- Fluidity 3 is an inference from those numbers, not an observation. Camera smoothness, the silence's weight and how the
  fight cue enters out of it need a human playtest with sound.

## Second run (23:44, after the fixes and the approved art)

**Build:** re-imported at 23:44:34 on 36a74534 plus the uncommitted tree. Changes since the first run:
- the zone covers room x 0..940, floor to roof, and the scripted walk uses pace 0.6;
- `GuardianStats.opening_hold` is 1.5 s;
- the frame is zoom 1.0 with offset (0, -112);
- the drawn `StillTurning`, `Cracking` and `RaisingWrong` strips are in, with a 0.8 s hold on the turned `Stasis`.

No file under scenes, resources, assets, globals or tools/playtest changed after the import (checked 23:48). Ratings for
this build: fun n/a, fluidity 4 (inferred), aesthetics 4.

### Runs

The probe ran on all four:

| Run | Result |
|---|---|
| `story38_keeper_wakes` | twice (probe with shots, then the retimed timeline) |
| `story38_keeper_wakes_skip` | |
| scratch `jump_over` | double jump from the hatch across the old x 11720..11820 strip |
| `story38_keeper_wakes_retry` | retimed: teleport back at 29.0, max 45 s |

- **Keeper and body:** 0 "both drawn", 0 "neither" and 0 "fight during the scene" in all four probe runs (about 1,500 frames).
- **The wall** closes one frame after the body appears, every time.

### Timeline (game s, played scene)

| t | Beat |
|---|---|
| 2.21 | zone crossed at x 11822; bars in; the camera follows at zoom 1 and eases up to (11711, -1360) |
| ~3.2 | Ivo on the mark (walk 0.6 pace, 115 px/s) |
| 3.55-4.55 | `StillTurning` (1.0 s) |
| 4.55-5.34 | turned `Stasis` held (0.8 s) |
| 5.34-5.98 | `Cracking` (0.64 s) |
| 5.98-7.10 | `RaisingWrong` (0.8 s), then the body faces Ivo (0.3 s) |
| 7.10 | body first frame, PRESSURE, wall closed |
| 8.66 | body first moves (+1.56) |
| 9.40 | first telegraph (+2.29) |
| 9.98 | swing (+2.88) |
| 10.41 | hits a still Ivo (+3.31) |

### Findings

- **Fixed: the first hit** (`bugs/the-mentor-guardian-hits-a-still-ivo-1-8-s-after-the-awakening-hands-back-control`). The
  same numbers came out in the played, skipped, jump-entered and retried scenes: move +1.55, telegraph +2.29-2.32, swing
  +2.87, hit +3.30 (was +0.02 / +0.80 / +1.36 / +1.80). The guardian stands idle for the whole release and 1.5 s after it,
  and the telegraph begins 2.3 s after control returns (`r2_06_first_telegraph_2_3s`). A hit ending the hold early was not
  exercised.
- **Fixed: the frame** (`bugs/the-keeper-wakes-frame-hides-ivo-and-the-keeper-below-the-waist`). From the mark to the end the
  camera holds (11710.9, -1360.0) at zoom 1.00. The lamp, the whole keeper, the whole Ivo and a floor strip sit between the
  bars (`r2_01_on_the_mark_whole_frame`). The release only eases the offset back: about 0.8 s to the look-ahead point
  (11608), with no zoom change. The only step is a single 6 px one at 7.9 s, mild. The cost of zoom 1 is that both figures are
  small (Ivo about 27 game px), so the strips' detail reads at a distance.
- **The drawn beats read** (`r2_03_turn_crack_raise_crops`, every shot from 3.55 to 7.10; each shot shows the frame before
  its label):
  - The turn is a real turn: back → three-quarter → front → facing Ivo, hand lowering.
  - The turned keeper then stands facing Ivo for 0.8 s (`r2_02_turned_keeper_held`). This was the missing recognition beat
    (first run, problem 3), now there.
  - `Cracking` shows as dark fragments breaking up the robe over about 0.6 s. That is the subtlest of the three at zoom 1: it
    reads as "something is wrong with him" more than "grey breaking".
  - `RaisingWrong` (the hand going to the mask, then out stiffly) reads as a gesture.
  - Still, `Stasis` and the guardian's idle are close in silhouette at this size. The change is told by the motion of the
    strips more than by any difference between the first and last pose.
- **No tone jump at the raise-to-body cut.** The two shots on either side of the cut were taken with the camera still, so
  pixel diffs are valid. The figure's mean RGB goes (183.4, 185.7, 190.9) → (184.0, 185.9, 190.0) over ~12.9k figure pixels.
  Only 624 pixels change, and all of them lie along the floor line under the hem (`r2_04_raise_to_body_cut_diff`, red: last
  strip frame, first body frame, and the changed pixels). The prop grey and the body's shield grey match. The hem's bottom
  row differs by about one art pixel, invisible at play speed.
- **The wall closing is now on screen briefly.** On the body's first frame the camera still sits at x 11711 (right edge
  12031), so the dithered column appears at the right edge (`r2_05_body_first_wall_closing`). The release then eases it out
  of frame. That is a glimpse, not a beat. Fine if sound also carries it (not verified).
- **Jump over the old zone:** Ivo (double jump) flies over x 11720..11820 at y about -1500 and lands at x 11667. The scene
  does not start in the air: it starts on landing (`CutsceneTrigger` waits for the floor). The walk then takes him back east
  to the mark at 11704, and the scene runs as usual (`r2_07_jump_over_old_zone`, `r2_08_scene_after_landing`). Not tried: a
  longer jump landing west of the keeper (x < 11600), from which the walk to the mark would pass through him.
- **Skip:** Escape → Pular cena → Z at 5.5 lands the same end, and the hold still applies after a skip (telegraph +2.32).
- **Death and retry:** a still Ivo is hit at +3.3, +7.6 and +11.6 s and dies at about 22 s. He respawns at the bench at
  23.7 with the lantern rewound. Back at the hatch, the scene plays again with identical beats, 31.71-36.59
  (`r2_09_retry_scene_again`).
- **Timelines updated:**
  - `story38_keeper_wakes.json` shots are retimed to this build: mark, turn, held, crack, raise, body, hold end,
    telegraph, swing, hit.
  - `story38_keeper_wakes_retry.json` is retimed for the longer death.
  - The probe driver's header gives the new zone.
- **Side note:** `--import` has made `.png.import` sidecars inside this report's screenshot folder (22:42, from some session's
  import). `docs/` has no `.gdignore`, so Godot imports doc images.

### Verdict (inferred from timings and frames, not felt)

The beat now does what the user asked:
- 3.9 s on the mark, of which the keeper looks at Ivo for 0.8 s before he changes;
- then 2.3 s of a standing guardian at zoom 1 after the bars before the first telegraph.

A player has time to recognise him, to see that he changed, and to take the controls before anything swings. What remains
is art-side and mild: the crack is quiet at zoom 1, and the start and end poses are similar enough that the strips carry
the change alone. Sound (the silence, the fight cue's entry, the wall) still needs a human run.

## Screenshots

`screenshots/2026-11-17-story38-the-keeper-wakes/`:

- `01_keeper_still_at_lamp.png`: on the hatch, the keeper's back.
- `02_frame_hides_legs.png`: on the mark, both bodies cut by the bar.
- `03_turn_cut_and_crossfade_crops.png`: crops of the moment the zone is crossed, the last frame on his back, the one
  `Stasis` frame, mid-fade, `GuardianStill`, and a `RaisingWrong` frame.
- `04_raise_and_handover_crops.png`: the raise and the strip-to-body frames.
- `05_body_after_bars.png`: the body standing at zoom 1, bars gone.
- `06_first_telegraph_0_8s.png`, `07_first_hit_1_8s.png`: the fight's opening.
- `08_wall_closed_off_frame.png`, `09_wall_holds_climb.png`: the wall from inside, and Ivo stuck at its top.
- `10_skip.png`: the pause menu on Pular cena.
- `11_retry_scene_again.png`: the scene again after the death.
- `12_before_four_opening.png`: the opening's turned keeper before the four.

Second run: `r2_01_on_the_mark_whole_frame.png`, `r2_02_turned_keeper_held.png`, `r2_03_turn_crack_raise_crops.png` (window-pixel crops of every probe shot from 3.55 to 7.10), `r2_04_raise_to_body_cut_diff.png`, `r2_05_body_first_wall_closing.png`, `r2_06_first_telegraph_2_3s.png`, `r2_07_jump_over_old_zone.png`, `r2_08_scene_after_landing.png`, `r2_09_retry_scene_again.png`.
