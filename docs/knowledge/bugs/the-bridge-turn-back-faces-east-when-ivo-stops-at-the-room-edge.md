---
id: bugs/the-bridge-turn-back-faces-east-when-ivo-stops-at-the-room-edge
type: bug
title: The Old Bridge turn-back faces Ivo east, toward the bridge, when he stops in the room's first 16 px
status: fixed
severity: low
tags: [dialogue, talkable, facing, story-33, threshold]
related: [systems/dialogue, bugs/ivo-faces-the-talkable-not-the-villager-beside-it]
created: 2026-11-17
updated: 2026-11-17
source_files:
  - scenes/world/rooms/threshold/contents/threshold_bridge.room
  - scenes/world/interactables/talkable/talkable.gd
  - scenes/characters/ivo/player.gd
---

## Summary

`sword_turn_back` is meant to face Ivo west, back toward the farmhouse. That holds only while his centre is east of the speaker point (x 16). If he stands still inside the zone west of x 16 for `auto_delay`, he says "Assim não." facing the bridge.

## Symptom

Found in review (STORY-33). Repro: without the sword, cross from threshold_fields into threshold_bridge and stop at once, centre at x 0..15. After 0.4 s the talk starts and Ivo turns east.

## Root cause

- The `t` at 0,8 has the default `speaker_offset` 0, so its speaker point is the cell's bottom centre: x 16 (`RoomMapNode.entity_position`, FEET).
- `reach_west` 16 puts the zone at x 0..96. Ivo's 12 px `DoorSensor` therefore overlaps it from centre x -6.
- `Player.begin_talk` (`player.gd:1502`) calls `face_towards(signf(at.x - global_position.x))`. For a centre in [-6, 16) the sign is positive (east).

## Fix

Not fixed. Put the speaker point at or west of the zone's west edge, so every overlapping centre lies east of it. For example: `"speaker_offset": -22.0, "reach_west": 0.0, "reach_east": 118.0`. That keeps the zone at x -6..112, still at least 80 px wide and still past the wall's face at x 96 (check that `talkable_rooms_test` holds). The point lies outside the room, but it is used only for facing and the box side.

## Prevention

A turn-back talk's test should assert the facing at the zone's west-most overlapping position as well as at the wall.

## Fix (2026-11-17)

The Talkable at `threshold_bridge` 0,8 has `speaker_offset` -22, `reach_west` 0, `reach_east` 118: the speaker point is x -6, west of every position whose sensor overlaps the zone (-6..112), so Ivo always faces west.
