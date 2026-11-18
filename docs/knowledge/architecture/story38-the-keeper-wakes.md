---
id: architecture/story38-the-keeper-wakes
type: architecture
title: STORY-38 plan - the final battle opens with the still keeper waking; a cutscene between two rest states whose SCENE_SEEN hands the keeper's staging over to the guardian body's FactPresence, and the body's ArenaTrigger re-entering the space with Ivo inside begins the fight
status: active
tags: [story-38, story, mentor, lighthouse, lantern, staging, save-fact, presence, cutscene, guardian, finale, fight-wall, plan]
related: [architecture/story34-mentor-at-the-lantern, architecture/grd-06-final-battle, architecture/cutscenes-are-data-played-between-two-rest-states, architecture/the-opening-is-staged-by-save-facts, systems/guardians, systems/cutscenes, systems/story, systems/songs-and-the-memorina, systems/life-benches-death, systems/music, systems/rooms, gotchas/an-area2d-emits-body-exited-when-disabled-or-removed, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move, gotchas/a-killed-tween-never-emits-finished, bugs/a-swordless-ivo-spends-the-arena-trigger-so-the-fight-never-starts-on-return, bugs/the-kit-check-counts-a-guardian-arena-as-an-exit-before-the-guardian-exists]
created: 2026-11-17
updated: 2026-11-17
source_files:
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
  - scenes/world/rooms/frost_edge/contents/lighthouse_top.room
  - scenes/characters/components/fact_presence.gd
  - scenes/characters/components/player_proximity_trigger.gd
  - scenes/characters/guardians/guardian.gd
  - scenes/world/environment/props/fact_staging.gd
  - scenes/world/cutscene/cutscene_trigger.gd
  - scenes/world/interactables/fight_wall/fight_wall.gd
  - resources/cutscene/story/mentor_turns.tres
  - resources/cutscene/cutscene_catalog.tres
  - globals/save_system.gd
  - tools/maps/gen_world_shells.py
---

# STORY-38 plan: the keeper wakes

**Status: BUILT** (2026-11-17; "Built" below). Roadmap STORY-38. The user's feedback on STORY-34: "a luta poderia demorar um pouquinho pra começar para o jogador poder assimilar o que está acontecendo. ele não espera encontrar o guardião que antes ele conversava agora agressivo" (2026-11-17); asked what comes before the final fight: "Cena de despertar (Recommended)". Ivo comes up the hatch and finds the still keeper at the lamp (not the guardian body); as he nears: silence, the slow turn (the opening's), the grey cracking on him, the flute raised wrongly, about 3 s; only then the grey walls close and the fight begins. This replaces STORY-34's Q8 default (the body standing there and the fight starting as Ivo comes up). Design 05 gives the final battle no words before the barks (§ "O mentor na luta final"); the scene is wordless.

## Context (what exists, commit a997a5ec)

- `lighthouse_top_contents.tscn`: `Props/Mentor` (`mentor_staging`, z -10) with stages, first that holds: **Gone** (`all_guardians_restored`, fade 0), **Stasis** (DIALOGUE_HEARD `mentor_gift`, 1.5 s, `stasis.png` flipped: facing east, toward the hatch), **Holding** (SCENE_SEEN `mentor_turns`), **AtLamp** (default, facing west). Children AtLamp, Holding, EmptyHand, Stasis, Turning (`turn.png`, 6 f at 6 fps, ends exactly on Holding, the Memorina in his hand), Playing.
- `MentorGuardian` at (720, 672), `cutscene_id` `mentor`, with a `FactPresence` child `when = [all_guardians_restored]`: absent, hidden and DISABLED. Its `ArenaTrigger` (radius 560: the whole lantern) is `stays_open` since STORY-33 and `close()`d only in `_on_player_entered` once a fight begins. Its `Sprite2D` is at (0, -96), scale (-2, 2); body radius 18.
- `FactStaging._on_progress_changed` switches at once; `FactPresence._on_progress_changed` applies **deferred** (`apply.call_deferred()`).
- The fight starts in `Guardian._on_player_entered` (DORMANT only, armed Ivo only) on the trigger's `body_entered`. `GuardianMusic` starts the fight cue when the fight leaves DORMANT (`systems/music`).
- An `Area2D` that is disabled and enabled again emits `body_entered` for a body already inside (`gotchas/an-area2d-emits-body-exited-when-disabled-or-removed`).
- **The lantern has no `FightWall`.** GRD-06 decided none was needed: `Player` refuses Up on a door while `Guardian.fight_at` holds. The hatch is the door at 30,20 (`hatch_down`, a floor hatch), and the floor row 21 is solid; one `.room` cell holds one entity.
- `SaveSystem.restore_world()` commits the whole live save at once, so a SCENE_SEEN written before the victory is kept by it. A death rewinds to the last commit: SCENE_SEEN is live data.
- The keeper gave the Memorina to Ivo; every mentor guardian clip plays an **absent** flute (`guardian_mentor_play_song.md`: "his hand stays empty").
- Frost Edge sits at 0.05 (design 04): the staging props draw in the root canvas, greyed by the place; the body draws under its own `GreyhushShield`.

## Options considered

**1. What holds the fight back while the scene plays** (the question that decides the rest).
- (a) **The body is absent until the scene is seen.** `FactPresence.when = [all_guardians_restored, seen_mentor_wakes]`. Until the record nothing of the guardian is in the physics space, so no trigger, contact or hurtbox can start anything. When the scene's end writes SCENE_SEEN, the presence turns the body on (deferred) with Ivo standing inside its `ArenaTrigger`. The trigger fires `body_entered` again (the gotcha above), and `_on_player_entered` begins the fight the ordinary way. `Guardian`, `GuardianFight` and `PlayerProximityTrigger` gain no code.
- (b) **A gate on `Guardian`** (refuse `_on_player_entered` while `Player.is_in_scene()`, as STORY-33 refuses an unarmed Ivo). After the scene Ivo is still inside the 560 px trigger and nothing enters again, so the fight would wait until he left the radius and came back. That is the bug STORY-33 fixed (`bugs/a-swordless-ivo-spends-the-arena-trigger-so-the-fight-never-starts-on-return`). It would need a poll in `_after_move`, plus a visible body during the scene beside the still keeper, so two mentors.
- (c) **Order the triggers** (the scene's zone fires before the arena's). The arena trigger covers the whole room, so the scene cannot come first unless the radius shrinks, and the body would still stand there during the scene.
- (d) **The body is the actor**: an AWAKENING phase in `GuardianFight` and clips in `GuardianAnimationResolver`, with the still handed over to the body at the scene's start. This changes the pure fight and the shared resolver for one encounter, and a cutscene cannot play a body's clips (gestures are an actor's). Rejected.
- **Chosen: (a).** No guardian code, and one writer of each visibility (`FactStaging` for the keeper's children, `FactPresence` for the body). The fight starts by the existing engine contract.

**2. A death mid-fight.**
- (a) **The awakening plays again on every attempt.** SCENE_SEEN `mentor_wakes` is live data: the death forgets it, and on return the keeper stands still at the lamp again. Nothing new is recorded. The scene is about 3.5 s and skippable from the pause menu ("Pular cena"), and a retry already costs the climb from the Frost Cliffs bench and the helix.
- (b) **Once per save, kept through death**, like `finale_revealed`. `SaveLedger.commit`/`rewind` would need a keep rule for one scene id, or a new `PlayerData` bool plus a `SaveFact` kind. A retry then finds the body standing and the fight starting as Ivo comes up, which is the STORY-34 behaviour the user disliked for the first meeting.
- **Recommended: (a)** (Q2). It is derived, it needs no save change, and it is short. "Death forgets" stays true of the keeper too.

**3. The grey walls the user expects to close.**
- (a) **Move the hatch to the east wall and stand a standard `FightWall` beside it.** `lighthouse_top.room` hatch 30,20 → **36,20** (x 1152..1184, the last air column). `I` at **35,20** (`cells` 4) is the column at the room's edge, as in every arena (`docs/maps/README.md`, `I`). The `Arena` is trimmed to x 0..1152 (centre (576, 384), size (1152, 768)), so a leap (margin 96) lands at x 1056 or less, west of the wall (x 1120..1152), and the wall's anchor (x 1136) stays inside the arena for `FightWall.closes`. The wall closes only once Ivo's body is clear of it, which the zone below guarantees.
- (b) **No wall**, as GRD-06 built it: the hatch refuses Up during the fight, and nothing closes on screen.
- (c) **The hatch shows its sealed frame while a fight is on.** `Door` would learn `Guardian.fight_at`, a door rule that only one room needs.
- (d) **A `FightWall` lid over the hatch:** impossible as data. The door owns 30,20, and an `I` in floor row 21 would turn a solid cell into air.
- **Recommended: (a)** (Q3). It is the existing vocabulary and the picture the user described. The cost is one `.room` edit, the generator tuple and the arena's shape.

**4. The keeper's pose on arrival.**
- (a) **Back at the lamp, facing it, in the stasis grey** (a new stage `Waiting` → child `StillAtLamp`), so the opening's picture and turn replay: "a mesma virada da abertura". Between the visits he has turned back to his post, which is itself the first sign that something moved.
- (b) **As Ivo left him:** Stasis, turned toward the hatch. Ivo sees his face from the hatch, so there is no turn and the awakening is only the crack and the raise.
- **Recommended: (a)** (Q1). The user asked for the same turn, and that needs his back to Ivo.

**5. How the scene starts.** A `CutsceneTrigger` with a `zone` (the flashback crossings' pattern) catches Ivo as he nears. Starting on room entry with a `delay` would play while he still stands on the hatch, about 250 to 430 px away. **Chosen: the zone**, full room height so it cannot be jumped over, spanning the floor between the keeper and the hatch. The scene walks Ivo the last steps to `ivo_stand` at pace 0.4, like `mentor_approach`. That also puts him 104 px from the body when the fight begins, outside its 18 px contact.

## Decision

### The lantern's staging (one writer each)

| Priority | Stage | When | Shows | Fade |
|---|---|---|---|---|
| 0 | Gone | `all_guardians_restored.tres`, new `seen_mentor_wakes.tres` | nothing: the body stands there | 0 |
| 1 | **Waiting** (new) | `all_guardians_restored.tres` | **StillAtLamp** (new child, grey, facing west, empty hand raised to the lamp) | 0 |
| 2 | Stasis | DIALOGUE_HEARD `mentor_gift` | Stasis | 1.5 |
| 3 | Holding | SCENE_SEEN `mentor_turns` | Holding | 0 |
| 4 | AtLamp | default | AtLamp | 0 |

- New children: **StillAtLamp** (Sprite2D), **StillTurning** (`StagedStrip`, intro `still_turn`, ends on Stasis exactly), **Cracking** (`StagedStrip`, intro `wake_crack`), and **RaisingWrong** (`StagedStrip`, intro `wake_raise`, uneven per-frame durations in its `SpriteFrames`, ending exactly on the guardian's idle frame 0 drawn as the body draws it at (720, 672): sprite at (0, -96), scale (-2, 2), facing east).
- `MentorGuardian/FactPresence.when = [all_guardians_restored.tres, seen_mentor_wakes.tres]`.
- Gone and the presence now share **two** facts. On the record, `FactStaging` cuts to Gone in the same physics tick and `FactPresence` applies at the deferred flush that ends that tick, before the frame is drawn. So the last strip frame and the body's first frame never overlap and never leave a gap. A test pins it (below).
- **The STORY-34 rule "the presence never flips while Ivo is in the lantern" is revised.** It flips once, at the awakening's recorded end, with Ivo inside on purpose. Turning on is safe: deferred, never inside the body's own physics step (`gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move` concerns turning off). The only explicit process mode under the body is the lesson's `AnimationTree` → ALWAYS, which an absent body never has (`gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor`).
- A death that rewinds the awakening shows Waiting and takes the body away again: both are derived.

### The scene `mentor_wakes` (`resources/cutscene/story/mentor_wakes.tres`, catalog, skippable)

Actor-free, data only. Timings are a starting point to tune in the playtest; the user's "about 3 s" is the turn, crack and raise (2.5 s).

1. Together: `CutsceneBars` in (0.6 s) · `CutsceneMusic` with an inline stream-less `MusicCue` `mentor_wakes_silence` (the `flashback_3_silence` pattern; fade 1.0 s) · `CutsceneCamera` targets `[ivo, mentor_home]` at the lantern talk's zoom (1.5, `mentor.tres`) and its raised offset, 1.0 s · `CutsceneWalk ivo → ivo_stand`, pace 0.4.
2. `CutsceneFace ivo toward mentor_home`.
3. `CutsceneWait` 0.5: the silence.
4. `CutsceneStage mentor_staging → StillTurning`, `CutsceneWait` 1.0 (6 f at 6 fps).
5. `CutsceneStage → Cracking`, `CutsceneWait` 0.7.
6. `CutsceneStage → RaisingWrong`, `CutsceneWait` 0.8.
7. `CutsceneFace mentor toward ivo`: the body, while still absent. `Character.face_towards` writes `flip_h` at once, so its first drawn frame faces Ivo. `CutsceneCast.find_body` resolves the disabled body because it joined `BODY_GROUP` in `_enter_tree`.
8. `CutsceneWait` 0.3, held on the guardian's first frame.

End (director): SCENE_SEEN `mentor_wakes` → Gone + presence → bars close, the silence is released, and the frame eases back to Ivo over 0.8 s. On the next physics step the `ArenaTrigger` sees Ivo, the fight leaves DORMANT, and `GuardianMusic` starts the fight cue out of the silence. Once Ivo is clear of it the `FightWall` closes (Q3 (a)). A skip lands the same end. A drop (hurt or hazard: neither exists in the lantern; doors are refused in a scene) leaves Waiting and no body, and the trigger re-arms on the next entry.

### The trigger

`Triggers/MentorWakes` (`CutsceneTrigger`, before `Triggers/WorldRestoration` in the tree): `cutscene = mentor_wakes.tres`, `when = [all_guardians_restored.tres]`, no `unless`, `delay` 0, `zone` = `Triggers/MentorWakes/Zone` (Area2D, mask 256). Its rect is x 840..1100 (with Q3 (a); x 840..940 if the hatch stays at col 30), y 0..704, so every path from the hatch to the keeper crosses it. No `unless world_restored`: a save that predates STORY-38 and is already restored (dev saves only; nothing has shipped) then plays the awakening once on entry, and the body appears in RESTORED (`_on_player_entered` ignores a non-DORMANT fight). The alternative, a body that never appears in a restored lantern, is worse. Timelines seed `scenes_seen` instead (below).

### What the never-breaks require, and how this meets them

- **No new `WorldFreeze` writer:** the scene uses only waits, stages, a walk, faces, bars, camera and music; nothing slows or pauses.
- **Cutscenes:** the rest after the scene is derived from SCENE_SEEN, written before the stagings uncover in the same frame. `FactStaging` stays the only writer of its children and `FactPresence` the only writer of the body's `visible`/`process_mode`. No actor, no input reader, pausable and scaled, and a skip lands without choosing.
- **Guardians:** `GuardianFight` owns the clock and is untouched; the fight begins only through `_on_player_entered`. A concrete guardian stays a scene plus `GuardianStats`. STORY-33's armed refusal still holds: an unarmed Ivo leaves the trigger open, and the fight starts when he returns armed.
- **Story:** the keeper's pose is derived from save facts; no beat writes visibility.
- **Rooms:** the hatch move and the wall are `.room` text plus the generator tuple; nothing is painted.

## Art

| Beat | Existing art | Gap |
|---|---|---|
| Still at the lamp | `at_lamp.png` (coloured, flute overlay separate), `stasis.png` (the stasis grey, `empty_hand` pose) | `still_at_lamp.png`: the at_lamp pose in the stasis grey, no flute |
| The slow turn | `turn.png` (coloured, the Memorina in hand, ends on Holding) | `still_turn.png`: the same turn in grey, empty hand, ending on `stasis.png` flipped |
| The grey cracks | none (`CutsceneFray` is an actor's edge glitch, not cracks, and the keeper is a prop) | `wake_crack.png`: the stasis grey splitting along the mantle and mask, flakes falling, the guardian's darker corrupted grey showing through |
| Flute raised wrongly | `mentor_guardian_play_song.png` (grey, empty hand at the mask), `raise.png` (coloured, the right way) | `wake_raise.png`: ends on `mentor_guardian_idle.png` frame 0 exactly (the bridge, as "B, com a ponte" did for the turn) |
| The fight | every mentor guardian clip | none |

**Contracts** (`tools/art/prompts/`, our own art as the only references, never pack art; credit in `CREDITS.md`; approval before they ship):
- `story_mentor_still_at_lamp.md`: refs `at_lamp.png`, `stasis.png`, `empty_hand.png`. Method first: measure whether `stasis.png` is a pixel-for-pixel recolour of `empty_hand.png`. If it is, apply that colour map to `at_lamp.png` (a script beside `cut_inhabitant.py`, no generation). Otherwise a Codex still from those three. 86x120, feet on the bottom row, facing west.
- `story_mentor_still_turn.md`: refs `turn.png`, `stasis.png`, `still_at_lamp.png`. The same colour map on `turn.png` with the flute painted out by hand per frame, or PixelLab `animate` from `still_at_lamp` to `stasis` mirrored. 6 frames at 6 fps, offset as `Turning` (-67, -126); last frame = Stasis exactly.
- `story_mentor_wake_crack.md`: refs `stasis.png` (flipped, facing east) and `mentor_guardian_idle.png` frame 0 upscaled 2x nearest. About 5 frames at 8 fps. "Cracks run through the still grey of the hooded figure from the mask down the mantle; small flakes of pale grey break off and fall, showing the darker, mottled grey beneath; he does not move." First frame = Stasis.
- `story_mentor_wake_raise.md`: refs `mentor_guardian_idle.png` frame 0 (2x) and `mentor_guardian_play_song.png`. About 6 frames, held unevenly (0.1 to 0.25 s). "Stiffly lifts his empty hand toward his mask as if holding a flute that is not there; the hand stops at the wrong place, beside the mask, fingers clawed around nothing; a small jerk; the arm drops back." Per Q4. Last frame = idle frame 0 at 2x, facing east.

**Placeholders until approved** (the build ships with these):
- StillAtLamp: `stasis.png` unflipped at (720, 672) (faces west; the pose is not the lamp pose).
- StillTurning: none. The scene cuts to `Stasis` after its 1.0 s wait, as STORY-34's turn placeholder did.
- Cracking: a `GuardianStill` child (Sprite2D, `mentor_guardian_idle.png` frame 0, at (720, 576), scale (-2, 2)) reached by `CutsceneStage … seconds 0.7`: a cross-fade from Stasis to the guardian's grey.
- RaisingWrong: a `StagedStrip` of `mentor_guardian_play_song.png` frames 0, 1, 0, 2 at 2x, uneven durations, plus idle frame 0 last.

**Risk:** the props are greyed by the place (0.05) and the body by its own shield's level, so the bridge frame can differ in tone at the cut. The playtest compares them. If they differ, the strip children take a SILHOUETTE `GreyhushShield`, as the ribbon's `Fluttering` does (`systems/cutscenes`, Flashback 2).

## What changes

| Kind | Change |
|---|---|
| Save fact | New `resources/save_facts/seen_mentor_wakes.tres` (SCENE_SEEN `mentor_wakes`). No new `SaveFact.Kind`, no `PlayerData` field (Q2 (a)). |
| Cutscene | New `mentor_wakes.tres` (+ `cutscene_catalog.tres`). Others unchanged. |
| Contents `lighthouse_top_contents.tscn` | `mentor_staging`: a Waiting stage, the Gone stage on two facts; children StillAtLamp, StillTurning, Cracking (or GuardianStill), RaisingWrong. `MentorGuardian/FactPresence.when` gains `seen_mentor_wakes`. `Triggers/MentorWakes` + `Zone`. With Q3 (a): the `Arena` shape becomes (1152, 768) at (576, 384). |
| Room `lighthouse_top.room` (Q3 (a)) | Hatch 30,20 → 36,20; `I` at 35,20; header comment (the awakening, the wall). |
| Room `lighthouse_interior.room` | None (the interior end of the hatch stays 12,4). |
| Generator (Q3 (a)) | `gen_world_shells.py` `lighthouse_hatch`: col 36 on top. |
| Code | **None.** `Guardian`, `GuardianFight`, `FactPresence`, `FactStaging`, `CutsceneTrigger`, `FightWall` and `PlayerProximityTrigger` stay as they are. |
| Dialogue / i18n | None. The scene has no text, and its skip uses the existing `PAUSE_SKIP_SCENE`. |
| Playtest timelines | `guardian_bot_mentor.json` (it spawns west of the keeper and never crosses the zone) and every timeline that starts in the lantern with the four restored and expects the fight, or that seeds `world_restored`, gains `"scenes_seen": ["mentor_wakes"]`. `story34_four_restored.json`'s note now expects the awakening. New `story38_keeper_wakes.json` and `story38_keeper_wakes_skip.json`. |

## Tests

- `tests/scenes/world/story/opening_test.gd`: the lantern's stage list has five stages. Stasis moves to index 2, so the line reading `stages[1].fade_seconds` 1.5 becomes `stages[2]`. With the four restored the staging shows `StillAtLamp` (was `""`); after SCENE_SEEN `mentor_wakes` it shows nothing. The STORY-34 presence case (hidden and DISABLED before the four) adds: still absent with the four restored and the awakening unseen; present and INHERIT after it.
- **New `tests/scenes/world/story/mentor_wakes_test.gd`** (lantern contents with a `Player` fixture, armed):
  1. With the four restored and the scene unseen: Waiting shows, the body is hidden and DISABLED, and Ivo standing at `ivo_stand` for 10 physics frames leaves the fight DORMANT.
  2. `mark_scene_seen(&"mentor_wakes")` with Ivo inside: after the tick's deferred flush the staging shows nothing and the body is visible and INHERIT, and never both on any frame.
  3. Within 3 physics frames the fight has left DORMANT. This pins the trigger's re-entry `body_entered` that the plan stands on.
  4. Unarmed, the fight stays DORMANT and the trigger stays open; armed again after re-entry, it begins.
  5. A rewind (live SCENE_SEEN not committed) shows Waiting again and removes the body.
  6. The body faces Ivo on its first visible frame.
  7. Every path from the hatch to `mentor_home` crosses the trigger's zone (the zone spans the floor x range between them, full height).
  8. RaisingWrong's last frame is the guardian's idle frame 0 at the body's transform (placeholder included).
- `cutscene_rooms_test` (the scene's ids `ivo`, `mentor_home`, `ivo_stand`, `mentor_staging`, body `mentor` resolve; a trigger's scene counts as started), `cutscene_catalog_test`, `cutscene_trigger_test` (unchanged; the zone pattern is covered), `fact_staging_test` (unchanged).
- With Q3 (a): `fight_wall_test` gains no case but must pass; `room_files_test`, `door_prompts_test`, `village_voices_test.test_no_talk_stands_within_a_body_of_a_door`, `guardian_talk_rooms_test` (the hatch is now farther from both talks and the body's landings; the leap must never land past x 1056, so add the lantern's arena to `guardian_leap_framing_test`'s or `guardian_talk_rooms_test`'s landing sweep), `room_kit_test` (the `memorina` milestone still reaches `lighthouse_top`).
- Unaffected: `guardian_finale_test`, `combat_reach_test` (the bare mentor scene has no presence), `fact_presence_test`.
- Smoke: `lighthouse_top` is already in `tools/smoke/scenes.txt`.

## Build order

1. `seen_mentor_wakes.tres`; `mentor_wakes.tres` with the placeholder stages; catalog. `cutscene_catalog_test`.
2. Lantern contents: the stage list, the placeholder children, the presence's second fact, `Triggers/MentorWakes` + zone. `opening_test` cases, `mentor_wakes_test` (cases 1-8), `cutscene_rooms_test`, smoke.
3. Q3 (a): `.room` hatch → 36,20 and `I` at 35,20, header comment, generator tuple, `--import`, the `Arena` shape; room, door, talk and kit suites.
4. Timelines: seed `scenes_seen` where listed; write `story38_keeper_wakes.json` (seed as `story34_four_restored.json`, come up the hatch, walk west into the zone, screenshots through the scene and the first 3 s of the fight) and the `_skip` variant (`"clock": "real"`, skip from the pause menu).
5. Art (Q5 (a)): the four contracts, the user's approval, generation, cuts; swap the placeholders (StillTurning replaces the cut, Cracking replaces GuardianStill); re-run case 8.
6. Docs (same change as the code): `systems/story` (the lantern's five stages, the awakening, FactPresence's two facts and the revised "never flips with Ivo inside" rule), `systems/cutscenes` (`mentor_wakes`), `systems/guardians` ("The body's presence": absent until the awakening; the fight begins by the trigger's re-entry; the lantern's FightWall if Q3 (a)), `systems/rooms`/`systems/world` (the hatch column), a dated `## Revision` on `architecture/grd-06-final-battle` (a FightWall now stands in the lantern) and on `architecture/story34-mentor-at-the-lantern` (Q8 replaced), design 04 §3.3 rows 59 and 122 and design 05 § "O mentor na luta final" with the user's approval; the roadmap row with the user's words.
7. Playtests: the awakening at speed (does 3.5 s read as "he is waking", is the cut from the strip to the body visible in tone or pixel density, does the fight's first telegraph come too soon after the bars), the skip, and a death mid-fight and return (the awakening replays; the climb's length).

## SOLID check

- Presence after the record, not a guardian gate → Open/Closed and Single Responsibility: `Guardian` keeps one entry point (`_on_player_entered`), and the story's timing lives in a fact and a component.
- The awakening as a `Cutscene` with stage stand-ins → data, not code: tuning is `.tres` edits, and a later actor-based version (STORY-35) can replace the strips without touching the fight.
- The grey wall as the existing `FightWall` → no new mechanism. The arena keeps the shape every arena has: a wall at the edge column.
- Every pose and presence derived from two facts → one source of truth that a death rewinds coherently.

## i18n

No user-facing strings: the scene is wordless (design 05 gives the final battle no line before `BARK_MENTOR_LUCID_0`), and the skip entry exists (`PAUSE_SKIP_SCENE`).

## Consequences and risks

- The fight starts by an engine behaviour (re-entry `body_entered`) instead of a walk-in. The gotcha documents it and `mentor_wakes_test` case 3 pins it; if a Godot upgrade changes it, that test fails first.
- The lantern gains a hatch pocket east of the wall (Q3 (a)); the restoration's zoom-0.5 pull-back shows it, open.
- The keeper turns back to the lamp between visits (Q1 (a)): a pose change no scene shows, read as the first sign.
- Pre-STORY-38 restored saves play the awakening once over a restored lantern (dev only).
- STORY-37 (breathing, gestures) and STORY-35 (hand-over clips, likely a mentor `StoryActor`) should draw from the same art set; if STORY-35 adds an actor, the four strips can become its clips and the scene's stages become gestures.

## Open questions (user)

- **Q1 The keeper on arrival.** (a) Back at the lamp, his back to the hatch, in the stasis grey, so the opening's turn replays (**recommended**); (b) as Ivo left him, turned toward the hatch in stasis: no turn, only the crack and the raise.
- **Q2 After a death mid-fight.** (a) The awakening plays again on each attempt: about 3.5 s, skippable, nothing new recorded (**recommended**); (b) once per save, kept through death like the revelation: later attempts find the guardian standing and the fight starts as Ivo comes up.
- **Q3 The grey wall.** The lantern has none today (GRD-06: the hatch just refuses Up during the fight). (a) Move the hatch to the east wall (col 36) and stand a grey wall beside it like every arena exit (**recommended**); (b) no wall, nothing closes on screen; (c) the hatch shows its sealed look while the fight is on.
- **Q4 "Ergue a flauta de um jeito errado".** The Memorina is in Ivo's hands since the gift, and the guardian's clips play an absent flute. (a) He raises his empty hand as if holding the flute that is not there, stopping at the wrong place beside the mask, fingers clawed, a stiff jerk (**recommended**); (b) a grey flute appears in his hand for this moment only (no other clip has it).
- **Q5 Art.** (a) Contracts first, placeholders meanwhile (the stasis still, a cut, a cross-fade to the guardian's grey, his play frames stuttered) (**recommended**); (b) placeholders only.
- **Q6 The frame.** (a) The lantern talk's frame (zoom 1.5, the raised frame chosen for STORY-34), released to the fight's zoom 1 as the bars close (**recommended**); (b) no camera step: the fight's frame throughout.

## Answers (user, 2026-11-17)

- Q1: "De volta à lâmpada (Recommended)": (a).
- Q2: "Repete sempre (Recommended)": (a).
- Q3: "Alçapão ao leste + parede (Recommended)": (a).
- Q4: "Mão vazia (Recommended)": (a).
- Q5 and Q6 were not asked; the orchestrator took the recommended option (a) for each (contracts first with placeholders; the lantern talk's zoom-1.5 frame, released to zoom 1 as the fight begins).

## Built (2026-11-17)

Steps 1-6 as above (step 5's art installed after the review, below); step 5 first wrote the four contracts (`tools/art/prompts/story_mentor_still_at_lamp.md`, `story_mentor_still_turn.md`, `story_mentor_wake_crack.md`, `story_mentor_wake_raise.md`) and their purple placeholder sheets (`tools/art/make_placeholders.gd`; nothing in the game draws them), awaiting the user's approval. Step 7 (playtests) is not run. Differences:

- **The wall is 18 cells, not 4.** The lantern is open above col 35 from the floor (row 20) to the roof (row 2), and Ivo's jump is 144 px (`ivo_jump_stats.tres`), so a 4-cell (128 px) wall could be jumped. `I` at 35,20 has `cells` 18 (rows 3..20); `docs/maps/README.md` asks for "the doorway's height", which here is the whole column.
- **The zone is x 0..940 and the walk's pace 0.6** (after review, 2026-11-17). The first build narrowed it to a 100 px strip (x 840..940). A zoned scene starts only on a grounded, free tick, so any strip narrower than a running double jump (434 px) can be jumped across (`bugs/a-jump-over-the-mentor-wakes-zone-skips-the-awakening`). The zone now covers every place Ivo can land on the way to the keeper, and `mentor_wakes_test.test_no_jump_from_the_hatch_lands_past_the_zone` sweeps the jumps.
- **The zone is `MentorWakesZone` at the contents root, not `Triggers/MentorWakes/Zone`.** `Triggers` and the trigger are plain `Node`s, under which an `Area2D` would lose the room's world offset.
- **The frame is zoom 1.0, offset (0, -112), not Q6's zoom 1.5.** The talk's frame was tuned without letterbox bars, and under them it hid both figures below the waist (`bugs/the-keeper-wakes-frame-hides-ivo-and-the-keeper-below-the-waist`). The 288 px band between the bars now holds the lamp, both figures and the floor. The release only eases the offset back.
- **The waits:** the first build's placeholder waited 1.0 s on his back and cut the turn and the crack's cross-fade together, so the turned keeper showed for one frame. With the art the turned Stasis is held 0.8 s before the crack.
- **One code change: the opening hold.** The fight began at full speed and hit a still Ivo 1.8 s after control returned (`bugs/the-mentor-guardian-hits-a-still-ivo-1-8-s-after-the-awakening-hands-back-control`). `GuardianStats.opening_hold` (default 0; the mentor 1.5 s) is armed by `GuardianFight.begin()` and counted by its `tick()`, and a hit ends it early. `Guardian` starts its AI on `opening_ended` (`systems/guardians`).
- **Art (step 5), approved and installed** ("Aprovar as quatro (Recommended)", user, 2026-11-17). The still and the turn are recolours (`tools/art/recolour_still.py`; the turn's flute colours dropped with `--drop-colours`). The crack is procedural (`tools/art/crack_reveal.py`), because PixelLab twice dissolved the figure instead of cracking it. The raise is four PixelLab frames between two copies of idle frame 0. The `GuardianStill` placeholder is gone, and `StillTurning` and `Cracking` are `StagedStrip`s on the turn's canvas. The scene plays 0.3 s of silence, the 1.0 s turn, the turned Stasis held 0.8 s, the 0.625 s crack and the 0.8 s raise, then the face and 0.3 s: about 3.8 s on the mark. `mentor_wakes_test.test_the_strips_meet_the_stills` holds each strip's end frames to the stills.
- **The leap sweep** is a new case in `guardian_talk_rooms_test` (`test_no_leap_lands_on_a_fight_wall`, every arena against every wall on its floor row).
