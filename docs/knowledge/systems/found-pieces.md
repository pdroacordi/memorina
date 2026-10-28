---
id: systems/found-pieces
type: system
title: "Found pieces: letters and songbooks in the reward slots, taken with Up, read in the notebook's Found tab"
status: active
tags: [story-06, found, collectibles, songbook, reward-slots, pickups, notebook, save, i18n]
related: [architecture/found-pieces, architecture/reward-slots-reserve-their-place-in-the-room-text, architecture/half-songs, systems/pickups, systems/notebook, systems/songs-and-the-memorina, systems/life-benches-death, systems/rooms]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - resources/world/found/found_piece.gd
  - resources/world/found/found_catalog.gd
  - resources/world/found/found_catalog.tres
  - scenes/world/interactables/found_pickup/found_pickup.gd
  - scenes/world/interactables/found_pickup/found_pickup.tscn
  - scenes/world/interactables/reward_slot/reward_slot.gd
  - scenes/characters/components/pickup_component.gd
  - scenes/characters/ivo/player.gd
  - resources/songs/song_halves.gd
  - globals/player_data.gd
  - globals/save_system.gd
  - resources/save_facts/save_fact.gd
  - resources/ui/notebook/notebook_catalog.tres
  - tools/art/draw_found_pickups.py
---

# Found pieces

**Never break:** A piece's presence is derived from the save, never recorded apart from the take: a letter lies while `found_pieces` lacks its slot id, a songbook while `SongHalves.can_teach(song, SECOND)` holds. A slot's content lives only in `found_catalog.tres`, keyed by `slot_id`; no `.room` file names content. A songbook is taken only when `Player.learn_song_half` returned true.

## Summary

STORY-06, design `docs/design/07_achados.md` (approved 2026-10-28). The 18 COLLECTIBLE reward slots hold 4 songbooks (second halves of Redoma, Chuva, Vendaval, Solstício), 13 letters, diaries and sketches in four threads, and the LIFE-05 life note in `caldera_temple_sanctum` (empty until LIFE-05). Plan: `architecture/found-pieces`.

User decisions (2026-10-28): taking a letter, "Quill only (Recommended)": the piece leaves the world, the notebook quill announces its Found entry, play continues. World art, "Letter + songbook (Recommended)": one letter sprite for the 13 pieces, one songbook sprite for the 4 books.

## How a slot fills

- `RewardSlot._ready` (COLLECTIBLE only) looks up its `slot_id` in `FoundCatalog` and adds a `FoundPickup` child; a filled slot stops drawing its debug marker. CACHE slots and unlisted slots stay markers.
- The legend, `.room` files and the importer are unchanged. The reach loader instantiates slots outside the tree, so `_ready` does not run there.
- The pickup inherits the slot's z (`RoomMapNode.SECRET_Z - 10`), so a piece in a closed `[secret]` stays under its world copy.

## The pickup (`FoundPickup`)

- An Area2D on `Seat.LAYER` masking the Player body, like `ItemPickup`; a 2x2-cell reach centred on the slot, rising from its floor; the sprite stands on the floor line; the `look_up` prompt shows over the reach while Ivo is in it, not in a story, and the piece lies there; a songbook's prompt also hides while Ivo moves, since a moving Ivo cannot read it (playtest 2026-10-28: a refused press on the run gave no sign why).
- `lies(piece, data)` is the one rule (static, pure). `take()` calls `SaveSystem.mark_found(slot_id)` and emits `taken`.

## Ivo

- `PickupComponent.reachable_found()`; `Player._try_found` runs after `_try_pickup` and before `_try_board`, with the one `UP_BUFFER` and `_free_for_up`; a refused press is spent.
- A songbook is read standing still: a held direction refuses the press; otherwise `velocity.x` is zeroed and `learn_song_half(song, SECOND)` runs (a full lesson when the half completes the song or confirms Ivo's guess, else the half sheet). Without the Memorina it returns false and the book stays.
- No item notice: `NoticeWatcher` diffs `owned_items` only.

## Save

- `PlayerData.found_pieces: Array[StringName]`, slot ids taken; live data like heard (a bench commits it, a death forgets it). An old save loads it empty.
- `SaveSystem.has_found(slot_id)`, `mark_found(slot_id)` (emits `progress_changed` only on a change).
- `SaveFact.Kind.PIECE_FOUND` (11, appended) reads `found_pieces.has(id)`; every Found notebook entry uses it with the slot id as `fact_id`.
- A book taken by F8 or a timeline's `song_halves` vanishes from the world with no Found entry: the entry means "picked up".

## Notebook

17 FOUND entries in design 07's order, ids `found_songbook_{bell_jar,rain,gale,solstice}`, `found_bento_{1,2,3}`, `found_marta`, `found_gull_{log,note,oar}`, `found_clara_{pond,crater,ringer}`, `found_pilgrim_{1,2,last}`. Keys `NOTEBOOK_FOUND_<ID>_{TITLE,DETAIL,BODY}`, en and pt_BR verbatim from 07; `notebook_text_fit_test` covers them.

## Reachability

Kits are unchanged: the four second songs still stand in for their halves (`reach_kits.tres` notes name each book's slot). CORE-04 must add first- and second-half milestones and drop the second songs from the guardian milestones in one change. `room_kit_test.test_no_songbook_needs_its_own_song` pins design 07's rule.

## Art

`assets/sprites/world/pickups/letter.png` (12x10) and `songbook.png` (12x13), propped upright with strong value contrast so they stand over the grass in the grey, drawn by `tools/art/draw_found_pickups.py`; contracts `tools/art/prompts/pickup_letter.md`, `pickup_songbook.md`.

## Debug and playtests

Timelines take `"found": ["<slot id>"]` (`tools/playtest/README.md`).

## Known limits

- The first art lay flat at grass height and blended into the grey (`playtests/2026-10-28-story06-found-pieces`); redrawn upright with a dark cover and a dark flap V, not yet playtested.
- Without the Memorina the songbook's prompt shows but Up does nothing; the village fences need the Memorina first, so normal play should not reach a book without it.

## Tests

- `found_catalog_test`, `found_pickup_test`, `reward_slot_test`, `player_found_test`, `save_system_found_test`.
- `song_halves_test.test_can_teach_per_state`.
- `room_files_test.test_found_pieces_and_collectible_slots_match`; `room_kit_test.test_no_songbook_needs_its_own_song`.
