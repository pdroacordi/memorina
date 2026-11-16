---
id: systems/flashbacks
type: system
title: "Flashbacks: five visits to a twin past garden, due one at a time from save facts, entered and left by Game.travel under a FlashbackDirector that holds the return point in memory only"
status: active
tags: [story-05, flashback, story, cutscene, travel, region, past, memory-field, music, save-fact, alba, garden]
related: [architecture/story-05-playable-flashbacks, systems/cutscenes, systems/story, systems/dialogue, systems/music, systems/notebook, systems/world, systems/rooms, systems/input, systems/life-benches-death, systems/greyhush, systems/backdrops, systems/grass, systems/props, playtests/2026-11-12-story05-flashback-1, playtests/2026-11-12-story05-flashback-2, playtests/2026-11-12-story05-flashback-3, playtests/2026-11-12-story05-flashback-4, playtests/2026-11-12-story05-flashback-5, playtests/2026-11-12-story05-garden-rebuilt, playtests/2026-11-12-story05-garden-fixes, bugs/a-quit-to-title-mid-scene-leaves-the-music-muffled, bugs/the-mill-lure-keeps-the-lullaby-playing-in-the-mill-house, bugs/a-flashback-return-glides-the-frame-from-the-past, bugs/a-travel-asked-under-a-cut-to-black-left-ivo-disabled]
created: 2026-11-13
updated: 2026-11-13
source_files:
  - scenes/world/story/flashback/
  - resources/story/flashbacks/
  - resources/cutscene/flashbacks/
  - resources/dialogue/flashbacks/
  - resources/save_facts/save_fact.gd
  - scenes/world/game.gd
  - scenes/world/rooms/region.gd
  - scenes/world/rooms/home_village/contents/village_garden_contents.tscn
  - scenes/world/rooms/past/contents/garden_past_contents.tscn
  - scenes/world/memory/fact_well.gd
  - scenes/ui/life_hud/life_hud.gd
  - globals/music/music.gd
---

# Flashbacks

**Never break:** Whether a flashback is due is derived (`FlashbackSchedule.due`), and "seen" is only the leaving scene's live `SCENE_SEEN flashback_<n>`; nothing else about a visit is recorded. `FlashbackDirector` holds the return point in memory only, writes no save, and is the only writer of the letterbox's rest thickness; Ivo reaches and leaves the past only through `Game.travel`. A visit never drops after its crossing is recorded: a refused travel is asked again.

## Summary

STORY-05, scope `docs/design/drafts/camada_pessoal.md` §1-2, plan `architecture/story-05-playable-flashbacks` (built 2026-11-12, closed 2026-11-13). A flashback starts in the present (a sound in the garden, a ribbon in a restored region, the fallen swing, the lullaby from the mill), plays one to two minutes in the garden of before in full colour with Ivo free to walk, talk and press Up, then returns him to the step and facing he left. No damage, death or save happens inside. The scene-by-scene data of each flashback lives in `systems/cutscenes` ("Flashback 1" to "Flashback 5", "Alba").

## Due and seen

- `SaveFact.Kind.FLASHBACK_DUE` (appended, `index` n) holds iff `FlashbackSchedule.due(data) == n`. `due` is the lowest unseen n in 1..5 whose gate holds: n = 1 needs the Memorina owned, n >= 2 needs n - 1 guardians restored; otherwise 0. One is due at a time, in order (`flashback_schedule_test`).
- Seen is `SCENE_SEEN flashback_<n>`, the leaving scene's id, recorded in the past before the travel back. It is live data: a bench commits it and a death forgets it with the restored guardians it was gated on.
- Every trigger, talk, staging, lure, well level and sky in both gardens is gated by `FLASHBACK_DUE` and `SCENE_SEEN`/`DIALOGUE_HEARD`, so every pose is derived and a quit loses a visit whole.

## The past region and the twin room

- Region `past` (appended last in `tools/maps/gen_world_shells.py`): memory 1.0, no guardian, no music, no title, calm interiors. `Region.past` reaches `Player.in_past` on each room change: the Memorina and the map are refused, the sword by calm, notices held; talks, Up and Down stay live (`player_past_test`).
- `garden_past` (2x2, at village_garden's x + 102400, y 12000) is `village_garden`'s twin: the same `.room` grid and water, dressing at the same room-relative pixels, every backdrop layer in phase (the shift keeps each scroll's phase), grass hashed on the present's columns (`Region.twin_shift`), the bloom wearing the region's season tint (`garden_twin_test`). Its contents hold no enemy, hazard, bench, door, pickup, reward slot or deep water (`flashback_rooms_test`). The life HUD hides there.
- `village_garden` (home_village, c5..6 r-3..-2) sits at the foot of the waterfall that feeds the mill's river, east off `lake_waterfall_path`, behind the Memorina fences (`systems/world`).

## The garden's well and sky

- `GardenWell`, a RECT `MemorySource` in `home_village.tscn` beside `Memory`, has one writer: a `FactWell` whose `FactLevel`s (first that holds wins) lift the waterfall's memory from 0 through 0.05, 0.1, 0.15, 0.4 to 0.8 as flashbacks are seen; once the world is restored the same targets hold at baseline 1.0 (seen 4: -0.6 to 0.4, seen 3: -0.85, seen 2: -0.9, seen 1: -0.95, none: -1.0) until all five are seen, which hides it (STORY-07 revision, `architecture/story-07-epilogue`). It snaps at `_ready` and tweens on `progress_changed` (`garden_memory_test`). The waterfall and flowers move only from 0.2 (seen 4).
- `FactBackdrop` (the `Sky` node) is the only writer of its Backdrop's set: in the past morning, day, afternoon, night and twilight for flashbacks 1 to 5; in the present day, and twilight while flashback 5 is due. The lantern is a `FactStaging` with a `PointLight2D` whose energy follows the memory at it. Grades are `CanvasModulate`s so Ivo and Alba share the light (`architecture/story-05-playable-flashbacks`, "The garden fixed").

## The director and the travel

- `FlashbackDirector` (`World/FlashbackDirector`, INHERIT; exports `catalog`, `cutscenes`, `dialogue`, `ivo`, `letterbox`) runs one visit: crossing recorded and due, then no talk open, then the visit's SCENE-layer music (owned by itself), then the entry mark, then `travel_requested(point, colour, seconds)` → `Game.travel`, answered by `Game.travelled(arrived)`. In the past it sets the bars to `bars_thin` and plays `opening`; the past's contents start `leaving` (a beat); its recorded end sets the bars to 0, cuts the music to a stream-less SCENE cue (`SILENCE`), waits out any open talk under the black and travels back under a 0 s black, then plays `returning` and releases the music.
- **The travel** (2026-11-13). `Game.travel` refuses only during its own transitions: a door, a death or an out-of-bounds recovery. A refused travel in goes back to waiting at the mark and is asked again on the next physics frame; a refused travel back goes back to `LEAVING_TALK` and is asked again. Dropping the visit instead would strand it: the crossing's `SCENE_SEEN` is recorded (it gates the crossing's trigger and the lure off) while the flashback stays due, and un-recording it would make a second `SCENE_SEEN` writer. A death's swap forgets both the visit and the crossing (live data), so nothing is stranded there either (`flashback_director_test`).
- **The hidden swap** (flashback 5): at the mark, inside the room's `FlashbackSwap` of its number, with Ivo on the floor, not in a talk and with the Memorina sheathed, the travel goes to the twin pixel, `Color.TRANSPARENT`, 0 s, `TravelPoint.keep_motion`. Outside it the flashback's own entry plays (a soft white). The visit's begin prepares the past room (`Room.prepare`) and fades the life notes (`visit_began` → `LifeHud.on_visit_began`).
- `_exit_tree` forgets the visit and writes nothing; owned music requests, ducks and muffles end with their owners.
- `Flashback` data (`resources/story/flashbacks/flashback_<n>.tres`): `number`, `crossing`, `opening`, `leaving` (id `flashback_<n>`), `returning`, `music`, `entry_mark`, `entry_fade`, `entry_colour`, `bars_thin`, `past_room`, `arrival`, `arrival_facing`. `FlashbackCatalog.validate` is asserted in debug builds.

## The lure

`FlashbackLure` (Node2D) sounds a flashback's call (or a sound of the past) on Sfx while its gates hold, and while Ivo is inside its `zone` ducks the music under its own name; with a `voice` it asks that cue at SCENE layer, the duck rising toward `near_db` as he nears, and muffles the bus 0.6. Its duck and muffle are owned by the lure (`Music.duck(id, db, owner)`, `systems/music`, "Owners"), and it releases all of it on `_exit_tree` and on `NOTIFICATION_DISABLED`, since an idled room's nodes are disabled, never freed (`bugs/the-mill-lure-keeps-the-lullaby-playing-in-the-mill-house`).

## The cutscene vocabulary it uses

`MemoryBloom` + `CutsceneBloom` (colour grows from the trigger, the collapse shrinks a keep to Alba last), `CutsceneFade.colour` (white), `CutsceneMusicMark` (with `every` for bar lines), `CutsceneFray` (flashback 4 only), `CutsceneTrigger.zone`, `CutsceneMuffle` (owned by the cutscene director), `Letterbox.rest_thickness`, `Dialogue.cut` and `DialogueLine.hold`; beats `GuitarJamBeat` (never finishes the morning song), `SwingRaiseBeat` (HELD_UP over `HoldRise`), `SwingPushBeat`, `CutsceneBeat`; `SongBloom` and `SongTint` (flashback 5's colour and dusk follow the song's position); `GroundSeat`. All in `systems/cutscenes`, `systems/story`, `systems/dialogue`.

## Alba

Her `Speaker` `alba` (`SPEAKER_ALBA`, portrait), a `StoryActor` (`alba_actor.tscn`, `AlbaAnimationResolver`) used only inside scenes, and the free-play figure `alba_figure.tscn` (a `StagedStrip` holding every clip) under the `Alba` `FactStaging`, picked by `FLASHBACK_DUE` and the visit's heard and seen facts. No `GreyhushShield` or `AmbientMotion` on the actor (`systems/cutscenes`, "Alba").

## Single writers

- `FlashbackDirector`: the letterbox's rest thickness. It and `BearerFragmentDirector` (`systems/bearer-fragments`) are the askers of `Game.travel`; each acts on `travelled` only while it awaits its own travel.
- `FactWell`: `GardenWell.strength` (and each ribbon room's `GreyPocket`).
- `FactBackdrop`: its Backdrop's set. `FactStaging`: its children's visibility.
- `CutsceneDirector`: `SCENE_SEEN`, crossings and leavings included.
- `Music`: the Music bus's low-pass; `WorldFreeze` is never asked by a flashback.

## User decisions, in their words

- 2026-11-11: "Aprovar o rascunho" (the draft `camada_pessoal` §1-2). "Pelo progresso (Recommended)": the first flashback after the Memorina, then one per guardian restored. Where: "Acho interessante um lugar que era importante para o casal. um lugar muito bonito, como um jardim, com cachoeira, algo assim." Her name: "Alba (Recommended)"; "gostaria que ela fosse ruiva". "Podemos fazer os gatilhos, transições para flashbacks e plays bem cinemáticos e dramáticos."
- 2026-11-11, the plan's decisions: "Pela trilha do Lago (Recommended)"; "Encenar sem câmera lenta (Recommended)": no slow motion, no `WorldFreeze` request; "Em toda região restaurada (Recommended)": the ribbon in every restored guardian's region; "Seguem depois; epílogo exige o 5º (Recommended)"; "Cenas puláveis, jogo não (Recommended)"; "Sim, como o resto (Recommended)": a death forgets a seen flashback; "Tirar a fala (Recommended)" (flashback 1's "Mais devagar"); "Esconder no passado (Recommended)": the life notes hide in the past.
- 2026-11-12: flashback 1's lines, "Eu gostaria de dar uma mudada no diálogo dessa cena, pq tá muito estranho. nada natural". The grey pocket, "Um bolsão cinza em volta (Recommended)". The notebook pages 1 to 5, "Aprovar". The garden rebuilt: "No pé da cachoeira do rio (Recommended)"; "a cachoeira deve ficar mais perto, na frente dos personagens. [...] a lâmpada pode ter iluminação dinâmica. o céu e iluminação também deve variar."; the board v2, "Aprovar a prancha"; the art, "Aprovar", with "menos chão para os personagens ficarem mais próximos da água". The fixes: "Corrige sim. Além disso, na foto mais zoomed out, veja a montanha. ela tá bugada".

## Known limits

Audio has not been judged by a human (every playtest reads frames only). Stand-ins: the synthesized water and rope creak, Ivo's hoist and the hands on the rope (flashback 3), her shawl, the ribbon on the wrist (flashback 4), Alba's laugh (flashback 1), the yellow flowers across the pool (flashback 2), and the lullaby restarting at the garden's entrance (a separate cue cross-faded, not one take from the mill). Open roadmap rows hold them.

## Tests

`flashback_schedule_test`, `save_fact_test`, `fact_well_test`, `garden_memory_test`, `hold_rise_test`, `guitar_jam_test`, `flashback_catalog_test`, `flashback_director_test`, `flashback_lure_test`, `swing_beats_test`, `song_progress_test`, `flashback_rooms_test`, `garden_twin_test`, `player_past_test`, `cutscene_steps_test`, the fit tests. Playtests: `story05_flashback_<1..5>.json`.
