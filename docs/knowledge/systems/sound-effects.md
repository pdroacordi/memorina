# Sound effects

Updated 2026-11-16. How gameplay, world and menu sounds are described and played. SND-01 is in progress: steps 1 (buses, measurements), 2 (the core), 4 (Ivo's one-shots) and 5 (footsteps and climbing) are built; world, combat, menus, the muffle and the credits role follow the build order in `architecture/sound-effects-system`.

**Never break:** A sound is a `SoundCue`; only `SfxEmitter` makes SFX players, with the bus from the cue. World emitters inherit their owner's pause; `IvoSounds` is explicit PAUSABLE; only `MenuSounds` plays under a hold. `Settings` stays the only writer of bus volume; `SfxMuffle` is the only writer of the `SfxWorld` effect.

## Contract

- **Buses** (`default_bus_layout.tres`, names in `AudioBuses`): `Sfx` sends to `Master`; `SfxWorld` sends to `Sfx`, volume 0 dB, one `AudioEffectLowPassFilter` named "Muffle" (cutoff 20 kHz, off). The Effects slider sets `Sfx`, so it governs `SfxWorld` too; `SfxWorld`'s volume is never written (`audio_buses_test`). `audio_buses_test` checks every scene `AudioStreamPlayer` and `AudioStreamPlayer2D`.
- **`SoundCue`** (`resources/audio/sound_cue.gd`): `stream` (normally an `AudioStreamRandomizer` in no-repeat mode: variants, pitch and volume jitter come from the engine), `volume_db`, `pitch_scale` (the player's base pitch, set when the emitter makes it; the randomizer jitters around it), `max_voices` 1..4 (the player's `max_polyphony`; a new voice steals the oldest), `cooldown` (real seconds between two starts of the cue, across every emitter; 0 never gates), `world` (`bus()` is `SfxWorld` if true, else `Sfx`). Only world-object cues set `world`: doors, pickups, found pieces, seeds, splashes, the bench. Ivo's body, creatures and menus stay on `Sfx`, unmuffled ("Characters never freeze", `systems/greyhush`).
- **`CueGate`** (`resources/audio/cue_gate.gd`, pure): per-cue cooldown keyed by the cue's instance id, on an injected clock (default `CueGate.real_seconds`, wall time, so it runs under a hold). A refused start does not extend the cooldown.
- **`SfxEmitter`** (`scenes/audio/sfx_emitter.gd`, Node2D, group `sfx_emitters`):
  - `play(cue, db_offset)`, `play_at(cue, point, db_offset)`, `stop_all()`, `player_of(cue)`, signal `cue_played(cue)` per started voice.
  - One player per cue, made on its first voice, as its child: `AudioStreamPlayer`, or `AudioStreamPlayer2D` when `positional` (`max_distance` 800 px, `attenuation` 1, `panning_strength` 0.6). `bus` comes from `cue.bus()`, `max_polyphony` from `max_voices`. `play` on a positional emitter sounds at the emitter; `play_at` moves the cue's player to the point.
  - One static `CueGate` for every emitter, so a cue struck by three creatures in one frame sounds once.
  - It starts nothing while `can_process()` is false (paused tree or DISABLED owner): a non-positional player would sound through the pause, and a positional one would start late (`gotchas/an-audio-player-that-cannot-process-still-starts-a-voice`).
  - On `NOTIFICATION_DISABLED` (an idled room) it stops every voice, so nothing comes back with the room. Under a freeze or a hold its voices pause where they are and resume with the world.
- **Ivo** (`scenes/characters/ivo/ivo_sounds.gd`, `IvoSounds`, the last child of Ivo in `ivo.tscn`, explicit PAUSABLE, with a non-positional `SfxEmitter` child):
  - Data: `IvoSoundSet` (`resources/audio/sfx/ivo/ivo_sounds.tres`): `surfaces` (`Dictionary[int, SurfaceSounds]` by `Enums.Surface`, each a `step` and a soft `land` cue), `land_hard`, `jump`, `double_jump`, `climb_grab`, `climb_step`, `swing`, `hurt`, `death`, `rest`, `soft_land_min_speed` (200 px/s), `soft_land_full_speed` (800 px/s, Ivo's `hard_land_speed`). One `SoundCue` `.tres` per sound beside it; variant sets are `AudioStreamRandomizer`s in no-repeat mode with `random_pitch` 1.05 and `random_volume_offset_db` 1.
  - One-shots, wired from Ivo's own signals with `from="."`: `jumped`, `double_jumped` (the jump file at `pitch_scale` 1.25), `landed` (new: `LandingComponent.landed(position, impact_speed)` for every landing that is not hard, re-emitted by `Player`; silent under `soft_land_min_speed`, levelled by `ImpactLevel.db`, the floor's `land` cue), `hard_landed` (`land_hard`), `swung(phase_index)` (new, emitted per attack phase start), `hurt` (silent once dead: a killing hit emits `died` first), `died`, `sat_down` (`rest`, a world cue; an arrival's `sit()` emits nothing). A corpse's landing is silent.
  - Steps: its `_physics_process` runs after Ivo's and after his `AnimationTree` (a child before it, physics callback). It feeds `Player.animation_state()`, `animation_position()` and `animation_length()` (`AnimationDriver.position()` / `length()`, 0 until the tree has started the driver's clip) to a `StepClock` with `StepContacts.contacts_of(clip)` (`ivo_footfalls.tres`). Each contact crossed plays `climb_step` while `is_climbing()`, else the step cue of `Player.floor_surface()`; NONE is silent. `is_climbing()` turning true plays `climb_grab`.
- **`StepClock`** (`resources/audio/step_clock.gd`, pure): contacts crossed in `(last, now]` of a looping clip. A new clip starts before its first contact (a contact at 0 sounds as the clip starts); a jump back over half the clip is the loop wrap (contacts on both sides counted); a smaller jump back reports nothing. Both bounds carry a 0.00001 s epsilon (`gotchas/a-float32-time-lies-past-the-same-float64-time`).
- **`StepContacts`** (`resources/audio/step_contacts.gd`): `contacts: Dictionary[StringName, PackedFloat32Array]`, clip -> contact seconds. Every key is a `PlayerAnimationResolver` const naming a looping state, every contact inside its clip (`step_contacts_test`).
- **Surfaces.** `Enums.Surface { NONE, EARTH, STONE, SNOW, WOOD, SHALLOW_WATER }`, append only. `BiomeTileset.step_surfaces: PackedByteArray` by `Look`, checked by `problems()`; NONE falls back to the cell's `Enums.Ground`. `StepSurfaces.of(look, ground, biome)` (pure), `RoomMap.look_at(cell)`, `RoomMapNode.surface_at(cell)`.
  - `StepSurfaceProbe` (`scenes/characters/components/`, child of Ivo): `Player._after_move` calls `update()` before the landing check. It reads the first floor collision of the last `move_and_slide()`: a room's `Solid` `TileMapLayer` answers `surface_at(get_coords_for_body_rid(rid))`; any other body its `step_surface` property, else STONE. A frame with no floor contact keeps the last surface.
  - Shallow water wins: `WaterVolume.wade` (true in `water_shallow.tscn`) calls `enter_wading` / `exit_wading` on the body; `Player` delegates to the probe's count, never below 0 (an Area2D reports a disabled or removed body as exited).
- **Process modes.** An emitter inherits its owner's mode, so it dies with the owner and pauses with it. `IvoSounds` (step 4) is explicit PAUSABLE: a DISABLED Ivo (door, arrival and hazard fades) still sounds, and a freeze or a hold pauses it (`gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor`). `MenuSounds` (step 8) is ALWAYS by inheritance from the `Screens` root, the only SFX that plays under a hold; audio ignores `Engine.time_scale`.

## Measured (4.7.2, headless, 2026-11-16)

- A CanvasPass `SubViewport` shares the root's `world_2d` but is no 2D listener (`audio_listener_enable_2d` false); the root is. Read from the flags, not heard.
- An explicit-PAUSABLE player under a DISABLED parent plays (0.47 s in 0.5 s) and pauses under a tree pause (`stream_paused` true, position held), then resumes.
- An ALWAYS player plays with the tree paused at `Engine.time_scale` 0 (0.66 s in 0.6 s).
- Details and the surprises: `gotchas/an-audio-player-that-cannot-process-still-starts-a-voice`.

## Files

- `globals/audio_buses.gd`, `default_bus_layout.tres`
- `resources/audio/sound_cue.gd`, `resources/audio/cue_gate.gd`
- `scenes/audio/sfx_emitter.gd`
- Ivo: `scenes/characters/ivo/ivo_sounds.gd`, `resources/audio/ivo_sound_set.gd`, `resources/audio/surface_sounds.gd`, `resources/audio/impact_level.gd`, `resources/audio/sfx/ivo/*.tres`; signals in `scenes/characters/ivo/player.gd` and `scenes/characters/components/landing_component.gd`.
- Steps: `resources/audio/step_clock.gd`, `resources/audio/step_contacts.gd`, `resources/audio/step_surfaces.gd`, `scenes/characters/components/step_surface_probe.gd`, `scenes/characters/components/animation_driver.gd` (`position`, `length`), `resources/world/tiles/biome_tileset.gd` and `biomes/*.tres` (`step_surfaces`), `resources/world/maps/room_map.gd` (`look_at`), `scenes/world/rooms/maps/room_map_node.gd` (`surface_at`), `scenes/world/environment/water/water_volume.gd` (`wade`).
- Tests: `tests/scenes/characters/ivo/ivo_sounds_test.gd` (death not hurt, a voice through Ivo DISABLED, a tree pause starts none, landings, wading, a run's steps through the real AnimationTree), `tests/resources/audio/{impact_level,step_clock,step_surfaces,step_contacts}_test.gd`, `tests/scenes/characters/components/step_surface_probe_test.gd`, `tests/scenes/world/environment/water/water_volume_test.gd`.
- Tests: `tests/globals/audio_buses_test.gd`, `tests/resources/audio/sound_cue_test.gd`, `tests/resources/audio/cue_gate_test.gd`, `tests/scenes/audio/sfx_emitter_test.gd` (tones built in code as `AudioStreamWAV`).
- Plan and build order: `architecture/sound-effects-system`.

## Decisions

- **Contacts** (`ivo_footfalls.tres`), from the drawn feet, measured as the lowest opaque rows of each 128 px frame (ground row 95): `run` (8 frames, 0.667 s) frames 0 and 5, where a foot comes down on the ground row after the airborne frames 7 and 4 (0, 0.417 s); `walk` (8, 0.8 s) frames 0 and 4, the wide double supports (0, 0.4 s); `brace` (10, 1.0 s) frames 0, 5, 7 and 9, where a foot is planted after a lifted frame (0, 0.5, 0.7, 0.9 s); `climb` and `climb_back` (4, 0.6 s) frames 1 and 3, the hand at its highest reach (0.15, 0.45 s).
- **Biome surfaces** (Look EARTH, STONE, WOOD, WALL): every biome EARTH, STONE, WOOD, NONE, except `frozen_lake` (earth is SNOW) and `summer_caldera_ash` (its STONE look is loose ash scree, so EARTH: a soft crunch, not a hard click). WALL is a back wall and never collides, so NONE.
- **Landings**: no landing files exist for stone, snow or wood, so their soft landing is the surface's own step set 4 dB over the step (-4 dB against -8); earth uses `land_earth`; shallow water uses `land_mud`. `step_mud` is unused until a surface needs it. Ivo's hurt is `hurt_low` (an old man's voice). The double jump reuses `jump` at `pitch_scale` 1.25.
- Levels are a first pass, to be set by ear in the playtest (step 11): steps -8 dB, soft landings -2 dB (earth, water) or -4 dB plus `ImpactLevel` (-12..0), `land_hard` -2, jump -6, climb grab -6, climb step -8, swing -4, hurt -3, death 0, rest -3.

- "Precisamos de sound effects para o jogo. Combate, pisadas, menu, etc." (user, 2026-11-16; SND-01). Every source is CC0.
- The greyhush: option (c), a `SfxWorld` bus with a low-pass set by the memory at Ivo, world-object cues only (user, 2026-11-16).
- World sources positional: `AudioStreamPlayer2D`, `max_distance` 800, attenuation 1, `panning_strength` 0.6 (user, 2026-11-16).
- The notebook reuses the pause's open and close cues; the map is silent (user, 2026-11-16).
