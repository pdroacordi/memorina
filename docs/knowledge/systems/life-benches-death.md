---
id: systems/life-benches-death
type: system
title: Life, benches, saving and death
status: active
tags: [save, bench, death, life, respawn]
related: [architecture/the-life-loop-rewinds-by-reloading, architecture/save-slots-and-the-boot-swap, systems/screens, bugs/a-teleported-ivo-enters-the-room-he-left, bugs/the-playtest-runner-adopts-the-legacy-save-before-going-memory-only, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step]
created: 2026-10-02
updated: 2026-10-06
source_files:
  - globals/save_ledger.gd
  - globals/save_system.gd
  - globals/save_slots.gd
  - globals/boot_policy.gd
  - globals/player_data.gd
  - scenes/boot/boot.gd
  - scenes/characters/character.gd
  - scenes/world/game.gd
  - scenes/world/scene_swap.gd
---

# Life, benches, saving and death

Moved verbatim from `CLAUDE.md` ("Life, benches and death") on 2026-10-02.

Design 02 "Vida, Derrota" and design 03 section 4.3, as the user decided them on 2026-10-01 (plan and reasons: `docs/knowledge/architecture/the-life-loop-rewinds-by-reloading.md`). **Only benches save, and death rewinds to the last of them** - songs, skills, items, restored guardians and shortcuts gained since are lost; restoring a guardian is not a save point.

- **The save is a ledger.** `SaveLedger` (pure, tested) holds `live` - what `SaveSystem.player_data` returns and every caller reads and writes - and `committed`, the last bench. `rest_at()` commits and writes; `record_death()` writes the death ONTO the committed save and rewinds to it, so the mark outlives the death that undoes everything else. Copies are `duplicate_deep(DEEP_DUPLICATE_ALL)`: a shallow `duplicate()` shares the flag arrays. Defeated enemies live in the ledger too, never on disk, and both a rest and a death bring them back. Saves live in three slots and the boot policy picks the session (see "Slots and boot" below). A HEADLESS run (the suite, the smoke test, the tools) and the playtest runner always start fresh in memory: none of them may read, move or write a player's save. `saved` fires only when the save landed.
- **Death rebuilds the world.** `Game._on_player_died` waits for `Player.death_shown` (the clip played out) and `death_hold`, fades to black, records the death, and `_reload_world()`s - a deferred `SceneSwap.replace(self, packed)` (removed, freed, a fresh `game.tscn` added at the same index, `current_scene` re-pointed), never `reload_current_scene()`, which under the playtest harness reloads the RUNNER. `SceneSwap.replace` also serves Boot (→ game or title), the title's play (→ game) and Quit to title (→ title). Every system that reads the save at `_ready` comes back as the bench left it; nothing has an undo. What lives outside the scene is reset twice: `WorldFreeze._exit_tree` (the old world leaving) and `WorldFreeze._ready` (the new one) put `Engine.time_scale` back to 1, unpause and clear the hold. `Player.died` → `Screens.lock()` closes any menu and refuses new ones until the world is rebuilt. Nothing rewinds before the black - the corpse's world must not change under the death clip.
- **A bench is a place** (`Bench`, room map `R`, a required `bench_id` unique across every map; `Seat` is an Area2D on physics layer 6 "Interactable", like `Climbable`). Ivo's body decides when he sits (`Player._try_sit`: a `look_down` PRESS, on the floor, no direction held, nothing else holding him); `SitComponent` holds him on the seat; any move, up or press stands him up, and a press that does so is routed through `_unless_seated` so it never reaches a component's buffer and cannot also jump or swing. `sat_down` → `Game` heals (`Health.reset()` now emits `healed`), `SaveSystem.rest_at(bench_id, SceneKey.of(room))`, evicts every other resident room and `expire()`s the current one so its dead return the next time it is entered, never under his feet. Every bench is full wind shelter (`DiscShelter`).
- **A rest is felt, not announced** (the user's choice, 2026-10-01): the bench's `Bloom` (a hidden `MemorySource`, shown only while it blooms so it costs the field nothing) opens like a small warm colour pulse - radius, leading `ring` and strength tweened - on `Seat.rested`; the life notes that come back refill one after another (`LifeNote.regain(delay)`, a white flash and a one-pixel hop); and `SaveMark`, a quill in the corner, answers `SaveSystem.saved`. The bloom reads by how forgotten the place is - and only where there is art behind it to remember.
- **Arrival.** A world built from a save that names a bench enters that room, waits a frame for its contents, finds the `Seat` by id and puts Ivo on it with `Player.sit()` (no rest). A missing room or bench warns and falls back to Ivo's authored start in `game.tscn`.
- **Places are named by `SceneKey.of(node)`**: the uid of the scene a region or room was instanced from, so a save survives renames made in the editor.
- **Death marks** are raw region-local points in `PlayerData.deaths`, clustered at mount by `DeathMarkClusters` (pure, tested; `DeathMarkStats`: merge within 48 px into one deepening mark, at most 6 per region - the field draws at most 32 sources on screen) into small negative `MemorySource`s under `RegionMemory`'s own `DeathMarks` node. They are not wells: `restore()` never touches them. A LIVE restoration erases them (`SaveSystem.clear_deaths` on the live save + `RegionMemory.erase_marks(lift_time)`); a region loaded already restored keeps the marks its save holds, which are deaths after its restoration. There is no decal: the greyhush draws the mark.
- **Life is a row of notes that lose their colour** (`LifeHud`, `LifeNote`, `life_note.gdshader`): the last child of the `CanvasLayer`, over the fade. A lost note greys pixel by pixel on the greyhush's Bayer cell in TEXEL space and its clock runs at its memory, so it stops on its frame and resumes from there - grey is stopped, not tinted. `GreyhushRenderer` pushes `greyhush_black_lift(_color)` as globals so the notes fade into the same print as the world.
- **Quit game saves nothing**: only benches save. The pause menu asks first, "Quit the game? Progress since the last bench will be lost." (`CONFIRM_QUIT_GAME`, `systems/screens`), and Yes calls `Game.quit_game()` → `get_tree().quit()`. User decision, 2026-10-02: "Confirm".

## Slots and boot (UI-05, built 2026-10-06)

Plan and options: `architecture/save-slots-and-the-boot-swap`.

- **Three slots, one file each** (`SaveSlots.COUNT`): release `user://save_1..3.tres`, debug `user://save_debug_1..3.tres`, so a debug build never overwrites a release save. `SaveSlots.adopt_legacy()` moves the pre-slot `save.tres` / `save_debug.tres` into slot 1 once, if slot 1 is empty.
- **Boot policy** (`BootPolicy.decide`, pure, `boot_policy_test`), read by `SaveSystem._ready` before anything touches `user://`:
  - headless, or the playtest runner's scene (`playtest_runner.tscn`) on the command line: memory only (`Session.MEMORY`);
  - debug: slot 1, fresh with `-- --new-game`; `-- --title` begins nothing, so a debug build can reach the title;
  - release: no session.
  `scenes/boot/boot.tscn` is `run/main_scene`: it swaps itself (deferred) for the game when `SaveSystem.has_session()`, else for the title. `Game._ready` asserts `has_session()`.
- **No disk** is `SaveSlots.dir` empty: slot reads answer empty, delete and writes do nothing. `use_memory_only()` sets it and clears the write path; the runner still calls it before `begin("", true)`.
- **API**: `has_session()`, `slot_path(slot)`, `read_slot(slot)` (null when empty), `read_slots()`, `delete_slot(slot)`, `begin_slot(slot, fresh)`, `rest_at(bench, room_key, region_name_key)`.
- **A new game writes nothing until its first rest**, so a slot left before any bench stays empty. New game takes the first empty slot (`SaveSlots.first_empty`); with all three used, the title asks which to overwrite, and Yes deletes that slot at once and begins fresh in it.
- **Play time** (`PlayerData.play_time`, seconds) is wall-clock time, menus included: `SaveSystem` keeps the tick of the last commit and passes the elapsed seconds to `SaveLedger.commit(elapsed)`, `record_death(key, point, elapsed)` and `rewind(elapsed)`. Time since the last bench is lost on quit; the title shows the time at the last write.
- **Last played**: `PlayerData.saved_at` is the Unix second of the last disk write, stamped by `SaveSystem._write` (rests and deaths); 0 in older saves. Continue focuses `SaveSlots.latest`; a new game over full slots focuses `SaveSlots.oldest` (user decision 2026-10-06: "Oldest save"). Ties go to the lower slot.
- **What the title shows**: `PlayerData.region_name_key` (the rested room's `Region.name_key`) and the bench name `SaveSlots.bench_name_key(bench_id)` = `"BENCH_" + bench_id` in capitals; `room_files_test` fails when a bench has no key.
- **A corrupt or unreadable slot is treated as empty** (user decision 2026-10-06: "Treat as empty"): `SaveSlots.load_data` pushes an error and returns null, so the card shows Empty and a new game may take that slot; the bad file is replaced at its first rest.

## Arrival and teleports

- Every move of a character that is not motion goes through `Character.teleport(point)` (`SitComponent.sit`, so arrival and resting; `Player.respawn`; `DebugTrials`; the runner's `player_position`). It writes the position and puts the physics server there too: `body_set_mode(STATIC)`, `body_set_state(TRANSFORM)`, `body_set_mode(KINEMATIC)`. A plain position write leaves a kinematic body at its old place for one step, and every Area2D there reports it (`gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step`). Without it, arriving on a bench outside BloomHollow faded into BloomHollow, the room of Ivo's authored start (`bugs/a-teleported-ivo-enters-the-room-he-left`). `character_teleport_test` pins the engine behaviour.
- `Game._ready` now always runs inside a deferred flush (Boot, the title and a death all swap deferred), so `_arrive`'s wait for the room contents no longer depends on load time (`gotchas/first-process-frame-can-precede-the-first-deferred-flush`).

## Tests

`tests/globals/save_slots_test.gd`, `save_ledger_test.gd`, `player_data_test.gd`, `boot_policy_test.gd`, `tests/scenes/characters/character_teleport_test.gd`, `tests/scenes/world/rooms/maps/room_files_test.gd` (bench keys).
