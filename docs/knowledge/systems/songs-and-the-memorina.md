---
id: systems/songs-and-the-memorina
type: system
title: Songs, pulses, the Memorina instrument, the pause-mode map, freeze and hold
status: active
tags: [songs, memorina, pulse, performance, pause]
related: [architecture/memory-runs-through-pause, architecture/played-pulses-hold-in-a-pause, architecture/pause-menu-worldfreeze-reuse, systems/screens, bugs/memorina-notes-dropped-while-previous-rings, gotchas/time-scale-zero-stops-delta-particles-and-time]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/ivo.tscn
  - scenes/characters/ivo/abilities/memorina_voice.gd
  - scenes/characters/components/song_performance.gd
  - scenes/world/world_freeze.gd
---

# Songs, pulses, the Memorina instrument, the pause-mode map, freeze and hold

- **A song is data** (`resources/songs/*.tres`): its id, its season palette, its note sequence and its pulse tuning. Adding one is a `.tres` plus an `Enums.Song` member appended at the end.
- **A guardian's pulse never carries the song's effect** (`PulseEmitter.song_acts = false` on both guardians): its lesson and its answer are the song remembered, not played - a Bloom Guardian teaching Enraizar must not root its own arena. Nor does the world answer it: a non-acting pulse's `SongArea` is not monitorable and `ColorPulse.lit()` skips it (`ColorPulse.acts()`).
- **A song does things two ways, and neither touches the song, pulse or instrument code.** What the WORLD answers composes a `SongReceiver` (ice on water); what the SONG itself does is a `PulseEffect` scene on `Song.pulse_effect`, mounted by `ColorPulse` at its centre (a gale's field, a shell, a burned shadow) and freed with it. An effect runs PAUSABLE although the pulse is ALWAYS. `ColorPulse.radius()`/`contains()` are the CLEAN disc - gameplay never reads the dithered edge (design 02 §7.3) - and `ColorPulse.lit(node, song_id)` finds live pulses by song. `SongReceiver.is_lit()` counts overlapping pulses, so an effect that ends on `song_left` asks it first: the last light leaving is what ends it.
- **`SongMatcher` is pure logic and carries no timing.** The guardian call-and-response needs the same matching with a window on top; that will wrap the matcher and call `reset()`, rather than the matcher growing two modes.
- **No song's note sequence may be a prefix of another's** — the longer one would become unreachable. `SongCatalog.validate()` asserts this at startup in debug builds.
- **`MemorinaComponent` holds the instrument's state and nothing else.** Whether Ivo is standing still enough is the body's judgement, pushed in through `try_draw(can_play)` and `interrupt()`, the same way `enabled` carries the item gate.
- **A new note cuts the one still ringing.** The samples ring ~1.6 s, far longer than a phrase is played at, so `MemorinaVoice.play_note()` retriggers once `min_note_gap` (0.25 s) has passed and `Player` gates presses on `MemorinaVoice.can_play_note()`; presses inside the gap are mashing and are dropped. Never gate on `is_busy()` for a press - a silently swallowed press reads as "the game got it wrong" (see `docs/knowledge/bugs/memorina-notes-dropped-while-previous-rings.md`).
- **Interruption reuses the failure vocabulary that already exists.** Being hit or stepping off a ledge mid-sequence emits `sequence_failed`, exactly as a wrong note does — no second kind of failure for the player to learn. A wrong note never sounds: the component emits `note_rejected` (drawn, not played) and then `sequence_failed`, and the mistake SFX plays in its place; an interruption lets the ringing note finish first (`MemorinaVoice.play_mistake_after_note()`). `sequence_reset` (the sheet clears) fires when the mistake has been heard.
- **A completed sequence starts a PERFORMANCE, not the song.** `MemorinaComponent` emits `song_matched` and locks. `Player._tick_pending_performance` (called from `_process_motion`, after the `is_still()` interrupt) waits until `MemorinaVoice.is_busy()` is false, then `SongPerformance.play()`s the song's `performance_stream()` (the excerpt, or the track cut at `excerpt_duration`). `performance_started` → `WorldFreeze.freeze()`, `cue_reached(i)` lights sheet slot `i`, `finished` → thaw → `finish_performance()` → `song_played` → the pulse, then the component sheathes itself (the answer ends the gesture). The freeze is never set at match time, so a hit during the ring-out aborts through `interrupt()` and nothing is left paused. A lesson (`learn_song`; F9 `debug_learn_song` in debug builds) is a performance of the whole track after `lesson_lead_in` (0.5 s) on the same tick.
- **A performance, a lesson track and the post-call sheathe start only on Ivo's pausable clock** (`_process_motion`). `MemorinaVoice` is ALWAYS, so a start from its callback would begin a performance under a menu, and its `finished` → thaw would unpause the world under the menu (`architecture/pause-menu-worldfreeze-reuse`). `MemorinaVoice.note_finished` was removed for this. Ticking after the `is_still()` interrupt means a performance never starts in the frame that ends it.
- **`learn_song` refuses while Ivo is seated**, like a draw press: it is "refused unless Ivo … could draw it right now". The guardian path stands him up in `stage_call`.
- **Pause-mode map.** `World` is PAUSABLE. `PROCESS_MODE_ALWAYS` on exactly: `MemorinaHud` (in its own scene), `Ivo/MemorinaVoice`, `Ivo/SongPerformance`, `LessonCinematic`, `LifeHud` (always visible means through a lesson and a death's fade), `ScreenLayer/Screens` (the menus' root Control, `systems/screens`), and **the memory layer**: `SeasonMask`, the `Greyhush` renderer, `CreatureMask`, every `ColorPulse` (its scene root) and `RegionWeather`. `Ivo/AnimationTree` is INHERIT and becomes ALWAYS only during a performance (`ivo.tscn`: `performance_started` → `set_process_mode(ALWAYS)`, `performance_finished` → `set_process_mode(INHERIT)`), so `memorina_idle` loops under a performance and Ivo stops under a menu. `CreatureMask` is in that list because it MIRRORS the camera every frame: the camera still moves while the world is frozen (a lesson pushes in), and a creature pass left on the last transform draws every body where it used to be - characters floating off the floor. `MemoryClock` stays pausable (environment time is what is frozen). Never the whole `CanvasLayer`. Camera zoom tweens use `TWEEN_PAUSE_PROCESS`. **Water adds nothing to this list**: `WaterBody` (motion) and the ice are pausable, and the reflection gate reads the season mask, which is already ALWAYS - so a lesson returns the reflection while the waves hold still. The playtest runner is ALWAYS too; `game.tscn`'s root is PAUSABLE so it never inherits that.
- **`SongPerformance` and `CueTracker` carry no song knowledge.** They play a stream and report crossed cue times; `Song.note_cues` (seconds, one per note, hand-tuned against the audio) is the only place timing lives. A future reduced excerpt must start at the same instant as the track so the cues stay shared; adding `excerpt_cues` later is an additive change.
- **The glyph a note is drawn with is decided in `PlayerInput`** (`glyph_set_for(event, joy_name)`, pure and tested) and travels as `Enums.GlyphSet` beside the note. `MemorinaComponent` never sees it — `Player` remembers the pressed glyph and relays `note_played(note, glyph_set)`. The HUD maps a set to textures through `NoteGlyphSet` resources (`resources/ui/memorina/`); no script names a glyph PNG.
- **The sheet is geometry, not layout.** `NoteSheet` authors the staff in `memorina_hud.png`'s own pixels (`LINE_Y`, `STAFF_LEFT/RIGHT`) and scales them by the `Frame` TextureRect's actual width, so the frame's offsets in `memorina_hud.tscn` are the one place that picks 1× (128×64) or 2× (256×128, current); the glyphs have their own `icon_scale` (1.5). The frame is placed by code on the side Ivo faces (`MemorinaHud._place_frame`), but only once `GameCamera.focused` reports the zoom and any in-flight look-ahead have landed, with Ivo's final screen position — a frame laid out earlier would cover where he is about to be. The camera is the one node that converts world to screen for UI. The title's outline is the Label's `outline_size`, not the outline `.ttf` (two fonts never overlay glyph for glyph). No nested `scale`, so nothing is left for pixel snapping to round.


## Freeze and hold

Two ways to pause, both written only by `WorldFreeze` (`architecture/pause-menu-worldfreeze-reuse`, second revision):

| | freeze / thaw | hold / release |
|---|---|---|
| Who | a performance or lesson (`Player.performance_started` / `finished`) | a menu that holds (`Screens.hold_requested` / `release_requested`): the pause, later the notebook |
| Tree | paused | paused |
| `Engine.time_scale` | 1 | 0 |
| ALWAYS nodes | run: memory moves, the voice rings, `memorina_idle` loops | delta is 0: the memory layer, life notes, pulses, CPU particles and scaled tweens stop |
| Shader clock | `greyhush_time` advances | `greyhush_time` stops |

- A lesson freezes TIME, not MEMORY: while the track plays the well of forgetting lifts, the baseline climbs, colour spreads from the guardian and the weather wakes. A hold stops all of it.
- **`MemorinaVoice._process` sets `stream_paused = WorldFreeze.is_held()`**: the pull keeps a ringing note silent under a menu and resumes it from the same position. A pausable voice (a guardian's call) is paused by the engine with the tree.
- **`SongPerformance._process` asserts `not WorldFreeze.is_held()`.** A menu opens only on a running tree, and a performance starts only on Ivo's pausable clock, so a performance is never under a hold.
- **The pause stays refused during a performance or lesson**: the tree is already paused, so `ScreenRouter` opens nothing. It is not refused in the ring-out or the lesson lead-in; the hold stops both.
- **Rule for a new ALWAYS node:** if it animates from anything but the scaled delta (`TIME`, ticks, `set_ignore_time_scale`, an audio stream), it must stop while `WorldFreeze.is_held()`. No shader reads `TIME`; the greyhush edge reads `greyhush_time` (`systems/greyhush`).
- Measured on screen (2026-10-02): two frames 2 real seconds apart under a held pause are pixel-identical over the ring-out, a spreading pulse and the lesson lead-in, with the voice paused (`gotchas/time-scale-zero-stops-delta-particles-and-time`).

User decisions, 2026-10-02: behind the pause, "Stop everything"; the pause during a performance or lesson, "Keep refused".

## Current limits (from the old "Known gaps", 2026-10-02)

- `Player.learn_song()` refuses without the Memorina instead of granting it. Handing the instrument over is the world's job (a pickup, the mentor); see roadmap STORY-02.
- Debug builds start a new game owning the sword and the Memorina (`SaveSystem._new_game()`).
- `debug_learn_song` (F9, debug builds only) teaches the next unknown song through `Player.learn_song()`. It stays until every song has a guardian.
