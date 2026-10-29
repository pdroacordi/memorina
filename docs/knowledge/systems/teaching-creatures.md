---
id: systems/teaching-creatures
type: system
title: "Teaching creatures: four coloured creatures sing a song's first half into a glyph balloon; Ivo echoes it through the Memorina's echo mode and the half is saved with no sheet"
status: active
tags: [core-04, teachers, creatures, songs, memorina, half-songs, echo, balloon, glyphs, greyhush-shield, legend]
related: [architecture/teaching-creatures, architecture/half-songs, systems/songs-and-the-memorina, systems/found-pieces, systems/creatures, systems/greyhush, systems/notices, systems/rooms, systems/input, systems/animation]
created: 2026-10-29
updated: 2026-10-29
source_files:
  - scenes/characters/components/phrase_echo.gd
  - scenes/characters/components/phrase_call.gd
  - scenes/characters/ivo/abilities/memorina_component.gd
  - scenes/characters/ivo/player.gd
  - resources/songs/song_halves.gd
  - resources/world/creatures/creature_lesson.gd
  - resources/world/creatures/snail_lesson.tres
  - resources/world/creatures/thrush_lesson.tres
  - resources/world/creatures/kestrel_lesson.tres
  - resources/world/creatures/lizard_lesson.tres
  - scenes/world/creatures/teaching_creature.gd
  - scenes/world/creatures/teaching_flow.gd
  - scenes/world/creatures/teacher_animation_resolver.gd
  - scenes/world/creatures/snail/snail.tscn
  - scenes/world/creatures/thrush/thrush.tscn
  - scenes/world/creatures/kestrel/kestrel.tscn
  - scenes/world/creatures/lizard/lizard.tscn
  - scenes/ui/teacher_balloon/teacher_balloon.gd
  - scenes/ui/teacher_balloon/teacher_balloon.tscn
  - scenes/ui/memorina_hud/memorina_hud.gd
  - scenes/world/game.tscn
  - resources/world/maps/room_legend.tres
  - resources/world/maps/reach_milestone.gd
  - resources/world/maps/reach_kit.gd
  - resources/world/maps/reach_kits.gd
---

# Teaching creatures (CORE-04)

**Never break:** An open echo is the only judge while it is set: `MemorinaComponent.echo_phrase` bypasses the matcher, and an echo and a guardian's call are exclusive. A teacher's half is saved only through `Player.learn_song_half(song, FIRST, false)`, never inside `receive_note` (the echo is acted on at the teacher's next tick) and never before a duet ends. A teacher has no body, no corruption material (so no unshielded mark) and a SILHOUETTE `GreyhushShield`; it is not an `Enemy`. Its presence is unconditional and what it sings is derived from `SongHalves.can_teach`; nothing about a teacher is recorded.

Plan and options: `architecture/teaching-creatures`. Design: 02 §2 "Criaturas escolhidas".

## User decisions (2026-10-29)

- The flow (design 02 §2, revised by the user, "ok", 2026-10-29): near Ivo the teacher sings three notes into a balloon of the current device's note glyphs; Ivo echoes them on the Memorina; a right note lights its glyph, a wrong one shakes the balloon and it sings again, at no cost. No freeze, no cinematic, no half sheet. On success: a flourish, the half saved, the quill. A half that completes the song: a duet, then the full lesson. Afterwards a draw near it brings the phrase back.
- Places: "The plan's picks (Recommended)": snail on the fishing village deck (7,8), thrush on the woodpile by the woods bench (25,6), kestrel on the windy gap's east ledge (38,8), lizard in the caldera's bench pit (17,44).
- Voices: "Memorina, an octave up (Recommended)": each teacher sings the Memorina's four notes an octave higher; no new sounds.
- Sheet: "Hide it (Recommended)": while an echo is open, Ivo's own note sheet does not show; only the balloon does.
- The rest: "Accept (Recommended)": near an untaught teacher only its phrase can be played; 0.55 s per note, a repeat every 4 s, 0.75 s per note after a mistake; after learning, one phrase per draw near it; a sword swing passes through a teacher with no reaction.

## The four

| Teacher | Song (first half) | Symbol | Room, cell | World feet (px) |
|---|---|---|---|---|
| snail | Redoma, L R L | `U` | `lake_fishing_village` 7,8 | (880, -1632) |
| thrush | Chuva, R R R | `Y` | `woods_edge` 25,6 | (-1744, 224) |
| kestrel | Vendaval, R R L | `K` | `orchard_windy_gap` 38,8 | (-6448, -1632) |
| lizard | Solstício, R D U | `Q` | `caldera_open_crater` 17,44 | (-1360, 2208) |

World feet = room position in its region scene + (32 col + 16, 32 (row + 1)); every region scene sits at the world origin in `game.tscn`.

## How it works

- **`PhraseEcho`** (pure): `feed(note)` returns RIGHT, COMPLETE, WRONG (progress resets) or IGNORED (after completion).
- **Echo mode.** `MemorinaComponent.echo_phrase` (setter rebuilds the `PhraseEcho`; setting the same phrase again is a no-op, so progress survives the teacher's per-tick `open_echo`). While set, `receive_note` takes the echo path: RIGHT → `note_played`; COMPLETE → `note_played`, `phrase_echoed`, stays DRAWN; WRONG → `note_rejected`, `sequence_failed`; IGNORED → nothing. `sheathe` resets the echo; `interrupt` counts echo progress as a buffer. `Player.open_echo(phrase)` (refused while a call is open), `close_echo()`, `is_echo_open()`, `echo_phrase()`; signals `echo_opened`, `echo_closed`, `phrase_echoed`. `open_call` closes an echo. An open echo gates nothing else. Presses still pass `MemorinaVoice.can_play_note()`.
- **`learn_song_half(song, half, sheet := true)`**: closes an open echo after its gates pass; emits `song_half_learned` only when `sheet`. Songbooks and F8 pass the default. The lesson test is `SongHalves.completes(data, song, half)` (`missing == half` or the guessed half).
- **`MemorinaHud`** keeps an `_echoing` flag (`on_echo_opened` / `on_echo_closed`, wired in `game.tscn`): a draw while echoing shows no sheet, and an echo opening on a drawn instrument hides it. The camera still focuses on the draw.
- **`TeachingFlow`** (pure, owns the clock): states AWAY, SINGING, LISTENING, DUET, FLOURISH, TAUGHT_QUIET, TAUGHT_SINGING. Approach: sing after `lead_in` (0.4 s), one glyph revealed per sung note, then LISTENING; no echo note for `repeat_after` (4 s) sings again; a right note while it sings cuts the phrase and lights the glyphs to the count; a wrong note shakes and unlights, and at `sequence_reset` (the mistake heard out) it sings again at `retry_interval` (0.75 s). Echo complete: a plain half asks to learn at once, then flourishes with all glyphs lit and closes after `flourish_linger` (1.2 s); a completing half duets (`DUET_LEAD_IN` 0.5 s so Ivo's last note rings out), closes the balloon, then asks to learn (the lesson). A refusal sings again. Out of reach or busy (talk, scene, lesson) it stops and closes; an interrupted duet teaches nothing. Taught: silent until a draw in reach, then one phrase with glyphs lit as they sound, closed after `after_linger` (2 s).
- **`TeachingCreature`** (Node2D, pausable, glue only): finds Ivo by `Player.GROUP`, feeds `set_near(lesson.reaches(...))`, `set_busy(is_in_story() or is_in_lesson())`, ticks the flow, faces Ivo while near (flips `Sprite2D.scale.x`; the art faces west and no clip keys scale). Teachable = `SongHalves.can_teach(data, song, FIRST)`, read at `_ready` and on `SaveSystem.progress_changed`. The echo is open exactly while Ivo is in reach of an untaught teacher. Ivo's `note_played`, `sequence_failed` and `sequence_reset` count only while the echo is this teacher's; `phrase_echoed` is recorded and acted on at the next tick. A refused learn reopens a fresh echo (the finished one ignores every note). A sheathe while the echo is its own calls `TeachingFlow.echo_cleared()` (count 0, glyphs unlit, repeat clock restarted; `bugs/a-sheathe-mid-echo-leaves-the-teachers-balloon-ahead-of-the-instrument`). When its processing stops (`NOTIFICATION_DISABLED`, a room idling; `NOTIFICATION_EXIT_TREE`) it closes its balloon and Ivo's echo (`bugs/a-teacher-whose-room-idles-leaves-ivos-echo-open`).
- **`CreatureLesson`** (one `.tres` per teacher): `song`, the cadence above, `reach` Rect2(-128, -96, 256, 192) px from the feet (edges inclusive). `phrase()` slices the song's first `HALF_LENGTH` notes; it is never stored twice. `TeachingCreature.TAUGHT_HALF` is FIRST.
- **Species scenes** (`scenes/world/creatures/<name>/<name>.tscn`): `Sprite2D` (no material), a flat `AnimationTree` (`idle` loop 6 fps, `sing` loop 8 fps, `flourish` one-shot 8 fps; no transitions), `AnimationDriver`, the shared `TeacherAnimationResolver` (consts IDLE, SING, FLOURISH: flourish held via `holding()`, sing while a phrase sounds, else idle), `GreyhushShield` (SILHOUETTE, CIRCLE over the body, `amount` 1.0), `BalloonAnchor`, and two `PhraseCall`s: `Call` (its `Voice` a `MemorinaVoice` with the Memorina notes, `pitch_scale` 2.0) and `Duet` (Ivo's pitch, 1.0). No Hurtbox, Hitbox or body.
- **`PhraseCall`** (`scenes/characters/components/`, renamed from `GuardianCall`): plays a phrase on `note_interval` and reports `note_sounded(index)` and `finished`. Guardians and teachers use it.
- **`TeacherBalloon`** (one, `game.tscn`'s `CanvasLayer` after `GuardianCallHud`, group `teacher_balloons`, `find(tree)`): `show_for(anchor, notes, lit_as_sung)`, `reveal`, `reveal_all`, `light(count)`, `shake` (0.3 s, 2 px), `close(linger)`, `speaker()`. Paper box and tail in `EmoteBubble.PAPER`, three 16 px glyphs from `glyph_sets[InputDevice.glyph_set]`, re-textured on `InputDevice.device_changed`. An unlit glyph is drawn at alpha 0.4 and a lit one at full strength, so the difference reads at true scale. The box is clamped inside the viewport (2 px margin); the tail moves along the box to keep pointing at the teacher (`playtests/2026-10-29-core04-teaching-creatures`). Follows the anchor through the canvas transform in `_process`, rounded; hides itself when the anchor is freed or hidden. A teacher touches the balloon only while it is the speaker. Tweens are bound to it (pausable, scaled); `close` kills the shake and puts it home.

## Pause, notices, notation

- Nothing joins the ALWAYS list: teacher, phrase players and balloon inherit PAUSABLE (`systems/songs-and-the-memorina`).
- No `NoticeHold` change: a plain half saves at the flourish and the quill announces it; the duet saves nothing; the completing lesson is held by `is_in_lesson()`.
- No new text: the balloon is glyphs; the quill and the lesson reuse existing keys.

## Placement rules (`room_files_test`)

Each teacher symbol once in the world, in its room; on air over a floor; no song puzzle (`P G L T H F D V O`, freezable water, rain or shell reach) within 4 cells either side and 3 rows (an open echo admits only the phrase). Teachers' rooms hold no corrupted creature (`NO_CREATURE_ROOMS`). `room_kit_test.test_no_teacher_needs_its_own_song`: some kit without the song reaches each teacher.

## Reach kits

`ReachMilestone.first_halves` / `second_halves` (taught through `SongHalves.teach` in `ReachKit.player_data()`); `is_half()` milestones ride along with the milestone a kit grows by (`ReachKits.next`). Eight half milestones: `half_{bell_jar,rain,gale,solstice}_first` in the teachers' rooms and the songbooks' `half_*_second` (woods_hut, lake_shore, caldera_seesaw, orchard_ridge). Each rides with its region's guardian milestone, except Redoma's book in woods_hut, which needs no song and rides with the memorina milestone. The guardians give only their first songs. Whole halved songs per kit: lake and lake_caldera Redoma; both, both_caldera and orchards Chuva and Redoma; woods_orchards_caldera Vendaval and Solstício; caldera all four; the others none. Against the previous kits no kit loses a room and no trap appears (2026-10-29).

## Tests

`phrase_echo_test`, `song_halves_test.test_completes_per_state`, `creature_lesson_test`, `teaching_flow_test`, `memorina_component_test` (echo section), `player_echo_test`, `memorina_hud_test`, `teacher_balloon_test`, `teaching_creature_test` (real Ivo: echo, wrong note, duet then lesson, rewound half, sheathe mid-echo, idled room, freed teacher), `teacher_sheet_test`, `room_files_test` (teachers), `room_kit_test.test_no_teacher_needs_its_own_song`, `reach_kits_test` (halves).
