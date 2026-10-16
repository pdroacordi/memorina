---
id: architecture/cutscenes-are-data-played-between-two-rest-states
type: architecture
title: Cutscenes are data played between two rest states - a Resource step tree run by a CutsceneDirector, scene-only actors handed over from FactStaging, SCENE_SEEN as the record (STORY-15)
status: active
tags: [cutscene, story, staging, save-fact, actor, camera, letterbox, dialogue, beat, skip, plan, story-15]
related: [architecture/the-opening-is-staged-by-save-facts, architecture/dialogue-is-data-and-choices-are-save-facts, architecture/props-and-ambient-life, architecture/character-controller-input-split, architecture/animation-driver-resolver-pattern, architecture/pause-menu-worldfreeze-reuse, systems/story, systems/dialogue, systems/animation, systems/songs-and-the-memorina, systems/guardians, systems/input, systems/life-benches-death, systems/props, systems/screens, systems/greyhush, bugs/a-beat-that-ends-resumes-the-talk-without-the-start-gates, bugs/the-canvas-passes-draw-one-frame-behind-a-camera-zoom-tween, gotchas/a-removed-subtree-emits-tree-exiting-later-siblings-first, gotchas/a-killed-tween-never-emits-finished, gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, gotchas/animationtree-reset-track-overwrites-script-writes, gotchas/a-tween-runs-after-every-process-so-a-process-mirror-is-a-frame-late, gotchas/gdunit-await-millis-never-resumes-while-the-tree-is-paused, gotchas/a-typed-array-of-an-inner-class-is-refused-from-another-script]
created: 2026-10-16
updated: 2026-10-16
source_files:
  - resources/cutscene/
  - scenes/world/cutscene/
  - scenes/characters/story_actor/
  - scenes/characters/components/scripted_controller.gd
  - scenes/world/environment/props/fact_staging.gd
  - scenes/characters/ivo/player.gd
  - scenes/world/camera.gd
  - scenes/ui/lesson_cinematic/lesson_cinematic.gd
  - scenes/world/dialogue/dialogue_director.gd
  - resources/save_facts/save_fact.gd
  - globals/player_data.gd
---

> **Status: BUILT** (2026-10-16, STORY-15; the contract is `systems/cutscenes`, the run `playtests/2026-10-16-story15-cutscenes`). Planned 2026-10-16. Direction: `docs/design/06_cinematica_e_experiencia.md` Pilar 1 ("Precisamos trabalhar com mais elementos cinemáticos. E basicamente fazer uma engine cinematica aqui.", user, 2026-10-15). The user's answers to the questions are at the end; what was built differently follows them.

## Context

Doc 06 §2: `FactStaging` swaps still poses by save facts, so nobody walks, turns or lowers their eyes, the camera never moves, and the failed song passes unmarked (playtest points 8, 9, 11, 12). Pilar 1 asks for scenes as a Resource timeline, real characters as actors, Ivo driven by a scene controller, the pausable scaled clock, no new `WorldFreeze` writer, skip and speed-up, and `FactStaging` kept for the rest state. Constraints from the contracts: `FactStaging` is the only writer of its children's visibility (`systems/story`); a talk blocks Ivo like the map and `PlayerInput.blocked` has one owner (`systems/dialogue`); the resolver owns clip names (`systems/animation`); villagers were rejected as `Character`s because a character never freezes in the grey (`architecture/props-and-ambient-life`), and only a `GreyhushShield` puts a body in the creature pass; three input readers only (`systems/input`).

## Options considered

**Timeline shape.** (a) Tracks with absolute times per actor: arrival of a physics walk varies, so times drift. (b) Fire-and-forget steps plus join steps: skip must chase loose tasks. (c) **Chosen:** a tree: a scene is a sequence; `CutsceneTogether` runs its children at once and ends when all end; `CutsceneBranch` runs the first `CutsceneCase` whose `when`/`unless` hold, read when reached (the `DialogueSet.current` idiom). Steps are transitions; what they set (frame, bars, poses) holds until a later step or the scene's end.

**Targets.** (a) NodePaths in a `.tres`: a Resource has no owner to resolve them. (b) A cast dictionary on the host node: splits the scene's data across files. (c) **Chosen:** ids looked up by group inside the host's contents scene (`host.owner`), like `DialogueBeat.find`: `StoryActor.actor_id`, `CutsceneMark.mark_id`, `CutsceneVisual.visual_id`, and the reserved `&"ivo"`. Scoping to the host's contents keeps neighbour rooms' ids apart; a test resolves every id.

**Actors.** (a) The actor is also the rest state (FactStaging places one body at marks): a second position writer, every rest still re-keyed as clips, and rest idles on the scaled clock, against `props-and-ambient-life` ("a Character never freezes"). (b) Tweened sprites: float over ground, no grass, no velocity. (c) **Chosen: hand-over.** A `StoryActor extends Character` exists only during a scene. On its first step it covers its `FactStaging` (`stands_for`), appears on the shown child's feet facing its `flip_h`, starting in the gesture named like that child (`Standing` → `standing`). At the scene's end the staging uncovers on its new stage at once and the actor hides. Rest stays props on the memory clock; a scene animates on the scaled clock, as `StagedStrip` already does. No `GreyhushShield`, so it is greyed in the root canvas like the prop it replaces. Walks are physics (`LocomotionComponent` + `ScriptedController`, the `Enemy`/`AIController` shape), so Ivo and actors share one path.

**Ivo.** (a) An override axis inside `PlayerInput`: mixes the human's reader with script. (b) **Chosen:** `Player.drive(controller: CharacterController)`; `move_axis()` reads the driver when set. `PlayerInput.blocked` becomes derived in one `_refresh_block()`: talk (when `_in_talk`) else scene else map, so a talk inside a scene owns the block and a NOTES beat still gets its notes.

**Talks inside scenes.** (a) A scene-only line API on the box: a second driver of `DialogueBox`. (b) **Chosen:** `CutsceneTalk` runs a `DialogueSet` through `DialogueDirector.start_dialogue(dialogue, at)` (the Talkable path becomes a caller of it), so lines, choices, grants, heard and cues are unchanged. A talk step waits for `talk_ended`; `wait = false` is allowed only as the last step (the hand-off: the scene ends, the talk goes on).

**Starts.** A talk's cue → **`CutsceneBeat extends DialogueBeat`** (hold STILL; it asks `CutsceneDirector.find(tree).play(scene, self)` and `finish()`es at the end). A room entry → **`CutsceneTrigger`** (`cutscene`, `when`, `unless`, `delay`), armed by `Game.room_changed` (the `RegionTitleWatcher` precedent), started when `Player.can_begin_scene()` holds. A Talkable → a dialogue whose first line is a cue. Another scene → a branch or a shared sub-sequence `.tres`. One scene at a time; no scene inside a talk inside a scene (`play` refuses; validated). Beats, triggers and marks are contents-scene nodes, not legend entities (the `Beats` precedent); an area trigger, if ever needed, is a legend entity.

**Record.** (a) Reuse DIALOGUE_HEARD: a scene with no talk records nothing, and a beat-scene ends before its talk's END. (b) **Chosen:** `SaveFact.Kind.SCENE_SEEN` (appended), `PlayerData.scenes_seen: Array[StringName]`, live data like `dialogues_heard` (a bench commits, a death forgets), written by the director at the scene's end or skip, before uncovering. The rest stage after a scene reads its SCENE_SEEN, which is what makes the hand-over a cut.

**Camera.** (a) `frame_pair`/`push_in`: an x-only blend about the subject, and a 45 s lesson zoom. (b) **Chosen:** the camera follows a `CameraRig` Node2D the director tweens on the physics clock (`follow()` already allows a Marker, camera.gd:187), plus a public `GameCamera.zoom_to(z, seconds)` that `focus`/`push_in` keep using through `_tween_zoom`, and `centre_for(subject)` / `rig_point_for(centre)` so the rig starts on the shown frame and returns to Ivo's framed centre before `follow(ivo)`, with no jump. Room clamps still apply: a one-screen interior cannot pan at zoom 1 but can at zoom 2.

**Letterbox.** (a) Calls into `LessonCinematic`: it hides itself outside lessons, so its bars would hide too. (b) **Chosen:** extract `Letterbox` (`scenes/ui/letterbox/`, the two bars, `PAUSE_PROCESS` scaled tweens) as a sibling after `LessonCinematic`; `LessonCinematic` gets it by export, and so does the director.

**Speed.** (a) A faster clock: physics walks speed up only through `Engine.time_scale`, and `WorldFreeze` is its one writer; a scene must not become one. (b) **Chosen for now:** skip lands the whole scene; a talk's box keeps its own complete-then-advance press. A "hurry" is question 2.

**Old beats.** `GuitarBeat` and `StagedBeat` stay `DialogueBeat`s (NOTES routing, stand-ins, pulses); no migration in STORY-15. Content that needs motion uses a `CutsceneBeat`.

## Decision

- **Data** (`resources/cutscene/`, one `class_name` per file): `Cutscene` (`id`, `steps`, `skippable`), `CutsceneCatalog` (+ `.tres`, `validate()`: unique ids, ids resolvable, no talk inside a Together, `wait = false` only last, one step per subject inside a Together, SCENE_SEEN facts name catalog scenes), `CutsceneStep` (base: `begin(ctx) -> CutsceneTask`, `land(ctx)`, `subjects()`), `CutsceneSequence`, `CutsceneTogether`, `CutsceneBranch`, `CutsceneCase`, and the steps `CutsceneWait`, `CutsceneBars`, `CutsceneCamera` (targets, offset, zoom, seconds), `CutsceneWalk` (actor, mark or x, pace 0..1), `CutsceneFace`, `CutscenePlace`, `CutsceneGesture` (wait for its settle), `CutsceneEmote` (`Emote { ELLIPSIS, NOTE, EXCLAIM }`, glyphs, no text), `CutscenePose` (Ivo, `DialogueBeat.Pose`), `CutsceneTalk`, `CutsceneSound`, `CutsceneMelody` (a `MelodyPlayer`), `CutsceneSilence` (cut scene voices), `CutsceneFade` (`Fade.to_black(seconds)`), `CutsceneShow` (a `CutsceneVisual`'s alpha: the light; no `PointLight2D`). No grant step: items come from talks, skills never from a scene.
- **Runtime** (`scenes/world/cutscene/`): pure `CutsceneRunner` (walks the tree, `next()`, `done(step)`, `to_land()` stops before a talk); `CutsceneTask` / `CutsceneWaitTask` / `CutsceneUntilTask` (`tick(delta) -> bool`, `stop()`), the only three task kinds; `CutsceneContext` (virtual services) with `WorldCutsceneContext`; `CutsceneCast` (lazy entry, `release_all()`); `CutsceneDirector` (`World`, INHERIT, one per world, group-found, ticks in `_physics_process`; exports `camera`, `letterbox`, `fade`, `dialogue`; signals `scene_began`, `scene_ended`, `ivo_driven(controller)`, `ivo_posed(pose)` wired to `Player`; `interrupt()` wired from `Player.hurt` and `fell_into_hazard`); `CameraRig`; `CutsceneBeat`, `CutsceneTrigger`, `CutsceneMark`, `CutsceneVisual`, `EmoteBubble`.
- **Ends.** End or skip: land the remaining steps (skip), `mark_scene_seen`, uncover the stagings, actors leave (`set_deferred` DISABLED), visuals hide, voices stop, bars close, camera returns, `scene_ended`. Drop (hurt, Ivo's room changes): the same restore without the record, so the pre-scene rest (a stand-in included) shows again. Out of the tree (a death's `SceneSwap`): write nothing.
- **Actors** (`scenes/characters/story_actor/`): `StoryActor` (root of each actor scene; collision layer 0, mask ground; inert `Hurtbox`/`Health`; Cast z -10), a per-actor resolver subclass holding its clip consts and `SETTLES` (one-shot → held clip), `ScriptedController` + pure `ArriveMath` (stop by braking distance, settle the last px or less by `teleport`). `FactStaging` gains `cover()` / `uncover()`: while covered it shows nothing and re-picks silently; uncover shows the pick (or a live stand-in) at once.
- **Ivo:** `begin_scene()`, `end_scene()`, `drive()`, `stage_pose()` (shared with `pause_talk`), `can_begin_scene()`, `is_in_story()`. Doors, talks, pickups, benches, the Memorina and the map are refused in a scene; the pause and the notebook hold over it; `NotebookWatcher.is_holding()` reads `is_in_story()`.
- **Skip:** a "Skip scene" pause entry (`PAUSE_SKIP_SCENE`, en and pt_BR) shown while `CutsceneDirector.can_skip()`; it requests, and the director lands on its next unpaused tick.

## The demo: the daughter goes to bed (replaces the InBedTurned cross-fade)

`daughter_song` gains a last cue-only line, cue `daughter_to_bed`, after "…" → `CutsceneBeat` in village_house `Beats` → `resources/cutscene/story/daughter_to_bed.tres`: Together(bars in, camera on daughter+ivo) · gesture `lower_eyes` · wait 0.6 · face away from Ivo · walk to mark `bed_edge` (pace 0.5) · gesture `sit` · wait 0.4 · gesture `lie_down_turned` (settles `in_bed_turned`) · camera on the daughter, zoom 2, 1.2 s · wait 1.5 · end. `Daughter` gains a stage InBedTurned on `seen_daughter_to_bed.tres` beside the heard-`daughter_song` one (old saves). Needs: the `Daughter` staging's children girl-only with feet at `position` (the bed a plain prop; today every standing child carries its own `Bed`, and covering would hide it); a stand-in spot during the song between the bed and Ivo so she walks away from him; art: walk, `lower_eyes`, `sit`, `lie_down_turned` ending on the InBedTurned pixels.

## Build order

1. SCENE_SEEN: `SaveFact`, `PlayerData` (+ migrate), `SaveSystem.is_scene_seen` / `mark_scene_seen`, playtest runner `"scenes_seen"`.
2. Pure: the data classes, `CutsceneRunner`, `ArriveMath`, `CutsceneCatalog.validate`.
3. `FactStaging.cover/uncover`; `ScriptedController`, `StoryActor`, a fixture actor.
4. `Player` (drive, scene gates, `_refresh_block`), `NotebookWatcher`.
5. `GameCamera.zoom_to/centre_for/rig_point_for`, `Letterbox` extraction (lesson unchanged), `Fade` seconds.
6. Director, context, cast, tasks, steps, `CutsceneBeat`, `DialogueDirector.start_dialogue`, `EmoteBubble`; then `CutsceneTrigger`.
7. Skip entry. 8. Demo content and art, playtest. 9. Docs: new `systems/cutscenes` + CLAUDE.md row; story, dialogue, songs pause map (Letterbox, CutsceneDirector, actors, voices INHERIT), screens, props, glossary.

## Tests

Pure: `cutscene_runner_test` (sequence, together, branch read when reached, `to_land` stops before a talk), `arrive_math_test` (no overshoot past 1 px for Ivo's and actors' stats from any start), `cutscene_catalog_test`, `save_fact_test`, `save_system_scene_test` (bench commits, death forgets). Steps against a fake `CutsceneContext` (begin and land each). Nodes: `fact_staging_test` (cover/uncover, no fade, stand-in kept on drop), `story_actor_test` (enters on the child's feet, arrives exactly, leaves disabled), `player_scene_test` (block owners, refusals, driven axis), `camera_test` (rig hand-over and return move < 1 px), `letterbox_test` + LessonCinematic regression, `cutscene_director_test` (end records then uncovers in one frame; skip lands and records; drop restores unrecorded; out-of-tree writes nothing; a hold stops the clock: `gotchas/gdunit-await-millis-never-resumes-while-the-tree-is-paused`), `cutscene_beat_test` (talk resumes), `cutscene_rooms_test` (ids resolve in the host contents; every actor-backed staging child has a gesture), `story_beats_test` counts CutsceneBeat cues. Playtest: `story15_daughter_to_bed.json`, a watched run and a skipped run.

## Consequences and traps

- The hand-over is a cut only if the actor's first and last frames match the rest children pixel for pixel; the actor starts its loop at frame 0 (`AnimationDriver` has no start offset).
- An actor never carries a `GreyhushShield` or an `AmbientMotion` (it asserts no `Character` ancestor); rest sprites never live under an actor.
- Camera rig and zoom tweens run on `TWEEN_PROCESS_PHYSICS` (`bugs/the-canvas-passes-draw-one-frame-behind-a-camera-zoom-tween`); prefer integer close-up zoom (1.5 draws uneven pixels).
- Nothing awaits a tween (`gotchas/a-killed-tween-never-emits-finished`); tasks poll. Actor teleports go through `Character.teleport`; disabling an actor is deferred.
- Letterbox is shared by a lesson and a scene; they cannot overlap (the Memorina is refused in a scene).
- The reach audit cannot read SCENE_SEEN: never gate a way on it without teaching `ReachKit`.
- Ivo has only `run` (192 px/s): a scene walk at pace < 1 slides its feet until he gets a `walk` clip (STORY-16/17).
- STORY-16's opening starts in black while `Game._on_room_entered` fades the first room clear: the trigger's `delay` or a fade step must own that.
- No music system or audio bus exists (`project.godot` has none): "abafar" is question 5.

## Questions for the user

1. Skip: through the pause menu ("Skip scene"), always allowed (Recommended), or a press-twice prompt on screen, or only for scenes seen before?
2. "Pode ser acelerada": no speed-up, skip only (Recommended); a press that completes the current movement step; or a 2x clock, which makes `WorldFreeze` a new time-scale mode and revises "no new WorldFreeze writer".
3. The demo's art: draw the daughter's walk, sit and lie-down now with PixelLab (Recommended), or placeholders until STORY-17.
4. Emote bubbles greyed with the place (Recommended) or in colour like Ivo.
5. A music bus and ducking now, or when music exists (Recommended: later).
6. An actor animates on the scaled clock during a scene even where the place is grey (as the mentor's flute strip does), while its rest pose follows the memory clock (Recommended).

## User decisions (2026-10-16), in their words

- Skip: "Pelo menu de pausa (Recommended)": a "Skip scene" pause-menu entry, always available; the scene lands its end state, records SCENE_SEEN, never chooses for the player.
- Speed-up: "Não, só pular (Recommended)": none; WorldFreeze stays the only time_scale writer.
- Demo art: "Desenhar agora (Recommended)": the daughter's clips drawn now with PixelLab (by the user: `walk`, `lower_eyes`, `sit`, `lie_down`).
- Actors in the grey: "Sim, se movem na cena (Recommended)": during a scene actors animate on the scaled clock even where the place is grey; after, the prop is back and freezes as before.
- Defaults (recommended, not asked; default, 2026-10-16): emote bubbles greyed with the place (question 4); no music bus or ducking until music exists (question 5).

## Built differently

- **Leaf ids, not steps.** `CutsceneRunner.next()` returns leaf ids and `done(id)` takes one, so a shared sub-sequence `.tres` can appear twice in a tree; `step(id)` reads the step.
- **A skip that ends the scene cuts** the bars and the frame back to Ivo at once instead of easing them (the first skipped run eased from the landed zoom-2 close-up, a flash of the end); a natural end still eases over 0.4 s (bars) and 0.8 s (frame).
- **`ArriveMath` settles within 2 px**, not 1: the braking distance includes one step's travel, so a walk stops short by up to about a pixel and a half, and the teleport closes it. The test still holds the overshoot to 1 px.
- **The block's map part survives a talk:** `_refresh_block` blocks during a talk when the talk listens *or* the map is open, so the existing beat test that opens the map over a FREE beat still waits.
- **`Fade.is_black()`** was added so a drop clears a fade the scene left black.
- **The demo's art and layout** follow the user's drawing session: the bed grew to 48x30 and moved against the west wall (x 56); the in-bed children are the `lie_down` clip's last frame on the bed (the old composites `child_bed_asleep`/`child_bed_turned` were deleted); the clip names are `lie_down` (settling `in_bed_turned`), not `lie_down_turned`; the `lie_down` clip plays frames 3..6 so it follows the `sit` crouch, and keys the sprite 12 px up onto the mattress.
- **The stand-in spot between the bed and Ivo** is the existing `Standing` child, moved to x 90; the song's talk was re-centred on HoldingOut (x 84) with `auto_delay` 0 so Ivo stops at its east edge, east of her. With a 0.4 s delay a run carried him 77 px into the zone, often west of her.
- **`CutsceneTalk` names a `DialogueSet`** (its current dialogue is read when reached) and a `speaker` id; `DialogueDirector.start_dialogue(dialogue, at) -> bool`.
- **Triggers are read from the room's contents, not the group** (bugs/a-cutscene-trigger-in-a-first-visited-room-never-arms, found in review): `room_changed` can come in the frame a room's contents are made and before they are added. No `CutsceneTrigger` is placed yet; `cutscene_trigger_test` covers it.
