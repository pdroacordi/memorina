---
id: systems/cutscenes
type: system
title: Cutscenes: a Resource step tree played by a CutsceneDirector between two rest states, scene-only actors handed over from FactStaging, SCENE_SEEN as the record
status: active
tags: [cutscene, story, staging, save-fact, actor, camera, letterbox, dialogue, beat, skip, story-15]
related: [architecture/cutscenes-are-data-played-between-two-rest-states, bugs/a-cutscene-trigger-in-a-first-visited-room-never-arms, playtests/2026-10-16-story15-cutscenes, systems/story, systems/dialogue, systems/animation, systems/songs-and-the-memorina, systems/guardians, systems/input, systems/life-benches-death, systems/props, systems/screens, gotchas/a-killed-tween-never-emits-finished, gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, gotchas/gdunit-await-millis-never-resumes-while-the-tree-is-paused, bugs/the-canvas-passes-draw-one-frame-behind-a-camera-zoom-tween]
created: 2026-10-16
updated: 2026-10-16
source_files:
  - resources/cutscene/
  - resources/cutscene/story/daughter_to_bed.tres
  - resources/cutscene/cutscene_catalog.tres
  - scenes/world/cutscene/
  - scenes/characters/story_actor/
  - scenes/characters/components/scripted_controller.gd
  - scenes/characters/components/arrive_math.gd
  - scenes/world/environment/props/fact_staging.gd
  - scenes/characters/ivo/player.gd
  - scenes/world/camera.gd
  - scenes/world/fade.gd
  - scenes/ui/letterbox/
  - scenes/ui/lesson_cinematic/lesson_cinematic.gd
  - scenes/ui/pause_menu/pause_menu.gd
  - scenes/ui/screens/screens.gd
  - scenes/world/dialogue/dialogue_director.gd
  - resources/save_facts/save_fact.gd
  - resources/save_facts/seen_daughter_to_bed.tres
  - globals/player_data.gd
  - globals/save_system.gd
---

# Cutscenes

**Never break:** A scene is data played between two rest states: `FactStaging` stays the only writer of its children's visibility and the rest after a scene is derived from `SCENE_SEEN`, written before the stagings uncover in the same frame. A `StoryActor` exists only during a scene, never carries a `GreyhushShield` or an `AmbientMotion`, and moves only through `Character.teleport` and its `ScriptedController`. The director runs on the pausable, scaled physics clock, writes nothing to `WorldFreeze`, reads no input, and writes nothing once it is out of the tree. A skip lands the scene and never chooses for the player: it stops before a talk. `PlayerInput.blocked` has one writer, `Player._refresh_block()`: a talk, else a scene, else the map.

## Summary

STORY-15, built 2026-10-16 from the plan `architecture/cutscenes-are-data-played-between-two-rest-states` (doc 06 Pilar 1). A `Cutscene` is a tree of steps (`resources/cutscene/`); the pure `CutsceneRunner` walks it; `World/CutsceneDirector` begins each leaf step, polls the task it returns, and ends the scene. Actors are `StoryActor` scenes in a contents scene's `Cast`; marks and visuals live beside them. A scene starts from a talk's cue (`CutsceneBeat`) or a room entry (`CutsceneTrigger`). The demo is the daughter going to bed after the failed song.

## Data (`resources/cutscene/`, one `class_name` per file)

- `Cutscene`: `id` (the SCENE_SEEN id), `steps`, `skippable`. `CutsceneCatalog` (`cutscene_catalog.tres`) lists them; `validate()` names duplicate or empty ids, a talk inside a `CutsceneTogether`, a talk with `wait = false` that is not the scene's last step, two steps of one together moving the same subject, and a SCENE_SEEN fact naming no catalog scene. The director asserts it in debug builds.
- Containers: `CutsceneSequence`, `CutsceneTogether` (all at once, ends with the last), `CutsceneBranch` + `CutsceneCase` (`when`/`unless`; the first case that holds plays, read when reached).
- `CutsceneStep`: `begin(context) -> CutsceneTask`, `land(context)` (the end state at once), `subjects()`, `names()` (the ids that must resolve). Leaves: `CutsceneWait`, `CutsceneBars`, `CutsceneCamera` (`targets`, `offset` from their mean feet, `zoom` 0 keeps, `seconds`), `CutsceneWalk` (`actor`, `mark` or `x`, `pace` 0..1), `CutsceneFace` (`toward`, `away`, or `side`), `CutscenePlace`, `CutsceneGesture` (`clip`, `wait` for its settle), `CutsceneEmote` (`Emote { ELLIPSIS, NOTE, EXCLAIM }`), `CutscenePose` (Ivo, `DialogueBeat.Pose`), `CutsceneTalk` (`talk` set, `speaker`, `wait`), `CutsceneSound`, `CutsceneMelody`, `CutsceneSilence`, `CutsceneFade`, `CutsceneShow` (a `CutsceneVisual`'s alpha). No grant step: items come from talks, skills never from a scene.
- Ids: `StoryActor.actor_id`, `CutsceneMark.mark_id`, `CutsceneVisual.visual_id`, and `&"ivo"`; found by group inside the host's contents scene (`host.owner`), so neighbour rooms' ids stay apart (`CutsceneCast.find_in`).

## Runtime (`scenes/world/cutscene/`)

- **`CutsceneRunner`** (pure): `next()` returns the leaf ids to begin now, `done(id)` ends one, `is_finished()`, `to_land()` ends every running leaf and every leaf up to the next `CutsceneTalk` and returns them in order. Ids, not steps, so one step resource can appear twice.
- **Tasks**, the only three kinds: `CutsceneTask` (over at once), `CutsceneWaitTask` (scaled seconds), `CutsceneUntilTask` (polls a Callable, `on_stop`). Nothing awaits a tween.
- **`CutsceneContext`** (virtual services) and **`WorldCutsceneContext`**: `point_of`, `walk`, `place`, `face`, `gesture`, `land_gesture`, `emote`, `pose`, `bars`, `frame`, `talk`, `sound`, `melody`, `silence`, `fade`, `show_visual`; `restore(clear_fade, cut)` undoes all but the record. **`CutsceneCast`**: an actor enters on its first step (`actor(id)`); `point_of` an actor that has not entered reads its rest child; `release_all()` uncovers every staging, then the actors leave.
- **`CutsceneDirector`** (`World/CutsceneDirector`, INHERIT, group `cutscene_directors`, `find(tree)`): exports `catalog`, `ivo`, `camera`, `letterbox`, `fade`, `dialogue`; signals `scene_began`, `scene_ended`, `ivo_driven(controller)`, `ivo_posed(pose)`. `play(scene, host) -> bool` refuses while a scene plays, so no scene runs inside a talk inside a scene. Each physics tick: a requested skip, the tasks, then up to 256 newly reached leaves begun (an instant step costs no frame).
  - **End:** SCENE_SEEN (`SaveSystem.mark_scene_seen`), then `restore`: stagings uncover, actors leave (process disabled deferred), visuals reset, voices and bubbles stop, the bars close (0.4 s), Ivo's driver and pose are released; the frame eases back to Ivo over 0.8 s and `follow(ivo)`.
  - **Skip** (`request_skip()`, only while `can_skip()`: skippable and no talk step running): lands on its next unpaused tick. If that ends the scene, the bars and the frame cut back at once (a skip is a cut already).
  - **Drop** (`interrupt()` from `Player.hurt` and `fell_into_hazard`; `on_room_changed` when the host is not in the new room's contents): the same restore without the record, and a fade the scene left black is cleared; the rest shown before (a stand-in included) shows again.
  - **Out of the tree** (a death's `SceneSwap`): `_exit_tree` forgets the scene and writes nothing.
- **`CameraRig`**: the Node2D the camera follows during a scene; it moves on `TWEEN_PROCESS_PHYSICS`. The first camera step places it on the shown frame (`GameCamera.rig_point_for(shown_centre())`) before `follow(rig)`, so the take-over does not move the frame.
- **`CutsceneBeat`** (`extends DialogueBeat`, hold STILL, asserted in `start()` and checked by `cutscene_rooms_test`): its `start()` asks the director to play `cutscene` and `finish()`es on `scene_ended`, so the talk resumes under the start gates. A refused play finishes at once with an error.
- **`CutsceneTrigger`** (contents scene; `cutscene`, `when`, `unless`, `delay`, `repeat`): `Game.room_changed` → `CutsceneDirector.on_room_changed` arms the room's first trigger whose gates hold and whose scene is unseen, read from `room.contents()` and not the tree's group, because contents made on this visit are added deferred (bugs/a-cutscene-trigger-in-a-first-visited-room-never-arms). Its `delay` counts once it is inside the tree, and it plays once `Player.can_begin_scene()`. Leaving the room disarms it. None is placed yet (`cutscene_trigger_test`).
- **`CutsceneMark`** (Marker2D), **`CutsceneVisual`** (hidden at rest; children are its picture; no `PointLight2D`), **`EmoteBubble`** (a word-less bubble drawn in the world at 2x, so it greys with the place; it follows its target on the pausable clock).

## Actors (`scenes/characters/story_actor/`)

- `StoryActor extends Character`: collision layer 0, mask ground; an inert `Hurtbox` (layer 0) and `Health`; `Controller` (`ScriptedController`) and `Locomotion`. Hidden and DISABLED at rest. `enter()` teleports onto its staging's shown child, faces the child's `flip_h`, asks the clip named like the child (`Standing` → `standing`), covers the staging and shows itself; `leave()` hides it and disables it deferred.
- **`StoryAnimationResolver`**: the walk clip while walking; else the clip asked, held on its settle clip once a one-shot ends (`settles()`); `is_settled()`. A walk asks the idle clip, so a one-shot never replays after it. Each actor's subclass owns its clip consts (`systems/animation`).
- **`ScriptedController`** + pure **`ArriveMath`**: brake when the braking distance plus one step reaches the gap; within `SETTLE_PX` (2) the walk is over and the body teleports onto the mark. `arrive_math_test` walks Ivo's and the daughter's locomotion from 3 to 400 px at three paces: never more than 1 px past.
- Actors are in the root canvas (no `GreyhushShield`), greyed like the props they stand for, and animate on the scaled clock even where the place is grey (user, below); the rest pose after the scene is a prop again and follows the memory clock.
- `cutscene_rooms_test`: every staging child an actor stands for has a clip of the same snake name.

## Ivo

- `Player.begin_scene()` / `end_scene()` (wired from the director's signals), `drive(ScriptedController)` (`move_axis()` reads the driver; `_steer_driver` teleports onto the mark on arrival), `stage_pose(pose)` (shared with `pause_talk`), `can_begin_scene()`, `is_in_story()` (talk or scene), `is_in_scene()`.
- **The block is derived** (`_refresh_block`): in a talk, the talk's listening (or the map); else in a scene, blocked; else the map. `block_input` / `unblock_input` set the map's part only. So a NOTES beat inside a scene still gets its notes, and a scene ending under the map leaves him blocked.
- In a scene, doors, talks, pickups, benches, the Memorina and the map are refused (`is_in_story()`); the pause and the notebook hold over it; `NotebookWatcher.is_holding()` reads `is_in_story()`.
- Ivo has only `run` (192 px/s): a scene walk at pace < 1 slides his feet until he gets a `walk` clip (STORY-16/17).

## Camera, letterbox, fade

- `GameCamera.zoom_to(z, seconds)` (0 cuts; `focus`/`push_in` keep `_tween_zoom`), `shown_centre()`, `centre_for(subject)` (its feet, look-ahead and current framing), `rig_point_for(centre)`. Following a marker freezes the offset (a running look-ahead tween is killed). Room clamps still apply: a one-screen interior cannot pan at zoom 1 but can at 2 (`camera_rig_test`).
- `Letterbox` (`scenes/ui/letterbox/`, `CanvasLayer/Letterbox` after `LessonCinematic`, ALWAYS, scaled PAUSE_PROCESS tweens): `open(seconds)`, `close(seconds)`, `is_open()`, `shown()`. `LessonCinematic.letterbox` uses it; a lesson and a scene never overlap (the Memorina is refused in a scene).
- `Fade.to_black(seconds)` / `to_clear(seconds)` (0.5 by default; 0 cuts), `is_black()`.

## Skip

`PauseMenu` has a hidden `SkipScene` entry ("Skip scene" / "Pular cena", `PAUSE_SKIP_SCENE`) between Resume and Quit to title; `open()` shows it when `can_skip` (set by `Game._ready` to `CutsceneDirector.can_skip` through `Screens.set_scene_skip`) answers true, and the box grows by one entry. Pressing it emits `Screens.skip_scene_requested` (→ `CutsceneDirector.request_skip`) and closes the menu.

## Save

`SaveFact.Kind.SCENE_SEEN` (appended; `id` is the scene id). `PlayerData.scenes_seen: Array[StringName]`; old saves load empty. `SaveSystem.is_scene_seen` / `mark_scene_seen` (emits `progress_changed`). Live data like heard: a bench commits it, a death forgets it. The playtest runner's `"scenes_seen": [ids]` seeds it. The reach audit cannot read SCENE_SEEN: never gate a way on it without teaching `ReachKit`.

## The demo: the daughter goes to bed

- `daughter_song` (`resources/dialogue/story/daughter_near.tres`) ends with a cue-only line, cue `daughter_to_bed`, after "…" on either answer → `Beats/DaughterToBed` (`CutsceneBeat`) in village_house → `resources/cutscene/story/daughter_to_bed.tres`: Together(bars in 0.6 s, camera on daughter + Ivo at zoom 1, 0.8 s) · `lower_eyes` · wait 0.6 · face away from Ivo · walk to mark `bed_edge` (pace 0.5) · `sit` · wait 0.4 · `lie_down` (settles `in_bed_turned`) · camera on the daughter (offset (0, -24)), zoom 2, 1.2 s · wait 1.5. About 7.8 s.
- `Daughter` gains a stage InBedTurned on `resources/save_facts/seen_daughter_to_bed.tres`, above the heard-`daughter_song` one (old saves).
- **The house's layout for it** (STORY-15; the bed is now 48x30 game px, recut by the user from the approved house props sheet):
  - `Props/ChildBed` is a plain prop at x 56 (32..80, against the west wall), always shown; the `Daughter` staging's children are the girl only, each a `Sprite2D` whose position is her feet: Asleep and InBedTurned (x 58: `lie_down.png` frame 6 of 7, flipped so her head is on the pillow, offset (-32, -74), i.e. 12 px up on the mattress), HoldingOut (x 84), Standing (x 90), AtGuitar (x 290).
  - `Marks/BedEdge` (x 58) is where she sits and lies down; the actor's last frame lands exactly on the in-bed children.
  - The song's talk (col 3) is centred on her at x 84 (`speaker_offset` -28, `reach_west` 60, `reach_east` 21: 81 px, 23 px short of the door) with `auto_delay` 0, so Ivo stops at its east edge (x ≈ 107), east of her: she turns her back on him and walks west to the bed. The bed's talk (col 2, Up) is centred on her in bed at x 58 (`reach_west` 26, `reach_east` 40).
- **The actor** (`scenes/characters/story_actor/daughter/daughter_actor.tscn`, `DaughterAnimationResolver`, `resources/characters/story/daughter_locomotion_stats.tres`: 64 px/s, so pace 0.5 is 32 px/s):
  - rest clips from the existing art: `standing` (8 frames ping-pong at 6 fps, as its `AmbientMotion`), `holding_out` (offset (-26, -62) keyed), `at_guitar` (offset (-18, -40)), `asleep` and `in_bed_turned` (`lie_down` frame 6, sprite position (0, -12) keyed);
  - the user's PixelLab clips (64x64, facing east, feet on row 61; contracts `tools/art/prompts/story_daughter_{walk,lower_eyes,sit,lie_down}.md`): `walk` (6 frames, loop, 8 fps), `lower_eyes` (5, one-shot 8 fps, held on `eyes_lowered`), `sit` (7, one-shot 8 fps, held on `seated`; a low crouch in front of the bed's middle), `lie_down` (frames 3..6 at 6 fps, from her kneel so it follows the crouch, rising 0/4/10/12 px onto the mattress; held on `in_bed_turned`). Every clip keys texture, hframes, frame, offset and position; RESET is `standing`.
- The old pre-painted composites `child_bed_asleep.png` / `child_bed_turned.png` and their contracts are gone (the coordinator, 2026-10-16): the 11 px bed hid her head.

## User decisions (2026-10-16), in their words

- Skip: "Pelo menu de pausa (Recommended)": a "Skip scene" pause-menu entry, always available; the scene lands its end state, records SCENE_SEEN, never chooses for the player.
- Speed-up: "Não, só pular (Recommended)": none; WorldFreeze stays the only time_scale writer.
- Demo art: "Desenhar agora (Recommended)": the daughter's clips drawn now with PixelLab (by the user).
- Actors in the grey: "Sim, se movem na cena (Recommended)": during a scene actors animate on the scaled clock even where the place is grey; after, the prop is back and freezes as before.

Defaults (recommended, not asked; default, 2026-10-16):
- Emote bubbles are greyed with the place.
- No music bus or ducking until music exists.

## Limits

- The hand-over is a cut only if the actor's first and last frames match the rest children; an actor starts its loop at frame 0 (`AnimationDriver` has no start offset), so entering on an idle loop can pop by one frame of breath.
- The camera's close-up on the daughter is clamped by the room: at zoom 2 the frame's centre stops at x 160, so she sits near its left edge.
- During the song Ivo stands about 23 px east of her, his sprite overlapping hers a little: the room between the wall and the door is 96 px for a 48 px bed, her and him.
- STORY-16's opening starts in black while `Game._on_room_entered` fades the first room clear: the trigger's `delay` or a fade step must own that.

## Tests

`tests/scenes/world/cutscene/cutscene_runner_test.gd`, `cutscene_director_test.gd` (end records then uncovers in one frame; skip lands and records; drop restores unrecorded; one scene at a time; bars close; out-of-tree writes nothing; a hold stops the clock), `cutscene_beat_test.gd` (the talk resumes and is heard), `cutscene_rooms_test.gd` (ids resolve in the host's contents, every gesture is a clip of its actor's resolver, a beat holds STILL and its scene holds no talk, every staging child an actor stands for has a clip, catalog and rooms agree), `cutscene_trigger_test.gd` (first-visited, door-arrival and resident rooms, delay and Ivo's gates, no replay, disarm, room-change drop), `camera_rig_test.gd`; `tests/resources/cutscene/cutscene_catalog_test.gd`, `cutscene_steps_test.gd` (each step against a recording context, begin and land), `cutscene_fixture.gd`; `tests/scenes/characters/components/arrive_math_test.gd`; `tests/scenes/characters/story_actor/story_actor_test.gd`; `tests/scenes/characters/ivo/player_scene_test.gd`; `tests/scenes/ui/letterbox/letterbox_test.gd` (with the LessonCinematic regression); `tests/globals/save_system_scene_test.gd`; additions to `fact_staging_test` (cover, uncover, stand-in kept), `opening_test` (the in-bed composite, the seen stage) and `screens_test` (the Skip scene entry). Playtests: `tools/playtest/scripts/story15_daughter_to_bed.json` (watched) and `story15_daughter_to_bed_skip.json` (skipped; `"clock": "real"`), report `playtests/2026-10-16-story15-cutscenes`.
