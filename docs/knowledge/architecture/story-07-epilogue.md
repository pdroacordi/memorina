---
id: architecture/story-07-epilogue
type: architecture
title: STORY-07 plan - the Return and the epilogue are save-fact stagings, one appended SaveFact EPILOGUE_DUE, a RegionYear that turns the village's season only on a wholly remembered view, the epilogue and the credits as two cutscenes ordered by an EpilogueDirector, and the post-credits save as a rest on a bench the flat stone becomes
status: plan
tags: [story, epilogue, return, cutscene, credits, season, year, greyhush, seasonal-art, save-fact, bench, save, music, dialogue, i18n, plan, story-07]
related: [architecture/story-05-playable-flashbacks, architecture/story-04-bearer-fragments, architecture/cutscenes-are-data-played-between-two-rest-states, architecture/the-opening-is-staged-by-save-facts, architecture/dialogue-is-data-and-choices-are-save-facts, architecture/grd-06-final-battle, architecture/the-life-loop-rewinds-by-reloading, architecture/pause-menu-worldfreeze-reuse, architecture/memory-field-cpu-gpu-split, architecture/regional-weather-push, architecture/music-system, architecture/notebook-entries-are-derived-from-the-save, systems/story, systems/cutscenes, systems/flashbacks, systems/dialogue, systems/music, systems/greyhush, systems/seasonal-art, systems/life-benches-death, systems/notices, systems/screens, systems/settings, systems/guardians, systems/world, systems/rooms, systems/backdrops, bugs/a-cutscene-trigger-in-a-first-visited-room-never-arms, bugs/a-flashback-return-glides-the-frame-from-the-past, bugs/a-neighbour-room-in-another-region-runs-on-the-current-regions-memory, bugs/a-quit-to-title-mid-scene-leaves-the-music-muffled, gotchas/a-killed-tween-never-emits-finished, gotchas/time-scale-zero-stops-delta-particles-and-time, gotchas/a-node-idled-or-swapped-out-keeps-what-it-opened-in-an-autoload, gotchas/tileset-padding-bakes-only-defined-tiles, gotchas/autowrapped-rows-settle-over-several-sorts, gotchas/gdunit-await-millis-never-resumes-while-the-tree-is-paused]
created: 2026-11-13
updated: 2026-11-16
source_files:
  - docs/design/drafts/camada_pessoal.md
  - docs/design/01_lore_e_narrativa.md
  - globals/save_system.gd
  - globals/save_ledger.gd
  - resources/save_facts/save_fact.gd
  - scenes/world/game.gd
  - scenes/world/rooms/region.gd
  - scenes/world/memory/memory_field.gd
  - scenes/world/memory/greyhush_renderer.gd
  - scenes/world/memory/seasonal/season_mask.gdshader
  - scenes/world/memory/seasonal/seasonal_common.gdshaderinc
  - scenes/world/environment/region_weather/region_weather.gd
  - scenes/world/interactables/bench/seat.gd
  - scenes/world/interactables/bench/bench.gd
  - scenes/world/interactables/bench/ground_seat.gd
  - scenes/world/rooms/home_village/contents/village_garden_contents.tscn
  - tools/audio/make_wife_song_midis.py
---

# STORY-07: the Return, the epilogue and the credits (plan)

**Status: PLAN, 2026-11-13.** Scope: `docs/design/drafts/camada_pessoal.md` §4 ("Aprovar o rascunho", user, 2026-11-11) and its decisions ("a" home on foot; "O ano volta a passar (Recommended)"; "a" back in the garden after the credits, with the game saved), design 01 §8 and §9.4, the STORY-05 decision "Seguem depois; epílogo exige o 5º (Recommended)", and the music decisions of 2026-11-02 (the epilogue is a scene, one piece; her lost ending rises to A). The texts are drafts until the user approves them.

## Context

The order is fixed by 01 §9.4: final battle, world restoration (built, GRD-06), the Return, the Memorina's final scene, the credits. What is already built and is reused as it is:

- `SaveSystem.restore_world()` sets `world_restored` and commits at once, the one exception to "only benches save". Every `Region` derives 1.0 from it, the village included (`Region._on_world_restored`, `restore(0)` on build). The village's 1.0 is therefore already on screen when Ivo arrives; nothing new lifts it.
- `world_restoration` (SCENE_SEEN) and the mentor's `mentor_final_first` ("…Vai pra casa. Alguém deixou a janela aberta.") are the seam to this item.
- The present garden `village_garden` (home_village): `GardenWell` with its `FactWell` levels, the `Sky` `FactBackdrop` (day; twilight while FLASHBACK_DUE 5), the `Lantern` FactStaging, the `FlatStone` mark (x 816), Alba's actor and clips (`alba_actor.tscn`, `sit`, `sit_sing`), `GroundSeat` (a seat that plays a cutscene, no save).
- `FlashbackSchedule.seen_count(data)`; `CutsceneDirector`, `CutsceneTrigger`, `CutsceneMelody`, `CutsceneMusic`, `CutsceneMusicMark` ("or the music stops"), stream-less cues for silence.
- The season mask: every seasonal drawable (tiles, `[back]` walls, grass, backdrop layers, weather particles) picks its band per game pixel from `greyhush_season_mask`, else from the global `greyhush_region_season`. No CPU code reads a season at a point (checked: only `Game`, `GreyhushRenderer`, `RegionWeather`, `ColorPulse` and two song effects touch a season). Summer has no art and shows spring's band with summer's tint (`systems/seasonal-art`), so the four seasons already have art in every seasonal drawable.

What is missing: the 1.0 voices; the daughter's reunion; a rule for "the epilogue is due"; the year; the epilogue scene; the credits; the save after them.

## Options considered

1. **Where "the epilogue is due" lives.**
   - (a) Copy the gate (WORLD_RESTORED, five SCENE_SEEN flashback ids, the reunion heard, the epilogue unseen) into every seat, sky set, lantern stage, light stage and intent. Eight facts in six places, and STORY-05 option 5 already rejected this shape.
   - (b) **One appended `SaveFact.Kind.EPILOGUE_DUE` answered by a pure `EpilogueSchedule`.** Chosen: one rule, one test oracle, the FLASHBACK_DUE pattern.
2. **How the year passes.**
   - (a) Cut `Region.season` on each entry into the village (one season per return). Simple, but every cut swaps the whole screen at once under a fade, and the draft's "o tempo anda" never shows.
   - (b) A screen-space colour cross-fade between two renders. A second greyhush pass; breaks "one formula in two languages".
   - (c) **A dithered turn in the season mask:** the mask writes the next season's code for unswapped pixels where `turn > BAYER[px]`, on the same game-pixel Bayer cell as a pulse's edge. Chosen. Every consumer (tiles, walls, grass, backdrops, particles) already decodes the mask, so no consumer shader changes; `MemoryFieldMath` and `greyhush_common.gdshaderinc` are untouched.
   - Grey pixels: a forgotten pixel must never change season ("grey is stopped time"). Gating the turn per pixel by memory still pops the grey pixels at the commit. Chosen instead: **the year advances only while the camera's view has no forgetting source in it** (a death mark, the garden well), so no grey pixel on screen ever turns.
3. **Credits.**
   - (a) A `Screens` router screen that holds. The hold sets the time scale to 0, so the garden behind stops (the water and the year), and `Music` pauses under a hold, so the credits would be silent. Rejected.
   - (b) A BLOCKING router screen (like the map). The world and music run, but a pause press closes an open router screen instead of pausing, and the skip would be a second vocabulary. Rejected.
   - (c) **A cutscene step over a `CreditsRoll` overlay**, a director service like `Letterbox`, `Fade` and `EngravingView`. Chosen: pause, "Skip scene", SCENE_SEEN and music work unchanged; the roll is pausable and scaled like every scene. The Screens rule "every tween ignores the time scale" does not apply: the roll is not under `Screens`.
4. **One scene or two.** (a) The credits as the epilogue's last steps: a skip during the duet would also skip the credits. (b) **Two scenes, `epilogue` then `credits`, ordered by a small `EpilogueDirector`.** Chosen; each is skippable on its own.
5. **The save after the credits.**
   - (a) A second exception, a commit wherever Ivo is. A load arrives on the save's `bench_id`, which is his last bench, not the garden; arriving anywhere else needs a non-bench arrival. Rejected.
   - (b) No save: the player must find a bench. A quit before that replays the epilogue. Rejected (the user chose "com o jogo salvo").
   - (c) **The flat stone becomes a bench (`garden_stone`) once the credits are seen, and the credits end in an ordinary rest on it** (heal, `rest_at`, bloom, quill). Chosen: "only benches save" holds; the load arrives seated on the stone in the garden; the title's slot card names "The flat stone". The only new thing is that the rest is asked by the director instead of a Down press. This needs the user's yes (question 1), because the draft says the garden has no save bench.
6. **Reading the tally** (`DialogueTally`, "STORY-07 decides how it is read"; 01 §10 still lists it as open). (a) Not read. (b) A branch in the scene. Forbidden: "não qual final acontece". (c) **`LineVariant`s on Ivo's own lines only, through an appended `SaveFact.Kind.TONE_LEANS`.** Recommended, and asked (question 7). Alba's lines never vary: 01 §9.4, "nenhum julgamento dela sobre ele".

## Decision

### Save facts and the rule (`resources/save_facts/`, `scenes/world/story/epilogue/`)

- `SaveFact.Kind.EPILOGUE_DUE` (appended). Holds iff `EpilogueSchedule.due(data)`.
- `EpilogueSchedule` (pure RefCounted, static):
  - `due(data)`: `world_restored`, `FlashbackSchedule.seen_count(data) == 5`, `dialogues_heard` has `daughter_reunion`, and `scenes_seen` lacks `epilogue`.
  - `finished(data)`: `scenes_seen` has `credits`.
  - `EPILOGUE_ID := &"epilogue"`, `CREDITS_ID := &"credits"`, `BENCH_ID := &"garden_stone"`.
- If question 7 is answered yes: `SaveFact.Kind.TONE_LEANS` (appended; `index` a `DialogueChoice.Tone`): holds iff that tone's count in `DialogueTally.count` is greater than the other non-NONE tone's. A tie holds for neither, so the base text plays.
- New fact resources: `village_restored.tres` (WORLD_RESTORED), `heard_daughter_reunion.tres`, `epilogue_due.tres`, `seen_epilogue.tres`, `seen_credits.tres`.
- All of it is live data: a bench commits it, a death forgets it. A quit mid-ending saves nothing, so the epilogue stays due.

| Beat | Gate | Rest after |
|---|---|---|
| Walk home | WORLD_RESTORED | intent "Home." until the reunion is heard |
| Reunion | `CutsceneTrigger` in village_house: when WORLD_RESTORED, unless SCENE_SEEN `daughter_reunion` | `Daughter` stage `AfterReunion`; intent "The garden." |
| Epilogue | `GroundSeat` on the flat stone: when EPILOGUE_DUE | Alba absent; garden in late afternoon |
| Credits | `EpilogueDirector`, on the recorded end of `epilogue` | `garden_stone` bench open; rest; the game saved |

### The Return: the village at 1.0

- **Voices.** The 0.6 voices hold from `GUARDIANS_RESTORED_AT_LEAST 2` with no upper bound (`systems/story`), so they would keep speaking at 1.0. First, every 0.6 dialogue gets `unless village_restored.tres`. Then one new `<who>_10` dialogue per villager (`when village_restored.tres`): baker, taverner, water carrier, seller (before the trade beat, which stays), boy. `village_voices_test` learns the 1.0 step: each set has a 1.0 dialogue, and no 0.6 dialogue holds at 1.0.
- **Every other `GUARDIANS_RESTORED_AT_LEAST 2` gate in the village** (the `Mugs`, `Children` and `Audience` stagings, the empty bench, `elder_empty`, the daughter's ≥2 stages) is listed in the build step. Each either stays or gets a 1.0 stage, by question 6.
- **The daughter** (village_house):
  - `Daughter` staging, two new stages on top: `Waiting` (WORLD_RESTORED, reunion unseen: by the window, facing it; the Standing strip flipped as a stand-in) and `AfterReunion` (SCENE_SEEN `daughter_reunion`: Standing by the drawings).
  - `Triggers/Reunion` (`CutsceneTrigger`; when WORLD_RESTORED, unless SCENE_SEEN `daughter_reunion`) plays `daughter_reunion.tres`: she turns from the window, runs to Ivo (her walk at pace 1 until a run clip lands), the frame pairs them at zoom 2, and the scene ends in a `CutsceneTalk` hand-off (`wait = false`, last step) to `daughter_reunion`. He does not take the guitar: `WallGuitar` stays `OnWall`.
  - Talk `daughter_reunion` (the draft's five lines) ends on "Vai lá." Then `daughter_garden` (heard reunion, until the epilogue) and `daughter_after` (`seen_credits.tres`), one line each, drafts.
- **Intents** (`intent_catalog.tres`, in priority order): `home_again` (WORLD_RESTORED, unless heard reunion; key `INTENT_HOME`, reused), `ribbon` (heard reunion, FLASHBACK_DUE 2 or 4; question 8), `garden` (heard reunion, unless SCENE_SEEN `epilogue`; `INTENT_GARDEN`). None after the epilogue.
- **The walk home** needs nothing built: the hatch and the routes are open at 1.0. Its playtest walks lighthouse_top to village_house and reports what the restored world sounds like on the way (frost_edge had no theme "até a batalha final"; if it is still silent after it, that is a separate roadmap item).

### The year (`systems/seasonal-art`; home_village only)

- `YearStats` (Resource, `resources/world/year/village_year.tres`): `order` (SPRING, SUMMER, AUTUMN, WINTER), `season_seconds` (scaled seconds of advance per season; a starting value of 240), `turn_seconds` (12), `when: Array[SaveFact]` (`village_restored.tres`).
- `YearMath` (pure RefCounted): `at(elapsed, stats, start) -> {season, next, turn}`. Each season holds for `season_seconds - turn_seconds`, then `turn` rises 0..1 over `turn_seconds`, eased.
- `RegionYear` (Node, child of the home_village `Region`, INHERIT, so pausable and scaled; `Region.year` export):
  - The only owner of the year's elapsed time, in memory only. It is not saved: a world build starts at `Region.season` (spring), with turn 0.
  - It advances in `_physics_process` only while all of these hold: its `when` holds; the current room is in its region and has sky (`Room.has_sky()`; interiors have no season); `not ivo.is_in_story()`; and `MemoryField.sources_intersecting(view)` holds no source with negative strength. Otherwise it holds, mid-turn included.
  - Its API: `season()`, `next_season()`, `turn()`, signal `season_changed(season)` at each commit.
  - `run_year(seconds)` and `settle()` exist only if question 4 is answered yes: one full cycle that ends on the season it began on.
- **One writer each.** `Game` stays the only writer of `MemoryField.season` and `palette`. It reads `region.current_season()` (the year's season when the region has a running year, else `Region.season`) at a region change, and on `RegionYear.season_changed` while in that region. `Game` also writes the new `MemoryField.year` (the region's `RegionYear` or null).
- `GreyhushRenderer` pushes two new globals each frame: `greyhush_region_season_next` and `greyhush_season_turn` (0 when `year` is null). It lerps the pushed `region_tint` from the palette of `season` to that of `next` by `turn`. The pulses' tints are untouched.
- `season_mask.gdshader`: where no pulse swapped the pixel and `greyhush_season_turn > BAYER[gh_bayer_index(px)]`, it writes `next + 1` into R. Strict greater, as the pulse test (`BAYER[0]` is 0). `px` is `UV * game_size`; no `TIME`, no `FRAGCOORD`. G (smooth memory) is unchanged.
- `RegionWeather` needs no change. Turned pixels read as "swapped", so the current season's ambient weather leaves them as they turn. At the commit, `_field.season` changes and it mounts the new season's particles, which fall in from the top (no respawn of a full sky).
- Indoors never turns (interiors draw band 0 and have no weather). The rest of the world keeps its own season at 1.0. The year is the village's only (01 §8).
- Neighbour rooms across the village seam already flip season on the crossing frame (`bugs/a-neighbour-room-in-another-region-runs-on-the-current-regions-memory`); the year adds nothing there. The year holds while Ivo is outside the region.
- `gotchas/tileset-padding-bakes-only-defined-tiles`: the year shows the village tileset's autumn and winter bands for minutes at a time, so step 3 checks every village look sheet defines all its bands.

### The garden for the epilogue (`village_garden_contents.tscn`, present only)

- **The well (a revision of STORY-05 step 3).** Today `WORLD_RESTORED → 0` (hidden) comes first, so a world restored with flashbacks unseen shows the garden whole before its time. The new levels, first match wins:
  - WORLD_RESTORED and seen 5: 0 (hidden), so the garden is whole.
  - WORLD_RESTORED and seen n < 5: the same targets as today at baseline 1.0. Seen 4 gives 0.4 (-0.6), seen 3 gives 0.15 (-0.85), seen 2 gives 0.1, seen 1 gives 0.05, none gives 0.
  - Then the current table.

  `garden_memory_test` adds the world-restored rows: the waterfall stays under 0.2 through seen 3, and the value rises with every one seen. The `## Revision` on `architecture/story-05-playable-flashbacks` is appended when this step is built.
- **Sky:** `FactBackdrop` gains `waterfall_garden_afternoon` (the past's set) when EPILOGUE_DUE, and again when SCENE_SEEN `epilogue` (question 10). **Light:** a `Warm` `CanvasModulate` stage on the same facts. **Lantern:** `LitDusk` on the same facts.
- **Alba** in the present `Cast`: her actor exists only during the scene. A `CutscenePlace` sets her on `Marks/BesideStone` while the frame is closed on Ivo; she has no `GreyhushShield`, no `CorruptionEdge` agitation and no bloom (draft: "Sem faixas pretas, sem pontilhado, sem a borda que falha"). Her rest staging shows nothing. If `StoryActor.enter` needs a shown child, it gains a fallback to a `home` mark, found in step 6.
- **The stone's two seats.** Both live in the contents scene, not the `.room`, because `garden_twin_test` needs the same ground grid in both gardens (precedent: flashback 1's Talkable).
  - `StoneSeat`: a `GroundSeat` with a new `ground` export set to false, so Ivo sits on the stone with the bench's `sit` clip. Its `cutscene` is `epilogue` and its `when` is `epilogue_due.tres`.
  - `StoneBench`: a `Bench`, `bench_id` `garden_stone`, `BENCH_GARDEN_STONE`, the bench bloom.
  - `SeatGate` (new, Node; exports `seat`, `when`, `unless`) is the only writer of a new `Seat.open` (default true). It picks at `_ready` and on `progress_changed`, the `FactStaging` pattern. `Player._try_sit` refuses a closed seat; both prompts hide while closed. `StoneSeat`: unless `seen_credits.tres`. `StoneBench`: when `seen_credits.tres`.
  - Arrival from a save finds `garden_stone` open, because SCENE_SEEN `credits` is committed in the same rest.
  - `room_files_test` checks bench keys in `.room` files only, so step 6 extends it to `Bench` nodes in contents scenes.

### The epilogue (`resources/cutscene/story/epilogue.tres`, skippable, host the garden's contents)

Built from 01 §9.4 and the draft's "Cinema". Ivo sits on the stone (`StoneSeat`), which plays it. Step outline:

1. Together: a `CutsceneMusic` stream-less cue (silence over the region theme); the camera on Ivo at zoom 2, no bars. `CutscenePose` MEMORINA while seated (art: `ivo_sit_memorina`; stand-in: the seated `sit` loop).
2. `CutsceneMelody`: the morning song's first 4 notes (`guitar_again`'s gap: E G E D) on the Memorina's note voices. He stops; `CutsceneSilence` 2.5 s.
3. While the frame is on him, `CutscenePlace alba BesideStone` (her `sit` clip). The camera pulls back to the pair at zoom 1 over 3 s; she is simply there.
4. `CutsceneTalk` `epilogue_talk` (lines 01-06). Her silence before line 03 is a `DialogueLine.hold` pause or a cue-only line, decided in step 10.
5. Camera closes on the two (zoom 2.5). `CutsceneTalk` `epilogue_name` (07 "Erra. Toca assim mesmo.", 08 Ivo "Alba.").
6. `CutsceneMusic` `wife_song_epilogue` (SCENE). Ivo's pose MEMORINA; Alba `sit_sing`. The camera rises from the stone up the fall to the room's top over the duet (`CutsceneCamera` to `Marks/FallTop`).
7. `CutsceneMusicMark` at her voice's last onset plus its release (measured). Then `CutsceneExit alba` (new) while the frame is up.
8. The camera returns to Ivo alone before the flute's last C. `CutsceneMusicMark` at the stream's end. A wait of 2 s.

Her voice finishes the song only inside this piece. The guitar never plays here, and no `Song` or `Melody` gains the lost ending, so `GuitarPhrase`'s and `GuitarJam`'s rules stand untouched.

### The credits (`resources/cutscene/story/credits.tres`, skippable)

- `CutsceneMusicMark` (the epilogue's one-shot rings to its end; "or the music stops").
- Together:
  - `CutsceneMusic` `menu_title` at SCENE layer;
  - the camera to the garden's widest frame (zoom 0.5, `Backdrop.widest_zoom`);
  - `CutsceneCredits` `credits_sheet`;
  - `CutsceneYear` (question 4).
- `CutsceneFade` to black 1.5 s at the end. The director's rest lands under it, then the fade clears.
- **`CreditsRoll`** (`scenes/ui/credits/`; `CanvasLayer/CreditsRoll` after `Letterbox`, before `Fade`; INHERIT; group `credits_rolls`) is a fourth director service, `CutsceneDirector.credits`:
  - `roll(sheet)`, `land()`, `hide_now()`, `is_done()`. `WorldCutsceneContext.restore` calls `hide_now()`, so an end, a skip and a drop all hide it.
  - Its clock is its own `_process` (pausable, scaled), like `EngravingView`. No `set_ignore_time_scale`: a pause stops it with the music.
  - Look: one 320x180 `Art` root at scale 2; a centred column 200 art px wide; `memorina_text_font_size_8`, cream text with a dark outline (the notice style); headings in `BannerTitle`'s font; the logo (`memorina_logo.png`) last, held 4 s.
  - Text: built from the sheet; every key through `tr()`, re-set in `_retranslate()` on `NOTIFICATION_TRANSLATION_CHANGED` (`systems/settings`).
- `CreditsSheet` (Resource, `resources/story/credits/credits.tres`): `sections: Array[CreditsSection]`, `scroll_speed` (art px/s), `hold_end`. `CreditsSection` holds `heading_key` and `entries: Array[CreditsEntry]`. `CreditsEntry` holds `role_key` (optional) and `names: PackedStringArray`; names are proper nouns and are not translated.
- `CreditsMath` (pure): `offset(t)` in whole art px, `duration(sheet_height)`, edge fade alpha.
- `CutsceneCredits` (`sheet`; subject `credits`) begins the roll and waits `duration`; `land` shows the logo held.
- `CutsceneYear` (only if question 4 is yes; `seconds`) calls `RegionYear.run_year(seconds)`; `land` and `restore` call `settle()`. The year ends where it began, so the rest after the scene is unchanged.

### The ending's order: `EpilogueDirector` (`World/EpilogueDirector`, INHERIT, not an autoload)

- One responsibility: the order epilogue, credits, rest. Exports `epilogue`, `credits` (Cutscene), `bench_id`, `cutscenes`, `ivo`.
- `ending_began` is emitted when the `epilogue` scene begins (`scene_began`). `LifeHud` fades on it, as on `FlashbackDirector.visit_began`. `ending_ended` brings the HUD back.
- On the recorded end of `epilogue` (`CutsceneDirector.ended_recorded()`, a skip included): play `credits` on the same host, deferred.
- On the recorded end of `credits`: emit `rest_requested(bench_id)`. `Game.rest_at_bench(id)` finds the open `Seat`, `Player.sit(seat)` (a teleport onto the same stone), and runs `Game`'s existing rest (heal, `SaveSystem.rest_at`, residency wake, `seat.rest()` → bloom, `SaveMark`). The rest is an extraction from `_on_player_sat_down`, so there is one rest path.
- A dropped `credits` (it cannot be hurt in the garden; a room change while seated is impossible) plays again on the next `StoneSeat` sit, because `epilogue` is seen but `credits` is not. So `StoneSeat` also plays `credits` while SCENE_SEEN `epilogue` holds and `credits` does not. Its `cutscene` becomes a two-entry pick, or a second `GroundSeat` on the same `SeatGate`; this is decided in step 9.
- `_exit_tree` writes nothing. A quit before the rest leaves the epilogue due at the last bench, and it plays again.

### Music

- `resources/music/wife_song_epilogue.tres`: one stream, stem `voice`, no loop, `fade_out` 0, so the scene's end lets it ring.
- Measure in the render: the flute's first onset, his wrong D, her entry, her A, her last onset, the flute's last C. `music_cue_test` pins them; the marks of step 7 and 8 read them.
- Nothing new is composed. The title theme `menu_title.tres` is reused at SCENE layer. The region theme is covered by the epilogue's stream-less cue.
- Only `Music` plays; no `WorldFreeze` writer anywhere in this plan.

### i18n (en + pt_BR; drafts until approved)

| Key | pt_BR | Status |
|---|---|---|
| `DLG_DAUGHTER_REUNION_01..05` | Você voltou colorido. / O mundo voltou. / E a música da mãe? / Ainda falta um pedaço. / Ela cantava no jardim. Você me levava lá, lembra? Vai lá. | draft §4 (approved draft); en at build |
| `DLG_DAUGHTER_GARDEN_01` | O jardim, pai. Ela tá esperando a música. | draft |
| `DLG_DAUGHTER_AFTER_01` | Você tá cantarolando. Você nunca cantarola. | draft |
| `DLG_EPILOGUE_01..07` | 01 §9.4, main version, verbatim | design text; en drafted at step 10 (below), for approval |
| `DLG_EPILOGUE_08` | Alba. | draft §4 |
| `DLG_BAKER_10` | Fiz o redondo e o comprido. Hoje ninguém precisa escolher. | draft |
| `DLG_TAVERNER_10` | Duas canecas. Dois fregueses. Como antes. | draft (question 6) |
| `DLG_WATER_CARRIER_10` | O poço sobe e desce com o ano. Eu tinha esquecido disso. | draft |
| `DLG_SELLER_10` | As sementes brotam sozinhas agora. Quase não precisam de mim. | draft |
| `DLG_BOY_10` | Ela voltou pra brincar. Disse que tava na casa da avó. | draft (question 6) |
| `INTENT_GARDEN` | O jardim. | draft |
| `INTENT_RIBBON` | A fita azul. | draft (question 8) |
| `BENCH_GARDEN_STONE` | A pedra lisa | draft (question 1) |
| `CREDITS_*` | headings and roles (question 9) | after the user's list |
| `DLG_EPILOGUE_02_V1`, `_06_V1` (HOLD_ON) | Eu devia ter escutado você. Penso nisso todo dia. / Eu ainda erro a mesma nota. Toda vez. | draft (decision 7), for approval |
| `DLG_EPILOGUE_02_V2`, `_06_V2` (LET_GO) | Eu devia ter escutado você. Hoje eu sei disso. / Eu ainda erro a mesma nota. Já não me assusta. | draft (decision 7), for approval |

The epilogue's en (step 10, drafts for approval): 01 Alba "You still carry that day." 02 Ivo "I should have listened to you." 03 Alba "That day never weighed on me the way it weighs on you." 04 Ivo "Why?" 05 Alba "Because I loved you. That never depended on you getting it right." 06 Ivo "I still miss the same note." 07 Alba "Miss it. Play it anyway." 08 Ivo "Alba." The variants' en: 02_V1 "I should have listened to you. I think about it every day.", 06_V1 "I still miss the same note. Every time.", 02_V2 "I should have listened to you. I know that now.", 06_V2 "I still miss the same note. It doesn't scare me anymore." 04 and 08 have no variant: a bare question and her name read the same in either tone.

No other text: the seats and the reunion use glyph prompts. Fit tests: `dialogue_text_fit_test`, `notice_text_fit_test` (intents), a new `credits_text_fit_test` (every key and name fits the column, in every locale), the slot card's bench name. A catalog test checks that `DLG_EPILOGUE_08` is the only Ivo line whose text is her name, in every locale (draft §2: "Ivo só diz o nome dela uma vez, no epílogo").

## Rules this pushes against

- **"Grey is stopped time"** (greyhush). The year turns only on a view with no forgetting source. Turned pixels are colour, not grey. The year never runs indoors, in a story, or outside the village.
- **"Only benches save"** (life-benches-death). The post-credits save is a bench rest asked by the director, not a new exception, but it puts a bench in the garden ("sem banco de salvar", draft §1). Question 1.
- **Credits are not a `Screens` screen.** A holding screen stops the garden and pauses `Music`; the credits are a scene service instead.
- **`Region.season` is no longer the only season of a region.** `Game` reads `Region.current_season()`. The plan keeps `Game` the single writer of the field's season and palette, and `RegionYear` the single owner of the turn.
- **STORY-05's well level for WORLD_RESTORED** is revised (above); a Revision is appended to that entry when built.
- **Twin rooms.** The stone's seats live in the present contents scene, not the `.room`.
- **`room_files_test`** knows benches only from `.room` files; extended.
- **The epilogue is watched.** "Cena (Recommended)", 2026-11-02: the player presses no notes; the first attempt and the duet are `CutsceneMelody` and the piece.

## Tests

- **Pure:**
  - `epilogue_schedule_test`: world restored, seen 0..5, reunion heard or not, epilogue seen.
  - `save_fact_test`: EPILOGUE_DUE (and TONE_LEANS, a tie holds neither).
  - `year_math_test`: hold, turn and commit times; `turn` monotonic within a turn; four commits return to the start.
  - `credits_math_test`: whole art px; duration from height.
  - `garden_memory_test`: the world-restored rows.
- **Scene:**
  - `region_year_test`: advances only outdoors in the region, never in a story or with a negative source in view, holds mid-turn, emits `season_changed`; `run_year` and `settle` end on the start season.
  - `season_mask_turn_test`: render the mask with turn 0, 0.5 and 1. Unpulsed pixels show the next code on the Bayer cells below the turn; a pulse's pixels are unchanged.
  - `greyhush_renderer_test`: the new globals; the tint lerp.
  - `game_season_test`: `Game` writes season and palette on a commit while in the village, not elsewhere.
  - `seat_gate_test`: a closed seat refuses Down and hides its prompt.
  - `epilogue_director_test` (fake scenes):
    - epilogue, then credits, then a rest at `garden_stone`;
    - a skipped epilogue still rolls the credits;
    - a dropped credits plays again from the stone;
    - `_exit_tree` writes nothing;
    - `game.tscn` wires it.
  - `epilogue_save_test`: after the rest, a world rebuilt from the committed save arrives seated on `garden_stone` with credits seen, and the epilogue is not due.
  - `credits_roll_test`: a pause hold stops it, it retranslates, `hide_now` resets it.
  - `cutscene_steps_test`: `CutsceneExit`, `CutsceneCredits`, `CutsceneYear`.
  - `cutscene_director_test`: restore hides the roll and settles the year.
  - `village_voices_test`: the 1.0 step.
  - `opening_test`: the house's new stages, the reunion trigger never in the opening.
  - `intent_catalog_test`; `music_cue_test`: the epilogue's onsets.
  - The fit tests.
- **Gates:** the shader scan covers the edited `season_mask.gdshader`.
- **Smoke:** `credits_roll.tscn`; the garden and house contents (already listed).
- **Playtests:**
  - `story07_walk_home.json`: lighthouse_top to the house, `world_restored`;
  - `story07_reunion.json`;
  - `story07_year.json`: the village through four turns at a shortened `season_seconds`, and a death mark in view holding it;
  - `story07_epilogue.json`: all five seen, reunion heard, Down on the stone;
  - `story07_credits_skip.json` (real clock);
  - `story07_reload.json`: quit after the rest, continue, seated on the stone.

  The reports state camera feel, the turn's visibility and what audio cannot be judged from frames (STORY-20 applies).

## Art (each a contract in `tools/art/prompts/`, board first, the user's approval; none made by this plan)

1. `ivo_sit_memorina`: Ivo seated on the stone, raising the Memorina and playing (raise once, play loop, lower once). The epilogue's main shot.
2. `story_alba_beside`: Alba seated beside him on the stone, turned to him, with a slight smile on line 07. Stand-in: her `sit` last frame. Her singing seated is `sit_sing` (exists).
3. `story_daughter_run`: the girl running (reunion). Stand-in: her walk at pace 1.
4. `story_daughter_window` (optional): her back at the window, waiting. Stand-in: Standing flipped.
5. No new garden art: the afternoon set, the Warm grade and `LitDusk` exist from the past.
6. The year: no new art. Step 3 audits every village drawable for its seasonal bands (tilesets, `[back]` walls, backdrops, grass) and lists the ones that never change (props, houses, villagers are not seasonal). The list goes to the user; any new art is a separate item.
7. Credits: the existing logo. Never pack art uploaded as a reference; `CREDITS.md` for anything new.

## Build order (one commit each, verify-gates each)

1. `EPILOGUE_DUE`, `EpilogueSchedule`, the fact resources; tests.
2. The village at 1.0: `unless` on every 0.6 voice, the 1.0 dialogues (keys with draft text), the audit of the other ≥2 gates per question 6; `village_voices_test`.
3. The year: `YearStats`, `YearMath`, `RegionYear`, `Region.current_season()`, `MemoryField.year`, `Game` writes, renderer globals and tint, `season_mask.gdshader`; the band audit; tests; playtest.
4. `Seat.open`, `SeatGate`, `GroundSeat.ground`; tests.
5. The Return: the daughter's stages, the reunion trigger, scene and talks, the intents; tests; playtest (walk home and reunion).
6. The garden: well levels (and the STORY-05 Revision), afternoon sky, light and lantern stages, `StoneSeat`/`StoneBench`, Alba's mark, `BENCH_GARDEN_STONE`, the `room_files_test` extension; tests.
7. Music: `wife_song_epilogue.tres`, the measured onsets; `music_cue_test`.
8. Vocabulary: `CutsceneExit`, `CreditsRoll`, `CreditsSheet`, `CreditsMath`, `CutsceneCredits` (and `CutsceneYear`); tests; smoke.
9. `EpilogueDirector`, `Game.rest_at_bench` (extracted rest), `LifeHud` wiring; director and save tests.
10. The epilogue scene and talks on stand-ins (the en lines for approval); playtest.
11. The credits sheet (after question 9) and the credits scene; playtest.
12. Art: contracts, boards, clips swapped in; playtest.
13. A new `systems/ending` entry (the Return, the epilogue, the credits, the post-credits rest) and its CLAUDE.md row; updates to `systems/seasonal-art` (the year), `story`, `cutscenes`, `music`, `life-benches-death`, `notices`, `dialogue` (the tally), `flashbacks` (the well). Roadmap: STORY-07, and UI-06 per question 2.

## Consequences

- `CutsceneDirector` has four services: `Letterbox`, `Fade`, `EngravingView` and `CreditsRoll`.
- A region can carry a `RegionYear`; only the village does. Any later "time passes" in another region is a `YearStats` resource, not a branch.
- `Seat.open` and `SeatGate` make any seat's presence derived. The garden's stone is the first; a bench that appears with a story fact reuses them.
- `Game` has one rest path, entered by a Down press or a director request.
- The post-game world is ordinary play: bearer fragments, letters and songbooks still due keep working. A death after the final rest rewinds to the stone.
- Not in this plan: re-watching the epilogue; a notebook page for it; a victory screen (question 2); a frost_edge theme after restoration.

## Open questions (user), each with a recommendation

1. **The save after the credits.** (a) **The flat stone becomes a bench, "A pedra lisa", once the credits are seen; the credits end in a rest on it (bloom, quill), and a load arrives seated there (Recommended).** (b) A second "save at once" exception; a load would arrive at the last bench, not the garden. (c) No save; the player rests at a bench himself.
2. **UI-06 (victory screen).** (a) **Close it as superseded: the credits and the rest on the stone are the victory (Recommended).** (b) A short victory card after the credits. (c) A mark on the title's slot card for a finished save.
3. **The year's pace.** (a) **On the clock, only while Ivo is outdoors in the village and out of any scene: about 4 minutes per season, a 12 s dithered turn, tuned in the playtest (Recommended).** (b) One season per return to the village, cut on entry.
4. **The year under the credits.** (a) **The garden lives through one full year while the credits roll, wide frame, ending in the season it began (Recommended).** (b) The garden holds still under the credits.
5. **The ribbon at the reunion** (draft: "detalhe da construção"). (a) **Without the ribbon (Recommended):** it stays in the flashbacks; giving it needs an item, icon, notice and art. (b) She gives it back (a new item, `RIBBON`).
6. **What 0.6 took away, at 1.0** (the girl back in the square, the patron's mug, the elders' bench). (a) **It comes back as at 0.8 (Recommended).** (b) It stays as at 0.6, and only the voices change.
7. **The quiet tally** (01 §9, §10 open). (a) **Read once, in the epilogue, as variants of Ivo's own lines by the leaning tone; Alba's lines never vary; a tie plays the base text (Recommended).** (b) Not read anywhere.
8. **After the reunion with a flashback still due in a far region** (2 or 4). (a) **The intent says "A fita azul." while 2 or 4 is due, "O jardim." otherwise (Recommended).** (b) "O jardim." always.
9. **The credits' content.** The list of names and roles (the author, the packs in `CREDITS.md`, fonts, testers, thanks). Recommended layout: a centred roll over the wide garden, no bars, cream text, the logo last; AIVA takes no line ("Não precisamos dar créditos ao AIVA").
10. **The garden's hour after the epilogue.** (a) **It stays late afternoon (Recommended).** (b) Back to day.

## Decisions (user, 2026-11-16)

1. Save after the credits: "Pedra vira banco (Recommended)". The flat stone becomes the bench "A pedra lisa" once the credits are seen; the credits end in a rest on it, and a load arrives seated there.
2. UI-06: "Fechar como substituído (Recommended)". The credits and the rest on the stone are the victory.
3. The year's pace: "Pelo relógio (Recommended)". About 4 minutes per season while Ivo is outdoors in the village, a 12 s turn, tuned in the playtest.
4. Under the credits: "Um ano inteiro passa (Recommended)". The garden lives through one year in the wide frame and ends on the season it began.
5. The ribbon at the reunion: "Deixar de fora (Recommended)".
6. What 0.6 took away: "Volta como em 0.8 (Recommended)".
7. The quiet tally: "Ler uma vez (Recommended)". Variants of Ivo's epilogue lines only; Alba's never vary; a tie plays the base text.
8. A flashback still due after the reunion: "\"A fita azul.\" (Recommended)", and "O jardim." once none is due.
9. Credits content: "Uso o CREDITS.md". The list is built from `CREDITS.md` and the author, and shown to the user for approval before it ships. Layout as recommended.
10. The garden's hour after the epilogue: "Fica no fim de tarde (Recommended)".
11. The draft texts in the i18n table: "Aprovar os textos" (user, 2026-11-16): the daughter's garden and after lines, the five villagers' 1.0 lines, `INTENT_GARDEN`, `INTENT_RIBBON` and `BENCH_GARDEN_STONE`, in pt_BR as written. The en lines, Ivo's tone variants and the credits list are shown for approval at build.
12. Approvals (user, 2026-11-16): the epilogue's en lines 01-08, "Aprovar"; Ivo's tone variants 02_V1, 02_V2, 06_V1, 06_V2 in pt_BR and en, "Aprovar"; the "Credits list (draft)" as written, "Aprovar" (no GandalfHardcore line; no AIVA, PixelLab or Codex line); Godot: "Aviso e linha nos créditos (Recommended)", a "Made with Godot Engine" line and the engine's MIT notice at the end of the roll.

## Corrections found while building

- **Step 1:** `village_restored.tres` is not made. `resources/save_facts/world_restored.tres` (WORLD_RESTORED) already exists and is the same fact; every 1.0 gate below reads it. `EpilogueSchedule` also names `REUNION_ID` (`daughter_reunion`), the heard talk its rule reads.
- **Step 2:** the seller's 1.0 voice is two pieces: `seller_10` (when he holds no seed) and, at the trade, a `LineVariant` on its first line (`DLG_SELLER_10` while `world_restored`), so the line comes before the shop beat, which stays. `daughter_eyes` and `elder_empty` also read the 0.6 fact and get the `unless`; the house's `Drawings` (Repeated at 0.6) and the tavern's `Mugs` give way at 1.0 (question 6). The Children, Audience and the daughter's ≥2 stages stay: at 1.0 the elder's story is always heard, so they show what 0.8 shows after it, and the daughter's 1.0 stages go on top in step 5. The girl, the patron and the cart need nothing: their `RegionPresence` (0.7) shows them at the restored baseline. The taverner's, the water carrier's and the boy's sets are not edited here: their files carry another change in the working tree.
- **Step 3:** `MemoryField` also carries `next_palette` (the palette of `year.next_season()`), written by `Game` with `season`, `palette` and `year`: the renderer has no `SongCatalog` to find the next season's tint. The mask reads the turn's Bayer cell at `floor(px - turn_origin)` (`turn_origin`, the rounded canvas origin, pushed by the renderer), not at `px`: a whole-screen turn on screen-fixed cells crawls over the world while the camera moves. `season_mask_turn_test` cannot render headless (the dummy renderer draws nothing); `greyhush_renderer_season_test` holds the mask to its source instead, and the playtest shows the turn. `RegionYear`'s gate is the pure `may_advance` plus `forgetting_in_view`, tested apart from Ivo. The band audit: every village tileset ground, backdrop layer, grass and seasonal prop has its three bands drawn; only the built wall, the cracks, `village_strata` and the non-seasonal props, facades and villagers never change (`systems/seasonal-art`, "The year").

- **Step 4:** the closed seat is skipped in `SitComponent.reachable()`, not refused in `Player._try_sit`: the stone carries two seats on one spot, and a refusal there would stop Down at whichever closed seat the sensor listed first. `Seat.offers()` is the one prompt rule both `Bench` and `GroundSeat` read.
- **Step 5:** the Standing strip needs no flip at the window: the window (x 400) is east of the door, so `Waiting` (x 384) faces it as drawn, her back to Ivo coming in. She runs to `Marks/Reunion` (x 240) while Ivo steps to `Marks/IvoReunion` (x 200), and `AfterReunion` is a new child `Reunited` there (flipped, facing him), not Standing by the drawings: the scene's last frame is the rest (as `home_return` ends on HoldingOut), so nothing jumps when the talk takes over. Its talks (`daughter_garden`, `daughter_after`) are a new set `daughter_reunited.tres` on a new legend `t` at col 7, Up, 32 px from the door's zone. The actor gains `waiting` and `reunited` clips (the standing strip) for the new children. The reunion talk is its own set `daughter_reunion.tres` (`once`, zoom 2), started only by the scene.
- **Step 5 (playtest):** a new actor clip must also be a state of the actor's AnimationTree, or the travel fails ("waiting is not found current state"); `story_actor_test` now checks every resolver clip is an animation and a state.
- **Step 6:** `StoneSeat`'s `cutscene` is left empty until the epilogue scene exists (step 10); until then Down on the stone only seats Ivo. `StoneBench` hides the bench's own sprite (the stone is the picture). The present garden's light is a new `Stagings/Light` FactStaging (`light_staging`, z 100) with the past's `LateAfternoon` (the `Warm` CanvasModulate and the `Sun` glow) on `epilogue_due` and `seen_epilogue`; the lantern gains the past's `LitDusk` on the same facts. Alba's actor is not placed yet: only `Marks/BesideStone` (x 840) is, for step 10.
- **Step 6 (tests):** `cutscene_rooms_test` lets a `GroundSeat` with no cutscene pass: it only seats Ivo.
- **Step 6 (twins):** `Marks/BesideStone` is in both gardens: `garden_twin_test` holds the two gardens' marks to one list.
- **Step 2 (rest, built after step 6):** the taverner's, the water carrier's and the boy's sets gain `taverner_10`, `water_carrier_10` and `boy_10` as their first talk; `water_carrier_06` and `boy_alone` get the `unless`. en: "Two mugs. Two regulars. Like before.", "The well rises and falls with the year. I'd forgotten that.", "She came back to play. Said she was at her gran's."
- **Step 7:** the render (`docs/knowledge/music/wifes-song.md`, "The epilogue's render") follows the sketch: the flute's last C (11.62 s) starts with her last C (11.56 s), not after it, so the epilogue outline's "before the flute's last C" (its item 8) cannot come after her exit (item 7). The camera instead comes down during the flute's held C, which sounds alone from her release (12.45 s) to 14.12 s. `fade_in` is 0 too: the flute's first note is 0.56 s in, inside a 1.5 s fade. The measured onsets are `music_cue_test`'s `EPILOGUE_*` consts, which the epilogue's marks read.
- **Step 8:** `RegionYear.run_year(seconds)` and `settle()` are built here, not in step 3 (decision 4 came after it): a run advances `cycle_seconds() / seconds` per scaled second whatever the gate, and its last frame jumps exactly back to where it began, emitting `season_changed`; `settle()` jumps there at once. `CutsceneCredits` waits on `CreditsRoll.is_done()` instead of a precomputed `duration`: the column's height is known only once its autowrapped rows have sorted.
- **Step 9:** `EpilogueDirector` knows the scenes by id (it asserts its exports are `epilogue` and `credits`) and plays the credits on `CutsceneDirector.host()`, a new accessor, deferred so `Player.end_scene` sees the epilogue end first. The replay of a dropped credits from the stone (the plan's "two-entry pick, or a second GroundSeat") is decided as a second `GroundSeat`, `CreditsSeat`, on its own `SeatGate` (open when SCENE_SEEN `epilogue` unless `credits`; `StoneSeat` then closes on `seen_epilogue`), built with the credits scene in step 11; the director itself never starts a scene from the stone. Until step 11 its `credits` is empty, so the epilogue's end closes the ending with no rest. `Game.rest_at_bench` takes the open seat of the bench (`Seat.find` takes the first of an id). `epilogue_save_test` holds the stone's seats and the committed save after the rest; no suite builds `game.tscn` in the tree, so the reload itself is the step 11 playtest (`story07_reload`).
- **Step 10:** the talk is three sets, not two: `epilogue_talk` (01-02), `epilogue_answer` (03-06) and `epilogue_name` (07-08); her "(silêncio)" before 03 is a 2 s `CutsceneWait` with the box closed (a cue in a talk inside a scene cannot start a scene, and a hold would show her line first). The zooms are integers (`CutsceneCamera`: 1.5 draws uneven pixels): the close-up is zoom 4 on Ivo with the frame 64 px west of him, the pull-back to the pair zoom 2 over 3 s, the close on the two zoom 3 with the frame 54 px over their feet, so both heads clear the dialogue box's top position (the playtest saw the box over Ivo's head at 32 px). Alba is placed on `beside_stone` + 12 px east and turned to face him while the frame is on him: at the mark itself, facing west, her hair showed 2-3 px inside the close-up's edge, and a wider offset cut Ivo; the mark is shared with the past garden, so the step offsets it. Ivo stays in the bench's seated `sit` loop (the stand-in for `ivo_sit_memorina`; a MEMORINA pose would stand him). The camera rises to `waterfall_top` (x 1216; there is no `Marks/FallTop`) at zoom 2 over 8.5 s. The marks are her release (12.45 s, then `CutsceneExit alba`, the frame up) and 15.8 s (inside the 15.9 s stream, so it fits), and the frame comes back to Ivo over 1.5 s inside the flute's lone C. `Cast/Alba` (z -10) stands for an empty `Stagings/Alba` (`alba_staging`). Tone (decision 7): `SaveFact.Kind.TONE_LEANS` (appended; `tone_leans_hold_on.tres`, `tone_leans_let_go.tres`) holds by `DialogueTally.leans`; Ivo's 02 and 06 carry the variants (`_V1` HOLD_ON, `_V2` LET_GO); 04, 08 and all of Alba's never vary. `game.tscn`'s `EpilogueDirector.epilogue` is set, so the life notes fade over the scene.

## Credits list (draft)

Built from `CREDITS.md` and the author (decision 9, "Uso o CREDITS.md"); for the user's approval before step 11 builds `credits.tres`. Headings and roles become `CREDITS_*` keys (en / pt_BR); names are never translated. No AIVA line ("Não precisamos dar créditos ao AIVA", user, 2026-11-02).

1. **Memorina** (the logo closes the roll; this opening line is the title in text)
   - A game by: Pedro Acordi
2. **Art** / **Arte**
   - Interface, icons and fonts (the *RPG UI pack*) / Interface, ícones e fontes: Franuka (franuka.itch.io; the licence asks for a link back)
   - Art direction and the art made for this game / Direção de arte e a arte feita para este jogo: Pedro Acordi (to confirm: CREDITS.md marks every other sheet "our own", generated for the project from our own stills)
3. **Music** / **Música**
   - Music / Música: Pedro Acordi (to confirm: the pieces are AIVA-made under the full-authorship plan, `systems/music`; AIVA takes no line)
4. **Thanks** / **Agradecimentos**
   - Thank you for playing / Obrigado por jogar (no name)

Open points, each with a recommendation:

- *FREE Platformer Assets* by GandalfHardcore: no line. CREDITS.md records that no room, trial, region or the title draws it since 2026-10-13 (the files stay on disk). If any of it is shipped in the export, it gets a line under Art.
- The jump and landing dust (`assets/sprites/particles/dust/`): its origin is "unconfirmed" in CREDITS.md (perhaps Cainos' *Pixel Art Platformer - Village Props*). Recommended: find the source or replace the dust before shipping; credit Cainos only if the source is confirmed.
- PixelLab and Codex (image tools that made most sprites from our own stills): no line, as with AIVA. Recommended: ask; a "Made with" line is optional.
- Godot Engine: CREDITS.md does not list it. Its MIT licence asks for its copyright notice in the shipped game, which a licences screen or file can hold; a "Made with Godot Engine" line in the roll is optional.
- Testers and other thanks: CREDITS.md names none. Add names here if there are any.
