---
id: playtests/2026-11-17-song21-weather-through-the-door
type: playtest
title: SONG-21 - Vendaval played in the door trial's interior blows outside after the door
status: active
build: uncommitted SONG-21 change over 866e2c44
area_tested: "song_gale_inside_out.json: Ivo enters the door trial's interior (x 18560), plays Vendaval beside the door, leaves through it at t 9.2."
tags: [song-21, weather, doors, playtest]
related: [systems/songs-and-the-memorina]
created: 2026-11-17
updated: 2026-11-17
ratings: { fun: 0, fluidity: 0, aesthetics: 0 }
screenshots:
  - screenshots/2026-11-17-song21-weather-through-the-door/gale_inside.png
  - screenshots/2026-11-17-song21-weather-through-the-door/gale_outside.png
---

# SONG-21: weather through the door

- `gale_inside.png` (t 8.9): the pulse opens and colours the interior; no gusts or leaves (SONG-20).
- `gale_outside.png` (t 11.4): outside the door, gusts and leaves blow across the screen around Ivo; the carried pulse holds the rest of its sustain.
- The same timeline with Chuva carries the pulse too, but the door trial's outside is under a stone ceiling, where `RainFall` suppresses every drop; Chuva played there directly shows none either.

## Cannot be judged from frames

Whether the carried weather reads as the same song or a new one: the carried pulse opens under the door's black at its inside phase, so it shows no ring and no attack.
