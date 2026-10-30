---
id: architecture/guardian-performance-and-talks
type: architecture
title: Guardian performance clips and talks (GRD-08 + STORY-18) - lucid_enter, play_song, relapse and a deep perform as resolver states; barks derived from the fight in a world balloon; a restoration scene through a CutscenePerformer; a Talkable composed into the guardian, all keyed by a GuardianVoice resource
status: accepted
tags: [grd-08, story-18, guardian, animation, resolver, lucidity, relapse, lesson, cutscene, performer, dialogue, bark, balloon, talkable, save-fact, plan]
related: [systems/guardians, systems/animation, systems/dialogue, systems/story, systems/cutscenes, systems/songs-and-the-memorina, systems/teaching-creatures, systems/notices, architecture/guardian-fight-phase-machine, architecture/animation-driver-resolver-pattern, architecture/cutscenes-are-data-played-between-two-rest-states, architecture/dialogue-is-data-and-choices-are-save-facts, architecture/teaching-creatures, architecture/pause-menu-worldfreeze-reuse, gotchas/a-freeze-stops-the-resolver-but-not-ivos-always-animation-tree, gotchas/animationtree-reset-track-overwrites-script-writes, bugs/the-lucidity-leap-lands-outside-the-frame-so-its-land-clip-is-not-seen, bugs/lesson-title-card-survives-a-cut-fade, features/lucidity-leap, features/encounter-sheet-slot]
created: 2026-10-30
updated: 2026-10-30
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/guardians/guardian_animation_resolver.gd
  - scenes/characters/guardians/guardian_fight.gd
  - resources/characters/guardians/guardian_stats.gd
  - scenes/world/cutscene/cutscene_director.gd
  - scenes/world/cutscene/cutscene_cast.gd
  - scenes/world/interactables/talkable/talkable.gd
  - scenes/ui/teacher_balloon/teacher_balloon.gd
---

# Guardian performance clips and talks (GRD-08 + STORY-18)

**Status: accepted** (2026-10-30; built the same day, see "What was built" at the end, which overrides the Decision where they differ). User, 2026-10-29: "Deve haver uma animação de tocando a música (tanto para o momento de ensinamento, quanto uma mais profunda para a cutscene), animações de lucidez e caída de volta à loucura, possibilidade de conversar com os guardiões após lucidez restaurada, e até conversas entre os momentos de lucidez e ensinamento. Isso para todos os guardiões". Four questions are open (end); the Decision states the recommended answers.

## Context

- A guardian is a scene plus `GuardianStats`, never a subclass (`systems/guardians`); autumn and summer come with GRD-04, so every clip, line and scene must be per-guardian data and a test must fail when a guardian lacks one.
- Today: after the opening blow `lucid` loops for ~0.65 s of `lucidity_delay` (1 s), then `leap_crouch`; the call plays `lucid` with a scripted bob; RELAPSE plays `hurt` then `idle`; the lesson and RESTORED play `restored`. Bloom restores in 2 answers, Frost in 3; `relapse_time` 1.4 s, 0.84 s after a failure.
- The lesson is a performance freeze (tree paused, scale 1). The guardian is pausable, so its resolver stops; a clip chosen before the freeze keeps playing only if its `AnimationTree` is ALWAYS (`gotchas/a-freeze-stops-the-resolver-but-not-ivos-always-animation-tree`).
- A talk blocks Ivo and is refused while `Guardian.fight_at` holds (`_free_for_up`); the answer window needs his notes; design 02 §3 says the lucid window runs "sem pausa do mundo". So no talk can run during a fight, and no box can show in the lesson's freeze.
- A cutscene can gesture only a `StoryActor`, which covers a `FactStaging` and has no `GreyhushShield`. A guardian is a live `Character` with a shield and no staging.
- A restored guardian stands where its last leap landed, so a `t` in the arena's `.room` cannot sit on it. Restoration, heard talks and seen scenes are all live data: a death before a bench rewinds them together.
- Design 05 rule 3: no line says "grey", "forget", "memory", "season" or "guardian". 01 §10 leaves the mentor's identity and the guardians' names open; no guardian line may settle them.

## Options considered

1. **Playing clips.** (a) One `play_song` loop for the call and the lesson, plus a deeper `perform` for a short scene after the lesson. Chosen. (b) The deep clip in the lesson and the short one only in the calls, with no scene. Cheaper, but the user named a "cutscene" separately from the teaching moment, and the lesson is Ivo's performance, not a scene (open question 1). (c) A clip per call note. Rejected: the scripted bob already accents each note.
2. **Lines during the fight.** (a) A blocking talk in the lucid window. Rejected: it pauses the fight and needs a `WorldFreeze` writer or a new block. (b) The line in `GuardianCallHud`'s message in place of "Listen…". It adds no text surface (the offscreen elder's precedent), but reads as a caption and fights the instruction. (c) A non-blocking word balloon over the guardian, shown in a longer lucid pause before it sings and closed at its first note. Chosen: it is speech, and the user's own word for the teachers' balloon. It never overlaps listening or answering (open question 3).
3. **How a scene moves a live guardian.** (a) A `StoryActor` stand-in. Rejected: it needs a staging to cover, and it would lose the guardian's colour. (b) The guardian plays its own beat and starts the talk itself. Rejected: no letterbox, no skip, no SCENE_SEEN, and a second sequencer. (c) A `CutscenePerformer` component that a scene addresses by id, with a `CutscenePerform` step. Chosen: any live character can join a scene this way, and the director stays the only sequencer.
4. **Starting the scene.** (a) The guardian calls `play()` at `performance_finished`. Rejected: `LessonCinematic` still owns the shared `Letterbox` while it closes. (b) A `CutsceneTrigger` inside the guardian scene: armed on room entry as today, plus a new `CutsceneDirector.arm(trigger)` at the lesson's end. It plays once Ivo `can_begin_scene()` and the letterbox is closed. Chosen: a dropped scene replays on the next entry for free.
5. **Where talks attach.** (a) A legend `t` in the arena. Rejected: the guardian moves. (b) A `Talkable` child of the guardian scene, so the zone follows the body. Chosen.
6. **Where the words live.** (a) Exports on the scene. (b) A `GuardianVoice` resource on `GuardianStats.voice`. Chosen: one object per guardian holds its speaker, barks, scene and talks, and GRD-04 adds a `.tres`.

## Decision

**GRD-08: clips** (all `const`s in `GuardianAnimationResolver`; scripts never name a clip):

| Clip | Kind | Plays when | Replaces |
|---|---|---|---|
| `lucid_enter` | one-shot, settles to `lucid` | `Guardian.just_lucid()` pulse at `_open_lucidity`, during `lucidity_delay` | the `lucid` loop before the crouch |
| `lucid` (kept) | loop | LUCIDITY: from the landing through the lucid pause, and the answer window | - |
| `play_song` | loop | `is_sounding()` (`PhraseCall` from its first note to `finished`) and `is_teaching()` (`_restore` to the lesson's `performance_finished`) | `lucid` + bob in the call; `restored` in the lesson |
| `relapse` | one-shot, settles to `idle` | `relapse_began()` pulse at `_begin_relapse` | `hurt` in RELAPSE (the `_just_hit = true` hack goes) |
| `perform`, `perform_end` | loop, then one-shot settling to `restored` | `performance_cue()` set by a `CutscenePerformer` request; the guardian sounds `stats.song.notes` on its own `Call` voice (an octave down) | - |
| `restored` (kept) | loop | rest, talks | - |

**Resolver priority:**
1. leap clips;
2. `performance_cue()` (PERFORM while sounding, then PERFORM_END held);
3. `is_teaching()` → PLAY_SONG;
4. the phase: RESTORED; LUCIDITY (LUCID_ENTER held, then PLAY_SONG while sounding, else LUCID); RELAPSE (RELAPSE held, else IDLE);
5. the pressure chain, unchanged.

**The lesson.** `_restore` connects `Player.performance_started`/`finished` (one-shot) to put `$AnimationTree` ALWAYS, then back to INHERIT. This is a new line in the pause-mode map (`systems/songs-and-the-memorina`). PLAY_SONG is a loop with no intro, picked during `lesson_lead_in` (0.5 s).

**Startup asserts.** `_assert_clip_durations` adds `lucid_enter <= lucidity_delay - leap_crouch` and `relapse <= relapse_time * FAILED_RELAPSE_SCALE`.

**Art contracts** (`tools/art/prompts/guardian_<bloom|frost>_<clip>.md`, the GRD-07 sheet rules: body centred, facing left, same palette; continuity frames: `lucid_enter` ends on `lucid` frame 0, `relapse` on `idle` frame 0, `perform_end` on `restored` frame 0):

| Clip | Bloom (128x96, feet row 95) | Frost (192x128, feet row 127) |
|---|---|---|
| lucid_enter | 4 f x 0.15 = 0.6 s (limit 0.7) | 4 f x 0.15 = 0.6 s (limit 0.64) |
| play_song | 6 f x 0.15, loop | 6 f x 0.15, loop |
| relapse | 5 f x 0.15 = 0.75 s (limit 0.84) | 5 f x 0.15 = 0.75 s (limit 0.84) |
| perform | 8 f x 0.2, loop | 8 f x 0.2, loop |
| perform_end | 4 f x 0.2 = 0.8 s | 4 f x 0.2 = 0.8 s |

Plus the portraits `portrait_guardian_<name>.md`: a 48-art-px bust of the restored face (`dialogue_catalog_test` wants a portrait for every speaker).

**STORY-18: data.** `GuardianVoice` (Resource, `resources/characters/guardians/guardian_voice.gd`):
- `speaker` (plate `SPEAKER_GUARDIAN_<ID>`, portrait);
- `lucid_barks: Array[String]` (one key per cure step, size = `cycles_to_restore`);
- `retry_bark` (said instead after a failed answer);
- `restored_scene: Cutscene` (id `guardian_<id>_restored`);
- `talks: DialogueSet`.

`GuardianStats.voice`. Nothing about barks is recorded: the key is `lucid_barks[cycles()]`, or `retry_bark` when `relapse_failed()` and `aggression() > 0`.

**Nodes per guardian scene:**
- `GuardianTalks` (Node, pausable; glue only, never reads `Input`): assigns `Talkable.talk = voice.talks`, says barks, and arms the trigger.
- `Talkable`: speaker_offset 0; reach = half body + 48 (Bloom 64, Frost 82); `height_cells` 2.
- `BarkAnchor` (Marker2D at head height).
- `CutscenePerformer`: Node2D at the feet, group `cutscene_performers`, `performer_id` `guardian_<id>`. It emits `perform_requested(cue)` and offers `mark_settled()`, `is_settled()` and `land(cue)`.
- `CutsceneTrigger`: `cutscene` = `voice.restored_scene`; `when` GUARDIAN_RESTORED <id>; `unless` SCENE_SEEN `guardian_<id>_restored` and DIALOGUE_HEARD `guardian_<id>_first`.

`Guardian` stays word-free and gains only signals: `lucid_landed(cycle, after_failure)`, `call_note_sung(index)`, `call_ended()` and `lesson_closed()`.

**Barks (STORY-18 a).** One `BarkBalloon` in `game.tscn`'s CanvasLayer, after `TeacherBalloon`:
- INHERIT; group `bark_balloons`, `find(tree)` like `TeacherBalloon`.
- `say(anchor, key)` and `close()`; text through `tr()`, at most 2 rows; the paper of `EmoteBubble.PAPER`; the 2x rule.
- Tweens bound to it, pausable and scaled; no event reader. `~stutter~` marks are stripped (`StutterText.parse`).
- It sits beside the head on the side away from Ivo, clamped to the viewport and clear of the encounter slot. Extract the pure `BalloonPlacement` (clamp and tail) that `TeacherBalloon` already does, and share it.

Timing: it opens on `lucid_landed` and closes on the first `call_note_sung` or on `call_ended` (a hit, a walk-out, an abandon). `call_lead_in` rises 0.7 → 2.2 s in both `.tres` files, so the line is read before the phrase. That time is free (contact is off outside PRESSURE) and the answer window is unchanged. No `WorldFreeze` writer, input reader, router screen or talk.

**At the lesson (b).** No line in the lesson: it is a freeze, and the box never shows in one. The last cure step's bark is the line before it. On `lesson_closed`, `GuardianTalks` calls `CutsceneDirector.arm(trigger)`. The director plays an armed trigger once Ivo `can_begin_scene()` and `letterbox.shown() == 0`, a new gate that also covers room entry. The scene `guardian_<id>_restored`, skippable:
1. Together(bars 0.6 s, camera on `ivo` + `guardian_<id>` at zoom 2);
2. `CutscenePerform(guardian_<id>, deep)`, which waits for `is_settled`;
3. `CutsceneTalk(voice.talks, wait = false)`, the set's current talk, `guardian_<id>_first`.

`CutsceneCast` finds performers and answers their `point_of`. The trigger's owner is the guardian scene, so the scene's ids resolve there (`_scope_of`). `CutsceneCatalog.validate` and `cutscene_rooms_test` check every perform cue against `GuardianAnimationResolver.performances()`. A drop restores unrecorded and the trigger re-arms on the next entry. A skip lands before the talk.

**After restoration (c).** `voice.talks` is one set, in priority order:
- `guardian_<id>_first` (once; `when` GUARDIAN_RESTORED <id>; `zoom` 2);
- `guardian_<id>_again` (repeatable; `when` restored + first heard; `LineVariant`s on GUARDIANS_RESTORED_AT_LEAST 2 and ALL_GUARDIANS_RESTORED).

Up to talk under the usual gates; the prompt hides while there is no current talk (the fight). No `FactStaging`: the guardian's pose is derived from `restored_guardians` (`restore_silently`), so the scene's end (`perform_end` → `restored`) is the rest. Death rewinds restored, heard and seen together.

**Node / Resource / Autoload.**
- Resources: `GuardianVoice`, `CutscenePerform`, the sets and the scenes. They are per-guardian data.
- Nodes: `GuardianTalks`, `CutscenePerformer`, `BarkBalloon`. Each is behaviour of one instance.
- No autoload: the balloon is found by group, as `TeacherBalloon` is.

**SOLID.**
- Single responsibility: `Guardian` fights and emits; `GuardianTalks` speaks; `BarkBalloon` draws.
- Open/Closed: a new guardian is a `GuardianVoice` and strips, not a branch. `CutscenePerformer` lets any live character join a scene without touching `StoryActor`.
- Liskov: the resolver keeps its contract for every guardian scene.
- Interface segregation: a separate `CutscenePerform` step, not a widened `CutsceneGesture`.
- Dependency inversion: the director depends on the performer's small interface, not on `Guardian`.

**i18n.** Every key is in `i18n/translations.csv` (en, pt_BR):
- `SPEAKER_GUARDIAN_<ID>`;
- `BARK_GUARDIAN_<ID>_LUCID_<N>` and `BARK_GUARDIAN_<ID>_RETRY`;
- `DLG_GUARDIAN_<ID>_FIRST_<NN>`, `DLG_GUARDIAN_<ID>_AGAIN_<NN>[_V<k>]` and `DLG_CHOICE_GUARDIAN_<ID>_*`.

A new `bark_text_fit_test` covers barks; `dialogue_text_fit_test` covers the talks.

## Consequences

- GRD-04 must add each new guardian's five strips, portrait, `GuardianVoice`, scene and talks. `guardian_voice_test` fails until it does: every `GuardianStats` has a voice, barks = `cycles_to_restore`, its set and scene are in the catalogs, and every resolver clip is in each guardian's tree.
- The lucid moment grows by 1.5 s per window. Playtest the pacing. The bark placement depends on GRD-09's framing at the landing, so decide GRD-09 first.
- Order: answers and text approval → GRD-09 call → art contracts and generation → resolver, guardian pulses and asserts (placeholder strips allowed) → `CutscenePerformer`/`arm` → `GuardianVoice`, `GuardianTalks`, `BarkBalloon`, data and keys → playtest both guardians → systems entries (guardians, animation, cutscenes, dialogue, songs' pause map).
- Tests:
  - `guardian_performance_animation_test`: each clip at its moment, after a success and after a failure; the tree ALWAYS only during the lesson.
  - `guardian_talks_test`: bark per cycle and retry, closed on the first note and on abandon, nothing saved.
  - `bark_balloon_test`: placement clear of the slot.
  - `cutscene_steps_test`: perform and land.
  - `cutscene_director_test`: `arm` waits for the letterbox.
  - `guardian_talk_rooms_test`: the talk zone keeps more than 22 px from every arena door zone at the spawn point and inside the leap margin.
  - Plus `guardian_voice_test` and the fit tests.
- Risks:
  - a quill or notice can slide in between the lesson's end and the scene and be withdrawn (allowed by `systems/notices`);
  - the bob and `play_song` can double-accent a note (playtest);
  - Bloom's notebook body still describes the pack art ("Two flower heads").

## User decisions (2026-10-30)

1. Cutscene: "Dentro da própria lição". The deep `perform` clip plays during the lesson itself (the tree is ALWAYS for the lesson, so the clip runs through the freeze); the short `play_song` stays in the fight's calls. No restoration scene: `CutscenePerformer`, `CutscenePerform`, `CutsceneDirector.arm` and the `guardian_<id>_restored` trigger are dropped. The first talk is the guardian's `Talkable` (Up), current from GUARDIAN_RESTORED.
2. Music: "Uma flauta da sua estação". Each guardian holds a pipe of its season's material (Bloom: blossoming wood; Frost: ice), echoing the Memorina's flute; the art contracts draw it in `play_song` and `perform`.
3. Lines in the fight: "Balão no mundo (Recommended)", as planned (`BarkBalloon`, `call_lead_in` 0.7 -> 2.2 s).
4. Gesture: "Sim, um por guardião (Recommended)". One HOLD/LET gesture in each first talk, feeding STORY-07's tally.

## What was built (2026-10-30)

The user decisions above, implemented; the systems entry is `systems/guardians` ("Performance clips", "Talks").

- **Resolver.** Priority: leap clips; `is_teaching()` → `perform`; RESTORED (`perform_end` right after `perform`, then `restored`); LUCIDITY (`driver.sequence(lucid_enter, lucid)` while the leap is pending, `play_song` while `is_sounding()`, else `lucid`); RELAPSE (`driver.sequence(relapse, idle)`); the pressure chain. Departure: no `just_lucid()` / `relapse_began()` / `performance_cue()` pulses. Each one-shot is derived from state the guardian already has, so nothing must be cleared after the resolve, and `Character` gained no hook.
- **The lesson.** `_restore` sets `_teaching` and connects `performance_started` → tree ALWAYS, `performance_finished` → INHERIT, `_teaching` off and unstage (one-shot). `is_teaching()` also reads `Player.is_in_lesson()`, so a lead-in cut short still ends `perform`. Dropped as decided: `CutscenePerformer`, `CutscenePerform`, `CutsceneDirector.arm`, the restored trigger and scene. No `lesson_closed` signal: nothing listens for it now.
- **Signals.** `Guardian` gained `lucid_landed(cycle, after_failure)`, `call_note_sung(index)` and `call_ended`. `after_failure` is `GuardianFight.relapse_failed()` (false before the first window).
- **Barks.** `GuardianVoice` without `restored_scene`. `GuardianTalks` (glue) and `BarkBalloon` as planned; placement is `BalloonPlacement.beside` (pure, art px), clear of `GuardianCallHud.slot_rect()`. `TeacherBalloon` uses `BalloonPlacement.above` and `tail_x`.
- **Talks.** `Talkable` per guardian scene. Departure: `height_cells` Bloom 4 and Frost 6 (the plan said 2), so the Up prompt stands over the head instead of on the chest. Each first talk ends in one HOLD/LET gesture (asking line with text, two toned choices with a reply each).
- **Not built:** `cutscene_steps_test` and the `cutscene_director_test` case (no cutscene). The landing framing (GRD-09) is still open, so the bark's placement is unverified in play.
