---
id: bugs/the-mentors-lantern-talk-opens-the-top-box-over-his-face
type: bug
title: The mentor's lantern talk (zoom 2) opens the top dialogue box over his face and raised hand, against "Caixa pela cabeça"
status: fixed
severity: medium
tags: [story-34, dialogue, dialogue-box, placement, face-height, mentor, lighthouse, talkable, zoom]
related: [playtests/2026-11-17-story34-mentor-at-the-lantern, systems/dialogue, architecture/story34-mentor-at-the-lantern, bugs/the-first-guardian-talks-zoom-hides-the-guardian-behind-the-dialogue-box]
created: 2026-11-17
updated: 2026-11-17
source_files:
  - scenes/world/rooms/frost_edge/contents/lighthouse_top.room
  - scenes/world/interactables/talkable/talkable.gd
  - scenes/ui/dialogue_box/dialogue_box_side.gd
---

## Summary

`mentor.tres` in the lantern runs at zoom 2 from the auto `t` at `lighthouse_top.room` 23,20, which has no `face_height`.
`DialogueBoxSide.place` therefore picks the top box, and every line of the talk covers the keeper from the waist up: his
face, his raised hand under the lamp and the lamp. The top box also clips the top of Ivo's head.

## Symptom

STORY-34 playtest, pt_BR, build ab5a1642 + the uncommitted STORY-34 tree. The camera holds at (11628, -1296), zoom 2,
for the whole talk. Feet are at screen y 276 (game px), and the top box's bottom edge is at ~165-176. The keeper's head
(about 85-95 px above his feet, so ~170-190 screen px above them at zoom 2) lands at screen y ~45-60: inside the box. Below
the frame you see only his robe; see `playtests/screenshots/2026-11-17-story34-mentor-at-the-lantern/04_box_over_mentor.png`.
Ivo's hair is cut by the box frame by ~3 game px. The keeper is visible only in the box-closed beats (the 1.2 s silence,
the turn, the 1.6 s pause, the phrase, the gift, the stasis).

The talk was already like this on the middle gallery (`playtests/2026-10-16-story16-opening`, `f00`). Moving it to a new
`t` in STORY-34 was the point at which `face_height` should have been set.

## Root cause

`Talkable.face_height` defaults to 0 ("no face"), so `DialogueBoxSide.place` falls through to `opposite()`. That picks
TOP whenever the floor is low on screen (`systems/dialogue`, Placement). The rule "Caixa pela cabeça" (user, 2026-10-30)
says a tall speaker's face must not be under the box. Of all the speakers it applies to, only the Frost golem sets it (150).

## Fix

Not fixed. Set `"face_height": ~88` on `lighthouse_top.room` 23,20 (and on 22,20 for the stasis "…", although at zoom 1
the eyes sit near the box edge, so check that one). At zoom 2 the eyes then sit at ~100 screen px, above `TOP_BOX_BOTTOM`
176, so the bottom box opens. The bottom box would cover Ivo's legs and the floor, as it does for the golem, so the
playtest must judge that trade. The other option is a camera lifted ~30 px for this talk (it would also bring the lowered
lamp, cropped at zoom 2, into frame), which needs a user decision.

## Prevention

Any Talkable whose speaker stands taller than Ivo and talks at zoom 2 needs a `face_height`. A check could flag a `talk`
entity with `Dialogue.zoom > 1` and a staging taller than ~70 px.

## Fix (2026-11-17)

Both lantern talks (`lighthouse_top.room` 23,20 and 22,20) carry `"face_height": 110.0`. In the second playtest run every
line of `mentor.tres` opened the bottom box with the keeper's face and raised hand visible above it, and the stasis "…"
(zoom 1) did the same. The cost: the bottom box covers Ivo below the chest at zoom 2, and all of him but his hair at zoom 1.
