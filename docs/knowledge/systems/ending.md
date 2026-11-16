---
id: systems/ending
type: system
title: "The ending: the Return, the village's year, the daughter's reunion, the epilogue on the flat stone, the credits and the rest that saves; due from one save fact, ordered by an EpilogueDirector that writes nothing"
status: active
tags: [story-07, ending, epilogue, return, reunion, credits, year, season, bench, save, save-fact, cutscene, alba, daughter, music]
related: [architecture/story-07-epilogue, systems/story, systems/cutscenes, systems/flashbacks, systems/dialogue, systems/music, systems/seasonal-art, systems/life-benches-death, systems/notices, systems/greyhush, playtests/2026-11-16-story07-walk-home-reunion, playtests/2026-11-16-story07-reunion-art, playtests/2026-11-16-story07-year, playtests/2026-11-16-story07-epilogue, playtests/2026-11-16-story07-credits, playtests/2026-11-16-story07-ending-art]
created: 2026-11-16
updated: 2026-11-16
source_files:
  - scenes/world/story/epilogue/
  - resources/cutscene/story/epilogue.tres
  - resources/cutscene/story/credits.tres
  - resources/cutscene/story/daughter_reunion.tres
  - resources/story/credits/
  - resources/world/year/
  - scenes/world/rooms/year/region_year.gd
  - scenes/ui/credits/
  - scenes/world/interactables/bench/seat_gate.gd
  - scenes/world/rooms/home_village/contents/village_garden_contents.tscn
  - scenes/world/rooms/home_village/contents/village_house_contents.tscn
  - scenes/world/game.gd
  - resources/save_facts/save_fact.gd
---

# The ending

**Never break:** Whether the epilogue is due is derived (`EpilogueSchedule.due`, `SaveFact.Kind.EPILOGUE_DUE`), and the ending's progress is only the live `SCENE_SEEN epilogue` and `credits`. `EpilogueDirector` writes nothing and forgets the ending on `_exit_tree`, so a quit or a death leaves it due. The only save is the ordinary rest on `garden_stone`, through `Game`'s one rest path. Alba's voice finishes the song only inside `wife_song_epilogue`; the guitar never does. The year turns only on a view with no forgetting source in it.

## Summary

STORY-07, scope `docs/design/drafts/camada_pessoal.md` §4, design 01 §8 and §9.4, plan `architecture/story-07-epilogue` (built 2026-11-16). The order is fixed (01 §9.4): the final battle and the world's restoration (GRD-06), then the Return (the walk home, the village at 1.0 and its year, the reunion with the daughter), then the epilogue on the flat stone in the garden, then the credits, then a rest on the stone that saves the game.

## Due and seen

- `SaveFact.Kind.EPILOGUE_DUE` (appended) holds iff `EpilogueSchedule.due(data)`: `world_restored`, all five flashbacks seen (`FlashbackSchedule.seen_count == 5`), `daughter_reunion` heard, and no `SCENE_SEEN epilogue`. `finished(data)` is `SCENE_SEEN credits`. Ids: `EPILOGUE_ID`, `CREDITS_ID`, `REUNION_ID`, `BENCH_ID` (`garden_stone`).
- Fact resources: `epilogue_due.tres`, `heard_daughter_reunion.tres`, `seen_epilogue.tres`, `seen_credits.tres`; every 1.0 gate reads the existing `world_restored.tres`.
- All of it is live data: the rest after the credits commits it, a death forgets it, a quit mid-ending saves nothing (`epilogue_schedule_test`, `epilogue_save_test`).

| Beat | Gate | Rest after |
|---|---|---|
| Walk home | `world_restored` | intent "Home." until the reunion is heard |
| Reunion | `CutsceneTrigger` in village_house, when `world_restored`, unless SCENE_SEEN `daughter_reunion` | the daughter `Reunited`; intent "The blue ribbon." while flashback 2 or 4 is due, else "The garden." |
| Epilogue | `StoneSeat` on the flat stone, when `epilogue_due` | Alba absent; the garden at late afternoon |
| Credits | `EpilogueDirector`, on the epilogue's recorded end; `CreditsSeat` replays a dropped roll | `garden_stone` open; the rest; the game saved |

## The Return

- **The village at 1.0** (`systems/story`, "Village voices"): every 0.6 talk has `unless world_restored.tres`; each villager has a 1.0 voice (`<who>_10`); the mugs and drawings come back as at 0.8 ("Volta como em 0.8 (Recommended)"). `village_voices_test` holds the step.
- **The year** (`systems/seasonal-art`, "The year"): `RegionYear` under the home_village `Region` turns the village through its four seasons on the clock (`YearStats`: 240 s a season, a 12 s dithered turn), only while Ivo is outdoors in the region, out of any story, with no forgetting source in view. It owns its elapsed time in memory only; `Game` stays the only writer of the field's season and palettes.
- **The reunion** (`systems/story`, "The Return"): the daughter waits at the window (`Waiting`, x 400, the `window` strip, her back to the room). `daughter_reunion.tres` turns her to her standing strip, a "!", and she runs to `Marks/Reunion` (`CutsceneWalk.run`: the `run` clip at `LocomotionStats.run_speed` 112 px/s) while Ivo steps in; the talk `daughter_reunion` takes over; she rests `Reunited`. No ribbon ("Deixar de fora (Recommended)").

## The garden and the stone

- The garden's well hides once all five flashbacks are seen (`systems/flashbacks`, "The garden's well and sky"); the sky, the `Warm` light and the lit lantern hold late afternoon on `epilogue_due` and `seen_epilogue` ("Fica no fim de tarde (Recommended)").
- Three seats on the flat stone (x 816), each opened by its own `SeatGate`, the only writer of `Seat.open` (`systems/life-benches-death`):
  - `StoneSeat` (`GroundSeat`, `ground` false), open until `seen_epilogue`; it plays `epilogue` only while `epilogue_due` (its `when`), so before that Down only seats Ivo;
  - `CreditsSeat` plays `credits`, open on `seen_epilogue` unless `seen_credits`, so a dropped roll plays again;
  - `StoneBench` (`garden_stone`, "A pedra lisa"), open on `seen_credits` ("Pedra vira banco (Recommended)").
- A seat offers its prompt only with no sitting Ivo in reach, so a second seat on the same spot never shows over him.

## The epilogue (`resources/cutscene/story/epilogue.tres`, skippable)

- The region hushes (a stream-less SCENE cue); the frame closes on Ivo at zoom 4, 64 px west of him. A `CutscenePose` MEMORINA raises the flute seated (`sit_memorina_raise`, then the `sit_memorina` loop), and the morning song's first four notes play (E G E D). He lowers it (`sit_memorina_lower`), and 2.5 s of silence follow.
- Alba is placed at `beside_stone` + 4 px (x 844), 2 px outside the close-up and 4 px from his flute, on her `beside` clip and turned to him. The frame pulls back to the pair at zoom 2 over 3 s; 1.5 s into it, Ivo turns to her. Her lap is the stone's seat height (9 art px), so she sits on it with no lift.
- Three talks: `epilogue_talk` (01-02), a 2 s silence with the box closed, `epilogue_answer` (03-06), the frame closing on both at zoom 3, `epilogue_name` (07-08, "Alba." the only line of Ivo's that is her name). Ivo's 02 and 06 vary by `TONE_LEANS` (the quiet tally read once, `systems/dialogue`); Alba's never vary.
- The duet: `wife_song_epilogue` at SCENE layer, Alba `beside_sing`, Ivo raises the flute again, and the frame rises to `waterfall_top` + (-320, 130) at zoom 1 over 8.5 s, the open sky with the sun and clouds. At her release (12.45 s) `CutsceneExit alba` while the frame is up; the frame comes back to Ivo alone inside the flute's last C; the scene ends 2 s after 15.8 s, and the end of the pose lowers his flute.

## The credits (`resources/cutscene/story/credits.tres`, skippable)

The title theme at SCENE layer, the frame on the whole garden (zoom 0.5), `CutsceneCredits` rolling `resources/story/credits/credits.tres` on the `CreditsRoll` service (`systems/cutscenes`, "Added for the epilogue"), and `CutsceneYear` running one whole year in 56 s, which ends on the season it began. The roll ends on 1.5 s of black. The list is approved ("Aprovar", 2026-11-16), with "Made with Godot Engine" and the engine's MIT notice.

## The order: `EpilogueDirector` (`World/EpilogueDirector`, INHERIT)

- `ending_began` when `epilogue` begins (`LifeHud` fades the notes), `ending_ended` when the ending closes.
- On the epilogue's recorded end, a skip included, it plays `credits` on the same host (`CutsceneDirector.host()`), deferred.
- On the credits' recorded end it emits `rest_requested(garden_stone)`. `Game.rest_at_bench` seats Ivo on the open seat and runs the one rest (heal, `SaveSystem.rest_at`, bloom, quill) under the black, which the director then clears over 1.5 s.
- `Game.rest_at_bench` takes `Seat.find_open` in the same call as the credits' `SCENE_SEEN`: the bench's `SeatGate` answers `progress_changed` at once, never deferred, or the rest finds no open seat (`epilogue_save_test`).
- A drop of either scene asks no rest. `_exit_tree` writes nothing.
- A load after it arrives seated on the stone in the garden.

## Single writers

- `EpilogueDirector`: none; it asks `Game` for the rest and clears the fade it ended on.
- `CutsceneDirector`: `SCENE_SEEN epilogue`, `credits`, `daughter_reunion`.
- `SeatGate`: `Seat.open`.
- `RegionYear`: the year's elapsed time; `Game`: `MemoryField.season`, `palette`, `next_palette`, `year`.
- `Music`: all music; no `WorldFreeze` writer anywhere in the ending.

## Art

Contracts in `tools/art/prompts/`: `ivo_sit_memorina`, `ivo_sit_memorina_raise`, `story_alba_beside`, `story_alba_beside_sing`, `story_daughter_run`, `story_daughter_window`. Clip names live in each resolver as consts (`systems/animation`). The seated pair was redrawn once for proportion: seated, Alba's head stands 2 art px below Ivo's, as standing she is shorter (26 to 29 art px) ("refazer alba e tbm o ivo nessa sentado, o cara tá esquisitão", user, 2026-11-16). `ivo_sheet_test` holds the seated flute to `ivo_sit`'s axis.

## User decisions, in their words (2026-11-16)

"Pedra vira banco (Recommended)"; "Fechar como substituído (Recommended)" (UI-06); "Pelo relógio (Recommended)"; "Um ano inteiro passa (Recommended)"; "Deixar de fora (Recommended)"; "Volta como em 0.8 (Recommended)"; "Ler uma vez (Recommended)"; "\"A fita azul.\" (Recommended)"; "Uso o CREDITS.md"; "Fica no fim de tarde (Recommended)"; "Aprovar os textos"; the en lines, the tone variants and the credits list "Aprovar"; Godot "Aviso e linha nos créditos (Recommended)". Art: "Ivo tocando sentado", "Alba ao lado", "Filha correndo", "Filha na janela", "Sim, na pedra (Recommended)", "Aprovar; boca à mão (Recommended)", "a proporção está errada", "refazer alba e tbm o ivo nessa sentado, o cara tá esquisitão", "Aprovar os dois", "Aprovar".

## Known limits

Every playtest read frames only. The audio has not been judged by a human: the hush, the four notes, the duet against her exit, the title theme coming in, the skip fade. Nor have the year's real 240 s pace and whether the dither crawls while the camera moves, or frost_edge's music after the final battle. Open roadmap rows hold them (STORY-28 onward).

## Tests

`epilogue_schedule_test`, `save_fact_test`, `epilogue_director_test`, `epilogue_save_test`, `epilogue_scene_test`, `garden_epilogue_test`, `garden_memory_test`, `seat_gate_test`, `ground_seat_test`, `year_math_test`, `region_year_test`, `game_season_test`, `greyhush_renderer_season_test`, `credits_math_test`, `credits_roll_test`, `credits_text_fit_test`, `credits_licence_test`, `cutscene_steps_test`, `cutscene_director_test`, `story_actor_test`, `ivo_sheet_test`, `village_voices_test`, `intent_catalog_test`, `dialogue_tally_test`, `music_cue_test`, `opening_test`, `room_files_test`. Playtests: `story07_walk_home_reunion.json`, `story07_reunion_art.json`, `story07_year.json`, `story07_epilogue.json`, `story07_ending.json`, `story07_ending_art.json`, `story07_credits_ptbr.json`, `story07_credits_skip.json`, `story07_reload.json`.
