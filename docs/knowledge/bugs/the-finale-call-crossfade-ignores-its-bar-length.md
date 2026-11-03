---
id: bugs/the-finale-call-crossfade-ignores-its-bar-length
type: bug
title: The finale fight fades out over 1 s, not the one bar GuardianMusic asks for
status: fixed
severity: low
tags: [music, finale, guardians, crossfade]
related: [systems/music, architecture/music-system, systems/guardians]
created: 2026-11-03
updated: 2026-11-03
source_files:
  - scenes/characters/guardians/guardian_music.gd
  - globals/music/music.gd
---

## Summary

When a track is chosen, the fight cue should cross to `call_music` over one bar (3 s at 80 BPM); it fades over the
fight cue's `fade_out` (1 s) instead, while the call fades in over 3 s.

## Symptom

Found in review of the audio commits (f36bd9fc..74e19fb9). After the track choice the fight drops out in 1 s and the
call underscore (`finale_call.tres`, `fade_in` 3.0) is still rising: about 2 s of near silence under the final call.

## Root cause

`GuardianMusic._on_track_chosen` (guardian_music.gd:75-76) requests the call first, then releases the fight with
`BarClock.bar_seconds(...)`. The request is newer at the same FIGHT layer, so `Music.request` -> `_refresh`
(music.gd:102) already retired the live fight deck with `fade = -1.0`, which uses the cue's `fade_out`. By the time
`release(_fight_request, bar)` runs, the fight is no longer `_live`, so music.gd:38 skips `_retire` and the bar length
is discarded.

## Fix

Not fixed. Release the fight with the bar fade before requesting the call (release then request, as `RegionMusic`
does), or let `request` take the outgoing fade.

## Prevention

A `music_test` case asserting the retired deck's `rate` (or gain after N real seconds) equals 1 / the fade passed to
`release` when a same-layer request has just replaced it.
