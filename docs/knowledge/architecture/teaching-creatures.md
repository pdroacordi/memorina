---
id: architecture/teaching-creatures
type: architecture
title: Teaching creatures (CORE-04) - a coloured world creature sings a song's first half into a glyph balloon; Ivo echoes it through an echo mode beside the matcher; the half is saved with no sheet
status: built
tags: [core-04, teachers, creatures, songs, memorina, half-songs, echo, balloon, glyphs, greyhush-shield, legend, reach-kits, plan]
related: [architecture/half-songs, architecture/found-pieces, architecture/corrupted-creatures, architecture/guardian-fight-phase-machine, architecture/animation-driver-resolver-pattern, architecture/pause-menu-worldfreeze-reuse, architecture/room-reachability-audit, architecture/rooms-are-text, systems/songs-and-the-memorina, systems/creatures, systems/greyhush, systems/notebook, systems/notices, systems/input, systems/props, systems/rooms, systems/life-benches-death, bugs/ivos-greyhush-shield-colours-a-creature-in-melee-range, bugs/the-notebook-quill-shows-through-a-lesson, bugs/a-half-taught-while-the-memorina-is-drawn-cannot-be-guessed-until-redrawn, bugs/memorina-notes-dropped-while-previous-rings, bugs/the-canvas-passes-draw-one-frame-behind-a-camera-zoom-tween, gotchas/a-killed-tween-never-emits-finished, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/components/phrase_echo.gd
  - scenes/characters/ivo/abilities/memorina_component.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/components/phrase_call.gd
  - resources/songs/song_halves.gd
  - resources/world/creatures/creature_lesson.gd
  - scenes/world/creatures/teaching_creature.gd
  - scenes/world/creatures/teaching_flow.gd
  - scenes/world/creatures/teacher_animation_resolver.gd
  - scenes/ui/teacher_balloon/teacher_balloon.gd
  - scenes/ui/memorina_hud/memorina_hud.gd
  - resources/world/maps/room_legend.tres
  - resources/world/maps/reach_milestone.gd
  - resources/world/maps/reach_kit.gd
  - resources/world/maps/reach_kits.tres
---

# Teaching creatures (CORE-04)

**Status: built** (2026-10-29; `systems/teaching-creatures`; "As built" at the end). Design: 02 §2 "Criaturas escolhidas" with the user's revised flow (2026-10-29, "ok"); `docs/design/drafts/creatures_board.md` "Decided". Art done: `assets/sprites/world/creatures/<name>/<name>_{idle,sing,flourish}.png`, 4 frames each, frames snail and thrush 32x32, kestrel 48x48, lizard 48x32, facing west, feet on the bottom row.

## Context

- Snail (BELL_JAR, L R L), thrush (RAIN, R R R), kestrel (GALE, R R L), lizard (SOLSTICE, R D U) each teach `Enums.SongHalf.FIRST` through `Player.learn_song_half` (`architecture/half-songs`, the one entry point).
- Near Ivo the teacher sings three notes into a balloon of the current device's note glyphs. Ivo echoes them on the Memorina; a right note lights its glyph, a wrong one shakes the balloon and it sings again, at no cost. No freeze, no cinematic, no half sheet. On success: a flourish, the half saved, the quill. A half that completes the song: a duet, then the full lesson. Afterwards a draw near it brings the phrase back.
- Constraints: the matcher stays pure and judges only 6-note songs; a call admits only its phrase; nothing reads `Input`; the save write must not land in a freeze (`bugs/the-notebook-quill-shows-through-a-lesson`); a drawn instrument must be re-drawn to take partials (`bugs/a-half-taught-while-...`); teachers are not `Enemy` (`systems/creatures`) and must not carry the unshielded mark (`systems/greyhush`); no `AmbientMotion` (they have memory; `systems/props`: a prop carries no gameplay).
- Today the matcher, fed L R L near the snail, would reject note 1 or 2 (no known song starts so) and the mistake would play instead of the note. The Memorina must know it is echoing.

## Options considered

**How the echo is judged.**
- Reuse the matcher with a `SongCandidate` masked `[T,T,T,F,F,F]`. Rejected: blanks decide on the sixth note, so three right notes never complete.
- Give the call path a three-note "phrase song". Rejected: `call_song` is a `Song`; a fake 3-note `Song` breaks `SongCatalog.validate` and the "every song has 6 notes" rule.
- The teacher judges `Player.note_played` itself. Rejected: the matcher would still reject the notes before the teacher hears them.
- **Chosen:** a pure `PhraseEcho` beside `SongMatcher`, installed in `MemorinaComponent` like `call_song` (`echo_phrase`). The matcher is untouched.

**Where the balloon draws.**
- World-space `Node2D` beside the creature, as `EmoteBubble`. Rejected: the root canvas is greyed; in Frost Edge or the Caldera (0.05-0.3) the pad colours and the lit/unlit glyph contrast are lost, and the creature is coloured while its words are not.
- Child of the teacher on the creature pass. Rejected: the SILHOUETTE shield lights only inside its shape; the balloon above it stays grey.
- A `CanvasLayer` (`follow_viewport_enabled`) per teacher. Rejected: a `CanvasLayer` ignores its room's hidden contents, so a deactivated room can strand it; its layer index must be threaded between the passes and the menus.
- **Chosen:** one HUD `TeacherBalloon` in `game.tscn`'s `CanvasLayer`, following its anchor through the canvas transform each frame (the `RecallPrompt` precedent), found by group like `CutsceneDirector.find`. One teacher is in reach at a time.

**The duet.**
- Ivo's voice driven by a new `Player` API. Rejected: a second writer of Ivo's voice for one moment.
- **Chosen:** the teacher sings the phrase through two phrase players at once, its own pitch and Ivo's (pitch 1.0); Ivo stays drawn, so `memorina_idle` plays the flute. The save is written only when the duet ends (`learn_song_half`, which starts the lesson), so an interrupted duet teaches nothing, the failure rule half songs already use.

**No half sheet for teachers.**
- The HUD ignores `song_half_learned` while an echo is open. Rejected: an implicit rule in a view.
- Move the sheet signal to `_try_found`. Rejected: F8 and future callers would each re-implement it.
- **Chosen:** `learn_song_half(song, half, sheet: bool = true)`; teachers pass false.

**Scene and data.**
- One generic teacher scene with the look in a Resource. Rejected: clips are keyed per species (`systems/animation`); the creature precedent is one scene per species.
- **Chosen:** four species scenes on one `TeachingCreature` script; per-teacher data in a `CreatureLesson` Resource. Scenes live in `scenes/world/creatures/<name>/`, mirroring the art already under `assets/sprites/world/creatures/`. A teacher is a `Node2D`, not a `Character` (no body, gravity, health), so not `scenes/characters/creatures/` as `architecture/corrupted-creatures` guessed.

**Placement.** Legend symbols (one per species, as `B J C N A Z`), not hand-placed nodes: rooms are text (`architecture/rooms-are-text`).

## Decision

**Pure logic.**
- `PhraseEcho` (`scenes/characters/components/phrase_echo.gd`, RefCounted): `_init(phrase: Array[Enums.Note])`, `enum Result { RIGHT, COMPLETE, WRONG, IGNORED }`, `feed(note) -> Result` (WRONG resets; IGNORED once complete), `count() -> int`, `is_complete()`, `reset()`.
- `SongHalves.completes(data, song, half) -> bool`: `missing(data, song) == half or guessed_halves[song] == half`. `Player.learn_song_half` uses it instead of its inline test (same behaviour); the teacher asks it before choosing the duet.
- `TeachingFlow` (`scenes/world/creatures/teaching_flow.gd`, RefCounted, owns the teacher's clock like `GuardianFight`). States `AWAY, SINGING, LISTENING, DUET, FLOURISH, TAUGHT_QUIET, TAUGHT_SINGING`. Inputs: `set_near`, `set_teachable`, `set_busy` (Ivo in a talk, scene or lesson), `drawn`, `note_echoed`, `echo_failed`, `echo_reset`, `echoed(completes)`, `phrase_sung`, `learned(ok)`, `tick(delta)`. Outputs as signals: `sing_requested(interval, lead_in, duet)`, `sing_stopped`, `balloon_shown(lit_as_sung)`, `revealed(index)`, `lit(count)`, `shaken`, `balloon_closed(linger)`, `learn_requested`, `flourished`.

**Data.** `CreatureLesson` (`resources/world/creatures/creature_lesson.gd`), one `.tres` per teacher (`snail_lesson.tres`...): `song: Song`; `note_interval` 0.55 s (the guardian call's); `retry_interval` 0.75 s (after a mistake); `repeat_after` 4.0 s (phrase end to next phrase while no echo note); `lead_in` 0.4 s; `flourish_linger` 1.2 s; `after_linger` 2.0 s; `reach: Rect2(-128, -96, 256, 192)` px from the feet (4 cells either side). `phrase()` = `song.notes.slice(0, SongHalves.HALF_LENGTH)` (never stored twice); `reaches(feet, ivo_feet)`; `validate()` (song set, `learned_in_halves`). `TeachingCreature.TAUGHT_HALF := FIRST`, as `FoundPickup.TAUGHT_HALF`.

**Instrument and Ivo.**
- `MemorinaComponent`: `signal phrase_echoed`; `var echo_phrase: Array[Enums.Note]` (setter rebuilds `_echo`). `receive_note` takes the echo path while it is set: RIGHT → `note_played`; COMPLETE → `note_played`, `phrase_echoed`, stays DRAWN; WRONG → `note_rejected`, `sequence_failed`; IGNORED → nothing. `sheathe` resets it; `interrupt` counts echo progress as buffer. Echo and call are exclusive (assert).
- `Player`: `open_echo(phrase)` / `close_echo()` / `is_echo_open()`; signals `echo_opened`, `echo_closed`, `phrase_echoed` (relayed). `learn_song_half(song, half, sheet := true)` closes an open echo after its gates pass, emits `song_half_learned` only when `sheet`. An open echo gates nothing else (doors, benches, Up all as today). Presses still pass `MemorinaVoice.can_play_note()` (`bugs/memorina-notes-dropped-...`).
- `MemorinaHud`: `on_echo_opened` / `on_echo_closed` keep a flag; `on_drawn` shows no sheet while it is set (design: "sem partitura no HUD"). The camera still focuses on draw.

**The teacher** (`TeachingCreature extends Node2D`, pausable, the glue only).
- Species scene children: `Sprite2D` (no material: no corruption edge, so no unshielded mark), `AnimationTree` (flat: `idle` loop 6 fps, `sing` loop 8 fps, `flourish` one-shot 8 fps), `AnimationDriver`, `TeacherAnimationResolver` (shared: consts IDLE, SING, FLOURISH; flourish held via `holding()`, then sing while a phrase sounds, else idle), `GreyhushShield` (SILHOUETTE, CIRCLE over the body, `amount` 1.0 as Ivo's), `BalloonAnchor` (Marker2D over the head), `Call` and `Duet` (phrase players, below). No Hurtbox, Hitbox or body: the sword and pogo pass through. Faces Ivo while near (flips `Sprite2D.scale.x`; clips never key scale).
- Root export `lesson: CreatureLesson`, set in the species scene (the guide lists it; a `.room` never sets it).
- Each physics tick: finds Ivo by `Player.GROUP` (lazily, connecting once), feeds `set_near(lesson.reaches(...))`, `set_busy(is_in_story() or is_in_lesson())`, ticks the flow. Teachable = `SongHalves.can_teach(data, song, FIRST)`, read at `_ready` and on `SaveSystem.progress_changed` (a death rebuilds the world, so a rewound half teaches again; nothing new is saved).
- Ivo's signals in: `memorina_drawn` → `drawn`; `note_played` while the echo is open → `note_echoed`; `sequence_failed` → `echo_failed`; `sequence_reset` → `echo_reset`; `phrase_echoed` → recorded, acted on at the next tick (never inside `receive_note`).
- Flow out: teachable and near → `open_echo(lesson.phrase())`; away or taught → `close_echo()`. `learn_requested` → hide the balloon, `learn_song_half(song, FIRST, false)`, report `learned(ok)`; a refusal (Ivo moved) sings again.

**Timing.** Approach: sing after `lead_in`, one glyph revealed per note (`note_interval`), then LISTENING with all three shown. No echo note for `repeat_after` → sing again. A right note while it sings cuts the phrase and shows all three, lit to the count. Wrong: shake at `sequence_failed` (0.3 s, 2 px), unlight; at `sequence_reset` (the mistake heard) sing again at `retry_interval`. Echo complete: not completing → `learn_requested` at once, flourish clip, all lit, close after `flourish_linger`; completing → duet (`note_interval`, `lead_in` 0.5 s so Ivo's last note rings out), then `learn_requested` (the lesson). TAUGHT: silent until `memorina_drawn` while near, then one phrase, glyphs lit as they sound, closed after `after_linger`. No ambient singing out of reach.

**Sound.** No new audio. `GuardianCall` is generic (no guardian knowledge, `guardian.gd` its one user): rename it `PhraseCall` and move it to `scenes/characters/components/` from the FileSystem dock. Each teacher's `Call/Voice` is a `MemorinaVoice` with the four Memorina notes (`assets/audios/sfx/memorina/note_*.mp3`) and `pitch_scale` 2.0 (an octave up, as guardians sing an octave down); `Duet/Voice` the same at 1.0. Same pitch classes, so the echo matches by ear; a timbre is a later data swap of `note_streams`.

**Balloon** (`scenes/ui/teacher_balloon/`, `TeacherBalloon extends Control`, group `teacher_balloons`, `static find(tree)`, under `CanvasLayer` after `GuardianCallHud`, INHERIT). `show_for(anchor, notes)`, `reveal(i)`, `reveal_all()`, `light(count)`, `shake()`, `close(linger)`, `speaker()`. Paper box and tail in `EmoteBubble.PAPER`/`INK`, three 16x16 glyphs (`NoteSheet.ICON_SIZE`) from `glyph_sets: Array[NoteGlyphSet]` indexed by `InputDevice.glyph_set`, re-textured on `InputDevice.device_changed` (the notebook's pattern); lit = `NoteGlyphSet.texture(note, true)`. Follows `anchor.global_position` through `get_viewport().get_canvas_transform()` in `_process`, rounded; hides itself when the anchor is freed or not visible in tree. Tweens bound to itself (pausable, scaled); `close` kills the shake (`gotchas/a-killed-tween-never-emits-finished`).

**Pause mode.** Nothing joins the ALWAYS list: teacher, phrase players and balloon inherit PAUSABLE, so a hold stops them and a lesson's freeze stills them (the balloon is hidden before the lesson starts). No explicit process modes (`gotchas/an-explicit-process-mode-escapes-...`).

**Notices.** No `NoticeHold` change. A plain half saves at the flourish and the quill announces it, as designed; the duet saves nothing; the completing lesson is held by `is_in_lesson()`. `NoticeWatcher` diffs items only.

**Placements** (cells are the feet cell; world feet = region origin + room position + (32 col + 16, 32 (row + 1)), region origins assumed 0; verify at build). One new symbol per species, free in the legend today: `U` snail, `Y` thrush, `K` kestrel, `Q` lizard (`*` is reserved by the reach board). No params. All four rooms are already in `room_files_test.NO_CREATURE_ROOMS`.

| Teacher | Room, cell | Feet (px) | Why |
|---|---|---|---|
| snail | `lake_fishing_village` 7,8 | (880, -1632) | On the deck by the first stilt, beside the landing; under the deck is lake (`w`), so "under the stilts" cannot be stood under. |
| thrush | `woods_edge` 25,6 | (-1744, 224) | On the woodpile between the hut and the bench (30,8); Ivo at the bench is 64 px below, in reach. |
| kestrel | `orchard_windy_gap` 38,8 | (-6448, -1632) | The east ledge, where Ivo lands from the dovecote, before the crossing. |
| lizard | `caldera_open_crater` 17,44 | (-1360, 2208) | The bench pit floor, three cells west of the bench, under the open sky. |

Rule (new `room_files_test` cases): each teacher symbol once in the world, in its room; on a floor cell; a standable floor cell inside its reach; no song puzzle inside its reach (an open echo admits only the phrase).

**Reach kits** (found-pieces' consequence, in one change): `ReachMilestone.first_halves` / `second_halves: Array[Enums.Song]`; `ReachKit.player_data()` calls `SongHalves.teach`. Eight milestones: `half_{bell_jar,rain,gale,solstice}_first` in the teacher rooms, `half_*_second` in the book rooms (woods_root_caves, lake_shore, caldera_seesaw, orchard_ridge). Each kit holding a region's guardian milestone gains that region's teacher and book milestones. Guardian milestones drop their second song (bloom [6], frost [0], autumn [4], summer [2]). Whole second songs per kit become: both (RAIN, BELL_JAR), woods_orchards_caldera (GALE, SOLSTICE), both_caldera (RAIN, BELL_JAR); the single-region kits and woods_orchards, lake_caldera, orchards, caldera none. Rerun `room_reach_test`: a room newly unreachable or a new trap is a design finding for the user, never a silent allowlist entry; check the windy gap first (its crossing needs Vendaval: 15.8-17.6 cells of a 20-cell chasm).

**i18n.** None. The balloon is glyphs; the flourish is wordless; the quill and the lesson reuse `NOTEBOOK_SONG_HALF_TITLE`, `MEMORINA_LEARNED` and the song titles. Legend descriptions are developer text.

## Build order (each step committable, `verify-gates` each)

1. `PhraseEcho` + tests; `SongHalves.completes` + `learn_song_half` refactor + tests.
2. Echo mode: `MemorinaComponent`, `Player` (`open_echo`, `close_echo`, signals, `sheet`), `MemorinaHud` flag, `game.tscn` wiring. Tests.
3. Rename `GuardianCall` to `PhraseCall` in the editor (guardian scenes follow). Guardian tests green.
4. `CreatureLesson` + four `.tres` + tests.
5. `TeachingFlow` + tests.
6. `TeacherBalloon` scene in `game.tscn` + tests.
7. `TeachingCreature`, `TeacherAnimationResolver`, four species scenes; sheet test, scene test; species scenes into `tools/smoke/scenes.txt`.
8. Legend `U Y K Q`, four `.room` edits, `docs/maps/README.md` regenerated, `room_files_test`.
9. Reach kits as above; kit notes; `room_kit_test`; `room_reach_test` read and findings surfaced.
10. Docs: new `systems/teaching-creatures` + CLAUDE.md row; `songs-and-the-memorina` (echo mode, `sheet`, teachers pausable), `creatures`, `greyhush` (a teacher's shield, no mark), `rooms`, glossary (criatura-professora → `TeachingCreature`, eco → `PhraseEcho`), roadmap. Playtests.

## Tests (gdUnit4, pure first)

- `phrase_echo_test`: right notes count; third completes; wrong resets; repeated R R R; notes after completion ignored; reset.
- `song_halves_test.test_completes_per_state` (unknown, second known, guessed first, guessed second, learned).
- `creature_lesson_test`: phrase is the song's first three; validate rejects a null or unhalved song; reach edges inclusive.
- `teaching_flow_test`: approach sings after lead-in; away stops and closes; repeat after 4 s without an echo, none mid-echo; a right note mid-phrase cuts and lights; wrong shakes, sings at retry pace after the reset; plain echo asks to learn and flourishes; completing echo duets then asks; a refusal sings again; taught sings only on a draw; busy is silent.
- `memorina_component_test` (echo section): only the phrase; wrong rejected and failed; complete emits `phrase_echoed` and stays drawn; ignored after; clearing reinstalls songs and partials; interrupt with progress fails.
- `player_echo_test`: open/close signals; `sheet = false` emits no `song_half_learned`; completing half starts the lesson; `learn_song_half` closes the echo. `memorina_hud_test`: no sheet on a draw while echoing.
- `teacher_balloon_test`: three glyphs of the device set; light uses selected; device change re-textures; shake returns home; hides when the anchor goes.
- `teaching_creature_test` (real Ivo): shield SILHOUETTE, sprite unmarked, no areas; echo opens in reach and closes out of it; taught opens none; a death-rewound half reopens. `teacher_sheet_test`: three clips per species, frame sizes, the resolver's consts.
- `room_files_test` rules above; `room_kit_test.test_no_teacher_needs_its_own_song`; `reach_kits_test` updated.

## Playtests (`tools/playtest/scripts/`, `player_position` at the feet above)

- `core04_snail_echo.json`: approach, read the balloon, draw, L L (shake, sings again), L R L, flourish, quill; Ivo's sheet absent.
- `core04_snail_duet.json`: `song_halves: [[1, 2]]`; echo, duet, lesson with the real name.
- `core04_after_repeat.json`: `song_halves: [[1, 1]]`; draw near the snail, the phrase returns; ordinary play elsewhere.
- `core04_thrush.json`, `core04_kestrel.json`, `core04_lizard.json`: scale and findability at true size, balloon over each, echo once. If the runner can send pad buttons, one on Xbox glyphs.
- Report what screenshots cannot: whether the balloon lags the zoom on draw (`bugs/the-canvas-passes-draw-one-frame-behind-...`), whether 0.55 s reads as a phrase.

## Consequences

- Inside a teacher's reach, before its half is known, the Memorina plays only the phrase. Placements keep song puzzles out of reach (tested).
- `learn_song_half` gains a parameter; songbooks and F8 unchanged.
- `PhraseCall` has two users; guardian scenes change only a script path.
- The kits stop giving second songs whole with their guardians; some rooms reachable in single-region kits today may not be.
- A teacher has no `save_id` and no record: its presence is unconditional; what it says is derived from the halves.

## Questions for the user (recommended defaults)

1. Snail: "under the stilts" is lake water in the room. Deck by the first stilt, 7,8 (recommended), or the stone landing, 5,8?
2. Thrush: on the woodpile by the bench, 25,6 (recommended), or on the hut roof, 13,3 (reached by climbing)?
3. Kestrel: the east ledge on arrival, 38,8 (recommended), or the west floor after the crossing, 14,8?
4. Lizard: the bench pit, 17,44 (recommended), or the cap top, 21,30?
5. Voices: the Memorina's notes an octave up for all four, the duet in Ivo's pitch, no new audio (recommended); or 16 new samples, one timbre per animal?
6. Ivo's own sheet hidden while he echoes, the balloon the only notation (recommended, "sem partitura no HUD"), or kept?
7. Near an untaught teacher only the phrase can be played (recommended; placements avoid puzzles), or every song too (a second judge beside the echo)?
8. Cadence: 0.55 s per note on approach, again every 4 s while he has not started, 0.75 s per note after a mistake (recommended)?
9. After the half: one phrase per draw near it (recommended), or repeating while the Memorina stays out?
10. A sword swing passes through a teacher with no reaction (recommended: no flinch art exists), or a flinch clip drawn later?

## User decisions (2026-10-29)

1. Places: "The plan's picks (Recommended)": snail on the fishing village deck (7,8), thrush on the woodpile by the woods bench (25,6), kestrel on the windy gap's east ledge (38,8), lizard in the caldera's bench pit (17,44).
2. Voices: "Memorina, an octave up (Recommended)": each teacher sings the Memorina's four notes an octave higher; no new sounds.
3. Sheet: "Hide it (Recommended)": while an echo is open, Ivo's own note sheet does not show; only the balloon does.
4. The rest: "Accept (Recommended)": near an untaught teacher only its phrase can be played; 0.55 s per note, a repeat every 4 s, 0.75 s per note after a mistake; after learning, one phrase per draw near it; a sword swing passes through a teacher with no reaction.

## As built (2026-10-29)

Every Build order step is in, with these differences:

- **`TeachingFlow` inputs.** Added `note_sung(index)`: the teacher forwards `PhraseCall.note_sounded`, so a glyph is revealed when its note actually sounds rather than on a second clock. `learned(ok)` answers `learn_requested`; on a refusal the teacher also reopens a fresh echo (the finished one ignores every note).
- **The balloon's API.** `show_for(anchor, notes, lit_as_sung)` carries the taught mode; `light(count)` reveals all three first; `is_lit(i)` is exposed for tests. A teacher touches the balloon only while `speaker()` is its own anchor.
- **The duet closes the balloon** before `learn_requested`, so the lesson never shows it; a plain half closes it after `flourish_linger`.
- **Placement rule.** "No song puzzle in reach" is checked in `room_files_test` as no `P G L T H F D V O`, freezable water, rain reach or shell reach within 4 cells either side and 3 rows of the feet cell (the reach rect in cells).
- **Positions.** Region origins are 0 in `game.tscn`; the feet in the table above are exact. The thrush's bench (30,8) is 160 px east of its feet, outside the 128 px reach; Ivo is in reach from col 27 (one cell east of the woodpile).
- **Reach kits: modelled.** `ReachMilestone.first_halves` / `second_halves`, `is_half()`, `ReachKit.player_data()` teaching through `SongHalves.teach`, and `ReachKits.next` letting half milestones ride with the milestone a kit grows by. The first try (Redoma's book in `woods_root_caves_alcove`, riding with the woods kit) found no trap and no unreachable slot, songbook or teacher, but the `lake` kit lost 11 rooms: the whole Caldera (sun stair, long corridor, bait, temple gate, cistern bottom, chimney base, open crater, dry moat, seesaw, arena) and orchard_cliff_chimney, because `caldera_cistern`'s way down needs Redoma on the slab (row 8, col 12) to dry the passage (cols 11-12, rows 11-12) and Redoma's second half lay behind the woods root wall (Enraizar). The user moved the book (2026-10-29: "Move the Redoma book (Recommended)", "Approve the swap (Recommended)"): Redoma's songbook is now in `woods_hut_letter` (room woods_hut, reached by the memorina kit with no song) and Bento's letter in `woods_root_caves_alcove`. `half_bell_jar_second` (room woods_hut) rides with the memorina milestone; the other seven with their region's guardian. The lake kit gets out of the Caldera again; against the kits before the change no kit loses a room and none has a pocket (`room_kit_test`, `room_reach_test` green). The plan's whole-song list was wrong for `orchards` (Chuva and Redoma whole) and `caldera` (all four); with the move, `lake` and `lake_caldera` also hold Redoma whole.
- **No new text, no new ALWAYS node, no `NoticeHold` change**, as planned.
