---
id: architecture/story34-mentor-at-the-lantern
type: architecture
title: STORY-34 plan - the mentor stands at the lantern's lamp; the hatch opens for good and the final battle is gated in the room by the body's FactPresence; the turn is a cutscene so the turned pose is a rest state
status: active
tags: [story-34, story, mentor, lighthouse, lantern, staging, save-fact, presence, cutscene, guardian, finale, hatch, plan]
related: [architecture/grd-06-final-battle, architecture/the-opening-is-staged-by-save-facts, architecture/cutscenes-are-data-played-between-two-rest-states, architecture/room-reachability-audit, systems/story, systems/cutscenes, systems/guardians, systems/ending, systems/rooms, systems/world, systems/dialogue, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, gotchas/an-area2d-emits-body-exited-when-disabled-or-removed, gotchas/a-killed-tween-never-emits-finished, bugs/the-kit-check-counts-a-guardian-arena-as-an-exit-before-the-guardian-exists]
created: 2026-11-17
updated: 2026-11-17
source_files:
  - scenes/world/rooms/frost_edge/contents/lighthouse_top.room
  - scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn
  - scenes/world/rooms/frost_edge/contents/lighthouse_interior.room
  - scenes/world/rooms/frost_edge/contents/lighthouse_interior_contents.tscn
  - scenes/world/environment/props/fact_staging.gd
  - scenes/characters/guardians/guardian.gd
  - scenes/world/memory/greyhush_shield.gd
  - scenes/world/rooms/room.gd
  - resources/cutscene/story/mentor_goes_still.tres
  - resources/cutscene/story/mentor_silence.tres
  - resources/cutscene/story/world_restoration.tres
  - resources/dialogue/story/mentor.tres
  - resources/dialogue/story/mentor_stasis.tres
  - resources/world/maps/reach_kits.tres
  - tools/maps/gen_world_shells.py
---

# STORY-34 plan: the mentor at the lantern

**Status: BUILT** (2026-11-17; decided the same day, the answers are at the end; "Built" below says what differs). Roadmap STORY-34. The user's place decision (2026-11-17): "Na lanterna, junto à lâmpada" (at the top, in the lantern room, his hand raised to the dark lamp: the keeper who stopped lighting it). The slower talk is `docs/design/drafts/story32_34_talks.md`, section STORY-34 (approved). The dialogue data and i18n keys are the main session's; this plan covers rooms, staging, beats, cutscenes, presence and gates.

## Context

- Today the mentor is a `FactStaging` `Props/Mentor` (`mentor_staging`: Gone on ALL_GUARDIANS_RESTORED, Stasis on `mentor_gift` heard, Holding by default; children Holding, EmptyHand, Stasis, Playing) on the interior's middle gallery at (240, 800). Its beats (`Beats/`: Pair, MentorPhrase, MentorGift, MemorinaFlat, MemorinaLowered, MentorGoesStill, MentorSilence) and the mark `mentor` (`Marks/MentorMark`) sit beside it. The talks are legend `t` at 8,24 (`mentor.tres`, auto, `speaker_offset` -32) and 7,24 (`mentor_stasis.tres`, Up).
- `lighthouse_top` (1280x768, floor row 21 = y 672, hatch_down at col 20 = x 640..672) is the GRD-06 arena: `Arena`, `Lamp` (`lamp_staging`: Lit on SCENE_SEEN `world_restoration`, else Dark) at (656, 114) on a 50 px chain from y 64, `MentorGuardian` (`cutscene_id` `mentor`) at (880, 672), marks `mentor_home` (880, 672), `ivo_stand` (776, 672), `lamp` (656, 400), and `Triggers/WorldRestoration`.
- The only way up is the interior hatch (12,4), `requires` `all_guardians_restored.tres` (also in `gen_world_shells.py`'s door table). Design 04 §3.3: "Alçapão do topo selado | alçapão: os quatro guardiões"; line 58: "Topo do farol | batalha final | os quatro guardiões restaurados".
- **`Guardian` has no gate of its own.** It begins its fight when Ivo enters its `ArenaTrigger` (radius 560) in DORMANT (`guardian.gd:316`). Hiding it does not stop it: a hidden body still processes, collides and fights. The hatch was the only thing keeping the opening out of the fight.
- `FactStaging` is the only writer of its children's visibility, and a prop carries no gameplay (`systems/props`), so the guardian cannot be a staging child.
- Cutscene ids (actors, marks, visuals, stagings, bodies) share one namespace per contents scene (`cutscene_rooms_test`). The interior's mark `mentor` would collide with the guardian body's `cutscene_id` `mentor` in the lantern.
- `StagedBeat.release_stand_ins` returns the staging to its **picked** stage (`FactStaging.release`). If the pose before the talk (facing the lamp) is the default stage, the phrase beat's release would snap him back to the lamp mid-talk. The turned pose must be a stage that a fact picks.

## Options considered

**1. Reaching the lantern while the fight stays gated.**
- (a) The hatch is always open; the final battle is gated in the room by the guardian body's presence (present only on ALL_GUARDIANS_RESTORED). No new door logic; the reach audit just loses a `requires`; the frozen keeper can be visited all game, so the `mentor_stasis` "…" keeps its purpose.
- (b) The hatch is open until the gift, then sealed until the four. `Door.requires` is one `SaveFact` and `gates_pass` is an AND, so this needs an OR gate (a new door field or SaveFact combinator) that `ReachKit` must also learn. After the gift the stasis talk is unreachable once Ivo leaves.
- (c) The hatch stays sealed and a second way up reaches the lantern (an outside ladder or gallery): new geometry in two rooms against design 04's "only way up".
- **Chosen: (a)** (Q1). The gate belongs to the fight, and the room shows it: the still keeper until the four, the guardian after. KISS: one fact, one gate, no door change.

**2. Gating the guardian body.**
- (a) Put `MentorGuardian` under the `Mentor` FactStaging as a sixth child. One writer for every form of the mentor, but FactStaging would learn to disable bodies (a prop node carrying gameplay), and `guardian_talk_rooms_test` reads guardians as direct contents children.
- (b) A `present_when` export on `Guardian` (or a sixth Finale seam): presence logic in `guardian.gd`; a `FinaleStats` field would also hide the bare mentor scene that `guardian_finale_test` and `combat_reach_test` mount with an empty save.
- (c) Instance the guardian only when the fact holds (a spawner): adds and frees nodes on `progress_changed` and breaks every test that instantiates the contents.
- (d) **A `FactPresence` component**, a child of the body on the lantern's instance: the only writer of its parent's `visible` and `process_mode`, from `SaveFact.gates_pass(when, unless)`. `Guardian` is untouched; the bare scene stays present in tests; it mirrors `RegionPresence` (a parent's visibility by baseline, for props) and `StoryActor` (hidden and DISABLED at rest).
- **Chosen: (d).** Open/Closed: `Guardian` gains no code; Single Responsibility: presence is one small node.

**3. The head that turns slowly.**
- (a) A held line (`DialogueLine.hold`): only times the text; nothing is seen to turn.
- (b) A `StagedBeat` standing in a turned child: its stand-in lasts until the next beat's release, which returns to the picked stage (the lamp pose).
- (c) **A `CutsceneBeat`** whose scene ends with SCENE_SEEN `mentor_turns`, and a stage `Holding when SCENE_SEEN mentor_turns`: the turned pose is the rest after the scene, derived (`architecture/cutscenes-are-data-played-between-two-rest-states`), and every later release returns to it.
- **Chosen: (c).**

**4. Where the opening's camera looks.** A new mark `mentor_still` at the figure's feet, or **reuse `mentor_home`**: the guardian takes the figure's place, so one mark names one place. **Chosen: reuse `mentor_home`**; the interior's `MentorMark` is deleted, and `mentor_silence.tres` targets `mentor_home`.

## Decision

### The lantern's layout (Q2, Q3)

- **The hatch moves off the lamp's axis:** `lighthouse_top.room` 20,20 → **30,20** (x 960..992); the interior end stays 12,4. Doors are teleports, so the two ends need not line up. `gen_world_shells.py` (the `lighthouse_hatch` tuple) gets col 30 so the table matches the file.
- **The hatch opens for good:** drop `requires` from `lighthouse_interior.room` 12,4 and from the generator tuple.
- **The lamp stays centred** (x 656) and is **lowered** so it hangs just above the keeper's raised hand: `Lamp` y 114 → 448 (bottom ≈ y 560), `LampChain` `region_rect` height 50 → 384. The `lamp` mark (656, 400) still centres the zoom-0.5 pull-back. A prop: no collision, no gameplay.
- **The keeper stands at (720, 672)**, 64 px east of the lamp's axis, **facing west to the lamp**, his back to the hatch, so Ivo comes up behind him and walks ~240 px west ("A figura não se mexe. Ele chega perto."). His hand (x ≈ 683, y ≈ 574) is under the lamp.
- `MentorGuardian` and `mentor_home` move to (720, 672): the body takes the figure's feet. `ivo_stand` → (824, 672), east of him, as Ivo stands in the opening. Guardian `Talkable` (64/64 px) spans 656..784, 176 px from the hatch.
- **The opening's talks** in `lighthouse_top.room`: auto `t` at **23,20** (`mentor.tres`, `auto_start`, `speaker_offset` -32 = on x 720, `reach_west` 40, `reach_east` 120: starts as Ivo walks in from the east, 120 px short of the hatch) and Up `t` at **22,20** (`mentor_stasis.tres`). Both keep > 22 px from the hatch zone (`village_voices_test.test_no_talk_stands_within_a_body_of_a_door`); the auto zone is ≥ 80 px wide (`talkable_rooms_test`).

### The staging (one writer each)

`Props/Mentor` (`mentor_staging`, same id) moves into `lighthouse_top_contents.tscn`; every child is rebased by (+480, -128) (interior (240, 800) → (720, 672)).

| Priority | Stage | When | Shows | Fade |
|---|---|---|---|---|
| 0 | Gone | `all_guardians_restored.tres` | nothing: the body stands there | 0 |
| 1 | Stasis | DIALOGUE_HEARD `mentor_gift` | Stasis (facing east, as today) | 1.5 (unchanged) |
| 2 | Holding | SCENE_SEEN `mentor_turns` (new `resources/save_facts/seen_mentor_turns.tres`) | Holding (facing east, to Ivo) | **0**: the turn's last frame is this still |
| 3 | AtLamp | default | **AtLamp** (new child, facing west, hand to the lamp) | 0 |

- Children: AtLamp (new), Holding, EmptyHand, Stasis, Playing (`StagedStrip`), and Turning (new `StagedStrip`, intro `turn`, loop its last frame) once the turn is drawn (Q4).
- **`FactPresence`** (`scenes/characters/components/fact_presence.gd`, Node, INHERIT; exports `when`, `unless: Array[SaveFact]`): a child of the lantern's `MentorGuardian` instance with `when = [all_guardians_restored.tres]`. On `_ready` it applies at once; on `SaveSystem.progress_changed` it applies deferred (progress can change inside a physics callback, as `FactBarrier` does). Absent: parent `visible = false`, `process_mode = DISABLED` (its `CollisionObject2D`s leave the physics server, so no `ArenaTrigger`, `Talkable`, hurtbox or contact). Present: `visible = true`, `process_mode = INHERIT`, so `Room.deactivate()` (which writes only the contents root) still disables it.
  - It never sits on a FactStaging child, nor on a node with another writer of `visible` or `process_mode`.
  - Gone and the presence read the same fact, so on a world build both are picked in `_ready`, and when the fourth guardian is restored elsewhere while the lantern's contents are cached, both flip on the same `progress_changed`.
  - The guardian's `GreyhushShield` reads nothing while hidden (`is_visible_in_tree()`, `greyhush_shield.gd:174`). The only explicit process mode under it is `AnimationTree` → ALWAYS during a freeze frame, inside a fight, which an absent body never has (`gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor`). The presence never flips while Ivo is in the lantern, so no `body_exited` fires on a disable mid-overlap (`gotchas/an-area2d-emits-body-exited-when-disabled-or-removed`).
  - A death that rewinds the fourth guardian puts the keeper back and takes the body away: both are derived.

### The talk's beats (`Beats/` in the lantern)

Moved with their relative paths kept: Pair (→ (752, 642)), MentorPhrase, MentorGift, MemorinaFlat, MemorinaLowered, MentorGoesStill, MentorSilence. New, in the order the draft plays them:

1. **`mentor_approach`** (Q7): a cue-only first line → `Beats/MentorApproach` (`CutsceneBeat`) → `resources/cutscene/story/mentor_approach.tres`: Ivo walks (`CutsceneWalk`, pace 0.4, his `walk` clip) to a new mark `ivo_near` (776, 672), 0.6 s still. The talk's zoom 2 keeps the frame; no camera step. However fast Ivo came in, the last steps are slow.
2. Ivo "Ei…" (plain line).
3. **`mentor_turns`**: a cue-only line → `Beats/MentorTurns` (`CutsceneBeat`) → `resources/cutscene/story/mentor_turns.tres`: `CutsceneWait` 1.2 (the silence, box closed), `CutsceneStage mentor_staging` → `Turning`, waits for the strip (≈1.0 s at 6 fps); placeholder until it is drawn: → `Holding`, 0 s (a cut). Then a 0.4 s wait. Its recorded end writes SCENE_SEEN `mentor_turns`, the staging picks Holding with no fade, and the stand-in drops.
4. Mentor "…Você veio pelo caminho ~longo~." · Ivo "Na vila contam uma história sua. Dizem que você guarda as coisas." · Mentor "Guardo."
5. **`mentor_pause`** (Q9): a cue-only line → `Beats/MentorPause` (`StagedBeat`, STILL, no stand-ins, `duration` 1.6 s, like `MemorinaLowered`): the box closes for the long pause, which a press cannot skip.
6. Mentor "Guardava. ~Guardava~." · Ivo "Tem uma música…" with **cue `mentor_phrase`** (moved from today's "They say you keep things." line).
7. As today: "Muitas mãos…", the gift, the flicker, the choice, `mentor_goes_still`, "Se eu o quê?", `mentor_silence` (now targeting `mentor_home`).

All four new cue names are unique across the tree (`DialogueBeat.find` searches it); `story_beats_test` ties cue to beat. The two new scenes go in `cutscene_catalog.tres`; neither is skippable-critical (both short; `skippable` true, and a skip lands the turned rest).

### Gates on the talks

- `mentor.tres` `mentor_gift` stays `once`.
- `mentor_stasis.tres` `mentor_stasis` gains `unless all_guardians_restored.tres`, so its Up prompt never shows over the guardian (the guardian's own talks open on WORLD_RESTORED, `systems/guardians`).

### The middle gallery (Q6)

`lighthouse_interior_contents.tscn` keeps `Backdrop` and `RoomMap`; `Props/Mentor`, `Beats/` and `Marks/` leave, with their now-unused ext_resources and the strip `SpriteFrames`. The `.room` loses 8,24 and 7,24 and its header comment (lines 1-7) is rewritten. The gallery stays (it is the helix joint, `systems/helix-stair`): the keeper's room without him.

## Save facts, resources and room entities that change

| Kind | Change |
|---|---|
| Save fact | New `seen_mentor_turns.tres` (SCENE_SEEN `mentor_turns`; live data, a bench commits it, a death forgets it with `mentor_gift`). Reused: `all_guardians_restored.tres` (Gone, FactPresence, `mentor_stasis` unless). No new `SaveFact.Kind`, no `PlayerData` change. |
| Cutscene | New `mentor_approach.tres`, `mentor_turns.tres` (+ catalog). `mentor_silence.tres`: target `mentor` → `mentor_home`. `mentor_goes_still.tres` and `world_restoration.tres`: unchanged (ids kept; positions move in the scene). |
| Dialogue (main session) | `mentor.tres`: new first cue-only line `mentor_approach`, "Ei…", cue-only `mentor_turns`, the split "Guardo." / `mentor_pause` / "Guardava.", the new Ivo line carrying `mentor_phrase`. `mentor_stasis.tres`: `unless all_guardians_restored`. |
| Room `lighthouse_top.room` | Hatch 20,20 → 30,20; new `t` 23,20 (auto) and 22,20 (Up); header comment. |
| Room `lighthouse_interior.room` | Remove 8,24 and 7,24; 12,4 loses `requires`; header comment. |
| Generator | `gen_world_shells.py` `lighthouse_hatch`: col 30 on top, no `requires`. |
| Reach | `reach_kits.tres` `memorina` milestone `room` → `lighthouse_top` (and its note). The base kit now reaches the lantern; it is the memorina milestone's exit, which the game does give (`bugs/the-kit-check-counts-a-guardian-arena-as-an-exit-before-the-guardian-exists`). |
| Contents | Lantern: `Props/Mentor` (+ AtLamp, Turning), `Beats/` (+ MentorApproach, MentorTurns, MentorPause), `Marks/IvoNear`, `MentorGuardian/FactPresence`, moved guardian/marks, lowered lamp. Interior: emptied as above. |
| Code | `FactPresence` only. |

## Tests that reference the current placement

- `tests/scenes/world/story/opening_test.gd`: `LIGHTHOUSE` preloads `lighthouse_interior_contents.tscn` → `lighthouse_top_contents.tscn`. Lines 45 and 177 expect `Holding` at rest → `AtLamp`; add Holding after SCENE_SEEN `mentor_turns`. Line 182 (`stages[1].fade_seconds` 1.5) still holds (Stasis stays index 1). Line 186 (`""` once the four are restored) holds; add: the guardian is hidden and DISABLED before the four, shown and INHERIT after. Lines 189-210 (phrase strip, gift) keep their node paths.
- `tests/scenes/characters/guardians/guardian_talk_rooms_test.gd`: the moved spawn needs `mentor_home` at (720, 672); the guardian stays a direct contents child, so `checked >= 5` holds.
- `tests/scenes/world/rooms/maps/reach/room_kit_test.gd`: line 78 holds; add `_report(&"base").rooms.has(&"lighthouse_top")`.
- By rule, every room: `village_voices_test` (talk vs door), `talkable_rooms_test`, `story_beats_test`, `cutscene_rooms_test` (namespace, actor-free scenes), `cutscene_catalog_test`, `door_prompts_test`, `room_files_test`.
- Unaffected: `guardian_finale_test`, `combat_reach_test` (they mount the bare mentor scene, which has no FactPresence), `helix_stair_test` (the interior grid keeps its shape).
- New: `tests/scenes/characters/components/fact_presence_test.gd`: absent at ready hides and disables its parent; a fact arriving shows and enables it after a deferred frame; `progress_changed` reaches it while its parent is disabled; INHERIT under a disabled contents root stays disabled.
- Playtest timelines: `mentor_gift.json`, `lighthouse_helix_climb.json`, `story16_returns.json` (positions on the gallery) move to the lantern; `traverse_opening_k2_lighthouse_hatch_knock.json` (the sealed knock) is retired.

## Build order

1. `FactPresence` + its suite (`--import` for the new `class_name`).
2. Rooms: the top `.room` (hatch, two `t`), the interior `.room` (talks out, `requires` out), the generator tuple, `--import`; `reach_kits.tres` + `room_kit_test`. Run the room and talk suites.
3. Move `Props/Mentor`, `Beats/` into the lantern (rebased), the guardian, `mentor_home`, `ivo_stand` to their new feet, `FactPresence` under the guardian, the lowered lamp; empty the interior; `mentor_silence` → `mentor_home`; `opening_test`, `guardian_talk_rooms_test`, `cutscene_rooms_test`, smoke.
4. AtLamp (placeholder: Holding mirrored about x 720, flute overlay mirrored), the four-stage list, `seen_mentor_turns.tres`, `mentor_approach.tres`, `mentor_turns.tres` (placeholder cut), catalog, `MentorApproach`/`MentorTurns`/`MentorPause` beats, mark `ivo_near`; `opening_test` cases.
5. Main session: `mentor.tres`, `mentor_stasis.tres`, i18n keys; `dialogue_text_fit_test`.
6. Art (Q4): contracts in `tools/art/prompts/` first (`story_mentor_at_lamp.md`, `story_mentor_turn.md`, from our own `empty_hand.png` / `memorina_in_hand.png`), user approval, then swap the placeholders (Turning strip in the staging and `mentor_turns.tres`).
7. Docs: `systems/story` (the lighthouse row, the four stages, FactPresence's contract), `systems/cutscenes` (`mentor_silence` target, the two scenes), `systems/guardians` (the body's place and its presence; "the interior's Mentor staging shows nothing" → the lantern's), `systems/rooms` (the talks are on the lantern), `systems/world` (hatch open), `CLAUDE.md`'s Story row if FactPresence becomes a never-break; design 04 §3.3 and 05 Act 3 ("No andar do meio") with the user's approval; the roadmap row with the user's words.
8. Playtests: the opening at the lantern (the approach, the turn, the two pauses, the camera at zoom 2 in a 1280 px room), and a four-restored run (the body in the keeper's place, the fight starting as Ivo comes up, `world_restoration` framing with the lowered lamp).

## SOLID check

- `FactPresence` as a component → Single Responsibility (presence is one node) and Open/Closed (`Guardian` is not modified; any body can be gated the same way).
- Gate in the room, not the door → Single Responsibility (the hatch is a way, the fight owns its own precondition); the door and `ReachKit` keep one fact per gate.
- Turn as a cutscene with a derived rest → the existing rest-state contract (Liskov-style substitution of one scene for another: `CutsceneBeat` is a `DialogueBeat`); no new beat type.
- Positions and pauses are data in `.room`, `.tscn` and `.tres`; no branch in code knows where the mentor stands.

## i18n

No new UI strings in the code. User-facing text is the main session's dialogue lines (new and changed `DLG_MENTOR_GIFT_*` keys, en and pt_BR, through `tr()` by the dialogue box). The two new cutscenes have no text. The intents (`east`, `village`) are unchanged.

## Consequences and risks

- The frozen keeper is visitable all game; design 04's "sealed hatch" line and its example of a fact-locked door (§ "Portas que só abrem com uma condição") need rewriting.
- The lowered lamp hangs at head height in the arena's middle; the fight's readability under it is a playtest item.
- A 1280 px lantern for a talk that was in a one-screen gallery: the zoom-2 frame and the room clamp must keep both in frame.
- `FactPresence` adds a second visibility mechanism beside `FactStaging`; its rule (never on a staging child, never with another writer) goes in `systems/story`.
- STORY-35 (the hand-over as an animated scene) will likely bring a mentor `StoryActor`; the Turning strip and the AtLamp still should come from the same art set.

## Open questions (user)

- **Q1 The hatch.** (a) Always open; the fight waits in the lantern for the four, and the keeper can be visited (**recommended**); (b) open until the gift, then sealed until the four (new OR gate on the door and in the reach audit); (c) sealed, with a second way up.
- **Q2 The layout.** (a) Hatch moved to the east side (col 30), lamp centred, the keeper east of it facing it, his back to the hatch (**recommended**); (b) hatch stays in the centre, lamp and keeper move to the east third (lamp off-centre in a symmetric roof).
- **Q3 The lamp's height.** (a) Lowered on a longer chain so it hangs just above his raised hand (**recommended**); (b) it stays under the roof and his hand reaches up toward it, out of reach; (c) a floor-standing lamp on a pedestal (new art).
- **Q4 Art.** (a) A new still `at_lamp` (arm raised to the lamp, flute in hand) and a `turn` strip (to Holding), contracts first, placeholders meanwhile (mirrored Holding, a cut) (**recommended**); (b) no new art: mirrored Holding and a cut.
- **Q5 The stasis.** (a) He freezes turned to Ivo, as today (**recommended**: no new art; the lamp behind him); (b) he goes back to the lamp pose as he freezes (another still and a longer `mentor_goes_still`).
- **Q6 The middle gallery.** (a) Empty, the keeper's room without him; dressing (cot, table, cold stove) as a later item with its own art contract (**recommended**); (b) dress it now.
- **Q7 The approach.** (a) A short scene walks Ivo the last steps at a stroll before "Ei…" (**recommended**); (b) the talk starts wherever Ivo stops.
- **Q8 When the four are restored.** (a) The body stands where the keeper stood, with no scene; the fight starts as Ivo comes up, as GRD-06 built it (**recommended** for STORY-34); (b) an awakening scene before the fight, as its own roadmap item (the fight would have to wait for it).
- **Q9 The long pause.** (a) A 1.6 s beat with the box closed (**recommended**); (b) `hold` on "Guardo.": the word stays on screen and a press skips the pause.

## Answers (user, 2026-11-17)

- Q1: "Sempre aberto (Recommended)": (a).
- Q3: "Baixar a lâmpada (Recommended)": (a).
- Q4: "Contrato e provisório (Recommended)": (a).
- Q7: "Cena curta (Recommended)": (a).
- Q2, Q5, Q6, Q8, Q9 were not asked; the orchestrator took the recommended option (a) for each, to be named in the run's report.

## Built (2026-11-17)

Steps 1-5 and 7 as above; step 6 wrote only the two contracts (`tools/art/prompts/story_mentor_at_lamp.md`, `story_mentor_turn.md`), awaiting the user's approval. Differences:

- **AtLamp's placeholder is `empty_hand.png` unflipped at (720, 672).** The still is 86 px wide at offset -43, so it is already symmetric about x 720; mirroring Holding only drops `flip_h`. The flute overlay moves to (683, 574), also unflipped.
- **No `Turning` child yet.** It is added with the drawn strip; until then `mentor_turns.tres` cuts to Holding (`CutsceneStage`, 0 s) between its 1.2 s and 0.4 s waits.
- **Playtest timelines:** `mentor_gift.json` and `story16_mentor.json` (not `story16_returns.json`, which never stands on the gallery) start in the lantern at (11780, -1250), east of the auto talk, and walk west into it; their timings are estimates from the beats' durations, not yet run. `lighthouse_helix_climb.json` keeps its positions (the gallery is unchanged), with its note updated. `traverse_opening_k2_lighthouse_hatch_knock.json` is deleted.
- **CLAUDE.md is unchanged:** FactPresence's rule is a never-break of `systems/story`, not of the Systems table.

## After the build (2026-11-17)

- Art approved and drawn: `at_lamp.png` and the `Turning` strip replace both placeholders (`systems/story`, "Art"); the lamp is raised 20 px (y 428) so the raised hand sits just under its right edge.
- Review: the approach could walk Ivo back east; it now ends with a `CutsceneFace` toward `mentor_home`. Playtest: the top box covered the keeper; both lantern talks have `face_height` 110.
- The user's feedback on the build became STORY-37 (he moves while he talks) and STORY-38 (the final battle opens with him waking, replacing Q8's default).
