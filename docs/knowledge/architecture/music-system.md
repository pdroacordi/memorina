---
id: architecture/music-system
type: architecture
title: Background music plan - a thin Music autoload that plays the top owned request; MusicCue Resources of synchronized stems; pure MusicRequests, MusicMix and BarClock; Guardian and cutscene ask, never play
status: accepted
tags: [music, audio, bus, ducking, stems, finale, cutscene, pause, plan]
related: [systems/music, systems/guardians, systems/cutscenes, systems/screens, systems/songs-and-the-memorina, systems/life-benches-death, systems/greyhush, architecture/grd-06-final-battle, architecture/pause-menu-worldfreeze-reuse, architecture/cutscenes-are-data-played-between-two-rest-states, architecture/save-slots-and-the-boot-swap, gotchas/time-scale-zero-stops-delta-particles-and-time, gotchas/a-killed-tween-never-emits-finished, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor]
created: 2026-11-02
updated: 2026-11-02
source_files:
  - scenes/world/world_freeze.gd
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/finale/guardian_finale.gd
  - scenes/world/cutscene/world_cutscene_context.gd
  - resources/cutscene/story/world_restoration.tres
---

# Background music plan

**Status: accepted and built (SONG-15).** User, 2026-11-02: "Sistema de música geral (Recommended)"; "Abafa ~6 dB (Recommended)". Pieces and stems: `music/final-battle`. Design 06 deferred the bus and ducking "para quando houver música".

## Context

No music exists and no bus layout: every `AudioStreamPlayer` is a note voice or a cutscene sound on Master. The first use is the final battle (winter bed + lead flute + spring layer loop, a call underscore, a restoration cue). Later uses must fit without redesign: region themes (grey/coloured variant), a fight theme per season, cutscene cues, the title, ducking under a performance, a lesson and talks.

## Options considered

1. **Who owns the player.** (a) A node in `game.tscn`: dies with every death `SceneSwap` (music cuts at each death) and cannot serve the title. (b) **A thin autoload `Music`**: outlives `SceneSwap`, serves the title and the world; knows no game rules. Chosen (b), justified like `SaveSystem`: playback continuity across scene swaps is genuinely global. It only plays what nodes in the tree ask for.
2. **Stems.** (a) One `AudioStreamPlayer` per stem started together: drift-free only if started in the same mix chunk, no guarantee. (b) **`AudioStreamSynchronized`** (one player, one clock, per-stream volume): chosen. (c) `AudioStreamInteractive` for clip changes: transitions live inside the stream, per-stem volume per clip is awkward and nothing is unit-testable. Rejected; cue changes are two decks crossfading on a bar boundary computed in GDScript (`BarClock`).
3. **Ducking.** (a) Sidechain compressor on Music keyed by Notes: level-driven pumping, not the fixed "~6 dB while the call is open" the user chose. (b) **Explicit named ducks** combined in a pure mix. Chosen (b).
4. **Fades.** Tweens on an ALWAYS node keep running under a hold (`architecture/pause-menu-worldfreeze-reuse`). Chosen: `MusicMix.step(real_delta)` in `Music._process`, skipped while `WorldFreeze.is_held()`.

## Decision: components

| Piece | Kind | Responsibility |
|---|---|---|
| `MusicCue` (`resources/music/music_cue.gd`) | Resource | `id`, `stream: AudioStreamSynchronized` (or a plain stream = one stem), `stems: Array[StringName]` (index = sync stream), `levels: Dictionary` stem -> 0..1 at start, `bpm`, `beats_per_bar`, `loops: bool`, `fade_in`/`fade_out` real s. `validate()`: stem count = stream count. |
| `MusicRequest` | RefCounted | `cue`, `priority` (enum `MusicLayer { REGION, FIGHT, SCENE, MENU }`), `owner: Node`. |
| `MusicRequests` | pure RefCounted | Ordered set; `top()` = highest priority, newest wins ties. A request whose owner left the tree drops. |
| `MusicMix` | pure RefCounted | Per-stem target and current dB, named ducks (`duck(id, db)`, `unduck(id)`; the deepest wins, they do not add), `hush`/`unhush`; `step(delta)` moves current toward target at the cue's fade rate; returns dB per stem and the deck gain. |
| `BarClock` | pure RefCounted | `next_bar(position_s, bpm, beats_per_bar) -> float` seconds to wait; used for "cross at the loop's next bar". |
| `Music` | autoload Node, ALWAYS | Two decks (`AudioStreamPlayer`, bus `Music`), plays `requests.top()`; same cue on top = no restart (survives death). `request(cue, priority, owner) -> MusicRequest`, `release(request, fade)`, `set_stem(request, stem, level, seconds)`, `duck(id, db)`, `unduck(id)`, `hush()`/`unhush()`. Each frame: `stream_paused = WorldFreeze.is_held() or hushed`; applies `MusicMix` via `set_sync_stream_volume` on a per-play duplicate of the stream (never write the shared `.tres`). |
| `GuardianMusic` (`scenes/characters/guardians/guardian_music.gd`) | Node child of a guardian scene | Reads `GuardianStats.music` and Guardian/Finale signals, asks `Music`. Never touches a player. |
| `CutsceneMusic` (`resources/cutscene/`) | Cutscene leaf | `cue` (null = release the scene's music), `fade`, `wait = false`. |

No new `WorldFreeze` writer, no `Input` reader, no `CanvasLayer` mode change.

## Bus layout (`default_bus_layout.tres`)

`Master` <- `Music`, `Notes`, `Sfx`. `Notes`: `MemorinaVoice`, `SongPerformance`, guardian `Call`/`CallB`, `MelodyPlayer`, teacher voices. `Sfx`: creatures, `WorldCutsceneContext.sound()`. No per-stem buses: stem volume lives in the synchronized stream. Ducks act on `Music` only, so the call's notes are never ducked (and the register rule in `music/final-battle` keeps C4..G4 free).

## Pause behaviour

| State | Music |
|---|---|
| Menu hold (`WorldFreeze.is_held()`) | `stream_paused`, fades stop; resumes at the same sample ("Stop everything", 2026-10-02; open question 1). |
| Performance/lesson freeze (tree paused, scale 1) | keeps playing (ALWAYS); later a `performance` duck. |
| Recall slow, hit stop (time scale < 1) | unaffected: audio ignores `time_scale`. |
| Freeze frame (revelation) | explicit `hush()` for `freeze_frame_seconds` real s, then `unhush()`: `stream_paused` keeps the loop point. |
| Title (no world) | plays; `is_held()` is false there. |

## Wiring for the final battle

New data: `GuardianStats.music: MusicCue` (`finale_fight.tres`, stems `bed`, `lead`, `spring`); `FinaleStats.call_music: MusicCue` (`finale_call.tres`); `finale_restoration.tres` (one stem, `loops = false`). New signals: `Guardian.phase_changed` re-emits `GuardianFight.phase_changed`; `GuardianFinale.revelation_opened` (in `open_call`, REVELATION), `track_chosen` (after `_finale.choose()`), `freeze_frame_began(seconds)` (in `_shatter`). `GuardianMusic` subscribes; one-directional.

| Event | GuardianMusic asks |
|---|---|
| `phase_changed` DORMANT -> PRESSURE | `request(music, FIGHT, self)`; `spring` 1 if `SaveSystem.is_finale_revealed()` (kept through death), else 0. |
| `revelation_opened` | `set_stem(spring, 1, 4 s)` |
| `freeze_frame_began(s)` | `hush()`, real timer `s`, `unhush()` |
| `lucid_landed` | `set_stem(lead, 0, 0.3 s)`, `duck(&"call", -6)` |
| `call_ended` | `set_stem(lead, 1, 1 s)`, `unduck(&"call")` |
| `track_chosen` | `set_stem(spring, 0, 2 s)`; `request(call_music, FIGHT, self)` at `BarClock.next_bar` (crossfade 1 bar) |
| `restored` | release both, fade 0.5 s |

The generic table (fight start, call duck, restored) is shared by every guardian; the three finale rows are skipped when the guardian has no Finale child. A death frees `GuardianMusic`, so its requests drop with the old world.

## The cutscene step change

`CutsceneContext.music(cue, fade) -> CutsceneTask`; `WorldCutsceneContext` requests at `SCENE` priority owned by the director and returns an instant task (`wait = false`) or a `CutsceneUntilTask` on the deck. `silence()`/`restore` release the scene's request: a looping cue fades out, a one-shot rings to its end (the restoration cue must not be cut by the bars closing). `land()` on skip: release with a 0.8 s fade. `CutsceneSound` keeps blocking and moves to `Sfx`. In `world_restoration.tres`, add a `CutsceneMusic` (`finale_restoration.tres`, `wait = false`) inside `together_14` beside `mentor_winter`; it ends 11.4 s after, under the 11.1 s of steps, so nothing is delayed.

## Later uses (fit, not built)

Region theme: `Region.music` (+ `grey_music` or a `colour` stem) requested at `REGION` by a watcher on `Game.room_changed`; the same cue across rooms continues. Per-season fight themes: data on each `GuardianStats`. Title: `MENU` request from the title screen. Performance, lesson, talk: named ducks from their existing signals. Greyhush: a stem level could follow the region's memory (`set_stem` from a watcher) - note only.

## Tests (`tests/` mirroring source)

`music_requests_test` (priority, ties, owner gone, same-cue no restart); `music_mix_test` (stem fades by real delta, deepest duck wins, hush keeps levels, held = no step); `bar_clock_test` (on, just after, just before a bar; 80 and 60 BPM); `music_cue_test` (every `.tres` in `resources/music/` validates, looping stems equal length and loop enabled); `bus_layout_test` (every scene `AudioStreamPlayer` names an existing bus, notes on `Notes`); `cutscene_catalog` validate accepts `CutsceneMusic` in a together. Playtest: the finale timeline, ears-only report on latency of the call duck and the freeze-frame silence.

## Build order

1. Bus layout and bus assignment of existing players (no audible change); `bus_layout_test`.
2. `MusicCue`, `MusicRequests`, `MusicMix`, `BarClock` with suites.
3. `Music` autoload; spike: confirm `set_sync_stream_volume` on a playing duplicate applies live in 4.7 (fallback: per-stem players started in one frame on stem buses).
4. Render the three AIVA pieces to looping OGG stems, the three `.tres`; `music_cue_test`.
5. `Guardian.phase_changed`, finale signals, `GuardianMusic` on the mentor; playtest.
6. `CutsceneMusic` and `world_restoration.tres`; playtest the scene and its skip.
7. Runtime section in `systems/music`, CLAUDE.md row, design 06 note.

## Consequences and risks

- One more autoload; it must stay a player. Any game rule creeping into it is a defect.
- Stems must share length and loop point exactly; AIVA exports need trimming (`music_cue_test` catches it).
- A request owner freed without `tree_exiting` cannot exist, but a request on a node outside the tree (e.g. a pooled one) would hang: drop on `is_inside_tree()` check each frame.
- Hit-stop and hush timers run on real time minus held time.

## Open questions for the user

1. Under the pause menu: music stops with everything, or keeps playing ducked?
2. After the restoration cue: silence until a region theme exists, or the lantern stays quiet by design?
3. Should the call underscore itself also take the ~6 dB call duck, or play at its written level?
4. A death mid-fight: the fight cue fades out at the bench, or cuts with the fade to black?

## Decisions (user, 2026-11-02)

- "Aprovo o plano (Recommended)": build in the slices above.
- Pause menu: the music stops with everything ("Para junto (Recommended)").
- A death mid-fight fades the music over ~1 s with the screen ("Some em fade (Recommended)").
- The call underscore plays at its written level, not ducked ("Não, já é baixo (Recommended)").
