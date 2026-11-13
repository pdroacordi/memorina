---
id: bugs/the-mill-lure-keeps-the-lullaby-playing-in-the-mill-house
type: bug
title: Flashback 5's mill lure keeps its duck, muffle and SCENE voice open while Ivo is inside the mill house
status: resolved
severity: low
tags: [music, duck, muffle, lure, flashback, residency, door, story-05]
related: [systems/music, systems/rooms, architecture/story-05-playable-flashbacks, gotchas/a-node-idled-or-swapped-out-keeps-what-it-opened-in-an-autoload]
created: 2026-11-13
updated: 2026-11-13
source_files:
  - scenes/world/story/flashback/flashback_lure.gd
  - scenes/world/rooms/home_village/contents/village_mill_contents.tscn
  - scenes/world/rooms/room_residency.gd
---

## Summary

While `FLASHBACK_DUE 5` holds, `Lure5` in `village_mill` asks for `wife_song_lullaby_far` at SCENE layer, plus a duck
and a 0.6 muffle, whenever Ivo is inside `LureZone5`. That zone covers the whole mill room. When Ivo takes the mill
house door, the mill's contents go idle before the lure can see him leave. All three requests stay open for as long as
he is indoors.

## Symptom

During flashback 5's call, enter `village_mill_house` from the mill (the door at col 3). Inside the house, the far
lullaby keeps playing, muffled and ducked to the level of the spot where he stood. It covers the region music the
house would otherwise play. When he comes back out, the mill wakes and the lure corrects itself.

## Root cause

- `FlashbackLure` releases its duck, muffle and voice from `_physics_process` (`flashback_lure.gd:50-55`) when Ivo is
  no longer in the zone, or from `_exit_tree` (`:46-48`).
- `Game._on_player_entered_door` → `_land_in` → `RoomResidency.settle` (`room_residency.gd`, the idle loop at the end
  of `settle`) idles every resident room that does not touch the new one. An interior at y 12000 touches nothing, so
  `Room.deactivate()` sets the mill's contents to `PROCESS_MODE_DISABLED` and hides them. The lure stays in the tree, so
  `_exit_tree` never runs, and its physics step has stopped, so the zone check never runs either.

## Fix

Fixed 2026-11-13 (commit 3a3f15f9). `FlashbackLure._notification(NOTIFICATION_DISABLED)` runs the same release as
`_exit_tree` (`_quiet`: the call stops, the duck, the muffle and the voice request close); its duck and muffle are also
owned by the lure (`systems/music`, "Owners"). Test: `flashback_lure_test`
`test_an_idled_room_closes_what_the_lure_opened`. The proposal was: Close the requests in `FlashbackLure._notification(NOTIFICATION_DISABLED)` (the same release as
`_exit_tree`). The `physics_process` check reopens them on `NOTIFICATION_ENABLED` if Ivo is still inside. The fix
proposed in `bugs/a-quit-to-title-mid-scene-leaves-the-music-muffled` (muffles owned by a node) would cover the muffle
half only.

## Prevention

A node in a room's contents that opens something in an autoload must also close it when the room goes idle
(`gotchas/a-node-idled-or-swapped-out-keeps-what-it-opened-in-an-autoload`).
