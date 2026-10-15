---
id: bugs/up-takes-a-door-during-a-free-beat-and-strands-the-talk
type: bug
title: Up takes a door during a FREE beat, the beat's room idles, and the talk never resumes or ends, so the map stays refused
status: fixed
severity: low
tags: [dialogue, beat, story, door, rooms, process-mode, map, latent]
related: [systems/story, systems/dialogue, systems/rooms, bugs/a-beat-that-ends-resumes-the-talk-without-the-start-gates, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, architecture/the-opening-is-staged-by-save-facts]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/world/dialogue/dialogue_director.gd
  - scenes/world/story/staged_beat.gd
  - scenes/world/rooms/room_residency.gd
  - scenes/world/game.gd
---

## Summary

FIXED 2026-10-15, latent (STORY-03 phase A review, 2026-10-15): no FREE beat is placed yet. During a beat with `hold = FREE`, Ivo hears Up, and `Player._try_door` has no talk gate. Taking a door idles the beat's room, so the beat never finishes. The talk then stays open with no box: `is_talking()` is true and the map is refused until the room is evicted or Ivo dies.

## Symptom

Reasoned from the code, not reproduced (no FREE beat exists in any room):

1. A talk cues a `StagedBeat` with `hold = FREE`. `Player.pause_talk(FREE)` unblocks `PlayerInput`.
2. Ivo walks to a door in the same room and presses Up. `_try_door` emits `door_entered` and `Game._on_player_entered_door` runs the trip.
3. `RoomResidency.settle` idles the old room (`room.deactivate()`: DISABLED and hidden, still in the tree; "a door trip from it idles it rather than evicting it"). The beat's `_process` stops, so `finished` is never emitted. `tree_exiting` is not emitted either, because the node stays in the tree.
4. `_in_talk` stays true. `can_open_map()` is false, a new Talkable is refused (`_try_talk`: `if _in_talk`), and a `Talkable` auto start never fires.
5. When the room is later evicted (two more idle rooms), `tree_exiting` → `_on_beat_over` → `resume_wanted`. The talk then resumes wherever Ivo is, facing the old speaker's point, with the box opened against a speaker in another room.

The same applies when Ivo walks out of reach of the beat's room across seams until it idles. `_try_pickup` also runs during a FREE beat, but a pickup is harmless.

## Root cause

- `scenes/characters/ivo/player.gd:598-613` (`_try_door`) and `_free_for_up` (`:662`) do not check `_in_talk`. Before STORY-08 there was no beat, so no Up could reach a door mid-talk.
- `DialogueDirector` (`dialogue_director.gd:138-140`) ends a beat only on `finished` or `tree_exiting`. A deactivated room produces neither.

## Fix

Fixed 2026-10-15. `Player._try_door` and `_try_pickup` refuse while `_in_talk`, a beat included: a talk never leaves its room, as the map is refused from its start to its end. The press is spent. Tests: `player_beat_test.test_up_takes_no_door_during_a_talk` (a FREE beat, Up at a door: nothing until `end_talk`, then the door) and `test_up_takes_no_item_during_a_talk`.

## Prevention

Before any phase B content uses `hold = FREE`, add a `player_beat_test` case: begin a talk, `pause_talk(FREE)`, put a reachable open `Door` beside Ivo, press Up, and assert that `door_entered` is not emitted. A FREE beat in content should stand where no door is in reach until the fix lands.
