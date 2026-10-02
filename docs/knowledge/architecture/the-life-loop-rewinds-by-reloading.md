---
id: architecture/the-life-loop-rewinds-by-reloading
type: architecture
title: The life loop - benches commit, death rewinds by reloading game.tscn from the committed save, death marks are written on top of the rewind
status: active
tags: [save, bench, death, respawn, rewind, death-marks, life-hud, region-memory, playtest, plan]
related: [architecture/hazard-respawn-on-safe-ground, architecture/the-region-owns-its-forgetting, architecture/pause-menu-worldfreeze-reuse, architecture/rooms-are-text, architecture/character-controller-input-split, architecture/animation-driver-resolver-pattern, gotchas/a-killed-tween-never-emits-finished, gotchas/monitorable-false-hides-an-area-from-every-monitor, gotchas/queue-free-keeps-the-name-until-frame-end, gotchas/import-plugin-output-is-stale-when-its-logic-changes, bugs/respawn-teleports-a-dead-ivo, bugs/a-second-fall-during-the-respawn-clear-sinks-forever]
created: 2026-10-01
updated: 2026-10-01
source_files:
  - globals/save_system.gd
  - globals/player_data.gd
  - scenes/world/game.gd
  - scenes/world/world_freeze.gd
  - scenes/world/rooms/region.gd
  - scenes/world/rooms/region_memory.gd
  - scenes/world/rooms/room.gd
  - scenes/characters/ivo/player.gd
  - scenes/combat/health/health.gd
  - tools/playtest/playtest_runner.gd
---

> **Status: built** (2026-10-01, commits 1d02d6f..5319a40). The plan below is what was implemented, with the user's decisions in "Decisions taken"; `systems/life-benches-death` is the short form.

## Context

The user's decisions of 2026-10-01 (design 02 "Vida, Derrota", already updated): death returns Ivo to the last
bench and drops everything gained since (songs, skills, items, restored guardians, shortcuts); only benches save;
Ivo sits by pressing DOWN (`look_down`) at a bench; resting brings defeated enemies back; life is a row of 3
notes that go grey and STILL when lost, always visible. Defaults: death marks (design 03 section 4.3) survive the
rewind; death also respawns enemies; a bench heals, saves and is a full wind shelter; with no bench yet, Ivo
returns to the authored start. Correction to the brief: `scenes/world/spawner.gd` spawns effects. The "existing
spawn" is Ivo's own authored position in `game.tscn`, which already is the new-game start.

Today `save_game()` is never called, `_defeated_enemies` is never cleared, `Health.reset()` emits nothing, and
`Player._on_health_died` only drops the recall.

## Options considered

**How to rewind.**
- *Reset in place.* Each system that read the save at `_ready` would need an undo: `RegionMemory` has no
  un-restore (its wells are hidden), `GuardianFight` would need to go back from RESTORED or mid-fight to DORMANT,
  enemies would have to be re-instanced, and in-flight pulses, ice, released loads, shadows, the staged camera,
  both call HUDs, `LessonCinematic` and about 30 `Player` fields would all need resetting. That is one `reset()`
  per system, and any one of them can be forgotten. Rejected.
- *Chosen: reload `game.tscn` after rewinding the save.* Every system already comes back right because each
  already reads the save at `_ready` (`Region` restores at 0 s, `Guardian.restore_silently`, `Enemy` frees
  itself, `Player` queries skills and songs live). The cost is one instantiate behind a black screen. The
  `PackedScene` is cached, and room contents load lazily anyway.

**What survives a reload and must be reset explicitly** (the traps of the chosen option):
`Engine.time_scale` and `get_tree().paused` (WorldFreeze is per-scene, so a tween or `hit_stop` await on the
freed node never finishes); the `SaveSystem` autoload; held `Input` state. `SaveSystem` is the only autoload.

**How to reload.** `reload_current_scene()` is wrong under the playtest harness. The runner instantiates
`game.tscn` as its child, so the RUNNER would reload and restart the timeline. Chosen instead:
`Game._reload_world()`, called deferred. It removes itself from its parent (`remove_child` first, so its
sources, shelters and groups leave before the fresh ones join, see `gotchas/queue-free-keeps-the-name-...`),
calls `queue_free`, adds a fresh `load(scene_file_path).instantiate()`, and re-points `current_scene` if it was
the current scene. One path serves both the main scene and the harness.

**Where Ivo comes back.** A world position goes stale when a `.room` or a region moves (FrostEdge already sits
at x 5856). A bench node does not exist at boot, because room contents load lazily. Chosen: save the
`bench_id` (authored, globally unique, enforced by tests) plus the bench's ROOM key. At arrival `Game`
activates that room, waits one frame (`Room.activate` adds contents deferred), and finds the bench by id.
Keys are `SceneKey.of(node)`: the node's scene uid text, falling back to `scene_file_path`, so a rename made in
the editor keeps old saves valid.

**What the save carries between commits.** Chosen: a pure `SaveLedger` holding `live` (what the world reads and
writes, still exposed as `SaveSystem.player_data`) and `committed` (the last bench). Disk is written only on a
commit or a death. The rejected alternative was re-reading the file on death: tests and playtests need a mode
with no disk, and the ledger gives them that.

**Death marks.** Two choices were weighed. (a) Merge marks in the save, which bakes tuning into the save.
(b) Store raw deaths and cluster them when they are mounted. Chosen (b): the save records facts (region key to
`PackedVector2Array` of region-local points), and `RegionMemory` clusters them. This lets the tuning change
without migrating saves. A mark is ONLY a small negative `MemorySource`: the greyhush draws it as a grey disc
with a dithered edge, which is literally "um pequeno símbolo do cinzesquecimento". A painted decal was rejected
because the grey is absence, not ink. Clustering is required because `MemoryField.MAX_SOURCES` is 32 on screen
and the renderer asserts past it. Twenty deaths at one boss would otherwise break the frame.

## Decision

### Data: `PlayerData` (globals/player_data.gd)
New fields: `@export var bench_id: StringName = &""`, `@export var bench_room: String = ""`, and
`@export var deaths: Dictionary[String, PackedVector2Array] = {}` (region key to region-local points). A
dictionary of packed arrays means no custom sub-resource script ends up in the save. Old saves simply lack the
keys and load with the defaults. `migrate()` is unchanged (it only grows the enum-indexed flags).

### Pure logic (RefCounted, gdUnit)
- `SaveLedger` (globals/save_ledger.gd). `_init(start)`: committed = start, live = copy.
  `commit() -> PlayerData` copies live into committed and clears `defeated`. `rewind()` copies committed into
  live and clears `defeated`. `record_death(region_key, point) -> PlayerData` appends to COMMITTED and then
  rewinds, so the mark is on top of the bench state. `defeated: Dictionary` replaces
  `SaveSystem._defeated_enemies`. Copies use `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)`, because a shallow
  `duplicate()` SHARES the flag arrays. The test walks every exported property to prove the copy is independent.
- `DeathMarkClusters` (scenes/world/rooms/death_mark_clusters.gd). `cluster(points, stats) -> Array[Dictionary]`
  returns `{centre, deaths}`, greedy in death order. A point within `merge_distance` deepens the nearest
  cluster. Past `max_marks` it merges into the nearest. `strength_for(deaths)` and `radius_for(deaths)` grow and
  are capped.
- `SceneKey` (scenes/world/rooms/scene_key.gd), static `of(node) -> String`.

### Autoload: `SaveSystem` stays thin
It delegates to the ledger. `player_data` is still the live data, so every existing caller is untouched. New
methods: `rest_at(bench_id, room_key)` (set bench fields, `ledger.commit()`, write), `record_death(region_key,
point)` (write the returned committed data), `commit()` (playtest setup), `bench_id()`, `bench_room()`,
`deaths_in(region_key)`, `begin(path, fresh)`. A path of `""` means in-memory. Boot policy:
- **Release**: `user://save.tres`, load if present.
- **Debug**: `user://save_debug.tres`, continued on launch (see decision 4: the user reversed "fresh unless `--continue`"); `--new-game` starts fresh. Originally: a FRESH new game unless the user arg `--continue` is
  given. Editor runs stay deterministic and never clobber a release save on the same machine.
- **Playtest runner**: `SaveSystem.begin("", true)` before instantiating, then teach `known_songs`, then
  `SaveSystem.commit()`. This way a death mid-timeline rewinds to the timeline's own start. That start is NOT
  `player_position`: a rewound run comes back at the authored start or a bench.

### Bench (a `.room` entity, legend `R`)
- `scenes/world/interactables/bench/bench.tscn` + `bench.gd` (`class_name Bench extends Node2D`). Map params:
  `bench_id: StringName` (required) and `facing: int`. Its children:
  - `Sprite2D`, world art, so the greyhush greys it.
  - `Seat` (`seat.gd`, `class_name Seat extends Area2D`). It is a PLACE, like `Climbable`: on a new physics
    layer 6 "Interactable", `monitoring = false`. Bench pushes `bench_id` and `facing` into it, and its origin
    is where the feet go.
  - `Shelter`: a `DiscShelter`. Make `radius` an `@export` (default 0 keeps `FrostShell` unchanged).
  - `Prompt`: a `KeyGlyph` for `look_down`, with no text, shown while Ivo can sit (see below).
- Legend: `RoomLegendEntry` gains `required_params: PackedStringArray`. `RoomMapValidator` rejects a missing
  one. Set it on `R` (`bench_id`) and `B` (`save_id`). `brute_shadow.tscn`'s default `save_id`
  `"downtown_brute_shadow"` must become `""`, because today every brute without a param shares one id.
  `room_files_test` asserts that `bench_id` and `save_id` are unique across ALL maps. Bump the importer's
  `FORMAT_VERSION` (the validator is baked into the import) and regenerate the guide.

### Sitting (the body's judgement, `PlayerInput`/`Player` split)
- `PlayerInput.look_down_pressed`: a new discrete signal. `look_direction` stays the polled axis.
- `SitComponent` (scenes/characters/components/, generic like `ClimbComponent`) with a `SeatSensor` Area2D
  child of Ivo masking layer 6: `reachable() -> Seat`, `sit(seat)`, `stand()`, `is_sitting()`, `seat()`. It
  calls `seat.set_occupied(bool)` so the bench hides its prompt. The prompt is shown while
  `seat.has_body_in_reach` and not occupied (the Seat monitors Ivo's BODY on layer 9, never the hurtbox, see
  the gotcha).
- `Player`: `MotionState.SIT` and `_sit_motion` (velocity zero, no gravity, no carry). `_try_sit()` runs on a
  buffered press only when on the floor, `is_still()`, not climbing, not sinking, not dead, the Memorina is
  sheathed (down is a note while drawn), and no call is open. It calls `sit()` and then emits
  `sat_down(seat)`. A public `sit(seat)` without the signal is used for arrival. He gets up on move input, up,
  jump, roll, attack or draw. The press is consumed: it stands him up and does not also act. A hit stands him
  up through `_react_to_hurt`. `look_axis()` returns 0 while seated, so the down press does not peek. `rest()`
  calls `health.reset()`.
- `PlayerAnimationResolver`: `const SIT`, one line right after HURT. Add `SIT_DOWN`/`STAND_UP` via
  `driver.sequence` only once art exists.

### Rest: `Game._on_player_sat_down(seat)` (wired in game.tscn)
It calls `_player.rest()` and `SaveSystem.rest_at(seat.bench_id, SceneKey.of(_room_at(seat.global_position)))`.
Then `_wake_rooms()`: `evict()` every resident room except the current one, and `expire()` the current one.
`Room.expire()` is new: its next `activate()` after being left re-instantiates the contents, so the current
room's dead also return.

### Death: `Game._on_player_died()` (wired to `Player.died`)
1. `_dying = true` and `_hazard_beat += 1` (a running hazard beat stands down at its next check).
   `_on_player_entered_room` ignores entries while dying, because a corpse can fall across a room boundary.
   Record the region key and the region-local point NOW.
2. Await `Player.death_shown` (new signal: Player polls `_player_resolver.is_death_finished()` in its dead
   branch and emits it once), then `death_hold` (export, about 0.6 s).
3. `await _fade.to_black()` (resolves on `Fade.faded`), then `SaveSystem.record_death(...)`, then
   `_reload_world.call_deferred()`.

The live save is NOT rewound before the black, or the corpse's world (a guardian's `has_skill` checks) would
change under the death clip. Cases:
- **Recall open**: `_drop_recall`, then `recall_ended`, then `WorldFreeze.restore`, already there.
- **Sinking**: the hazard beat checks `beat != _hazard_beat` and stops; a dead corpse is never `respawn()`ed.
- **Guardian fight**: nothing special; the reload brings the guardian back DORMANT.
- **Mid-performance or lesson**: cannot begin, because the tree is paused and nothing deals damage. Assert
  `not get_tree().paused` at step 1.

Separately, `WorldFreeze._ready()` sets `Engine.time_scale = 1.0` and `paused = false` ("a new world starts on
a running clock"). It is still the one writer.

### Arrival: `Game._ready()` calls `_arrive()`
With no bench saved, today's flow runs unchanged (Fade starts black, and the first room entry clears it).
Otherwise:
1. `_is_transitioning = true`, Ivo `PROCESS_MODE_DISABLED`.
2. `_enter_room(room_by_key)`, await `process_frame`, `Seat.find(bench_id)` (group), place and `sit()` Ivo
   (respawned SEATED).
3. `_camera.snap()`, re-enable, `await _fade.to_clear()`.

A missing room or bench is a `push_warning` and falls back to the authored start (the smoke test fails on
warnings, which is right for a broken map).

### Death marks in the region
`Region._ready` calls `_memory.mark_deaths(SaveSystem.deaths_in(SceneKey.of(self)))`. `RegionMemory` (export
`death_mark_stats: DeathMarkStats`, at resources/memory/death_mark_stats.gd + .tres: merge_distance,
max_marks, radius, feather, strength per death, strength cap) mounts one CIRCLE `MemorySource` per cluster
under its own `DeathMarks` Node2D child. They are NOT in `_wells`, so `restore()` leaves them alone; a live
restoration erases them through `erase_marks()` instead (decision 1 below). The marks are mounted only at
`_ready`, which after a death is the reload, behind black.

### Life HUD
- `Health.reset()` emits `healed(max_hp - before, max_hp)` when it changes anything.
- `Player` relays `health_changed(current, max_hp)` from `damaged` and `healed`, and emits it once, deferred,
  from `_ready`. The HUD keeps listening to one node.
- `scenes/ui/life_hud/life_hud.tscn` (`LifeHud extends Control`, `PROCESS_MODE_ALWAYS`, mouse ignore,
  top-left at 8,8) is the LAST child of `CanvasLayer`, after `Fade`. It is drawn over the greyhush pass, the
  letterbox AND the fade, because the user said always visible. `show_health(current, max_hp)` builds `max_hp`
  `LifeNote`s, and note `i` is remembered iff `i < current` (the rightmost greys first). The first call is
  instant.
- `LifeNote` (`life_note.tscn`, a Control holding a Sprite2D strip, material `resource_local_to_scene`).
  `_memory` eases toward 0 or 1 over `fade_time`. Its own frame clock advances by `delta * _memory`, so at 0
  the note STOPS on its frame and resumes from it, as `MemoryClock` does, never resetting.
  `life_note.gdshader` includes `dither_common.gdshaderinc`. It greys by luma plus black lift and decides
  colour against grey per texel through `wd_quantise` in TEXEL space (`UV / TEXTURE_PIXEL_SIZE`, never
  `FRAGCOORD`), so a note forgets pixel by pixel on the greyhush's own Bayer cell. To keep one knob,
  `GreyhushRenderer` also pushes `greyhush_black_lift` and `greyhush_black_lift_color` as shader globals
  (declared in `project.godot`).

### Art contracts (tools/art/prompts/, placeholders via make_placeholders.gd)
- `bench.md`: one still. Its seat height is a contract number the sit clip must match.
- `life_note.md`: a strip of about 6 frames of a living sway, roughly 12x14.
- No `ivo_sit.md`: the sit clip is the pack's own Crouch-Idle at 2x (decision 2). It could never have been a
  PixelLab animation from Ivo's frames anyway, because the ZeggyGames licence forbids AI training (CREDITS.md).

### i18n
There are NO user-facing strings. The bench prompt is a `KeyGlyph`, and resting gives no "saved" text (show,
not tell). If a label is ever wanted, the key is `BENCH_REST`.

## Consequences

- `game.gd` takes on the death beat, rest and arrival beside the hazard beat (they share `Fade`, `_enter_room`
  and the camera). If it passes about 250 lines, extract the resident-room cache (`_enter_room`, `_room_at`,
  `_touch_resident`, `_wake_rooms`) into its own node first.
- Every future system that reads the save at `_ready` is rewind-correct for free. Every future piece of state
  that must OUTLIVE a death (as marks do) must be written into `committed` inside `SaveLedger.record_death`.
- A future pause menu opening during the death beat is refused by its own "already paused" guard only if the
  beat pauses, which it does not. That is acceptable: the fade owns the screen.
- Pause-mode map gains `LifeHud` (ALWAYS). Its clock still uses scaled `delta`, so it slows with a recall.
- Smoke list: add `bench.tscn` and `life_hud.tscn`. Playtest: `tools/playtest/scripts/bench_rest_and_death.json`
  (sit, be killed by the summer-trial brute, arrive seated with full notes and the brute back, mark visible) and
  `death_after_lesson.json` (F9 lesson, die, song gone).

### Tests
- `tests/globals/save_ledger_test.gd`
- `player_data_test.gd`: old save without the new fields.
- `tests/scenes/world/rooms/death_mark_clusters_test.gd`
- `scene_key_test.gd`
- `health_test.gd`: `reset` emits.
- `room_files_test`: required params and global uniqueness.
- A `LifeHud` scene test: `show_health(1, 3)` leaves two notes targeting 0.
- `RegionMemory` test: marks survive `restore(0)`.

### Build order (each step one commit, suite + smoke green)
1. `Health.reset` emits; `health_changed` relay; LifeHud/LifeNote/shader/globals; art contract and placeholder.
2. `SaveLedger`, `PlayerData` fields, `SaveSystem` delegation and boot policy, playtest runner, tests.
3. `WorldFreeze._ready` reset, `death_shown`, death beat, `_reload_world` (returns to the authored start).
4. `SceneKey`, `DeathMarkClusters`, `DeathMarkStats`, `RegionMemory.mark_deaths`, `Region` wiring.
5. Seat and Bench entity, layer 6, `DiscShelter.radius` export, legend `R` with `required_params`, brute
   `save_id` fix, uniqueness test, `FORMAT_VERSION` bump, guide regenerated, benches placed in maps.
6. Sitting (`look_down_pressed`, `SitComponent`, `MotionState.SIT`, `SIT` clip placeholder), rest flow,
   `Room.expire`.
7. Arrival at the saved bench.
8. CLAUDE.md (pause map, glossary: banco to `Bench`/`Seat`, marca de morte to `DeathMarkClusters`, known gaps)
   and playtests.

## Decisions taken (2026-10-01)

1. **Restoring a guardian ERASES its region's death marks** (the user's choice, overriding the plan's "no").
   This happens only on a LIVE restoration: `Region`, on `SaveSystem.guardian_restored`, calls
   `SaveSystem.clear_deaths(region_key)` (on LIVE data, so a death before the next bench rewinds the erasure along
   with the restoration) and `RegionMemory.erase_marks(lift_time)`, which fades the marks out with the lift. A
   region loaded already restored (`restore(0)`) mounts whatever deaths the save holds. Those happened AFTER its
   restoration, so they stay. `erase_marks` is therefore separate from `restore`, and the `RegionMemory` test
   becomes "marks survive `restore(0)` and fade under `erase_marks`".
2. **Sit art**: the user had the full ZeggyGames download checked (`D:\Free Assets\2D-Pixel-Art-Character-Template`).
   It has no sit strip. Its `Crouch-Idle/Player Crouch-Idle 48x48.png` (10 frames) is the same colour-coded
   template figure as every clip Ivo has today, so it is imported at 2x as `player_sit_96x96.png` and used as the
   `SIT` loop. No art contract for `ivo_sit` until Ivo's real art exists; the bench's seat height is matched to
   the crouch.
3. Respawn SEATED on the bench, on death and on load: **yes** (default taken).
4. Debug builds keep a separate `save_debug.tres`. The default taken here (start fresh unless `--continue`) was REVERSED by the user the same day after testing: a closed game lost its bench. Debug builds now continue their save; `-- --new-game` starts fresh.
5. **Death marks merge** within about 48 px into one deepening mark, at most 6 per region (the user's choice).
6. **First benches** (the user's choice): Downtown, the Frost Edge approach before the lighthouse, and the summer
   trial.
7. Sitting is on the down PRESS, so standing at a bench can no longer peek down: **accepted** (default taken).
