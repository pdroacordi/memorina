---
id: architecture/sound-effects-system
type: architecture
title: Sound effects - cues as data, emitters owned by the scene that sounds, menu sounds under the hold
status: active
tags: [audio, sfx, sound, footsteps, menu, pause, greyhush, buses, plan]
related: [architecture/music-system, systems/music, systems/screens, systems/songs-and-the-memorina, systems/settings, systems/rooms, systems/greyhush, systems/creatures, systems/guardians, architecture/pause-menu-worldfreeze-reuse, gotchas/time-scale-zero-stops-delta-particles-and-time, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, gotchas/a-node-idled-or-swapped-out-keeps-what-it-opened-in-an-autoload, gotchas/an-area2d-emits-body-exited-when-disabled-or-removed, gotchas/a-freeze-stops-the-resolver-but-not-ivos-always-animation-tree]
created: 2026-11-16
updated: 2026-11-16
source_files:
  - globals/audio_buses.gd
  - default_bus_layout.tres
  - scenes/characters/ivo/player.gd
  - scenes/characters/components/landing_component.gd
  - scenes/characters/components/animation_driver.gd
  - scenes/characters/enemies/enemy.gd
  - scenes/characters/guardians/guardian.gd
  - scenes/world/environment/water/water_body.gd
  - scenes/world/rooms/maps/room_map_node.gd
  - resources/world/tiles/biome_tileset.gd
  - scenes/ui/screens/screens.gd
  - scenes/ui/menu/menu_input.gd
  - scenes/ui/notebook/notebook.gd
  - scenes/ui/notice/notice_toast.gd
---

# Sound effects (SND-01)

BUILT (2026-11-16; SND-01; planned as below except the credits-roll role, dropped because every source is CC0; user: "Precisamos de sound effects para o jogo. Combate, pisadas, menu, etc."; licences "CC0 e CC-BY"). Nothing is downloaded before the user approves the candidate list (roadmap SND-01).

## Context

The game has an `Sfx` bus and story stand-ins, but no gameplay or menu sounds and nothing to play them. The constraints:
- Every `AudioStreamPlayer` names a bus from `AudioBuses`; `Settings` is the only writer of bus volume; only `Music` plays background music (`systems/music`).
- A freeze (performance, scale 1) and a hold (menu, scale 0) both pause the tree; world time is what stops (`systems/songs-and-the-memorina`). A menu runs on real time under the hold; never a whole `CanvasLayer` to ALWAYS (`systems/screens`).
- `Game` sets Ivo `PROCESS_MODE_DISABLED` for every door, arrival and hazard fade (`game.gd:128`, `:275`, `:314`, `:333`); an idled room's contents are DISABLED; a death swaps `game.tscn`.
- `Enums.Ground` has no snow: snow is how a biome draws EARTH (frozen_lake), so a footstep surface is biome data, not ground.

## Options considered

**Data shape.**
1. A bare `AudioStreamRandomizer` `.tres` per sound. It covers variants (`PLAYBACK_RANDOM_NO_REPEATS`), pitch (`random_pitch`, a factor: pitch in 1/f..f) and volume jitter (`random_volume_offset_db`), but has no cooldown, voice cap or bus.
2. A `SoundCue` with its own variant picker and jitter in GDScript. Rejected: it re-implements tested engine code.
3. **Chosen:** a thin `SoundCue` Resource that holds the engine randomizer as its `stream` and adds only what the engine lacks.

**Who plays.**
1. A thin `Sfx` autoload with a pool. Rejected: it would need one pool that pauses with the tree and one that does not, it outlives the `game.tscn` swap, and an owner freed mid-sound leaves it playing (`gotchas/a-node-idled-or-swapped-out-keeps-what-it-opened-in-an-autoload`). `Music` is an autoload because music crosses scene swaps; a sound does not.
2. A bare `AudioStreamPlayer` per sound in each scene. Rejected: 40+ hand-made players, a bus to set on each, and no shared cooldown.
3. **Chosen:** one generic `SfxEmitter` component per sounding owner. It makes one player per cue lazily, in code, with the bus from the cue. It inherits its owner's pause, so an idled room or a frozen world silences it, and it dies with its owner.

**Positional or not.**
1. Everything non-positional. This is simple, but a creature in a running neighbour room off screen would be heard at full level.
2. **Chosen:** Ivo and the UI are non-positional (`AudioStreamPlayer`). World sources (creatures, guardians, water) use `AudioStreamPlayer2D`: `max_distance` 800 px (the 640x384 frame's diagonal is about 746), attenuation 1, `panning_strength` 0.6. The distance cap is the off-screen gate, and needs no code.

**Footstep cadence.**
1. Distance walked: a step every N px on the floor. Rejected: the run clip plays at a fixed fps while speed varies (brace, wind, ice, a walk-in by a `ScriptedController`), so the steps drift off the drawn foot contacts. A wind carry or an ice slide would also count as walking.
2. **Chosen:** animation contacts. Each step clip gets contact times in seconds (data). A pure `StepClock` reports the contacts the play position crossed since the last physics frame, loop wrap included. It works like `CueTracker` does for songs.

**Surface.**
1. Read the cell under the feet from the current room through `Game`. Rejected: it couples Ivo to the room list, and it is wrong on a body that is not the map (a lift, ice, a root bridge, a roof).
2. **Chosen:** read the floor collision. After `move_and_slide`, the floor collider is either the room's `Solid` `TileMapLayer` or another body.
   - On the `Solid` layer, the cell is `get_coords_for_body_rid(collider_rid)`, and its parent `RoomMapNode.surface_at(cell)` gives the surface. A cell with a look reads `BiomeTileset.step_surfaces[look]`; a look-less cell (a roof `^`) falls back by its `Enums.Ground`.
   - Any other body answers its own `step_surface` export, or `STONE` when it has none.
   - Shallow water wins over the floor: its `WaterVolume` tells the body it holds, the way `SoftLanding` does.

**Menu sounds under the hold.**
1. Make the `ScreenLayer` ALWAYS. This is forbidden (`systems/screens`).
2. Have `MenuSounds` pull `WorldFreeze.is_held()` like `MemorinaVoice` does. Rejected: that is backwards here, since a menu must sound while held.
3. **Chosen:** a `MenuSounds` node under the ALWAYS `Screens` root Control. It inherits ALWAYS, and an audio stream is unaffected by `Engine.time_scale` 0 (`gotchas/time-scale-zero-stops-delta-particles-and-time`). It plays menu cues only, never a world cue. Cooldowns use real ticks, because delta is 0 under the hold.

**The greyhush (user decision, below).**
- (a) No muffle.
- (b) Per-source: at play time the emitter samples `MemoryField.sample(point)` and lowers the volume. Godot has no per-player filter, so this changes level only, never timbre.
- (c) A bus effect. A new bus `SfxWorld` (sending to `Sfx`, volume fixed at 0 dB) carries one `AudioEffectLowPassFilter`, off at rest. One writer, `SfxMuffle` in `game.tscn`, sets its cutoff from the memory at Ivo. Only world-object cues (`SoundCue.world`) route to `SfxWorld`: doors, pickups, found pieces, seeds, splashes, the bench. Ivo's body and the creatures stay clear, as his `GreyhushShield` keeps him coloured ("Characters never freeze", `systems/greyhush`). The `Music` bus's "Muffle" precedent is 20 kHz to 400 Hz; the starting map here is 20 kHz at memory 1 to 1.2 kHz at 0, tuned by ear.

## Decision

**Data** (`resources/audio/`, `.tres` under `resources/audio/sfx/<ivo|combat|world|menu>/`; files under `assets/audios/sfx/<same>/`, mono WAV, peak -3 dBFS, lead silence under 5 ms):
- `SoundCue`: `stream: AudioStream` (an `AudioStreamRandomizer`, no-repeat mode, for variants), `volume_db`, `max_voices` 1..4 (becomes the player's `max_polyphony`; the engine steals the oldest voice), `cooldown` (real s between two starts of this cue, across emitters), `world: bool` (bus `SfxWorld` if true, else `Sfx`).
- `IvoSoundSet` (`ivo_sounds.tres`):
  - `surfaces: Dictionary[int, SurfaceSounds]` (step, land), by `Enums.Surface`;
  - `land_hard`, `jump`, `double_jump`, `climb_grab`, `climb_step`, `swing`, `hurt`, `death`, `rest`;
  - `door_open: Dictionary[StringName, SoundCue]` by `Door` look (an empty entry is silent: `passage`, `stairwell`), and `door_knock`;
  - `taken: Dictionary[int, SoundCue]` by `Player.Taken`;
  - `soft_land_min_speed` (px/s, 200: a step-down is silent).
- `StepContacts` (`ivo_footfalls.tres`): per clip, the contact seconds. The clips are run, walk, brace, climb and climb_back. A clip name must be one of the `PlayerAnimationResolver` consts (test).
- `BodySoundSet` (`struck`, `blocked`, `death`) on `EnemyStats.sounds` and `GuardianStats.sounds`. A species stays a scene plus stats, so a new species is a new `.tres`.
- `MenuSoundSet`: `move`, `confirm`, `back`, `open`, `close`, `page`.
- `Enums.Surface { NONE, EARTH, STONE, SNOW, WOOD, SHALLOW_WATER }`, append only, because biome `.tres` files store it by index. `BiomeTileset.step_surfaces: PackedByteArray` is indexed by `Look`. frozen_lake's earth is SNOW.
- No `NoticeSoundSet`: the toast exports one `slide_sound`.

**Pure logic** (`RefCounted`, each with a suite mirroring its path):
- `CueGate`: per-cue cooldown on an injected clock. `SfxEmitter` keeps one static instance, so 3 creatures struck in one frame sound once.
- `StepClock`: contacts crossed between two positions of a looping clip. A clip change restarts it at its first contact; a backward position reports nothing.
- `StepSurfaces.of(look, ground, biome)`.
- `ImpactLevel.db(speed, min, max)`: landing and splash level, -12..0 dB.
- `MenuCueGate`: at most one menu cue per process frame, by priority OPEN = CLOSE > PAGE > BACK > CONFIRM > MOVE. A focus change counts as MOVE only in a frame that had a navigation press, so the focus grab when a screen opens and a press at the end of a list are silent.
- `SfxMuffleMath.cutoff(memory)`, if (c) is chosen.

**Nodes:**
- `SfxEmitter` (`scenes/audio/sfx_emitter.gd`, Node2D, group `sfx_emitters`):
  - API: `play(cue, db_offset := 0.0)`, `play_at(cue, point, db_offset := 0.0)`, `stop_all()`, and a signal `cue_played(cue)` for tests and the playtest log.
  - It stops every voice on `NOTIFICATION_DISABLED` (an idled room) and keeps a paused voice under a freeze or hold, which resumes with the world.
- `IvoSounds` (`scenes/characters/ivo/ivo_sounds.gd`, a child of Ivo with an `SfxEmitter` child), **explicit PAUSABLE**.
  - An explicit mode escapes Ivo's DISABLED fades (`gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor`), so a door creak plays through the fade, while a freeze or a hold still pauses it.
  - Its `_physics_process` runs after Ivo's (a child) and polls `Player.animation_state()`, `animation_position()`, `is_on_floor()`, `floor_surface()` and `is_climbing()` for footsteps, climb steps and the grab edge.
  - Its one-shots are wired in `ivo.tscn` with `from="."`, as `DustEmitter` is.
- `StepSurfaceProbe` (`scenes/characters/components/`): the floor-collision read and the wading count (`enter_wading` / `exit_wading`, balanced by `gotchas/an-area2d-emits-body-exited-when-disabled-or-removed`). `Player.floor_surface()` delegates to it.
- `BodySounds` (`scenes/characters/components/`, with a positional `SfxEmitter`): `on_struck` (silent once dead, because `died` fires first), `on_blocked`, `on_died`. `Enemy._apply_stats` pushes `stats.sounds` into it and connects the signals; `Guardian` does the same.
- `MenuSounds` (`scenes/ui/menu/menu_sounds.gd`, a child of `Screens` and of `Title`'s root): exports `sounds`, `menu_input` and `scope`.
  - It hears `Viewport.gui_focus_changed` and plays MOVE only for a control inside `scope`, so the dialogue box's Buttons never click. On first focus of each `BaseButton` in scope it connects `pressed` (CONFIRM).
  - Screens, Title and the notebook drive it through its methods, wired in their scenes. It flushes the `MenuCueGate` in `_process`.
- `SfxMuffle` (only if (c)): in `World`, PAUSABLE. It is the only writer of the `SfxWorld` low-pass, and it resets it on `_exit_tree`, because a bus outlives the `game.tscn` swap.

## Hooks (the line where each event happens today)

| Event | Hook | New |
|---|---|---|
| Jump | `Player.jumped`, re-emitted at `player.gd:278` | |
| Double jump | `Player.double_jumped`, `player.gd:1369` | |
| Hard landing | `LandingComponent.hard_landed`, `landing_component.gd:31`; `player.gd:279` | |
| Soft landing | `landing_component.gd:28-31` (`check_landing`) | `LandingComponent.landed(position, impact_speed)`, emitted for non-hard landings; `Player.landed` re-emits it beside `player.gd:279` |
| Footsteps | polled: `AnimationDriver` (`animation_driver.gd:15`) | `AnimationDriver.position()`; `Player.animation_state()` / `animation_position()`; `Player.floor_surface()` |
| Climb | grab at `player.gd:627`; `is_climbing()` `player.gd:466`; clips `CLIMB`, `CLIMB_BACK` | none (an edge plus contacts) |
| Sword swing | `_attack.phase_started`, `player.gd:314`, handler `:1653` | `Player.swung(phase_index)`, re-emitted |
| Ivo hurt | `hurt.emit()`, `player.gd:1646` (hits and hazards, `:1611`) | none; silent when `is_dead()` |
| Ivo death | `Character.died`, `character.gd:173-174` | |
| Bench rest | `sat_down.emit(seat)`, `player.gd:680` (an arrival's `sit()` at `:1589` stays silent) | |
| Door | `door_entered.emit(door)`, `player.gd:699`; knock `door.knock()`, `:701` | `Player.door_knocked(door)` |
| Item / letter / songbook / seed | `pickup.take()` `player.gd:747`, `found.take()` `:774`, `cache.take()` `:789` | `Player.took(what: Taken)` (`ITEM`, `LETTER`, `SONGBOOK`, `SEED`) |
| Splash | `WaterBody.splash`, `water_body.gd:278`, after the ice and dry return at `:282-283`; wired `water_pool.tscn:54`, `water_shallow.tscn:45` | `WaterBody.surface_splashed(point, speed)` → a positional `SfxEmitter` |
| Wading | `WaterVolume` `body_entered` / `body_exited`, `water_volume.gd:26` | `WaterVolume.wade` (true in `water_shallow.tscn`) → `Player.enter_wading` / `exit_wading` |
| Creature hit | `Enemy._on_hit_received`, `enemy.gd:129`, after `_wound` at `:139` | `Enemy.struck` |
| Creature block | `blocked.emit()`, `enemy.gd:134` | |
| Creature death | `died`, `enemy.gd:45`; it is freed at `:122` once `CorruptionEdge.is_gone()` (`vanish_time` 0.6 s) | |
| Guardian hurt | `Guardian._on_hit_received`, `guardian.gd:334-337` (PRESSURE only) | `Guardian.struck` |
| Pause / notebook open, close | `Screens._apply`, `screens.gd:152-170` | `Screens.screen_changed(from, to)`; the map is silent |
| Back (inner panel) | `screens.gd:107` (`step_back()` true); `PauseMenu.step_back`, `pause_menu.gd:77`; `Title._step_back`, `title.gd:134` | `Screens.stepped_back(kind)` (ignored for NOTEBOOK: its shut is the close); `Title.stepped_back` |
| Move focus | `Viewport.gui_focus_changed` (engine) | `MenuInput.focus_stepped` (the `ui_up` / `ui_down` press edge, as `_page_edge` does it, `menu_input.gd:58`); `page_pressed` also counts |
| Confirm | `BaseButton.pressed` (engine) | |
| Page turn | `Notebook.turn_to`, `notebook.gd:153-163` | `Notebook.page_turned(direction)` |
| Notice slide-in | `NoticeToast.show_notice`, `notice_toast.gd:38` | `NoticeToast.slide_sound` played there (pausable HUD: held with the world) |

## Consequences

- **Pause-mode map** (`systems/songs-and-the-memorina`) gains entries:
  - `MenuSounds` is ALWAYS by inheritance from `Screens`, the one audio that plays under a hold;
  - `IvoSounds` is explicit PAUSABLE;
  - every other `SfxEmitter` inherits.
- **Cue lengths are rules** (`sound_cue_test`):
  - a world one-shot is at most 1.0 s;
  - a songbook's cue is at most `Player.lesson_lead_in` (0.5 s), because the lesson's freeze pauses Ivo's emitter;
  - a creature's `death` is at most `CorruptionEdge.vanish_time` (0.6 s), because the emitter dies with the body.
- **Lakes have no `Volume`**: Ivo sinking in a lake plays only `hurt`. A lake splash waits for a lake that can be entered.
- **Surface coverage**: ice and root bodies need a `step_surface` export, or they default to STONE. A season-dependent surface (snow in a winter band, `RegionYear`) is not modelled: the biome decides.
- **Settings** is unchanged: `SfxWorld` sends to `Sfx`, so the Effects slider governs it, and its own volume is never written.
- **CC-BY attribution**: `CREDITS.md` gets every file, and the credits roll gets a `CREDITS_SOUND_EFFECTS` role (`resources/story/credits/credits.tres`, a new key in every language). No other user-facing text is added.
- **To measure in step 1** (a gotcha each if they surprise):
  - that a CanvasPass `SubViewport` is no 2D audio listener, so a 2D voice is not heard twice;
  - that an explicit-PAUSABLE player under DISABLED Ivo plays, and pauses under a tree pause;
  - that an ALWAYS player plays at `time_scale` 0.

## Build order

Each step is one commit and passes `verify-gates`.

1. **Buses and measurements.**
   - Add `SfxWorld` (sending to `Sfx`, a "Muffle" low-pass, off) and `AudioBuses.SFX_WORLD`.
   - `audio_buses_test` checks the routing, also checks `AudioStreamPlayer2D`, and allows `SFX_WORLD`.
   - Run the three measurements.
   - Create `systems/sound-effects` and its `CLAUDE.md` row.
2. **The core.** `SoundCue`, `CueGate`, `SfxEmitter`, and their suites, using tones built in code as `AudioStreamWAV`.
3. **The candidate list** for the user: source, licence, URL, use. This is a gate with no download before approval, and it can run beside step 2. After approval, download, trim and normalise, and add `CREDITS.md` lines.
4. **Ivo's one-shots.**
   - `IvoSoundSet`, `IvoSounds`;
   - `Player.landed` and `swung`, `LandingComponent.landed`;
   - jump, double jump, landings, swing, hurt, death, rest;
   - `ivo_sounds_test` (a killing hit plays death, not hurt; a door fade keeps the voice; a hold pauses it).
5. **Footsteps and climbing.**
   - `StepClock`, `StepContacts` and `ivo_footfalls.tres`;
   - `AnimationDriver.position()`;
   - `Enums.Surface`, `BiomeTileset.step_surfaces` on every biome, `StepSurfaces`, `RoomMapNode.surface_at`, `StepSurfaceProbe`;
   - `WaterVolume.wade`;
   - the climb grab and steps.
6. **World.**
   - `Player.door_knocked` and `took`, and the door table (a test covers every `Door.LOOKS` key);
   - `WaterBody.surface_splashed` and the water emitters.
7. **Combat.**
   - `BodySoundSet`, `BodySounds`, `Enemy.struck`, `Guardian.struck`;
   - `sounds` on every `EnemyStats` and `GuardianStats` (a test checks they are present and the death length).
8. **Menus.**
   - `MenuInput.focus_stepped`, `MenuCueGate`, `MenuSounds`;
   - `Screens.screen_changed` and `stepped_back`, `Notebook.page_turned`, `Title.stepped_back`;
   - the notice slide;
   - `menu_sounds_test` under a hold.
9. **The greyhush** (option (c) only): `SfxMuffleMath` and `SfxMuffle`.
10. **Credits roll**: the `CREDITS_SOUND_EFFECTS` role and its keys.
11. **Close.** The systems entry, the pause-mode map, the roadmap, and a playtest with the `cue_played` log (a screenshot cannot show latency or mix).

## Open user decisions

1. The greyhush: (a) none, (b) per-source volume, or (c) the `SfxWorld` low-pass by memory at Ivo, with Ivo's body and the creatures clear (Recommended).
2. Positional world sources (creatures, guardians, water), panned gently and inaudible past 800 px (Recommended), or everything centred.
3. A "Sound effects" role in the in-game credits for CC-BY authors (Recommended), or `CREDITS.md` only.
4. The notebook opening and shutting with the pause's open and close cues, and the map silent (Recommended), or cues of their own.
