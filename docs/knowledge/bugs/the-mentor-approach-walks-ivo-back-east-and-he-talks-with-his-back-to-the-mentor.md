---
id: bugs/the-mentor-approach-walks-ivo-back-east-and-he-talks-with-his-back-to-the-mentor
type: bug
title: The mentor_approach walk turns a running Ivo back east, so "Hey…" and the turn play with his back to the mentor
status: fixed
severity: medium
tags: [story-34, cutscene, dialogue, facing, talkable, auto-start, mentor, lighthouse]
related: [playtests/2026-11-17-story34-mentor-at-the-lantern, architecture/story34-mentor-at-the-lantern, systems/cutscenes, systems/dialogue, bugs/the-bridge-turn-back-faces-east-when-ivo-stops-at-the-room-edge, bugs/look-at-the-painting-turns-ivo-the-way-he-already-faces]
created: 2026-11-17
updated: 2026-11-17
source_files:
  - resources/cutscene/story/mentor_approach.tres
  - scenes/world/rooms/frost_edge/contents/lighthouse_top.room
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
  - resources/cutscene/cutscene_walk.gd
  - scenes/world/cutscene/cutscene_beat.gd
---

## Summary

An Ivo who walks west into the lantern's auto talk at full speed is already past `ivo_near` (x 776) when the talk
starts, so `mentor_approach` walks him back east. He ends facing east, and `CutsceneBeat.face_after` holds that facing
until `MentorPhrase`: "Hey…", the turn, the pause and four lines play with his back to the mentor.

## Symptom

Found in the STORY-34 review (uncommitted). Playtest from (11780, -1250) with Left held: Ivo reaches local x 766
(world 11646), then walks east at about 47-77 px/s to 776 (world 11656). The screenshot at "Hey…" shows him facing
east, away from the keeper at x 720. The committed timeline `mentor_gift.json` misses this because it releases Left
after 0.5 s, so Ivo stops near x 800, east of the mark.

## Root cause

- The auto Talkable at `lighthouse_top.room` 23,20 (`speaker_offset` -32, `reach_east` 120) has its zone east edge
  at x 840. Ivo's body (radius 11) enters it at a centre of about x 851.
- `auto_delay` is 0.4 s. At `move_speed` 192 px/s Ivo covers about 77 px before the talk starts, and then a few
  frames more before it does. That brings him to about x 766, west of `ivo_near` at x 776, which is 64 px inside the
  edge.
- `CutsceneWalk.land`/`ScriptedController` turns the walker the way it walks (`cutscene_walk.gd:3`, `:22-24`). The
  walk calls `note_ivo_turned`, and `CutsceneBeat.face_after` (`cutscene_beat.gd:25-28`) holds Ivo at that side for
  the rest of the talk. The next beat that sets a `face` is `MentorPhrase` (`face` = `Holding/Body`).

## Fix

Not fixed. Add a last step to `mentor_approach.tres`: `CutsceneFace` with `actor` `ivo` and `toward` `mentor_home`.
`WorldCutsceneContext.face` calls `note_ivo_turned`, so `face_after` then holds him facing west whichever way he
walked. Moving `ivo_near` east only narrows the window, because the overshoot depends on the arrival speed and the
frame timing.

## Prevention

- A `CutsceneWalk` inside a talk ends facing the way it walked, and that facing outlasts the beat. When the walker
  can start on either side of the mark, end the scene with a `CutsceneFace` toward the person he talks to.
- Playtest an auto talk's approach with the direction held through the zone, not only with an early release.

## Fix (2026-11-17)

`mentor_approach.tres` ends its walk with a `CutsceneFace` (`ivo` toward `mentor_home`) before its 0.6 s wait; the recorded turn makes `face_after` hold him facing the keeper whichever way he walked.

Verified in play (2026-11-17, `playtests/2026-11-17-story34-mentor-at-the-lantern`): Ivo came up the hatch with Left held. Before the fix (run at 16:59) he faced east from "Ei…" to the end of the run, 30 s. After the fix (17:0x) he showed `facing=1` for one 0.25 s sample at x 11646 while stepping back to the mark, and faced west from "Ei…" onward.
