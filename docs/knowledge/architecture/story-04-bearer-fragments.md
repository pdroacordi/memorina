---
id: architecture/story-04-bearer-fragments
type: architecture
title: STORY-04 plan - a bearer fragment is a skippable cutscene of engraved stills on an EngravingView overlay, played in a hidden stage room reached by Game.travel; armed by Player.song_performed of the restored guardian's song once its pulse is gone; seen is live SCENE_SEEN bearer_<guardian>
status: built
tags: [story, bearer-fragment, cutscene, engraving, travel, notebook, music, i18n, plan, story-04]
related: [architecture/story-05-playable-flashbacks, architecture/cutscenes-are-data-played-between-two-rest-states, architecture/notebook-entries-are-derived-from-the-save, architecture/found-pieces, architecture/music-system, systems/cutscenes, systems/story, systems/songs-and-the-memorina, systems/guardians, systems/notebook, systems/music, systems/greyhush, systems/dialogue, systems/found-pieces, systems/screens, systems/world, systems/rooms, gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step, gotchas/a-killed-tween-never-emits-finished, bugs/a-travel-asked-under-a-cut-to-black-left-ivo-disabled, bugs/a-flashback-return-glides-the-frame-from-the-past]
created: 2026-11-13
updated: 2026-11-13
source_files:
  - docs/design/drafts/camada_pessoal.md
  - docs/design/01_lore_e_narrativa.md
  - docs/design/07_achados.md
  - scenes/characters/ivo/player.gd
  - scenes/world/memory/color_pulse/color_pulse.gd
  - scenes/world/story/flashback/flashback_director.gd
  - scenes/world/game.gd
  - scenes/world/game.tscn
---

# STORY-04: bearer fragments, one per tube (plan)

**Status: BUILT, 2026-11-13** (closed; the contract is `systems/bearer-fragments`). Scope: `docs/design/drafts/camada_pessoal.md` §3 ("Aprovar o rascunho", user, 2026-11-11; "Cena curta assistida (Recommended)"; the four bearers are the hands of the four songbooks of `07_achados.md`, all four marked by the user) and design 01 §5-6. The 16 captions are the draft's (pt_BR); en is written at build for approval.

## Context

Each of the four guardian tubes carries the memory of an earlier bearer. The first time Ivo plays the restored guardian's song outside a fight, after the song's effect ends, a ~30 s watched scene plays: 4 still frames of an engraving (one season colour drawn as line work over the world's grey), slow camera moves, few moving layers, black bars, 1-2 caption lines per frame, no portrait or dialogue box, skippable. Then a page appears in the notebook's Memories tab. The fragment never mentions the crack (reserved for the final fragment, GRD-06).

| Guardian | Song (taught in its fight) | Tube | Hand (songbook, 07) |
|---|---|---|---|
| BLOOM | ROOT (Enraizar) | the living stem | an earthy hand (Chuva's book) |
| FROST | FREEZE (Congelar) | the petrified branch | a winter hand (Redoma's book) |
| AUTUMN | RELEASE (Soltar) | the hollow bone | a restless hand (Vendaval's book) |
| SUMMER | SHADOW (Sombra) | the pierced stone | an old hand (Solstício's book) |

The song is `GuardianStats.song` (verified in the four `*_guardian_stats.tres`); the catalog validates it against the stats, never a second table. The mentor teaches no song (`systems/story`) and his winter tube has no ordinary fragment.

Constraints read from the contracts: a scene is data between two rest states and its director never writes `WorldFreeze` or reads input (`systems/cutscenes`); the pause can open only on a running tree, so a freeze would remove the "Skip scene" entry (`systems/screens`); `Music` pauses under a hold and is the only music player (`systems/music`); a notebook page is 81x106 pack px, about 7 lines or 120 English characters under a title (`07_achados.md`, `systems/notebook`); no shader reads `TIME` or `FRAGCOORD` (`systems/greyhush`).

## Options considered

1. **Where the scene plays.**
   - (a) In place, over the live room. Ivo is blocked, but creatures, wind, hazards and song timers run for 30 s; a hurt drops the scene at second 25.
   - (b) In place under `WorldFreeze.freeze()`. The world stops, but the director would become a `WorldFreeze` asker, and the pause (and so "Skip scene") cannot open over a paused tree.
   - (c) As a held `Screens` screen. The hold pauses `Music`, so the scene would be silent, and skipping would be a second skip vocabulary.
   - (d) **A cutscene on a hidden stage room, reached and left by `Game.travel`**, with the stills on a screen overlay. Chosen. This is the reuse the STORY-05 plan foresaw (its "Consequences"). The room left is deactivated with its state kept (`Room.deactivate`), nothing in the stage can hurt, the tree runs (pause, skip and music work), and `SCENE_SEEN` and skip come from `CutsceneDirector` unchanged. Only about 3.5 s, the call, plays in the live room.
2. **How the stills are drawn.**
   - (a) As world-canvas sprites in the stage room. The greyhush pass and the region's season grade would shade them.
   - (b) Pre-coloured PNGs on an overlay. These are simple, but the season colour would be baked into 16 files and a generator would drift from one hue.
   - (c) **Greyscale layers with the ink in one key colour, shaded by a small `engraving.gdshader`** on an overlay drawn after `Greyhush`/`Creatures`/`Foreground` and before `LessonCinematic`/`Letterbox`/`Fade`. Chosen. The greys go through `gh_print` (the world's forgotten print, `greyhush_print.gdshaderinc`), so "over the world's grey" is the same formula. The ink is the song's `SeasonPalette` tint, so the colour is data with one source.
3. **How the frames are sequenced.**
   - (a) One opaque player node with its own timeline. That would be a second scene runner, needing its own skip and record.
   - (b) **One cutscene step per frame** (`CutsceneEngraving`) inside an ordinary `Cutscene`. Chosen. Bars, fades, waits, skip and `SCENE_SEEN` stay the cutscene vocabulary, and a frame's pan, reveal and caption timing is a pure helper.
4. **"Seen".**
   - (a) A new death-proof record. It could leave a fragment seen while a death has rewound the restoration that armed it.
   - (b) **Live `SCENE_SEEN bearer_<guardian>`**, as the flashbacks do (STORY-05 option 4). Chosen. No new `SaveFact` kind: "due" is `GUARDIAN_RESTORED g` and not `SCENE_SEEN bearer_<g>`.
5. **Telling a world performance from a lesson.** The lesson's end also emits `MemorinaComponent.song_played` → `Player.song_played` (`finish_performance`), so it would arm a fragment inside the arena right after restoration.
   - (a) The director tracks `lesson_started`. This is fragile when a lesson is aborted.
   - (b) An extra argument on `song_played`. The signal is connected to `PulseEmitter.spawn_pulse(song, at, stats)`, so a third argument would land in `stats`.
   - (c) **A new `Player.song_performed(song: Song)`**, emitted only when a performance that a matched sequence started reaches its end, never after a lesson, a by-ear lesson or a completing half. Chosen.

## Decision

### Trigger: `BearerFragmentDirector` (`World/BearerFragmentDirector`, INHERIT, group `bearer_directors`, not an autoload)

The director is pausable and scaled, reads no input, writes no `WorldFreeze` and does not write the save itself. It exports `catalog`, `cutscenes`, `ivo` and `start_grace` (s, scaled; default 2.0).

1. On `Player.song_performed(song)`: `catalog.by_song(song)` gives the fragment, armed only if `BearerSchedule.due(data, fragment)`. One pending fragment, held in memory only.
2. **Wait for the effect to end.** The pending fragment waits while `ColorPulse.lit(self, song.id)` is non-empty. Ivo's pulses act; a guardian's do not. The pulse's `PulseEffect` is freed with it, so this is "the song's effect".
3. **Start gates**, checked each tick for `start_grace` after the pulse is gone. The pending fragment starts on the first tick at which all of these hold:
   - `ivo.can_begin_scene()`: alive, not sinking, not in a talk or scene, map closed, not seated, on the floor and free for Up;
   - not `ivo.is_memorina_drawn()`;
   - not `NoticeHold.applies(ivo)`, which covers a lesson, a story and `Guardian.fight_at`;
   - not `ivo.in_past`;
   - `CutsceneDirector` idle and `FlashbackDirector` not visiting;
   - no acting `ColorPulse` of any song alive (a puzzle still held).

   If the grace runs out, the pending fragment is dropped, and the next performance of that song arms it again. A world rebuild forgets it.
4. **The call** (`bearer_<g>_call`, not skippable, about 3.5 s) on the current room's contents:
   - Together: bars in (0.8 s), the frame on Ivo at zoom 2 (1.6 s), and `CutsceneMuffle` 0.9 on the region's music;
   - a 0.6 s wait;
   - `CutsceneFade` to the paper colour (`EngravingView.paper`), 1.2 s. The world goes grey all the way.

   A hurt drops it unrecorded, and the fragment stays due.
5. On the call's recorded end (it leaves the screen covered, as a flashback crossing does):
   - the director keeps the return point `TravelPoint.new(room, ivo.global_position, ivo.facing)` in memory;
   - it asks `Music` for `fragment.music` at SCENE layer, owned by itself;
   - it emits `travel_requested(stage_point, paper, 0.0)` → `Game.travel`;
   - on `Game.travelled(true)` it plays `engraving` on the stage room's contents.

   `travelled(false)` clears the fade, releases the music and stays due. `travelled` is a broadcast, so each director acts only while it is awaiting its own travel.
6. **The engraving** (`bearer_<g>`, skippable) ends under a 0.8 s fade to black. A recorded end never clears a fade. The director then travels back (0 s, black), plays `returning` on the return room's contents and releases the music at its end.
7. **The returning** (`bearer_<g>_returning`, not skippable, about 2 s): bars held, fade clear 1.0 s, wait 0.8 s; the bars and the frame return at its end. Ivo stands where he stood, facing as before.
8. `_exit_tree` forgets everything and writes nothing. A quit mid-visit saves nothing, because only benches save, so the fragment stays due.

`Game.travel` and `TravelPoint` are reused as they are; nothing needs extracting from `FlashbackDirector` (its return point is one `TravelPoint.new`).

### Data (`resources/story/bearers/`)

- `BearerFragment` (Resource, `bearer_<guardian>.tres`) has these fields:
  - `guardian` (`Enums.Guardian`) and `song` (Song);
  - `call`, `engraving` (id `bearer_<guardian>`) and `returning` (Cutscene);
  - `music` (MusicCue; stream-less if silence, see questions);
  - `stage_room` (`bearer_stage`), `arrival` (feet, px from the room's top-left) and `arrival_facing`.
- `BearerSchedule` (pure, static). `due(data, fragment)` is `SaveFact.check(GUARDIAN_RESTORED, guardian)` and not `SaveSystem`'s `SCENE_SEEN engraving.id`. `ID_FORMAT := "bearer_%s"`.
- `BearerFragmentCatalog` (`bearer_catalog.tres`) has `fragments`, `by_song(song)` and `validate(cutscenes, guardian_stats)`. `validate` names:
  - a guardian listed twice or missing;
  - `song` != that guardian's `GuardianStats.song`;
  - an engraving id not `bearer_<guardian>`;
  - a scene missing from the cutscene catalog;
  - a skippable call or returning;
  - a call whose last fade colour is not the paper;
  - an engraving with fewer than 4 or more than 5 frames, or a frame with 0 or more than 2 captions;
  - an engraving shorter than 25 s or longer than 35 s.

  The director asserts it in debug builds.

### The look: `EngravingView` (`scenes/ui/engraving/`)

- **Placement.** One node in `game.tscn`'s `CanvasLayer`, after `RegionTitle` and before `LessonCinematic`, so it covers the greyed world, the creatures and the foreground, and sits under the bars and the fade. It is INHERIT (pausable): a pause hold stops it, and a lesson never overlaps a scene. Every tween is bound to the node and scaled (`systems/story`: beats run on the pausable, scaled clock). Group `engraving_views`; `CutsceneDirector` gains an `engraving` export beside `letterbox` and `fade`.
- **Children:**
  - `Paper`, a ColorRect in `paper`;
  - `Layers`, a Node2D whose Sprite2D layers are drawn at 2x and carry `engraving.gdshader`;
  - `Caption`, a Label centred in the bottom bar's 36 px, in the dialogue box's text font, at most 2 lines. Text is `tr(key)`, re-set in `_retranslate()` on `NOTIFICATION_TRANSLATION_CHANGED` (`systems/settings`).
- **API:** `show_frame(frame, tint, dissolve)`, `clear(seconds)`, `land()`, `hide_now()`, `is_settled()`.
- **`EngravingFrame`** (Resource):
  - `layers: Array[EngravingLayer]`;
  - `captions: Array[StringName]` (1-2 keys);
  - `seconds`;
  - `pan_from` and `pan_to` (art px, the view window's top-left on the canvas);
  - `reveal_seconds`, `dissolve_seconds`.
- **`EngravingLayer`** (Resource):
  - `texture`;
  - `depth` (0..1, the fraction of the pan the layer follows, which gives parallax);
  - `ink_only` (grey pixels transparent);
  - `drift` (px/s; ink-only layers only);
  - `hframes` and `fps` (an ink-only loop).

  **Only ink moves; the grey never does**, because grey is stopped time (`systems/greyhush`). The pan moves the whole picture, as a camera moves over a frozen world.
- **`EngravingMath`** (pure RefCounted) gives, for a frame and its elapsed time:
  - the window (pan eased in-out, rounded to whole game px);
  - each layer's offset;
  - the reveal and dissolve amounts;
  - the caption alpha: in 0.5 s after the reveal, out 0.4 s before the dissolve;
  - `fits(frame)`: every window at every t inside every layer's canvas.

  Zoom is never used: a non-integer scale draws uneven pixels.
- **`engraving.gdshader`** (CanvasItem; includes `greyhush_print.gdshaderinc`):
  - grey texels become `gh_print(rgb)`;
  - key texels `#FF00FF` become `ink_colour`, the song palette's tint;
  - `reveal` (0..1) dithers the frame in from flat `paper`, and `dissolve` dithers to the next frame. Both use a 4x4 Bayer in the texture's art pixels (`UV / TEXTURE_PIXEL_SIZE`), the same grid rule as `CorruptionEdge`.

  No `TIME` and no `FRAGCOORD`: every value comes from script.
- **Sizes.** The view between the bars is 640x288 game px, which is 320x144 art px at 2x. A layer canvas is 384x176 art px, so a pan reaches 64x32 art px.

### Cutscene vocabulary added (each with a `cutscene_steps_test` case)

- `CutsceneEngraving` (`frame: EngravingFrame`, `ink: SeasonPalette`). `begin` shows the frame (reveal on the first frame, dissolve after) and waits `frame.seconds`. `land` shows its end state.
- `CutsceneEngravingClear` (`seconds`) dithers the ink and greys out to `paper`, then the step is over.
- `CutsceneContext.engrave(frame, tint, dissolve)` / `clear_engraving(seconds)`. `restore` calls `EngravingView.hide_now()`, so a skip, a drop and an end all leave it hidden. The view is a director service like `Letterbox` and `Fade`, not a contents `CutsceneVisual`.
- The engraving scene `bearer_<g>` (about 29 s):
  - bars open 0 s;
  - frame 1: reveal 1.5 s, then 6.5 s;
  - frames 2-4: dissolve 1.0 s, then 6.5 s each;
  - `CutsceneEngravingClear` 1.0 s;
  - fade to black 0.8 s.

### The stage: room `bearer_stage`, region `past`

- `gen_world_shells.py` `INTERIORS` gets `("past", "bearer_stage", 1, 1)` at region `past`'s next free interior slot. `garden_past` keeps its x and twin phase.
- One floor row, the `Arrival` mark, `interior_stone` backdrop (every room has one), `WorldEdges`, and nothing else.
- Reusing `past` gives `Player.in_past` for free: the Memorina, the sword and the map are refused, notices are held and the life HUD hides. There is no music, no title and no map.
- It is never seen: it is reached under the paper colour and left under black.
- `flashback_rooms_test` "nothing harmful in the past" covers it. Add it to `tools/smoke/scenes.txt`.

### Player

- `signal song_performed(song: Song)`, emitted in `_on_song_played` only when the finished performance was not a lesson. Player keeps a `_performing_lesson` flag set in `_tick_pending_performance`.
- No other change: the director only pulls existing reads (`can_begin_scene`, `is_memorina_drawn`, `in_past`).

### Notebook (Memories tab)

- Entries `lore_bearer_bloom`, `lore_bearer_frost`, `lore_bearer_autumn` and `lore_bearer_summer`, after `lore_flashback_5`, in the draft's order (spring, winter, autumn, summer).
- Requirement `SCENE_SEEN`, `fact_id` `bearer_<g>`. `NotebookCatalog.validate(cutscenes)` already checks the id.
- Title `NOTEBOOK_LORE_BEARER_<G>_TITLE` is the tube ("The living stem" / "O caule vivo"). Detail `_DETAIL` is the hand, in the songbook's words ("An earthy hand" / "Uma mão de terra"), so a reader who found the book recognises the person. `_BODY`: see the open questions.
- Read only. Re-watching is deferred (draft §3).

### Music

`fragment.music` is asked at SCENE layer by the director, from the travel out to the end of the returning, through `Music` only. The call's `CutsceneMuffle` covers the region's music before that. Which music to use is a user question.

### i18n

- `BEARER_<GUARDIAN>_<N>` (N 1..4): 16 captions, pt_BR verbatim from the draft and en drafted at build for approval.
- `NOTEBOOK_LORE_BEARER_<GUARDIAN>_TITLE`, `_DETAIL` and `_BODY` (12 keys).
- No other text: no title card and no prompt.
- New `engraving_caption_fit_test`: every caption, in every locale of `translations.csv`, is at most 2 lines at the `Caption` Label's width and inside the 36 px bar. The notebook keys are covered by `notebook_text_fit_test`.

## Rules this pushes against

- **"Grey is stopped time"** (greyhush). The engraving moves over grey paper. Kept by the rule that only ink layers animate, and by its being an overlay picture, not the memory field.
- **"After the song's effect ends"** is read as the pulse and its `PulseEffect` being gone. World answers that outlast the pulse (roots, held shells) do not delay the fragment.
- **The notebook page.** The four captions (about 170-200 characters per fragment) plus a tube drawing exceed the 81x106 page (`07_achados.md`: about 120 characters). `notebook_text_fit_test` would fail. This needs a user choice.
- **Region `past`** now also hosts a non-flashback stage. `in_past` then means "a remembered place", and every effect it has is the one wanted here.
- **01 §6 "deixa o jogador revisitá-los"** is met by reading the page. Re-watching stays deferred, as the draft proposes.

## Tests

- **Pure:**
  - `bearer_schedule_test`: restored × seen for each guardian.
  - `bearer_fragment_catalog_test`: the validate cases, with the real catalog against the four `GuardianStats`.
  - `engraving_math_test`: eased pan in whole game px, parallax by depth, drift only on ink layers, caption alpha windows, and `fits` for every shipped frame.
- **Scene:**
  - `player_song_performed_test`: a matched performance emits it; a lesson, a by-ear lesson and a completing half do not.
  - `bearer_fragment_director_test` (a fake travel in Game's order):
    - a lesson never arms;
    - a performance arms and waits out the pulse;
    - it starts within the grace under each gate;
    - it is refused in a fight, a talk, a scene, with the map open, seated, in the past and while another pulse acts;
    - the grace expires and the fragment is dropped;
    - there and back to the same point and facing;
    - a dropped call stays due;
    - a skipped engraving records and returns;
    - the music lives the visit;
    - `_exit_tree` writes nothing;
    - `game.tscn` wires it.
  - `engraving_view_test`: a hold stops it, the caption retranslates, the ink comes from the palette, and `hide_now` resets it.
  - `cutscene_steps_test` and `cutscene_director_test`: restore hides the view.
  - `flashback_rooms_test`: the stage is harmless.
  - The two fit tests.
- **Gates:** the `verify-gates` shader scan (no `TIME`/`FRAGCOORD`) covers `engraving.gdshader`.
- **Smoke:** `bearer_stage_contents.tscn`, `engraving_view.tscn`.
- **Playtests:**
  - `story04_bearer_<guardian>.json` with `restored_guardians`, `known_songs`, the song played and the wait;
  - `story04_bearer_after_lesson.json`: no fragment from the lesson;
  - `story04_bearer_skip.json` (`"clock": "real"`).

  The report states camera feel and caption readability.

## Art

- 16 frames, 4 per fragment. **One contract per fragment** (`tools/art/prompts/story_bearer_<guardian>.md`), because the bearer must look the same across the frames. It lists each frame, its layers, the 384x176 art px canvas, greys only plus the one key ink `#FF00FF`, and at most 2 ink-only moving layers per frame (snow, ice spreading, leaves, birds, a shadow).
- A board per fragment for approval first, then `tools/art/cut_engraving.py`: it quantizes to greys plus the key, splits the layers, and writes `assets/sprites/story/bearers/<guardian>/frame_<n>_<layer>.png`.
- Until the art lands, `tools/art/draw_engraving_placeholders.py` writes paper plus a key outline and the frame number.
- Never upload pack art as a reference. Credit in `CREDITS.md`.
- If the user approves a drawing on the page, 4 tube drawings for the notebook.

## Build order (one commit each, verify-gates each)

1. `Player.song_performed` + test.
2. `EngravingLayer`/`EngravingFrame`, `EngravingMath`, `engraving.gdshader`, `EngravingView` in `game.tscn`, placeholder script; tests, smoke.
3. `CutsceneEngraving`, `CutsceneEngravingClear`, context services, the director's `engraving` export and restore; step and director tests.
4. Stage room `bearer_stage` in region `past` (generator row, `.room`, contents); smoke, rooms test.
5. `BearerFragment`, `BearerSchedule`, `BearerFragmentCatalog`, `BearerFragmentDirector`, `game.tscn` wiring; fixture fragment; director test.
6. The 16 caption keys (pt_BR from the draft, en for approval) + `engraving_caption_fit_test`.
7. The FROST fragment end to end on placeholders; playtest.
8. BLOOM, AUTUMN, SUMMER; playtests.
9. Notebook pages (after the page answer); fit test.
10. The music (after the music answer).
11. Art per fragment: contract → board → frames swapped in; playtest each.
12. A new `systems/bearer-fragments` entry + CLAUDE.md row; updates to `systems/cutscenes`, `notebook`, `songs-and-the-memorina`, `music`, `world`.

## Consequences

- `Game.travel` now has two askers. Each director acts on `travelled` only while it awaits its own travel, and `Game.travel` refuses while one is running.
- `EngravingView` is a third director service beside `Letterbox` and `Fade`. GRD-06's final fragment must not reuse it: design 01 §6 reserves that fragment its own look.
- A fragment never runs inside a fight, a lesson, a talk or a scene, and never with any acting pulse alive.

## Open questions (user)

1. Music: the song's own `track` as the fragment's cue (an existing asset, recommended), silence, or a new piece per season (AIVA, `song-loop`)?
2. The notebook page cannot hold the four captions plus the tube drawing. Options: the captions only, with no drawing; the drawing plus the last caption; or the drawing plus a short line by Ivo.
3. Confirm "over the world's grey" as an opaque frame whose paper is the world's forgotten-print grey (recommended), rather than ink drawn over the live room where Ivo stands.
4. If Ivo cannot start within about 2 s after the pulse (a talk, a bench, a fight), the fragment waits for his next time playing that song (recommended), rather than starting at the next quiet moment anywhere.
5. Engraving pixel scale: the world's 2x art pixel (recommended, consistent), or 1x game pixels for finer hatching?

## Decisions (user, 2026-11-13)

- Music: "A faixa da própria canção (Recommended)": each fragment plays its song's own track.
- Look: "Quadro opaco sobre papel cinza (Recommended)": an opaque frame on forgotten-print paper; the world is hidden during the scene.
- Notebook page: "O tubo e uma frase do Ivo (Recommended)": the tube drawing and one short line in Ivo's voice (texts drafted for approval).
- Pixel density: "Igual ao mundo, 2x (Recommended)".
- Not asked; the plan's recommendation taken (orchestrator, 2026-11-13): if the start gates fail within the grace, the fragment waits for his next play of that song.
- Texts: "Aprovar os textos" (user, 2026-11-13): the 16 en captions (`BEARER_<G>_<N>` in `i18n/translations.csv`), the 4 en notebook lines (`NOTEBOOK_LORE_BEARER_<G>_BODY`) and the page titles taken from the tube names (O caule vivo / The living stem, O galho petrificado / The petrified branch, O osso oco / The hollow bone, A pedra furada / The pierced stone).


## Corrections found while building (2026-11-13, steps 1-5)

- **Step 2, no placeholder script.** The approved art (`assets/sprites/story/bearers/`) was already cut, so `draw_engraving_placeholders.py` was not written.
- **One dither uniform.** `engraving.gdshader` has one `shown` (0..1) instead of `reveal` and `dissolve`: a frame dithers in over bare paper or over the frame before it, whose sprites `EngravingView` keeps under the new ones until it is whole. A clear dithers `shown` back to 0. The Bayer cell is the cell-local, unscrolled texel, so drifting ink keeps its dither grid.
- **The paper is a plain colour.** `EngravingView.paper` is `gh_print(#b8b8b8)` at the project's black lift, `Color(0.758, 0.761, 0.771)` (`engraving_view_test` recomputes it), so a call's `CutsceneFade` and `Game.travel` can cover the screen in it. The ink is darkened to luma 0.42 at most (`ink_max_luma`): the winter and summer tints are lighter than the paper.
- **`CutsceneEngraving.dissolve`.** A step cannot know it is a scene's first, so it carries `dissolve` (false on the first frame); the catalog checks it. The context gains `land_engraving()` beside `engrave` and `clear_engraving`.
- **Recorded or dropped.** The call's `SCENE_SEEN` stays from any earlier attempt, so `is_scene_seen` cannot tell a recorded call from a dropped one: `CutsceneDirector.ended_recorded()`, read inside `scene_ended`, does.
- **Catalog.** `validate(cutscenes, guardian_stats, paper)` checks only the fragments listed; a missing guardian is `missing()`'s, so the empty catalog of steps 5-7 boots under the debug assert (the catalog test asserts `missing()` empty from step 8). It also checks the first frame reveals and the rest dissolve, every frame is inked in its song's palette and the returning names only Ivo. `GUARDIAN_STATS` maps each guardian to its stats file, since `GuardianStats` names no guardian.
- **Director exports.** `flashbacks` (for "FlashbackDirector not visiting") and `engraving` (the paper) join `catalog`, `cutscenes`, `ivo`, `start_grace`. A refused travel to the stage drops the fragment and clears the fade (it stays due); a refused travel back is asked again on the next frame, so Ivo never stays on the stage.
- **The stage.** `bearer_stage` is region `past`'s interior slot 1, at (85600, 12000). `past.tscn` is written once by the generator, so the room was added to it by hand.
- **For step 7.** `Game.travel` clears its cover over `Fade.DURATION` (0.5 s) right after `travelled`; that kills the returning scene's own 1.0 s clear, so the returning's clear is Game's 0.5 s unless the returning re-covers first.

## Corrections found while building (steps 6-11)

- **Step 7, the returning.** It is bars held (0 s) and a 1.8 s wait: `Game.travel`'s own 0.5 s clear is the returning's clear, as in the flashbacks' returning scenes; no second cover is laid.
- **Step 7, the caption under the bar.** The caption is in the bottom bar, so a view drawn before `Letterbox` hid every caption (playtest 2026-11-13). `EngravingView` sits after `Letterbox` and before `Fade`, and its `Paper` covers only the 288 px between the bars, so the bars stay black (`engraving_view_test`).
- **Step 7, the data.** `resources/cutscene/bearers/bearer_<g>{_call,,_returning}.tres` and `resources/story/bearers/bearer_<g>.tres`. Each frame's moving ink layers and drifts are the art contract's (`tools/art/prompts/story_bearer_<g>.md`), at depth 1; the pans are chosen per frame toward its subject.
- **Step 7, `cutscene_rooms_test`.** Every catalog scene must be started by something; the bearer catalog's three scenes per fragment are started by `BearerFragmentDirector`, so the test reads them from `bearer_catalog.tres` as it reads the flashbacks'.
- **Step 9, no hand line.** The tube (40 px), the title, the hand (`_DETAIL`) and Ivo's line needed 116 px of the 106 px page (`notebook_text_fit_test`), so the hand line was dropped, as "O tubo e uma frase do Ivo" asks: a page is `NOTEBOOK_LORE_BEARER_<G>_TITLE` (the tube's name from the draft's headings) and `_BODY` (Ivo's line, "Aprovar as quatro", user, 2026-11-13).
- **Step 9, the drawing.** The tube is a new `NotebookEntry.drawing` (an AtlasTexture of one 72x40 cell of `bearer_tubes.png`), drawn by `Drawing` above the title on the right page. `art` stays the guardians' portrait on the left page.
- **Step 10, the music.** `resources/music/bearer_<g>.tres` streams the song's `track` as one stem and does not loop: each track (60-97 s) outlasts the visit (~38 s). `Music.release` without a fade lets a one-shot ring to its end, so the director releases with the cue's `fade_out` (1.5 s). `validate` names a fragment whose music is not its song's track.
- **Step 11.** No stand-ins were ever drawn: the four engravings use the 32 approved files of `assets/sprites/story/bearers/<g>/` and the pages the 4 cells of `bearer_tubes.png`. The playtest (`playtests/2026-11-13-story04-bearer-fragments`) found the caption bug fixed in step 7; the summer ember layer (single-pixel embers) barely shows, an art note left open.

## Corrections found while closing (step 12, review 2026-11-13)

- **The music on a quit.** `_exit_tree` only dropped the request, so `Music` pruned it and let the one-shot track ring 60-97 s over the title or the rebuilt world. It now calls `_finish()`, which releases with the cue's fade (`bearer_fragment_director_test` checks no deck still sounds the track).
- **No stage at the travel.** That branch now clears the paper cover the call's recorded end left, as a refused travel in does.
- **Catalog.** `validate` also names an engraving that cannot be skipped and one whose last fade is not to black (the travel back is a 0 s cut).
- **`EngravingMath.fits`** tests the snapped windows `layer_window` draws, not the raw lerp.
- **Not changed:** a `CutsceneTrigger` armed but not yet playing does not block the call. The travel out re-arms the room's trigger on the way back (`CutsceneDirector.on_room_changed`), and a trigger that wins the same tick makes the call's `play` refuse, which drops the fragment unrecorded; neither loses a scene.
