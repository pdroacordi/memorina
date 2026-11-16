# Sound effects

Updated 2026-11-16. How gameplay, world and menu sounds are described and played. SND-01 is in progress: steps 1 (buses, measurements) and 2 (the core) are built; Ivo, footsteps, world, combat, menus, the muffle and the credits role follow the build order in `architecture/sound-effects-system`.

**Never break:** A sound is a `SoundCue`; only `SfxEmitter` makes SFX players, with the bus from the cue. World emitters inherit their owner's pause; `IvoSounds` is explicit PAUSABLE; only `MenuSounds` plays under a hold. `Settings` stays the only writer of bus volume; `SfxMuffle` is the only writer of the `SfxWorld` effect.

## Contract

- **Buses** (`default_bus_layout.tres`, names in `AudioBuses`): `Sfx` sends to `Master`; `SfxWorld` sends to `Sfx`, volume 0 dB, one `AudioEffectLowPassFilter` named "Muffle" (cutoff 20 kHz, off). The Effects slider sets `Sfx`, so it governs `SfxWorld` too; `SfxWorld`'s volume is never written (`audio_buses_test`). `audio_buses_test` checks every scene `AudioStreamPlayer` and `AudioStreamPlayer2D`.
- **`SoundCue`** (`resources/audio/sound_cue.gd`): `stream` (normally an `AudioStreamRandomizer` in no-repeat mode: variants, pitch and volume jitter come from the engine), `volume_db`, `max_voices` 1..4 (the player's `max_polyphony`; a new voice steals the oldest), `cooldown` (real seconds between two starts of the cue, across every emitter; 0 never gates), `world` (`bus()` is `SfxWorld` if true, else `Sfx`). Only world-object cues set `world`: doors, pickups, found pieces, seeds, splashes, the bench. Ivo's body, creatures and menus stay on `Sfx`, unmuffled ("Characters never freeze", `systems/greyhush`).
- **`CueGate`** (`resources/audio/cue_gate.gd`, pure): per-cue cooldown keyed by the cue's instance id, on an injected clock (default `CueGate.real_seconds`, wall time, so it runs under a hold). A refused start does not extend the cooldown.
- **`SfxEmitter`** (`scenes/audio/sfx_emitter.gd`, Node2D, group `sfx_emitters`):
  - `play(cue, db_offset)`, `play_at(cue, point, db_offset)`, `stop_all()`, `player_of(cue)`, signal `cue_played(cue)` per started voice.
  - One player per cue, made on its first voice, as its child: `AudioStreamPlayer`, or `AudioStreamPlayer2D` when `positional` (`max_distance` 800 px, `attenuation` 1, `panning_strength` 0.6). `bus` comes from `cue.bus()`, `max_polyphony` from `max_voices`. `play` on a positional emitter sounds at the emitter; `play_at` moves the cue's player to the point.
  - One static `CueGate` for every emitter, so a cue struck by three creatures in one frame sounds once.
  - It starts nothing while `can_process()` is false (paused tree or DISABLED owner): a non-positional player would sound through the pause, and a positional one would start late (`gotchas/an-audio-player-that-cannot-process-still-starts-a-voice`).
  - On `NOTIFICATION_DISABLED` (an idled room) it stops every voice, so nothing comes back with the room. Under a freeze or a hold its voices pause where they are and resume with the world.
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
- Tests: `tests/globals/audio_buses_test.gd`, `tests/resources/audio/sound_cue_test.gd`, `tests/resources/audio/cue_gate_test.gd`, `tests/scenes/audio/sfx_emitter_test.gd` (tones built in code as `AudioStreamWAV`).
- Plan and build order: `architecture/sound-effects-system`.

## Decisions

- "Precisamos de sound effects para o jogo. Combate, pisadas, menu, etc." (user, 2026-11-16; SND-01). Every source is CC0.
- The greyhush: option (c), a `SfxWorld` bus with a low-pass set by the memory at Ivo, world-object cues only (user, 2026-11-16).
- World sources positional: `AudioStreamPlayer2D`, `max_distance` 800, attenuation 1, `panning_strength` 0.6 (user, 2026-11-16).
- The notebook reuses the pause's open and close cues; the map is silent (user, 2026-11-16).
