---
id: bugs/a-beat-that-ends-resumes-the-talk-without-the-start-gates
type: bug
title: A DialogueBeat that ends or leaves the tree resumes its talk with no gate, under an open map or after a death's rewind
status: fixed
severity: medium
tags: [dialogue, beat, save, death, map, input, story-08]
related: [systems/dialogue, architecture/dialogue-is-data-and-choices-are-save-facts, systems/life-benches-death, systems/input, gotchas/a-removed-subtree-emits-tree-exiting-later-siblings-first]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/dialogue/dialogue_director.gd
  - scenes/characters/ivo/player.gd
  - scenes/world/game.gd
---

## Summary

FIXED 2026-10-15 (STORY-08 review, before commit). It was latent: no `DialogueBeat` ships yet; the first is STORY-03's guitar. When a beat emits `finished` or leaves the tree, `DialogueDirector._on_beat_over` re-emits `talk_began` and steps on at once, with none of the gates a talk start has. Two failures follow.

## Symptom

1. **Two owners of `PlayerInput.blocked`.** During a beat Ivo is free and `Player._talking` is false, so `can_open_map()` is true and the map opens. If the beat finishes under the map, `begin_talk` runs (the box opens under the map layer and takes GUI focus). When the map closes, `Screens.unblock_requested` → `Player.unblock_input()` frees Ivo while the talk still runs: he walks away with the box open, and Z both jumps and advances the line. This breaks "the map is refused while a talk runs, so `blocked` has one owner".
2. **A death keeps what the talk gives after it.** Ivo can die during a beat, because he is free then. `Game._on_player_died` calls `SaveSystem.record_death` (the rewind) and then defers `SceneSwap.replace`. `remove_child(game)` emits `tree_exiting` on the beat, so `_on_beat_over` runs after the rewind. The director has already left the tree (it comes after the regions under `World`, and later siblings exit first). `_step()` then writes into the rewound live save: `SaveSystem.set_item_owned` when the next line grants (the mentor's Memorina after the guitar is the planned STORY-03 flow), or `mark_dialogue_heard` when the cue was the last line. The fresh `game.tscn` reads that save, so the death does not forget the gain. A CUE as the next step calls `get_tree()` on the out-of-tree director: "Parameter data.tree is null", then a null call in `DialogueBeat.find`.

The talk also resumes wherever Ivo is: mid-air, on a stair or sinking (`fell_into_hazard` already fired, so nothing interrupts the resumed talk).

## Root cause

`scenes/world/dialogue/dialogue_director.gd:95-110`. `_play` emits `talk_ended`, so `Player._talking` is false for the whole beat (`player.gd:1127-1129`, `can_open_map` at `:1108`). `_on_beat_over` treats "finished" and "left the tree" the same way, does not check whether the director itself is leaving the tree or whether Ivo is alive and free, and calls `talk_began.emit(_at)` and `_step()` directly. `Player.begin_talk` (`player.gd:1122`) applies no gates.

## Fix

Fixed 2026-10-15.
- `DialogueDirector._play` emits `talk_paused`, not `talk_ended`: `Player.pause_talk()` frees his input but keeps `_in_talk`, so `is_talking()` and the map refusal (`can_open_map()`) hold from the start to the final `talk_ended`, beat included. `PlayerInput.blocked` keeps one owner.
- `_on_beat_over` drops the talk unheard and writes nothing when the director is out of the tree (the world is being swapped out). Otherwise it emits `resume_wanted` and waits.
- `Player.request_talk_resume()` sets `_resume_wanted`; `_try_talk` answers with `talk_resumed` only under the start gates (on the floor, `_free_for_up`, not blocked; dead or sinking never reach it), and `DialogueDirector.resume()` goes on. An `interrupt()` while it waits ends the talk unheard.
- Tests: `dialogue_director_test.test_a_world_swapped_out_under_a_beat_writes_nothing` (a parent holding the beat then the director is removed after a rewind; fails without the out-of-tree guard), `test_a_cue_hands_off_to_its_beat_and_resumes_when_ivo_answers`, `test_a_beat_freed_with_its_room_waits_for_ivo_then_resumes`, `test_an_interrupt_while_waiting_to_resume_drops_the_talk`, and `player_talk_test.test_the_map_is_refused_during_a_beat_and_the_resume_waits_for_the_gates`.

## Prevention

`dialogue_director_test` has `test_a_beat_freed_mid_talk_resumes_it`, which asserts the resume but never frees the director with the beat. Add a test that frees a parent holding both the director and a beat after `SaveSystem.rewind()` and asserts the save is unchanged. Add a Player-level test that opens the map (`block_input`) during a beat, finishes the beat, closes the map, and asserts `PlayerInput.blocked` stays true while `is_talking()`.
