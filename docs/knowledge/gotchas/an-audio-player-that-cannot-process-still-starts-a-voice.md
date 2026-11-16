---
id: gotchas/an-audio-player-that-cannot-process-still-starts-a-voice
type: gotcha
title: An audio player that cannot process still starts a voice on play(); only a change of process state pauses one
status: active
tags: [audio, sfx, process-mode, pause, rooms, testing]
related: [systems/sound-effects, architecture/sound-effects-system, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, gotchas/time-scale-zero-stops-delta-particles-and-time]
created: 2026-11-16
updated: 2026-11-16
source_files:
  - scenes/audio/sfx_emitter.gd
  - tests/scenes/audio/sfx_emitter_test.gd
---

## Summary

A player pauses its voices on the notification it gets when it stops processing (tree pause, or an
ancestor turned DISABLED). A `play()` called after that, while `can_process()` is false, is not paused:
- `AudioStreamPlayer` sounds at once, through the pause or the idled room.
- `AudioStreamPlayer2D` reports `playing` true but stays silent at position 0, and starts when it can
  process again, late.

`SfxEmitter` therefore refuses a start when `can_process()` is false.

## Details

Measured in 4.7.2, headless (the Dummy driver mixes in real time, so `get_playback_position()` advances),
scratch script, 2026-11-16:

| Case | Result after the wait |
|---|---|
| PAUSABLE `AudioStreamPlayer`, `play()` while the tree is paused | playing, 0.377 s in 0.4 s, `stream_paused` false |
| INHERIT `AudioStreamPlayer` added and played under a DISABLED parent | playing, 0.47 s in 0.5 s |
| INHERIT `AudioStreamPlayer2D` played under a DISABLED parent | `playing` true, position 0.0 after 0.3 s |
| A playing INHERIT voice, then its parent set DISABLED | paused (`playing` false), position held; resumes when re-enabled |
| A playing PAUSABLE voice, then the tree paused | `playing` false, `stream_paused` true, 0.012 s moved in 0.4 s; resumes |
| Explicit PAUSABLE player under a DISABLED parent | plays (0.47 s in 0.5 s) and pauses with the tree |
| ALWAYS player, tree paused, `Engine.time_scale` 0 | plays, 0.66 s in 0.6 s |
| PAUSABLE player, tree running, `Engine.time_scale` 0 | plays: audio ignores the time scale |

A CanvasPass `SubViewport` shares the root's `world_2d` but is not a 2D listener
(`is_audio_listener_2d()` false, `audio_listener_enable_2d` false); the root is. A 2D voice is therefore
panned against one listener. This was read from the flags, not heard.

## Gotchas / pitfalls

- `playing` reads false while a voice is paused. Test `stream_paused` or the position to tell a paused
  voice from a stopped one.
- A paused-by-DISABLED voice resumes on re-enable. An idled room's emitter stops its voices on
  `NOTIFICATION_DISABLED` instead, so they do not come back when the room does.
- In the GdUnit runner, wait on `Time.get_ticks_usec()` when comparing with the mixer: a 1 s game timer
  (`create_timer(1.0, true, false, true)`) ended after 0.77 wall s, and `await_millis` stops with the tree.
