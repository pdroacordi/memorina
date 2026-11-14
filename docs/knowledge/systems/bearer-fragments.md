---
id: systems/bearer-fragments
type: system
title: "Bearer fragments: one engraved scene per guardian tube, armed by a world performance of the restored guardian's song, played on a hidden stage reached by Game.travel; seen is live SCENE_SEEN bearer_<g>"
status: active
tags: [story-04, bearer-fragment, story, cutscene, engraving, travel, past, notebook, music, i18n]
related: [architecture/story-04-bearer-fragments, systems/cutscenes, systems/flashbacks, systems/story, systems/songs-and-the-memorina, systems/notebook, systems/music, systems/world, systems/greyhush, systems/screens, playtests/2026-11-13-story04-bearer-fragments]
created: 2026-11-13
updated: 2026-11-13
source_files:
  - scenes/world/story/bearer/
  - resources/story/bearers/
  - resources/story/engraving/
  - resources/cutscene/bearers/
  - resources/cutscene/cutscene_engraving.gd
  - resources/cutscene/cutscene_engraving_clear.gd
  - resources/music/bearer_bloom.tres
  - scenes/ui/engraving/
  - scenes/characters/ivo/player.gd
  - scenes/world/game.tscn
  - scenes/world/rooms/past/bearer_stage.tscn
  - tools/art/cut_engraving.py
---

# Bearer fragments

**Never break:** Seen is only the engraving's live `SCENE_SEEN bearer_<g>`; due is `BearerSchedule.due` (`GUARDIAN_RESTORED g` and not seen), and nothing else about a fragment is recorded. A fragment is armed only by `Player.song_performed` (a world performance), never by a lesson. The engraving is drawn only by `EngravingView`, and only its ink moves. The music goes only through `Music`, released with its cue's fade. Ivo reaches and leaves the stage only by `Game.travel`, and a refused travel back is asked again.

## Summary

STORY-04, scope `docs/design/drafts/camada_pessoal.md` §3 and design 01 §6, plan `architecture/story-04-bearer-fragments` (built and closed 2026-11-13). Each guardian tube held the memory of an earlier bearer. The first time Ivo plays a restored guardian's song outside a fight, after its pulse is gone, a ~38 s watched scene plays: four engraved stills in the song's season ink over forgotten-print paper, slow pans, a few moving ink layers, one caption line per frame in the bottom bar, skippable. A Memories page in the notebook follows. The mentor teaches no song, so his tube has no ordinary fragment; the crack is kept for GRD-06's final fragment, which must not reuse `EngravingView` (design 01 §6).

| Guardian | Song | Tube (page title, en / pt_BR) |
|---|---|---|
| BLOOM | ROOT | The living stem / O caule vivo |
| FROST | FREEZE | The petrified branch / O galho petrificado |
| AUTUMN | RELEASE | The hollow bone / O osso oco |
| SUMMER | SHADOW | The pierced stone / A pedra furada |

## Due and seen

- `BearerSchedule.due(data, fragment)` is `SaveFact.check(GUARDIAN_RESTORED, guardian)` and not `SCENE_SEEN bearer_<guardian>` (`BearerSchedule.id`). No new `SaveFact` kind.
- Seen is recorded by `CutsceneDirector` at the engraving's end or skip. It is live data: a death forgets it with the restoration that armed it, so the fragment plays again after the guardian is restored again.
- The pending fragment, the return point and the music request live in the director's memory only. A quit or a world rebuild mid-visit writes nothing, so the fragment stays due.

## The trigger: `Player.song_performed`

`Player.song_performed(song)` follows `song_played` only when the finished performance started from a matched sequence: never after a lesson, a by-ear lesson or a completing half (`_performing_lesson`, `player_song_performed_test`). `song_played` cannot carry the difference: it is connected to `PulseEmitter.spawn_pulse(song, at, stats)` (`systems/songs-and-the-memorina`).

## The director

`BearerFragmentDirector` (`World/BearerFragmentDirector`, INHERIT, group `bearer_directors`; exports `catalog`, `cutscenes`, `flashbacks`, `ivo`, `engraving`, `start_grace`). Pausable and scaled; no `WorldFreeze` writer, no input reader, no save writes.

1. **Arm.** On `song_performed`, `catalog.by_song(song)` gives the fragment, kept only if due and the director is idle.
2. **Wait for the effect.** While `ColorPulse.lit(self, song.id)` is non-empty. A guardian's non-acting pulse does not hold it.
3. **Start gates**, checked each physics tick for `start_grace` (2.0 scaled s) after the pulse is gone (`can_start()`): `ivo.can_begin_scene()` (alive, not sinking, no talk or scene, map closed, not seated), the Memorina sheathed, not `NoticeHold.applies` (a lesson, a story, `Guardian.fight_at`), not `in_past`, `CutsceneDirector` not playing, `FlashbackDirector.visiting()` null, and no acting `ColorPulse` of any song. If the grace runs out the fragment is dropped; the next performance of that song arms it again ("Not asked; the plan's recommendation taken", orchestrator, 2026-11-13).
4. **The call** `bearer_<g>_call` (not skippable, ~3.5 s) on the current room's contents: bars, the frame on Ivo at zoom 2, `CutsceneMuffle` 0.9, a wait, `CutsceneFade` to `EngravingView.paper`. A hurt drops it unrecorded (`CutsceneDirector.ended_recorded()` tells a dropped call from one recorded on an earlier attempt), and the fragment stays due.
5. **Travel in.** On the call's recorded end the director keeps `TravelPoint.new(room, feet, facing)`, asks `fragment.music` at SCENE layer (owned by itself) and emits `travel_requested(stage point, paper, 0.0)` → `Game.travel`. On `travelled(true)` it plays `engraving` on the stage's contents. `travelled(false)`, or no stage, clears the cover, releases the music and drops the fragment (still due). `travelled` is a broadcast: each director acts only while it awaits its own travel.
6. **The engraving** `bearer_<g>` (skippable, ~29 s, ends under a 0.8 s fade to black). On its end the director travels back (black, 0 s); a refused travel back is asked again on the next physics frame, so Ivo never stays on the stage.
7. **The returning** `bearer_<g>_returning` (not skippable): bars held and a 1.8 s wait; `Game.travel`'s own 0.5 s clear is its clear. At its end the music is released.
8. `_exit_tree` calls `_finish()`: the fragment is forgotten and the music released with its cue's fade, nothing written.

## The stage

`bearer_stage` (region `past`, interior slot 1, (85600, 12000), 1x1): one floor, the `Arrival` mark, the `interior_stone` backdrop, nothing harmful (`flashback_rooms_test`). Region `past` gives `Player.in_past`: the Memorina, the sword and the map are refused, notices held, the life HUD hidden; no music, no title, no map. It is reached under the paper and left under black, so it is never seen (`systems/world`).

## The look: `EngravingView`

- One node in `game.tscn`'s `CanvasLayer`, after `Letterbox` and before `Fade`, INHERIT, group `engraving_views`; `CutsceneDirector.engraving` beside `letterbox` and `fade`. Its `Paper` covers only the 288 px between the bars, so the bars stay black and the caption (in the bottom bar) shows (`engraving_view_test`).
- `paper` is `gh_print(#b8b8b8)` at the project's black lift, `Color(0.758, 0.761, 0.771)`, so a fade and a travel can cover the screen in it.
- `EngravingFrame` (`layers`, `captions` 1-2 keys, `seconds`, `pan_from`/`pan_to` in art px, `reveal_seconds`, `dissolve_seconds`) and `EngravingLayer` (`texture`, `depth` 0..1, `ink_only`, `drift` px/s, `hframes`, `fps`).
- `EngravingMath` (pure): the eased pan snapped to whole game px, parallax by depth, drift and loop cells on ink-only layers, the 0..1 `shown` dither, the caption alpha (in 0.5 s after the entry, out 0.4 s before the end), and `fits(frame)`, which tests the snapped windows `layer_window` draws. Zoom is never used.
- `engraving.gdshader`: grey texels become `gh_print(rgb)`; key `#FF00FF` texels become the song palette's tint, darkened to luma 0.42 at most (`ink_max_luma`); one `shown` uniform dithers a 4x4 Bayer in the texture's art pixels. No `TIME`, no `FRAGCOORD`.
- **Only ink moves; the grey never does** (`systems/greyhush`: grey is stopped time). The pan moves the whole picture.
- Its clock is its own `_process` (pausable, scaled); no tweens. A pause hold stops it.
- The caption is `tr(key)`, set again in `_retranslate()`.

## The cutscene vocabulary it adds

`CutsceneEngraving` (`frame`, `ink: SeasonPalette`, `dissolve`; false only on a scene's first frame) and `CutsceneEngravingClear` (`seconds`); the context's `engrave`, `land_engraving`, `clear_engraving`; `restore` calls `EngravingView.hide_now()`, so an end, a skip and a drop all hide it (`systems/cutscenes`).

## Data

- `BearerFragment` (`resources/story/bearers/bearer_<g>.tres`): `guardian`, `song`, `call`, `engraving`, `returning` (`resources/cutscene/bearers/`), `music`, `stage_room`, `arrival`, `arrival_facing`.
- `BearerFragmentCatalog` (`bearer_catalog.tres`): `by_song`, `missing()`, `validate(cutscenes, guardian_stats, paper)`, asserted in debug builds. It names a guardian listed twice; a song that is not its guardian's `GuardianStats.song` (`GUARDIAN_STATS`); an engraving id not `bearer_<g>`; a scene missing from the cutscene catalog; a skippable call or returning, or an engraving that cannot be skipped; a call not ending covered in the paper; an engraving not ending covered in black; fewer than 4 or more than 5 frames; a frame with 0 or more than 2 captions, that pans out of its canvas, that reveals or dissolves out of turn, or that is not inked in its song's palette; an engraving outside 25..35 s; music that is not its song's track; a returning scene naming anything but Ivo.
- `cutscene_rooms_test` reads the three scenes per fragment from `bearer_catalog.tres` as started by the director.

## Art

16 frames, 4 per fragment, from one contract per fragment (`tools/art/prompts/story_bearer_<g>.md`) and an approved board, cut by `tools/art/cut_engraving.py` into `assets/sprites/story/bearers/<g>/frame_<n>_<layer>.png` (384x176 art px, greys plus the key ink; at most 2 ink-only moving layers per frame). The notebook tubes are 4 cells of `bearer_tubes.png`. Credits in `CREDITS.md`.

## Notebook

`lore_bearer_bloom`, `_frost`, `_autumn`, `_summer` after `lore_flashback_5`, present on `SCENE_SEEN bearer_<g>`. A page is the tube drawing (`NotebookEntry.drawing`), `NOTEBOOK_LORE_BEARER_<G>_TITLE` (the tube) and `_BODY` (one line in Ivo's voice). The hand line (`_DETAIL`) was dropped to fit the 106 px page (`systems/notebook`).

## Music

`resources/music/bearer_<g>.tres` streams the song's own `track` as one stem, not looping (60-97 s, longer than the ~38 s visit). The director asks it at SCENE layer from the travel in to the returning's end and releases it with the cue's `fade_out` (1.5 s): `Music.release` without a fade lets a one-shot ring to its end (`systems/music`). The call's `CutsceneMuffle` covers the region's music before that.

## Single writers

- `CutsceneDirector`: `SCENE_SEEN bearer_<g>` (and the call's and returning's).
- `EngravingView`: every engraving pixel and the caption.
- `BearerFragmentDirector`: its own `Game.travel` requests and its music request. `FlashbackDirector` is the other asker of `Game.travel`; `Game.travel` refuses while one runs.

## User decisions, in their words

- 2026-11-11: "Aprovar o rascunho" (`camada_pessoal` §3); "Cena curta assistida (Recommended)".
- 2026-11-13: "A faixa da própria canção (Recommended)" (the song's own track); "Quadro opaco sobre papel cinza (Recommended)" (an opaque frame on forgotten-print paper); "O tubo e uma frase do Ivo (Recommended)" (the notebook page); "Igual ao mundo, 2x (Recommended)" (pixel density); "Aprovar a arte" (the 16 frames and the tubes); "Aprovar as quatro" (Ivo's four lines); "Aprovar os textos" (the 16 en captions, the 4 en notebook lines and the page titles from the tube names).

## Known limits

- The summer ember layer (single-art-pixel embers) barely shows; the summer engraving reads as still (`playtests/2026-11-13-story04-bearer-fragments`; STORY-25).
- Nobody has listened to a fragment: the muffle, the track's entry and its 1.5 s release fade, and the pan speed were judged from frames only (STORY-26, STORY-27).
- Re-watching a fragment is deferred (draft §3); the page is the revisit.

## Tests

`bearer_schedule_test`, `bearer_fragment_catalog_test`, `bearer_fragment_director_test` (every start gate: a drawn Memorina, a talk, a scene, the past, a seat, the open map, a fight, a flashback visit, another acting pulse; there and back; a dropped call; a skip; refused travels; leaving the tree releases the music), `player_song_performed_test`, `engraving_math_test`, `engraving_view_test`, `engraving_caption_fit_test`, `cutscene_steps_test`, `cutscene_director_test`, `cutscene_rooms_test`, `flashback_rooms_test`, `notebook_catalog_test`, `notebook_text_fit_test`. Playtests: `story04_bearer_<g>.json`, `story04_bearer_skip.json`.
