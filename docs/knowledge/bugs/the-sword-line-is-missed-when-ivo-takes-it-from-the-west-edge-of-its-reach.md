---
id: bugs/the-sword-line-is-missed-when-ivo-takes-it-from-the-west-edge-of-its-reach
type: bug
title: "\"…Sorry. I'll need this.\" never plays when Ivo takes the sword from the west edge of its reach, because the auto talk's zone starts 27 px further east than the pickup's"
status: fixed
severity: medium
tags: [story, dialogue, talkable, pickup, sword, auto-start, story-16, opening]
related: [systems/story, systems/pickups, systems/dialogue, bugs/the-daughters-song-talk-needs-ivo-inside-her-and-a-run-past-never-starts-it, playtests/2026-10-16-story16-opening]
created: 2026-10-16
updated: 2026-10-16
source_files:
  - scenes/world/rooms/threshold/contents/threshold_farmhouse.room
  - resources/dialogue/story/sword.tres
  - scenes/world/interactables/talkable/talkable.gd
  - scenes/world/interactables/item_pickup/item_pickup.gd
---

## Summary

FIXED 2026-10-16, medium (STORY-16 review, 2026-10-16). Design 05 Ato 2 has Ivo say "…Sorry. I'll need this." as he takes the sword. STORY-16 built it as an auto Talkable (`sword_sorry`, `when` the sword is owned) one cell east of the pickup. Its zone does not cover the west part of the pickup's reach. Ivo comes in from the door at the west, takes the sword as soon as the prompt shows and walks back out, and the line never plays. It plays instead on a later visit, if he ever crosses that spot, with no sword on the table.

## Symptom

New game to Act 2. In `threshold_farmhouse` walk east from the door (col 4) and press Up when the sword's prompt appears. Then walk back to the door. No talk starts. The intent and the sword notice are told, and Act 2's only line is lost.

## Root cause

Both zones are measured against different shapes of Ivo:

- The pickup (`threshold_farmhouse.room:28`, `9,8`, `width_cells` 4) spans x 240..368. Up reaches it through `DoorSensor`, which is 12 px wide (`ivo.tscn`, `RectangleShape2D_seatsensor`), so it is in reach from Ivo's centre x ≈ 234.
- The talk (`threshold_farmhouse.room:29`, `10,8`) sits at the cell centre x 336 with `speaker_offset` -16 and the default `REACH` 48 each side, so it spans x 272..368. `Talkable` detects his body (`collision_mask = Seat.PLAYER_BODY`, capsule radius 11), so it arms from his centre x ≈ 261.

From centre x 234 to 260 Up takes the sword and the auto talk is never armed. `Talkable.auto_ready()` needs `_armed` (set only in `_on_body_entered`), and walking back west to the door never enters the zone.

## Fix

Fixed 2026-10-16 with the second option: the pickup starts the line itself. `ItemPickup.talk` (a DialogueSet, legend param `talk`) is read after the take (`talk_after_take()`), and `Player._try_pickup` emits `pickup_talk_started(dialogue, at)`, wired in `game.tscn` to `DialogueDirector.start_dialogue`. The farmhouse's sword carries `talk = sword.tres`; the col-10 Talkable is gone, so no zone geometry is involved and a save that already owns the sword never sees the pickup, nor the line. Tests: `player_pickup_test.test_taking_the_sword_starts_its_line_from_any_edge_of_its_reach` (taken from the reach's west edge) and `test_a_save_that_owns_the_sword_never_hears_its_line`.

## Prevention

A talk that must follow a pickup or a door has to arm everywhere the other one can be used. Prompts and Up use the 12 px `DoorSensor`, auto talks use the 22 px body. Compare the two extents with those widths, not the cells.

Legacy saves have the same trigger. A save that already owned the sword before STORY-16 hears the line on its next walk past the table, which no longer shows the sword.
