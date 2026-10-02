---
id: systems/life-benches-death
type: system
title: Life, benches, saving and death
status: active
tags: [save, bench, death, life, respawn]
related: [architecture/the-life-loop-rewinds-by-reloading, architecture/save-slots-and-the-boot-swap, systems/screens]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - globals/save_ledger.gd
  - globals/save_system.gd
  - scenes/world/game.gd
  - scenes/world/scene_swap.gd
---

# Life, benches, saving and death

Moved verbatim from `CLAUDE.md` ("Life, benches and death") on 2026-10-02.

Design 02 "Vida, Derrota" and design 03 section 4.3, as the user decided them on 2026-10-01 (plan and reasons: `docs/knowledge/architecture/the-life-loop-rewinds-by-reloading.md`). **Only benches save, and death rewinds to the last of them** - songs, skills, items, restored guardians and shortcuts gained since are lost; restoring a guardian is not a save point.

- **The save is a ledger.** `SaveLedger` (pure, tested) holds `live` - what `SaveSystem.player_data` returns and every caller reads and writes - and `committed`, the last bench. `rest_at()` commits and writes; `record_death()` writes the death ONTO the committed save and rewinds to it, so the mark outlives the death that undoes everything else. Copies are `duplicate_deep(DEEP_DUPLICATE_ALL)`: a shallow `duplicate()` shares the flag arrays. Defeated enemies live in the ledger too, never on disk, and both a rest and a death bring them back. Debug builds use `user://save_debug.tres` and continue it like a release (the user's call, 2026-10-01); `-- --new-game` starts fresh; the playtest runner calls `SaveSystem.begin("", true)` and works in memory, and a HEADLESS run (the suite, the smoke test, the tools) always starts fresh in memory - nobody plays headless, and none of them may read or write a player's save. `saved` fires only when the save landed.
- **Death rebuilds the world.** `Game._on_player_died` waits for `Player.death_shown` (the clip played out) and `death_hold`, fades to black, records the death, and `_reload_world()`s - a deferred `SceneSwap.replace(self, packed)` (removed, freed, a fresh `game.tscn` added at the same index, `current_scene` re-pointed), never `reload_current_scene()`, which under the playtest harness reloads the RUNNER. Quit to title and the title's play (UI-05) reuse `SceneSwap`. Every system that reads the save at `_ready` comes back as the bench left it; nothing has an undo. What lives outside the scene is reset twice: `WorldFreeze._exit_tree` (the old world leaving) and `WorldFreeze._ready` (the new one) put `Engine.time_scale` back to 1, unpause and clear the hold. `Player.died` → `Screens.lock()` closes any menu and refuses new ones until the world is rebuilt. Nothing rewinds before the black - the corpse's world must not change under the death clip.
- **A bench is a place** (`Bench`, room map `R`, a required `bench_id` unique across every map; `Seat` is an Area2D on physics layer 6 "Interactable", like `Climbable`). Ivo's body decides when he sits (`Player._try_sit`: a `look_down` PRESS, on the floor, no direction held, nothing else holding him); `SitComponent` holds him on the seat; any move, up or press stands him up, and a press that does so is routed through `_unless_seated` so it never reaches a component's buffer and cannot also jump or swing. `sat_down` → `Game` heals (`Health.reset()` now emits `healed`), `SaveSystem.rest_at(bench_id, SceneKey.of(room))`, evicts every other resident room and `expire()`s the current one so its dead return the next time it is entered, never under his feet. Every bench is full wind shelter (`DiscShelter`).
- **A rest is felt, not announced** (the user's choice, 2026-10-01): the bench's `Bloom` (a hidden `MemorySource`, shown only while it blooms so it costs the field nothing) opens like a small warm colour pulse - radius, leading `ring` and strength tweened - on `Seat.rested`; the life notes that come back refill one after another (`LifeNote.regain(delay)`, a white flash and a one-pixel hop); and `SaveMark`, a quill in the corner, answers `SaveSystem.saved`. The bloom reads by how forgotten the place is - and only where there is art behind it to remember.
- **Arrival.** A world built from a save that names a bench enters that room, waits a frame for its contents, finds the `Seat` by id and puts Ivo on it with `Player.sit()` (no rest). A missing room or bench warns and falls back to Ivo's authored start in `game.tscn`.
- **Places are named by `SceneKey.of(node)`**: the uid of the scene a region or room was instanced from, so a save survives renames made in the editor.
- **Death marks** are raw region-local points in `PlayerData.deaths`, clustered at mount by `DeathMarkClusters` (pure, tested; `DeathMarkStats`: merge within 48 px into one deepening mark, at most 6 per region - the field draws at most 32 sources on screen) into small negative `MemorySource`s under `RegionMemory`'s own `DeathMarks` node. They are not wells: `restore()` never touches them. A LIVE restoration erases them (`SaveSystem.clear_deaths` on the live save + `RegionMemory.erase_marks(lift_time)`); a region loaded already restored keeps the marks its save holds, which are deaths after its restoration. There is no decal: the greyhush draws the mark.
- **Life is a row of notes that lose their colour** (`LifeHud`, `LifeNote`, `life_note.gdshader`): the last child of the `CanvasLayer`, over the fade. A lost note greys pixel by pixel on the greyhush's Bayer cell in TEXEL space and its clock runs at its memory, so it stops on its frame and resumes from there - grey is stopped, not tinted. `GreyhushRenderer` pushes `greyhush_black_lift(_color)` as globals so the notes fade into the same print as the world.
- **Quit game saves nothing**: only benches save. The pause menu asks first, "Quit the game? Progress since the last bench will be lost." (`CONFIRM_QUIT_GAME`, `systems/screens`), and Yes calls `Game.quit_game()` → `get_tree().quit()`. User decision, 2026-10-02: "Confirm".
