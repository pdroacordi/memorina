---
id: architecture/save-slots-and-the-boot-swap
type: architecture
title: Three save slots, a Boot scene that picks title or game, and one SceneSwap for death, quit-to-title and new game
status: active
tags: [save, slots, title, boot, scene-swap, play-time, headless, playtest, plan]
related: [architecture/the-life-loop-rewinds-by-reloading, architecture/pause-menu-worldfreeze-reuse, architecture/map-reveal-seen-cells-per-room, gotchas/queue-free-keeps-the-name-until-frame-end, gotchas/first-process-frame-can-precede-the-first-deferred-flush, systems/life-benches-death]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - globals/save_system.gd
  - globals/save_ledger.gd
  - globals/save_slots.gd
  - globals/player_data.gd
  - scenes/boot/boot.gd
  - scenes/ui/title/title.gd
  - scenes/world/scene_swap.gd
  - scenes/world/game.gd
  - scenes/world/world_freeze.gd
  - tools/playtest/playtest_runner.gd
  - project.godot
---

> **Status: planned** (2026-10-02, roadmap UI-05). Nothing here is built yet.

## Context

The user's decisions (2026-10-02): release builds boot into a title screen with 3 save slots.
Each slot shows the region and bench, the time played, and a delete with confirmation. An empty
slot starts a new game. Debug builds keep booting straight into `game.tscn` on `save_debug.tres`.
The pause menu gains "Quit to title".

The constraints already paid for: death rebuilds the world by a deferred self-swap, never
`reload_current_scene()`, because the playtest runner instantiates `game.tscn` as its child. A
headless run (suite, smoke, tools) never reads or writes a player's save, and the playtest
runner works in memory (`systems/life-benches-death`).

## Options considered

**Slot storage.** One file holding three `PlayerData` was rejected: every bench rewrites all
three, and one bad write loses all three. **Chosen: one file per slot.** Release slots are
`user://save_1..3.tres`. Debug slots are `user://save_debug_1..3.tres`, so a debug build still
never overwrites a release save. A legacy `save.tres` / `save_debug.tres` is renamed into slot 1
once, if slot 1 is empty.

**Switching between title and game.**
- `change_scene_to_packed` was rejected again: under the harness it replaces the runner.
- A persistent `Main` root hosting the title or the game was rejected. A death's self-swap replaces
  `Game` behind Main's back and drops Main's connections, and it adds a tree level for nothing.
- **Chosen: `SceneSwap.replace(old, packed) -> Node`** (static), which is `Game._reload_world`
  generalised. It does `remove_child` first, then `queue_free`, adds the new scene at the same index,
  and re-points `current_scene`. Death, quit-to-title and the title's "play" all use it.

**Boot.** A `run/main_scene.debug` feature override was rejected: it is unverified for this
setting and invisible. A title that skips itself in debug was rejected: the title would then own
the debug policy. **Chosen: `Boot` (`scenes/boot/boot.tscn`, the new main scene)** swaps to the game if
`SaveSystem.has_session()`, else to the title. `SaveSystem._ready` keeps the whole policy:
- headless: in memory;
- debug: debug slot 1 (`--new-game` starts it fresh; the new `--title` argument begins nothing,
  so a debug build can reach the title);
- release: no session.

**Scene references.** `Game` exporting the title `PackedScene` while `Title` exports the game
`PackedScene` is a cyclic resource dependency. **Chosen:** both export file paths
(`@export_file`) and `load()` them at swap time.

**Leaving a frozen world.** "Quit to title" is pressed while the pause menu holds the tree.
Thawing first lets enemies act during the fade, and a death beat can race the quit. **Chosen:**
stay frozen. `Screens` blacks out on its own ALWAYS layer (a `Fade` instance), then `Game` swaps.
`WorldFreeze._exit_tree()` resets the time scale to 1 and unpauses. It is still the only writer,
and the title starts on a running clock.

**Play time.**
- A per-frame counter node was rejected: a pausable one also stops through performances, an ALWAYS one is one
  more node.
- **Chosen:** `SaveSystem` keeps the tick of the last commit (`Time.get_ticks_msec`) and passes the
  elapsed seconds to the ledger: `SaveLedger.commit(elapsed)` adds them to live before the copy, and
  `record_death(key, point, elapsed)` adds them to COMMITTED, like a death mark. Time in menus
  counts. Time since the last bench is lost on quit, because only benches save.

**What the title shows.** The title cannot load the world to turn a room uid into a name. **Chosen:**
`rest_at` also stores the region's `name_key` (a translation key, never translated text) in
`PlayerData.region_name_key`. The bench name follows the convention `"BENCH_" + bench_id.to_upper()`,
which `room_files_test` enforces against `translations.csv`.

**No disk.** **Chosen: `SaveSystem._dir` empty means no disk.** It is set in headless runs and by
`SaveSystem.use_memory_only()`, which the playtest runner calls before `begin("", true)`. Slot
reads then answer empty, and `delete_slot` and every write do nothing.

## Decision

- `SaveSlots` (RefCounted, pure): `COUNT := 3`, `file_name(slot, debug)`, `legacy_file_name(debug)`,
  `play_time_parts(seconds) -> Vector2i` (hours, minutes).
- `SaveSystem` (still a delegating autoload): `has_session()`, `use_memory_only()`, `slot_path(slot)`,
  `read_slot(slot) -> PlayerData` (`CACHE_MODE_IGNORE`, null when empty), `delete_slot(slot)`,
  `begin_slot(slot, fresh)`, `rest_at(bench, room_key, region_name_key)`. `begin(path, fresh)` is
  unchanged.
- `PlayerData`: `play_time: float` (seconds), `region_name_key: String`. Old saves load with the defaults.
- A new game writes nothing until its first bench, so a slot quit before any bench stays empty.

## Consequences

- `game.tscn` and `title.tscn` roots are PAUSABLE explicitly, so they never inherit ALWAYS from a
  parent (the playtest runner becomes ALWAYS).
- `Game._ready` asserts `SaveSystem.has_session()`; running `game.tscn` in a release build
  without the title is a bug, not a fallback.
- `SaveSystem` is near the size where disk I/O should move into its own RefCounted. Split it if it
  passes about 250 lines.
- A slot's file appears only at the first rest, so "time played" on the title is the time at the
  last bench.
