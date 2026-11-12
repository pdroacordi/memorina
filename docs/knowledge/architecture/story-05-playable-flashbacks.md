---
id: architecture/story-05-playable-flashbacks
type: architecture
title: STORY-05 plan - a flashback is a visit to a twin past room (its own region at memory 1.0), entered and left by travel, staged by save facts; one appended SaveFact FLASHBACK_DUE; colour written only through MemorySources
status: active
tags: [story, flashback, cutscene, memory-field, greyhush, save-fact, travel, region, music, notebook, plan, story-05]
related: [systems/story, systems/cutscenes, systems/dialogue, systems/greyhush, systems/life-benches-death, systems/world, systems/rooms, systems/notebook, systems/music, systems/input, systems/backdrops, architecture/cutscenes-are-data-played-between-two-rest-states, architecture/the-opening-is-staged-by-save-facts, architecture/the-region-owns-its-forgetting, architecture/memory-field-cpu-gpu-split, architecture/doors-and-interiors, architecture/music-system, bugs/a-cutscene-trigger-in-a-first-visited-room-never-arms, bugs/a-teleport-across-the-world-glides-like-a-seam-walk, bugs/a-teleported-ivo-enters-the-room-he-left, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step, gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move, gotchas/a-killed-tween-never-emits-finished]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - docs/design/drafts/camada_pessoal.md
  - tools/maps/gen_world_shells.py
  - resources/save_facts/save_fact.gd
  - scenes/world/game.gd
  - scenes/world/cutscene/cutscene_director.gd
  - scenes/world/rooms/region.gd
  - scenes/world/memory/memory_source.gd
---

# STORY-05: five playable flashbacks (plan)

**Status: PLAN, 2026-11-11.** Scope: `docs/design/drafts/camada_pessoal.md` §1-2 ("Aprovar o rascunho", user, 2026-11-11). Built: steps 1-2 (2026-11-12).

## Context

A flashback starts in the present (a sound in the garden, a ribbon in a far region, the fallen swing), plays 1-2 min in the garden of before in persistent colour with Ivo free to walk, press Up, play the guitar and sit, then returns him to where he stood. No damage, death or save happens inside. Constraints: a `StoryActor` exists only during a scene and a scene blocks Ivo; the director drops a scene when its host leaves the room; `FactStaging` is the only writer of its children; `WorldFreeze` is the only time-scale writer; only `Music` plays music; items are save facts.

## Options considered

1. **Where the past is.** (a) Re-stage `village_garden` with stagings and a forced full-colour override. Fails flashbacks 2 and 4, which start in another region and must return there. It would also mix the present's well, ribbon and swing with the past's figures in one contents scene. (b) **A twin room `garden_past`, same ground, in its own region at memory 1.0, entered by travel.** Chosen. The colour then needs no override: the past is remembered time, so water falls and flowers move.
2. **The past's region.** (a) Put it in home_village with a +1 source. The baseline is 0.8/0.6 and sources sum and clamp, so the collapse cannot reach 0 at the edges while staying 1 at Alba. (b) **A new region `past`** (authored 1.0, `shows_title` false, no music, no weather, `calm_interiors`). Chosen.
3. **Free play inside.** (a) Run the whole flashback as one cutscene. A scene blocks Ivo. (b) Track visit-scoped state (flowers picked, pushes) in a director. This state is not derived and would need its own undo. (c) **Talkables, beats and short cutscenes, gated by `DIALOGUE_HEARD`/`SCENE_SEEN`.** Chosen: every pose stays derived, and a quit loses it all with the bench rewind.
4. **"Seen".** (a) A new death-proof record. (b) **`SCENE_SEEN flashback_<n>`, live data.** Chosen: the gates read restored guardians, which a death also rewinds. A death-proof "seen" could leave flashback 3 seen with one guardian restored.
5. **Due rule.** (a) Copy `when`/`unless` lists into every trigger, talk and staging. (b) **One appended `SaveFact.Kind.FLASHBACK_DUE` (`index` n)** answered by a pure `FlashbackSchedule`. Chosen: one rule, one test oracle.
6. **Crossing and collapse effects.** (a) A new screen-space shader. (b) **Growing/shrinking `MemorySource`s.** Chosen: the dither, game-pixel grid and `greyhush_time` animation come from the existing greyhush. `MemoryFieldMath` and the shader are untouched.

## Decision

### Save and rule (`resources/save_facts/`, `scenes/world/story/flashback/`)
- `SaveFact.Kind.FLASHBACK_DUE` (appended). It holds iff `FlashbackSchedule.due(data) == index`.
- `FlashbackSchedule` (pure RefCounted, static). `due(data) -> int` returns the lowest n in 1..5 with `flashback_<n>` unseen, provided its gate holds. Gate: n = 1 needs ITEM MEMORINA; n >= 2 needs `restored_guardians.count(true) >= n - 1`. Otherwise it returns 0. Also `seen_count(data)` and `ID_FORMAT := "flashback_%d"`. The order can never break.
- The "seen" id is the **leaving** scene's `Cutscene.id` (`flashback_<n>`), recorded in the past before the travel back. So the ribbon, the swing and the well have already flipped when Ivo lands in the present (under the cut).

### The garden (present): `village_garden`, home_village
- Generator rows (`gen_world_shells.py`): `("home_village", "village_garden", 2, 3, -2, -2, True)`. Plus an `H_LINKS` side opening to `lake_waterfall_path` at r -2. Its `.room` gets a hand-edited west ledge and opening at rows 5-8 (the shell exists, so it is not rewritten).
- Placement: r -2 keeps a clear screen over the street, so the square and mill keep their sky band. The garden is 320+ px from them (`room_ring_test`). It sits up the river trail, behind the same `owns_memorina` fence at mill col 30. No bench, no creatures, no title. 2x1 so the tree half can be off-frame (flashback 5). Add to `tools/smoke/scenes.txt`; must pass `backdrop_seams_test`.
- **Its well:** `GardenWell`, a RECT `MemorySource` in `home_village.tscn`, beside `Memory` and not under it, so `RegionMemory.restore()` is not a second writer. A new `FactWell` (Node) is the only writer of its `strength`. It exports `source` and `levels: Array[FactLevel]`. `FactLevel` is a Resource with `when`, `unless` and `strength`; the first that holds wins, like `FactStaging.pick`.
  - Levels: WORLD_RESTORED 0 (hidden); seen 5 +0.3; seen 4 +0.1; seen 3 -0.1; seen 2 -0.3; seen 1 -0.5; else -0.8. These are starting numbers for the playtest.
  - It snaps at `_ready` and tweens on `progress_changed` (pausable, scaled).
  - The value is derived from SCENE_SEEN, never recorded.
- Waterfall and flowers are props with `AmbientMotion`, so they stop below 0.2 and run when remembered. `garden_memory_test` pins that the waterfall's cell reaches >= 0.2 only from seen 4. Correction (step 2): the field is the region's baseline plus the well (`MemoryFieldMath.combine`), so at these levels the garden is 0 with none seen and 0.3 (village 0.8, flashback 1 seen) already from seen 1; `garden_memory_test` pins 0 with none seen, a rise with every one seen at every restored count, and 1.0 with the world restored. Moving the 0.2 crossing to seen 4 needs new levels (the playtest's call).
- **Twin rule:** `garden_past.room` has the same ground grid as `village_garden.room`. The two Backdrops place every layer at the same room-relative pixel: pick the past x so each repeating layer's phase matches. `garden_twin_test` checks both rules.

### The past: region `past`, room `garden_past`
- `REGIONS` gets `past` appended last, so no other interior moves: memory 1.0, no guardian, no music, `shows_title` false, `calm_interiors`. `INTERIORS` gets `("past", "garden_past", 2, 1)` at (84000, 12000), with the garden's backdrop set (`INTERIOR_SETS`).
- `Region.past` (bool) → `Room.is_past()` → Game copies it to `Player.in_past` on each room change, as it does `calm`.
  - The sword is refused by calm, as today.
  - `_try_memorina` sets `enabled = owns and not in_past`; items are untouched.
  - The map is refused.
  - `NoticeHold.applies` reads `is_in_story() or in_past`.
  - Talks, Up and Down stay live.
- Contents: no Enemy, HazardZone, Bench, Door, pickup, reward slot, or deep water (`flashback_rooms_test`). `WorldEdges` walls it. The reach audit skips `past` rooms, as it skips the trials.
- Stagings by `FLASHBACK_DUE n`:
  - `Alba`: Stone, Flowers, Swing, PoolBack, TreeWithDaughter.
  - `Light`: overlay children for day, dusk, night and twilight, as `CutsceneVisual`s so a scene can darken them.
  - `Guitar` and `Flowers`, by heard ids.

### The visit: `FlashbackDirector` (World node, INHERIT, group, not an autoload)
- One responsibility: the visit. It holds the return point (room, feet, facing) in memory only. It asks `Game` to travel. It owns the visit's SCENE-layer `Music` request, the letterbox's rest thickness, and the order crossing → travel → opening → (free play) → leaving → travel → returning.
- `Flashback` Resource (`resources/story/flashbacks/flashback_<n>.tres`): `number`, `crossing`, `opening`, `leaving` (id `flashback_<n>`), `returning` (Cutscene), `music: MusicCue`, `entry_mark`, `bars_thin` px. `FlashbackCatalog.validate()` checks numbers 1..5, ids in the CutsceneCatalog, and that the scenes' hosts resolve.
- Begin: the director watches `CutsceneDirector.scene_ended`. When the scene is a catalog `crossing`, its SCENE_SEEN is recorded (a dropped scene never travels) and no talk is open, it travels.
- Travel: `Game.travel_requested(point, fade)` → `Game._travel()` reuses `_land_in` (Ivo disabled deferred, teleport, `camera.snap()`, `room_changed`) and the door path's guards. That is the cure for the three teleport bugs/gotchas in `related`. Entry is under a white fade, return under a 0 s black cut.
- Then the director plays `opening` on the past host (`CutsceneDirector.play`).
- End: the leaving scene ends on a 0 s cut to black and must not clear it at `restore`. The director travels back, plays `returning` (kneel, silence 1 s or 5 s) and releases the music.
- Quit mid-visit: nothing written (only benches save), so the bench reload shows the flashback still due. Death inside: impossible. `_exit_tree` writes nothing.

### Cutscene vocabulary added (each with a `cutscene_steps_test` case)
- `MemoryBloom` (Node2D owning one hidden `MemorySource`, the bench `Bloom` pattern) + step `CutsceneBloom` (`bloom_id`, shape, rect/radius, offset, strength, ring, seconds). The cutscene's `restore` hides it.
  - Crossing: a positive bloom grows from the trigger. For flashback 1 it is a RECT from the waterfall's top downward.
  - Collapse: a -1 room RECT plus a +1 RECT the size of the view, centred on Alba's actor and shrunk to 0, so grey eats in from the edges and she goes last. Flashback 5 does this in 0 s.
- `CutsceneFade.colour` (white).
- `CutsceneMusicMark` (waits for `Music.position() >= seconds`): the cut lands before the lacuna. `validate` checks it is earlier than the cue's `gap_at`.
- `CutsceneFray` (actor, seconds): calls the actor's `CorruptionEdge.agitate(true/false)`. Alba's sprite carries a `CorruptionEdge` with `rest_fray` 0, so it stays the only writer of the edge uniforms.
- `CutsceneTrigger.zone` (an Area2D path): plays when Ivo's body is inside, for the pool edge.
- `Letterbox.rest_thickness` (one writer: `FlashbackDirector`): `close()` returns to it.
- `Music.muffle(id, amount)`: a low-pass on the Music bus that only `Music` toggles; volume stays `Settings`'.

### Triggers and play, per flashback (data in contents scenes, no per-region code)
1. Sound.
   - `FlashbackLure` (Node2D; an `AudioStreamPlayer2D` on Sfx plus a named `Music.duck`) is active while `FLASHBACK_DUE 1` holds. At the pool, a `CutsceneTrigger` with a zone plays `crossing`.
   - Inside, a Talkable on the guitar starts the talk `flashback_1_guitar`. Its cue goes to a `GuitarJamBeat` (NOTES; `extends DialogueBeat`) over a pure `GuitarJam`, which has no PLAYED outcome.
   - Strings sound detuned. The 3rd mismatch against the morning song cues her laugh (a stand-in). The beat ends after `max_presses` or silence. The final cue is a `CutsceneBeat` → `leaving`.
2. and 4. Ribbon.
   - In each of the four arena regions' exit rooms: a `t` Talkable with `ribbon_<guardian>.tres` (dialogues gated `FLASHBACK_DUE 2|4` + `GUARDIAN_RESTORED g`), a `Ribbon` FactStaging (a `StagedStrip` loop with a SILHOUETTE `GreyhushShield`, so it is the one colour in the grey; still for 4), and a `CutsceneBeat` → the shared `crossing`. The ids are the same in all four rooms, so one Cutscene serves.
   - Flashback 2's flowers are three Talkables, `once`. The third ends with a cue for the far-camera chest scene.
   - Flashback 4: a Talkable on her; `CutsceneFray` at "Por você." This is the only time any flashback uses it.
3. Swing.
   - A Talkable on the fallen swing (`FLASHBACK_DUE 3`) starts a `SwingRaiseBeat`, which holds a new `Hold.HELD_UP` (appended).
   - `Player.pause_talk` sets a new `PlayerInput.up_only`, the twin of `notes_only`: only `up_held` reads, nothing is emitted. The beat samples `Player.up_held()` (a property, not a per-frame signal).
   - Pure `HoldRise` turns the hold into steps every 0.5 s; releasing recedes, and 2 s finishes. A full recede plus 1.5 s idle interrupts the talk unheard.
   - It drives a `MemoryBloom` up the rope and stand-ins of the swing's rise.
   - Inside, each push is one `once` Talkable dialogue (gated on the previous one heard; a cue-only push beat, then her line).
5. Lullaby.
   - Lures in village_mill and village_garden. Garden entry asks the director to start the visit early: music `wife_song_lullaby`. A `MemoryBloom` follows the song's position while Ivo walks, still in control.
   - At full colour the director travels with a 0 s fade. The rooms are identical, so the swap is hidden.
   - A `Seat` with no `bench_id` sits him down: `Game` rests only a bench seat. Then the opening scene (the widest shot), then the darkening twilight, then the 0 s collapse at the mark.

### Alba
- A `Speaker` `alba` (`SPEAKER_ALBA`, portrait).
- A `StoryActor` `alba_actor.tscn` with `AlbaAnimationResolver` (clip consts), used only in scenes, covering the `Alba` staging. Free play shows the staging's figures.
- No `GreyhushShield`, no `AmbientMotion` on the actor.

### Notebook
- Memories entries `lore_flashback_<n>`: requirement `SCENE_SEEN`, `fact_id` `flashback_<n>`. `NotebookCatalog.validate` gains a check that a SCENE_SEEN `fact_id` is in the cutscene catalog. Texts to be approved.

### i18n
- `SPEAKER_ALBA`.
- `DLG_FLASHBACK_<N>_<NN>` for every line of the draft (en + pt_BR; fit test).
- `NOTEBOOK_LORE_FLASHBACK_<N>_TITLE` / `_BODY`.
- The region `past`'s `REGION_PAST` name (never shown; required by `Region`).
- No other text: triggers and prompts are glyphs.

## Rules this pushes against

- **"O tempo desacelera"** (crossing). WorldFreeze is the only time-scale writer, and a director never asks it. The plan stages stillness instead (Ivo held, sound drops, a slow bloom ring); real slow motion would need a user decision.
- **Flashback 5 "sem corte"** needs the hidden swap. Its conditions: the twin room, backdrop phase, the tree half off-frame, and the camera snap matching. If the playtest shows the seam, fall back to a soft white.
- **The free guitar** must not finish the morning song. `GuitarJam` never yields PLAYED; its test runs every press sequence, the melody included.
- **`CorruptionEdge` on a root-canvas actor** writes alpha 253 (the unshielded mark). Check it composites invisibly, or swap the material only for the glitch.
- **"Mais devagar"** (flashback 1) needs a slower take of the hum. `Music` cannot change tempo.

## Tests

- **Pure:**
  - `flashback_schedule_test`: all combinations of Memorina owned, 0-4 restored and seen prefixes.
  - `save_fact_test` (FLASHBACK_DUE).
  - `fact_well_test` and `garden_memory_test`: monotonic in seen for every restored count; 0 with none seen; 1 restored.
  - `hold_rise_test`.
  - `guitar_jam_test`.
  - `flashback_catalog_test`.
- **Scene:**
  - `flashback_director_test`: there and back to the same point and facing; a dropped crossing stays; waits out the talk; the music lives the visit; `_exit_tree` writes nothing.
  - `flashback_rooms_test`: nothing harmful in the past; ids resolve; four ribbons, one per arena region.
  - `garden_twin_test`.
  - `player_past_test`: Memorina, sword, map refused; notices held.
  - `cutscene_steps_test` additions.
  - The fit tests.
- **Smoke:** `village_garden_contents.tscn`, `garden_past_contents.tscn`, `past.tscn`, `alba_actor.tscn`.
- **Playtests:** `story05_flashback_<1..5>.json` (`player_position`, `owned_items`, `scenes_seen`) plus a skip run. The runner needs `"restored_guardians"` if it lacks it.

## Build order (one commit each, verify-gates each)

1. `FLASHBACK_DUE` + `FlashbackSchedule` + tests.
2. `FactLevel`/`FactWell`, the garden room (generator, trail opening, placeholder art), `GardenWell`, smoke.
3. Region `past`, `garden_past`, `Region.past` → `Player.in_past`, non-bench `Seat`, reach-audit skip, twin test.
4. Cutscene vocabulary: `MemoryBloom`/`CutsceneBloom`, white fade, `CutsceneMusicMark`, `CutsceneFray`, trigger zone, letterbox rest, `Music.muffle`.
5. `Flashback`/`FlashbackCatalog`/`FlashbackDirector` + `Game.travel`, with a fixture flashback.
6. Alba: speaker, actor, resolver (placeholder clips until the art contracts land).
7. Flashback 1 (lure, `GuitarJam`), its notebook page; playtest.
8. Flashback 2: the four ribbons; playtest.
9. Flashback 3: `HELD_UP`, `up_only`, `HoldRise`; playtest.
10. Flashback 4 (fray); playtest.
11. Flashback 5 (hidden swap, seat); playtest.
12. A new `systems/flashbacks` entry + CLAUDE.md row; updates to `systems/story`, `cutscenes`, `music`, `notebook`, `world`, `input`.

## Consequences

- A second "visit elsewhere and come back" (the epilogue's, the bearer fragments' engraving) reuses `FlashbackDirector`'s travel and return point, never the save.
- Every past pose is derived; the past room is never a save place.
- The new region is the eighth; interiors of the seven keep their x.
- Art not in this plan: Ivo kneeling, Ivo seated on the ground, the push gesture, the ribbon in hand.

## Decisions (user, 2026-11-11)

- Garden placement: "Pela trilha do Lago (Recommended)": `village_garden` at c2..3 r-2, entered from `lake_waterfall_path`; on a first visit the Frozen Lake title plays before the garden.
- The crossing: "Encenar sem câmera lenta (Recommended)": Ivo held still, sound out, colour from the trigger; no new `WorldFreeze` request.
- The ribbon: "Em toda região restaurada (Recommended)": while flashback 2 or 4 is due, a ribbon shows in every restored guardian's region; no new save data.
- After the final battle: "Seguem depois; epílogo exige o 5º (Recommended)": due flashbacks still play after the world is restored; the epilogue needs all five seen.
- Skipping: "Cenas puláveis, jogo não (Recommended)".
- Death: "Sim, como o resto (Recommended)": a death before a bench forgets a seen flashback.
- Flashback 1's "Mais devagar": "Tirar a fala (Recommended)"; the line is rewritten in the draft without asking for another tempo.
- HUD: "Esconder no passado (Recommended)": the life notes hide while Ivo is in the past.
