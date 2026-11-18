---
id: bugs/the-keeper-wakes-frame-hides-ivo-and-the-keeper-below-the-waist
type: bug
title: The awakening's zoom-1.5 frame, raised 128 px, puts Ivo's and the keeper's legs under the bottom letterbox bar for the whole scene
status: fixed
severity: medium
tags: [camera, cutscene, letterbox, framing, mentor, lighthouse, story-38]
related: [playtests/2026-11-17-story38-the-keeper-wakes, architecture/story38-the-keeper-wakes, bugs/the-mentors-lantern-talk-opens-the-top-box-over-his-face, systems/cutscenes]
created: 2026-11-17
updated: 2026-11-17
source_files:
  - resources/cutscene/story/mentor_wakes.tres
  - resources/cutscene/cutscene_camera.gd
---

## Summary

`mentor_wakes` frames the pair's feet + `offset` (0, -128) at zoom 1.5, which copies the lantern talk's frame. The talk has
no letterbox, but this scene does. The bottom bar starts 32 world px above the floor, so from the mark to the scene's end
Ivo shows only from the waist up and the keeper's robe is cut at the knees. The grey cracking and the wrong raise play on
half a body.

## Symptom

Measured on every run of `story38_keeper_wakes.json` (screenshots `playtests/screenshots/2026-11-17-story38-the-keeper-wakes/02_frame_hides_legs.png`):

- Camera centre (11710.9, -1376.0), zoom 1.500 from t ~3.2 to 7.05. Feet y -1248.
- At zoom 1.5 the view is 240 world px tall, so the frame bottom is y -1256: the feet already sit 8 px below it.
- The bars are 72 window px each (36 game px = 24 world px at 1.5). The bottom bar's top edge is window row 648, world
  y -1280: 32 px of Ivo's 54 px body and the bottom of the keeper's robe are behind it.

## Cause

`CutsceneCamera` centres on the targets' mean feet + `offset` (`cutscene_camera.gd:29`). The plan derived (0, -128) from
the talk frame (`framing_offset_y` -64 + `frame_lift` 64), which was tuned without bars.

## Fix

Fixed 2026-11-17 (uncommitted). `mentor_wakes.tres` frames the pair at zoom 1.0 with offset (0, -112). The view is 360 px tall and each bar 36 px, so the band between the bars is 288 px: y 416..704 in the room. That shows the lamp's top (y 428), the whole keeper and Ivo, and 32 px of floor under their feet (y 672); -96 would cut the lamp's top by 4 px. The release changes no zoom; only the offset eases back. `mentor_wakes_test.test_the_frame_keeps_the_lamp_and_both_figures_between_the_bars` checks the band against the lamp and the floor, from the scene's own camera step, the letterbox's `bar_height` and the viewport height. Not yet re-measured in a playtest.

Verified in a playtest 2026-11-17 (second run of `playtests/2026-11-17-story38-the-keeper-wakes`): from the mark to the end the camera holds (11710.9, -1360.0) at zoom 1.00. The lamp, the whole keeper and Ivo, and a floor strip all sit between the bars (`r2_01_on_the_mark_whole_frame.png`).

## Fix direction

At zoom 1.5 with bars the visible band is 160 world px tall (480 window px / 3). The lamp's top (~y -1463) to the floor
(-1248) is 215 px, so both cannot fit at 1.5:

- keep zoom 1.5 and drop the lamp: the bar's top edge is at world y -1152 + offset.y, so offset.y >= -88 shows the feet
  with a floor strip; (0, -64) shows 32 px of floor;
- or keep the lamp: zoom 1.1 with offset (0, -100) shows y -1479..-1217 between the bars (lamp top ~-1463, floor -1248).

Then check `02_frame_hides_legs` again: feet and the floor line inside the frame on the mark.
