---
id: architecture/found-pieces
type: architecture
title: Found pieces (STORY-06) - a reward slot fills itself from a catalog keyed by slot_id; letters and songbooks taken with Up, presence derived from the save
status: active
tags: [story-06, found, collectibles, songbook, reward-slots, pickups, notebook, save, save-fact, reach-kits, i18n, plan]
related: [architecture/reward-slots-reserve-their-place-in-the-room-text, architecture/half-songs, architecture/notebook-entries-are-derived-from-the-save, systems/pickups, systems/notebook, systems/notices, systems/rooms, systems/life-benches-death, systems/songs-and-the-memorina, architecture/room-reachability-audit, architecture/rooms-are-text]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - scenes/world/interactables/reward_slot/reward_slot.gd
  - scenes/world/interactables/found_pickup/found_pickup.gd
  - resources/world/found/found_piece.gd
  - resources/world/found/found_catalog.gd
  - resources/world/found/found_catalog.tres
  - scenes/characters/components/pickup_component.gd
  - scenes/characters/ivo/player.gd
  - resources/songs/song_halves.gd
  - resources/save_facts/save_fact.gd
  - globals/player_data.gd
  - globals/save_system.gd
  - resources/ui/notebook/notebook_catalog.gd
  - resources/ui/notebook/notebook_catalog.tres
---

# Found pieces (STORY-06)

**Status: built** (2026-10-28, STORY-06). Design: `docs/design/07_achados.md` (approved 2026-10-28). Fills 17 of the 18 COLLECTIBLE slots: 4 songbooks (second halves, design 02 §7.2.1) and 13 letters, diaries and sketches. `caldera_temple_sanctum` stays empty for LIFE-05.

## Context

- Slots are `$` entities (`RewardSlot`, `slot_id`, `kind`) placed in `.room` text; WORLD-35 promised that the filler keys content by `slot_id` and no map changes (`architecture/reward-slots-reserve-their-place-in-the-room-text`).
- `ItemPickup` is the model: presence derived from the save, Up through `Player`'s chain (`_try_door`, `_try_talk`, `_try_pickup`, one `UP_BUFFER`, `_free_for_up`), found by `PickupComponent` on the `DoorSensor`.
- A songbook must go through `Player.learn_song_half` (the one entry point, `architecture/half-songs`), which needs the Memorina and Ivo still.
- Notebook presence is derived from save facts; Found entries are plain pages (title, detail, body), already rendered by `Notebook.render_entry`'s default branch.

## Options considered

**How a slot becomes a pickup.**
- Point `$` at a new scene (WORLD-35's sketch). Rejected: CACHE slots and the LIFE-05 slot would become empty pickups, and the scene would branch on "no content".
- The importer resolves content at import. Rejected: couples the importer to content, a catalog edit would not reimport, and it bumps `FORMAT_VERSION`.
- **Chosen:** `RewardSlot` stays the `$` scene and, at `_ready`, asks `FoundCatalog` for its `slot_id`; with content it adds a `FoundPickup` child. Legend, `.room` files and importer unchanged. The reach loader instantiates slots without the tree, so the audit is unaffected.

**Pickup class.**
- Extend `ItemPickup` with a mode. Rejected: two unrelated save rules in one script.
- A `Pickup` base class for both. Rejected: inheritance on a non-engine base (CLAUDE.md).
- A `PickupGift` strategy Resource on one generic pickup. Rejected for now: rewrites the sword's legend params and `.room` for one new user.
- **Chosen:** a new `FoundPickup` (Area2D) beside `ItemPickup`. The ~20 lines of reach/prompt/body tracking are duplicated as `Talkable` and `ItemPickup` already do; extract on a third pickup.

**Songbook presence and its Found entry.**
- Entry derived from the half (`knows(SECOND)`). Rejected: F8 or a playtest's `song_halves` would show a "found" book never found; needs a second fact kind.
- **Chosen:** world presence from the half rule (`SongHalves.can_teach`), the Found entry from one recorded fact (`found_pieces`), written in the same frame only if the half was taught. One `SaveFact` kind for every Found entry.

**Kits.**
- Model halves now (`first_halves`/`second_halves` milestones). Rejected: no creature places a first half (CORE-04), so every kit would lose the four songs and the check would regress.
- **Chosen:** kits unchanged; notes updated; a new test pins the design rule "no songbook needs its own song".

## Decision

**Data (Resources, `resources/world/found/`).**
- `FoundPiece`: `slot_id: StringName`, `texture: Texture2D` (world sprite), `song: Song` (null for a letter). No half field: a songbook always teaches SECOND (design 02 §7.2.1), `FoundPickup.TAUGHT_HALF`.
- `FoundCatalog`: `pieces: Array[FoundPiece]`, `const DEFAULT_PATH`, `get_piece(slot_id) -> FoundPiece`, `validate(songs: SongCatalog) -> PackedStringArray` (unique non-empty ids, texture set, every book's song `learned_in_halves`, exactly one book per halved song).
- `found_catalog.tres`: 17 pieces; `letter.png` on 13, `songbook.png` on 4.

**Save.**
- `PlayerData.found_pieces: Array[StringName] = []`: slot ids taken; live data like `found_secrets` (a bench commits, a death forgets; `SaveLedger`'s deep copy covers it; no `migrate` change, an old save loads it empty).
- `SaveSystem.has_found(slot_id) -> bool`, `mark_found(slot_id) -> void` (asserts non-empty; appends and emits `progress_changed` only on a change, like `mark_dialogue_heard`).
- `SaveFact.Kind.PIECE_FOUND` appended (= 11): `data.found_pieces.has(id)`.
- `SongHalves.can_teach(data, song, half) -> bool`: `not knows(half) and (not learned_songs[song] or guessed_halves[song] == half)`. `Player.learn_song_half` refuses with it instead of `knows` alone, so a song learned whole (F9) refuses a half and its book is gone; a song guessed by ear with SECOND guessed still takes the book (CONFIRMED, lesson).

**World.**
- `RewardSlot`: plain `var found_catalog: FoundCatalog = preload(...)` (not exported: the map guide would list it as a param); `_fill()` in `_ready` for COLLECTIBLE only; `content() -> FoundPickup`; the debug marker stops drawing once filled. A child inherits the slot's z 30, so a piece in a closed `[secret]` stays under its z-40 copy.
- `FoundPickup` (`scenes/world/interactables/found_pickup/`): layers as `ItemPickup` (`Seat.LAYER`, mask `Seat.PLAYER_BODY`); 2x2-cell reach; sprite standing on the floor line; `look_up` prompt while in reach (`Player.reaches`) and not in a story.
  - `static lies(piece, data) -> bool`: a book while `SongHalves.can_teach(data, song.id, TAUGHT_HALF)`, a letter while `not found_pieces.has(slot_id)`. Read on ready and on `progress_changed`.
  - `is_available()`, `is_lying()`, `teaches() -> Song`, `take()` (`SaveSystem.mark_found`, emits `taken(slot_id)`).
- `PickupComponent.reachable_found() -> FoundPickup`.
- `Player._try_found(on_floor)` after `_try_pickup`, before `_try_board`: same buffer and gates (a refused press is spent). For a book: if no direction is held, `velocity.x = 0.0`, then `learn_song_half(book, TAUGHT_HALF)`; on false nothing is taken; on true `found.take()`. A letter: `found.take()`. A book is read standing still, as the Memorina is played.

**UI.** No new node.
- `NotebookCatalog`: `SECTION_REQUIREMENT[FOUND] = PIECE_FOUND`; PIECE_FOUND joins the kinds that need `fact_id` (= slot id).
- 17 FOUND entries in 07's order (books, then threads A-D), ids `found_songbook_{bell_jar,rain,gale,solstice}`, `found_bento_{1,2,3}`, `found_marta`, `found_gull_{log,note,oar}`, `found_clara_{pond,crater,ringer}`, `found_pilgrim_{1,2,last}`.
- `NotebookWatcher` announces them with the quill (held through the book's lesson by `NoticeHold`). No item notice: `NoticeWatcher` diffs `owned_items` only, and nothing here touches it.

**i18n.** 51 keys, en and pt_BR verbatim from 07: `NOTEBOOK_FOUND_<ID>_{TITLE,DETAIL,BODY}` (e.g. `NOTEBOOK_FOUND_BENTO_1_DETAIL` "Letter · Woodcutter's hut"). The `·` is already in the font (song detail lines). A text that fails the fit test goes back to the user shortened (07, Notas). No text in scripts or scenes.

**Art.** Contracts `tools/art/prompts/pickup_letter.md`, `pickup_songbook.md`; procedural `tools/art/draw_found_pickups.py` (PIL, like `draw_notebook_found_tab.py`) → `assets/sprites/world/pickups/letter.png`, `songbook.png`, 2x like `sword.png`; `CREDITS.md`.

**Playtest runner.** `"found": [slot_ids]` → `SaveSystem.mark_found`, after `song_halves`. Timeline `tools/playtest/scripts/story06_found.json`: take `frost_wreck_letter` (base kit), open the notebook; take `woods_root_caves_alcove` with `song_halves: [[1, 1]]` (completing lesson) and with none (half sheet).

## Build order

1. Data and save: `PIECE_FOUND`, `found_pieces`, `SaveSystem` API, `SongHalves.can_teach` + `learn_song_half` refusal, runner `found`. Tests.
2. `FoundPiece`, `FoundCatalog` (+ `.tres` with placeholder textures from step 6's script run first, or `make_placeholders.gd`).
3. `FoundPickup` scene; `RewardSlot._fill`; legend `$` description ("COLLECTIBLE slots are filled from found_catalog.tres by slot_id"), `docs/maps/README.md` regenerated.
4. `PickupComponent.reachable_found`, `Player._try_found`.
5. Notebook: catalog requirement, 17 entries, 51 keys; fit test.
6. Art script and contracts, `CREDITS.md`.
7. Kits: the four notes ("songbook placed in <slot> by STORY-06; the first half waits for CORE-04"); no allowlist entry is stale (the two slot-related reasons are jump skips, unchanged by content); rerun `room_reach_test`.
8. Docs: new `systems/found-pieces` + CLAUDE.md row; `systems/pickups`, `notebook`, `rooms`, `songs-and-the-memorina`, `life-benches-death`; glossary (achado → `FoundPiece`/`found_pieces`, caderno de canções → songbook); this entry's As built; roadmap. `verify-gates`, then playtest.

## Tests (gdUnit4)

- `tests/resources/songs/song_halves_test.gd`: `test_can_teach_per_state` (unknown, first, second, learned whole, by ear guessed SECOND/FIRST, confirmed).
- `tests/resources/save_facts/save_fact_test.gd`: `test_piece_found`.
- `tests/globals/save_system_found_test.gd`: emits once; repeat silent; a death forgets; `player_data_test`: an old save loads `found_pieces` empty, round trip.
- `tests/resources/world/found/found_catalog_test.gd`: shipped catalog validates; 17 pieces; the four books on the four 07 slots with BELL_JAR, RAIN, GALE, SOLSTICE; bad catalogs report (duplicate, unhalved song, no texture).
- `tests/scenes/world/interactables/found_pickup/found_pickup_test.gd`: letter shown/hidden both ways; book per half state; a rewind puts both back; take records and emits; prompt.
- `tests/scenes/world/interactables/reward_slot/reward_slot_test.gd`: a COLLECTIBLE with content gets one child and no marker; `caldera_temple_sanctum` and a CACHE get none.
- `tests/scenes/characters/ivo/player_found_test.gd`: Up takes a letter once; a book teaches SECOND and records; refused without the Memorina (not taken, press spent); refused with a direction held; completing half `is_in_lesson()`; door, talk and item win; airborne refused.
- `room_files_test`: `test_every_collectible_slot_but_the_life_note_has_found_content` (const `RESERVED := [&"caldera_temple_sanctum"]`, LIFE-05); `test_every_found_piece_names_a_collectible_slot`.
- `room_kit_test.test_no_songbook_needs_its_own_song`: for each book, some kit without its song reaches the slot (07's rule).
- `notebook_catalog_test`: FOUND needs PIECE_FOUND and a `fact_id`; FOUND entries and catalog pieces are one-to-one; keys in both languages. `notebook_text_fit_test` covers the pages by iterating every entry. `notebook_watcher_test.test_a_found_piece_announces`; `notice_watcher_test.test_a_found_piece_raises_no_notice`; `map_guide_test`.

## Consequences

- A slot's content lives only in `found_catalog.tres`; moving a piece is a data edit, never a map edit. LIFE-05 adds its own lookup in `RewardSlot._fill` for `caldera_temple_sanctum`.
- `learn_song_half` refuses a half on a song learned whole; F8 is unaffected (it skips learned songs).
- A book taken by F8 or `song_halves` vanishes with no Found entry: the entry means "picked up".
- CORE-04 must add `first_halves`/`second_halves` to `ReachMilestone`, a second-half milestone per book room (woods_root_caves, lake_shore, caldera_seesaw, orchard_ridge), and drop the second song from the guardian milestones in one change.

## User decisions (2026-10-28)

- Taking a letter: "Quill only (Recommended)": the letter leaves the world, the quill announces the Found entry, play continues.
- World art: "Letter + songbook (Recommended)": one letter sprite for all 13 pieces, one songbook sprite for the 4 books.

## As built (2026-10-28)

- As planned, except: the `$` legend description was not changed (`room_legend.tres` carried unrelated uncommitted work), so its text still says the slot does nothing until filled.
- `_try_found` drops the other buffers only after `learn_song_half` returns true (`bugs/up-on-a-songbook-during-a-hard-landing-is-spent-and-the-book-stays`).
- A songbook's prompt hides while Ivo moves (`playtests/2026-10-28-story06-found-pieces`: a refused press on the run gave no sign why).
