---
id: gotchas/scripted-presses-timed-in-real-ms-collapse-at-a-low-frame-rate
type: gotcha
title: Presses a -s driver schedules in real ms reach the game on frame boundaries, so at a low frame rate two of them land one frame apart and MemorinaVoice's real-time gap drops one
status: active
tags: [playtest, input, parse-input-event, frame-rate, memorina, driver]
related: [bugs/memorina-notes-dropped-while-previous-rings, playtests/2026-11-19-grd16-sun-fight, systems/songs-and-the-memorina]
created: 2026-11-19
updated: 2026-11-19
source_files:
  - tools/playtest/scripts/guardian_fight_bot_driver.gd
  - tools/playtest/scripts/guardian_fight_player_driver.gd
  - scenes/characters/ivo/abilities/memorina_voice.gd
  - scenes/characters/ivo/player.gd
---

## Summary

A SceneTree driver's `_process` runs once per rendered frame, and `Input.parse_input_event` reaches the nodes at the
next input flush. A press schedule written in `Time.get_ticks_msec()` is therefore quantised to the frame time. With
slow frames, two presses 450 ms apart can arrive about 260 ms apart. `MemorinaVoice.can_play_note()` measures
`min_note_gap` (0.25 s) in real ms, and `Player._on_note_pressed` returns without a rejection, so the note is lost and
the call times out with no `sequence_failed` until the window closes.

## Details

- GRD-16 review, 2026-11-19, probe of `guardian_fight_bot_driver.gd` on `guardian_bot_summer.json`: windowed frames came
  every ~265 ms (two frames ~3 ms apart, then a ~260 ms stall). `max_physics_steps_per_frame` (8) ran 10 physics
  steps per ~265 ms, so game time ran at about 60 % of real time. The answer's notes 1, 2, 3 played. Note 0 arrived
  264 ms (runner clock) after note 3 with `can_play_note()` false and was dropped. The remaining 0, 0 played, the
  phrase was one note short, and the 10.6 s window ran out.
- The same rate (median 247-249 ms per frame) held in caldera_arena, lake_frost_arena and bloom_hollow in that session,
  so it was the machine or the build, not one arena. The GRD-14/15 driver logs show much shorter gaps between frames.
- The draw press is not affected: `toggle_buffer_max` (0.12 s) is game time and the instrument was drawn on the next
  frame.

## Gotchas / pitfalls

- A driver's "answer timed out" or "hit late" is not evidence about the game until the run's frame rate is known. Log
  real ms per frame, or the physics-frame count beside each press.
- Schedule each note after the last `note_played` (or until `can_play_note()`), not at fixed real-ms offsets from the
  window opening.
- At about 4 fps the driver decides once every ~10 physics steps: Ivo walks ~32 px and a guardian at 120 px/s ~20 px
  between two decisions. Margins under that (a 22 px stand-off from a contact box) are driver limits, not game
  unfairness.

## Applied (2026-11-19, GRD-16 review)

Both guardian drivers now press the answer's notes on the physics clock: the first 42 physics frames after the draw,
then one every 27 (0.45 s of game time), and only while `MemorinaVoice.can_play_note()` holds. Both print
`[frame] median_ms=...` every 600 rendered frames. The GRD-16 re-measure ran with no other Godot process (checked
before each run) at a median of 5-6 ms per frame, and every answer in it was good.
