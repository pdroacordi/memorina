---
id: architecture/story-05-playable-flashbacks
type: architecture
title: STORY-05 plan - a flashback is a visit to a twin past room (its own region at memory 1.0), entered and left by travel, staged by save facts; one appended SaveFact FLASHBACK_DUE; colour written only through MemorySources
status: built
tags: [story, flashback, cutscene, memory-field, greyhush, save-fact, travel, region, music, notebook, plan, story-05]
related: [systems/flashbacks, systems/story, systems/cutscenes, systems/dialogue, systems/greyhush, systems/life-benches-death, systems/world, systems/rooms, systems/notebook, systems/music, systems/input, systems/backdrops, architecture/cutscenes-are-data-played-between-two-rest-states, architecture/the-opening-is-staged-by-save-facts, architecture/the-region-owns-its-forgetting, architecture/memory-field-cpu-gpu-split, architecture/doors-and-interiors, architecture/music-system, bugs/a-cutscene-trigger-in-a-first-visited-room-never-arms, bugs/a-teleport-across-the-world-glides-like-a-seam-walk, bugs/a-teleported-ivo-enters-the-room-he-left, gotchas/a-teleported-kinematic-body-overlaps-from-its-old-place-for-one-step, gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move, gotchas/a-killed-tween-never-emits-finished]
created: 2026-11-11
updated: 2026-11-13
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

**Status: BUILT, 2026-11-13.** Planned 2026-11-11, scope `docs/design/drafts/camada_pessoal.md` §1-2 ("Aprovar o rascunho", user, 2026-11-11); steps 1-11 built 2026-11-12, step 12 (the contract `systems/flashbacks`) and the review fixes 2026-11-13. The current contract is `systems/flashbacks`; this entry keeps the reasoning and the history.

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
  - Levels (step 3, 2026-11-12): WORLD_RESTORED 0 (hidden); seen 5 +0.2; seen 4 -0.2; seen 3 -0.45; seen 2 -0.5 with 2+ restored, else -0.7; seen 1 -0.55 with 2+ restored, else -0.75; else -0.8. With the village baseline (0.8, 0.6 from 2 restored) the waterfall reads 0, 0.05, 0.1, 0.15, 0.4, 0.8 by flashbacks seen at every reachable restored count (flashback n needs n - 1), 1.0 once the world is restored.
  - It snaps at `_ready` and tweens on `progress_changed` (pausable, scaled).
  - The value is derived from SCENE_SEEN, never recorded.
- Waterfall and flowers are props with `AmbientMotion`, so they stop below 0.2 and run when remembered. `garden_memory_test` pins that the waterfall's cell reaches >= 0.2 only from seen 4. `garden_memory_test` pins those targets, under 0.2 through seen 3 and from 0.2 from seen 4, and a rise with every one seen.
- **Twin rule:** `garden_past.room` has the same ground grid as `village_garden.room`. The two Backdrops place every layer at the same room-relative pixel: pick the past x so each repeating layer's phase matches. `garden_twin_test` checks both rules.

### The past: region `past`, room `garden_past`
- `REGIONS` gets `past` appended last, so no other interior moves: memory 1.0, no guardian, no music, `shows_title` false, `calm_interiors`. `INTERIORS` gets `("past", "garden_past", 2, 1)`, with the garden's backdrop set (`INTERIOR_SETS`). Built (step 3) at (103680, 12000), not the slot (84000, 12000): `INTERIOR_ORIGINS` puts it at village_garden's x + 102400, the least shift at which every village_valley layer (scroll x 0.05, 0.12, 0.3, 0.55 over 1024 px) keeps its phase; the region horizon is 13003 (1003 px under the top, as the garden's).
- `Region.past` (bool) → `Room.is_past()` → Game copies it to `Player.in_past` on each room change, as it does `calm`.
  - The sword is refused by calm, as today.
  - `_try_memorina` sets `enabled = owns and not in_past`; items are untouched.
  - The map is refused.
  - `NoticeHold.applies` reads `is_in_story() or in_past`.
  - Talks, Up and Down stay live.
- Contents: no Enemy, HazardZone, Bench, Door, pickup, reward slot, or deep water (`flashback_rooms_test`). Both garden pools are the legend's shallow water `s` (reach role WADE, `water_shallow.tscn`: a pool with no Hazard), one row deep over stone: it reflects and splashes, Ivo wades. garden_past is an interior (calm, never mapped), but grows grass like the garden (`RoomMapNode._indoors`). The life HUD hides on `Game.room_changed` into a past room. A `Seat` with no `bench_id` only sits him down (`Game._on_player_sat_down`). `WorldEdges` walls it. The reach audit skips `past` rooms, as it skips the trials.
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
- Built (step 5, 2026-11-12; `systems/cutscenes`, "The visit"). Corrections to the plan: the travel is `FlashbackDirector.travel_requested(point, colour, seconds)` → `Game.travel()`, answered by `Game.travelled(arrived)` (Game cannot be asked by a signal of its own). `Flashback` also needs `past_room`, `arrival`/`arrival_facing` (where Ivo lands) and `entry_fade` (flashback 5 travels in 0 s). The director does not play `leaving`: the past's contents start it (a beat); the director waits for its recorded end. The host of opening and returning is the room's contents root, so "hosts resolve" became: a returning scene names only `ivo`, and the opening's ids resolve in the past room (checked when step 7 ships one). Music is asked after the talk ends, not at the crossing's end. The "due" check (`FlashbackSchedule.due == number`) also gates the start, so a replayed old crossing never travels.

### Cutscene vocabulary added (each with a `cutscene_steps_test` case)
- `MemoryBloom` (Node2D owning one hidden `MemorySource`, the bench `Bloom` pattern) + step `CutsceneBloom` (`bloom_id`, `at`, shape, rect/radius, offset, strength, ring, seconds). The cutscene's `restore` hides it.
  - Crossing: a positive bloom grows from the trigger. For flashback 1 it is a RECT from the waterfall's top downward.
  - Collapse: a -1 room RECT plus a +1 RECT the size of the view, centred on Alba's actor and shrunk to 0, so grey eats in from the edges and she goes last. Flashback 5 does this in 0 s.
- `CutsceneFade.colour` (white).
- `CutsceneMusicMark` (waits for `Music.position() >= seconds`): the cut lands before the lacuna. `MusicCue` has no `gap_at` (built, step 4): `CutsceneCatalog.validate` checks a mark against its own scene's cues (before the stream's end); `FlashbackCatalog` must check `entry_mark` and the leaving scene's marks against `Flashback.music` with `CutsceneMusicMark.fits`.
- `CutsceneFray` (actor, seconds): calls the actor's `CorruptionEdge.agitate(true/false)`. Alba's sprite carries a `CorruptionEdge` with `rest_fray` 0 and `creature_pass` false (built, step 4: it stays in the root canvas and carries the edge material only while agitated), so it stays the only writer of the edge uniforms.
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

### Flashback 1 (step 7, built 2026-11-12; `systems/cutscenes`, "Flashback 1")
- Corrections: the guitar's talk opens with a cue-only `flashback_1_take` (Ivo walks from the tree to her, 3.8 s) so the lines and the jam play beside her; the Talkable sits in the contents scene, not the `.room` (twin grids). The leaving is a beat of that talk, so the director waits for the talk to end under the black (`LEAVING_TALK`) before the travel back, cuts the visit's music at the leaving's end and holds a stream-less SCENE cue through the returning scene (the 1 s of silence). `Game.travel` emits `travelled` before the fade clears. `CutsceneMusicMark.every` (bar lines) and `CutsceneMuffle` were added. `wife_song_full` loops on beats before the lost ending (`systems/music`), so a long visit never reaches it and the leaving's mark lands on the next bar line.
- The laugh is a stand-in (her `sit_sing` loop at 2.5x, no laugh sound). The kneel is the bench's `sit` loop.
- Lines rewritten 2026-11-12 ("Eu gostaria de dar uma mudada no diálogo dessa cena, pq tá muito estranho. nada natural", user): Ivo "De novo essa?", Alba "É a única que eu sei inteira.", Ivo "Eu nunca acerto o meio.", Alba "Então toca o começo comigo. O meio eu canto." (the jam), Alba "Viu? Ninguém percebeu." (the leaving). The notebook page keeps its text until the user gives the new one.

### Flashback 2 (step 8, built 2026-11-12; `systems/cutscenes`, "Flashback 2")
- Corrections: the exit rooms are lake_glacier, woods_hollow_tree, orchard_cliff_chimney and caldera_sun_stair; the ribbon's nodes sit in their contents scenes, not the `.room`, and each region's talk has its own cue (`DialogueBeat.find` is tree-wide). A scene cannot walk Ivo back to her: the pool is a one-row dip he must jump. So the third flower plays the chest scene where he stands (the far frame), and her next talk (`flashback_2_pale`, gated on `SCENE_SEEN flashback_2_chest`) auto-starts when he comes back. Alba's poses are stagings on the SCENE_SEEN of the chest and tie scenes, not stand-ins.
- Stand-ins: `wife_song_full` as the music and the yellow flowers. The garden's art, the ribbon on its twig and the grey pocket around it landed 2026-11-12 (`systems/props`, "The waterfall garden"; `systems/cutscenes`, "The ribbon's art", "The grey pocket").

### Flashback 3 (step 9, built 2026-11-12; `systems/cutscenes`, "Flashback 3")
- Corrections: a beat ends a talk unheard through a new `DialogueBeat.abandon()` (the director refuses `interrupt()` while a beat runs). The raise's last cue plays the crossing as a `CutsceneBeat`, as the ribbon's does; the swing's rise is three stand-in frames (`swing_rise.png`) and a `SwingSway` at the top. In the past, Alba's `Swing` child carries the swing itself (a `SwingSway` with her figure on the seat), so the past's prop swing is a staging that hides while flashback 3 is due. The push talks are one set on one Talkable (`once`, each gated on the previous heard), one shared push beat; the fourth adds a let-go beat before the leaving. The light is a `Light` FactStaging (multiply and add overlays), not a `CutsceneVisual`: it lasts through free play. The leaving releases the visit's music to a stream-less cue, so the stop is silent.
- Two camera fixes found by the playtest (`bugs/a-flashback-return-glides-the-frame-from-the-past`): an end under an opaque fade cuts the frame back, and `GameCamera.snap()` lands a running zoom or pair ease.
- Stand-ins: her hands on the rope, Ivo's hoist, the creak (synthesized), the music; the shawl is not drawn.

### Flashback 4 (step 10, built 2026-11-12; `systems/cutscenes`, "Flashback 4")
- Corrections: the crossing ends black and `Flashback.entry_colour` (white by default) lets the travel cut to night under black. The music is a stream-less cue, so nothing plays; the water is a `FlashbackLure` with no zone in the past, silenced when the first talk is heard. The close on "Por você." is a second talk, auto-started, framed with a new `Dialogue.cut` (the frame lands at once): a beat's scene cannot hold the frame after it ends, and cannot hold a talk. The fray plays as that line's box closes, in the leaving scene. Her back is `PoolBack` (flipped `standing`), her turn a beat scene whose SCENE_SEEN stages `Turned`.
- Stand-ins: the water (synthesized), the ribbon on the wrist (in his hand), her untying (the `ribbon` clip).

### Flashback 5 (step 11, built 2026-11-12; `systems/cutscenes`, "Flashback 5")
- The hidden swap holds (playtest `playtests/2026-11-12-story05-flashback-5`); the soft-white fallback is kept for Ivo outside the swap zone at the mark. Corrections: the crossing is a scene with no steps, recorded on entering the garden, so the director's visit (music, mark, travel) runs while Ivo walks; a `FlashbackSwap` area in the present room makes the travel hidden (twin pixel, `Color.TRANSPARENT`, 0 s, `TravelPoint.keep_motion`) only while Ivo stands inside it on the floor, else the flashback's own entry plays. The past room is built ahead (`Room.prepare`) and the life notes fade at the visit's begin (`FlashbackDirector.visit_began`). Two seams the twin rule missed: the song's bloom must wear the region's season tint, and grass hashes on world columns (`Region.twin_shift`). The opening has no steps. The seat is a `GroundSeat` (`sit_ground`) that plays the leaving. One line, held (`DialogueLine.hold`). `Game.travel` awaits a physics frame after its cover (`bugs/a-travel-asked-under-a-cut-to-black-left-ivo-disabled`).
- The lure is Music, not Sfx: `FlashbackLure.voice` asks `wife_song_lullaby_far` at SCENE layer with a distance duck and a muffle; the water is the stand-in loop. The visit's cue is a separate resource, so the song restarts (cross-faded) at the garden.
- Not met in step 11: the widest shot was zoom 1 (the room's height). Met since the garden was rebuilt (2026-11-12, "The garden rebuilt"): zoom 0.5 frames the whole 1280x768 room, the waterfall in it.

### The garden rebuilt (2026-11-12; draft "Decisões", "O jardim refeito"; board `tools/art/references/regions/garden_concept_v2.png`)
- **Where.** `village_garden` moved to c5..6, r-3..-2 (x 3200..4480, y -1152..-384): the foot of the waterfall that feeds the mill's river, east off `lake_waterfall_path` (its east opening at rows 40-43 over a stub at row 44, cols 16-19, `[back]` rock at col 19 rows 39-44; the old west opening closed). Every way in still passes the mill's or the lane's `owns_memorina` fence. It touches only the trail; lake_ice_caves (r-5) and village_gate_east (r0) are 384 px off, so the gate keeps its sky band (`room_ring_test`). Two seams moved east with it (`backdrop_seams_test`: `x 3360, y -384..-224` UNDER_FLOOR_REGION, `y -1312, x 3200..3360` RING_LIMIT).
- **Size.** 2x2 screens (1280x768), so flashback 5's widest frame, zoom 0.5 (a 1280x720 view), stays inside the room: the cut-down zoom 1 of step 11 is gone. `Backdrop.widest_zoom` (0.5 in both gardens) grows each layer's cover to that view.
- **Twin.** `garden_past` is 2x2 at (105600, 12000): still village_garden's x + 102400, and the region `past`'s horizon is 13387 (1387 px under its top, as 235 is under -1152). The new sets keep the valley's x scrolls, so the shift still phases every layer (`garden_twin_test`).
- **Layout** (`village_garden.room` = `garden_past.room`). A grass bank, one earth row deep (row 20, floor y 640 local), "menos chão": the lake (`w`, rows 21-23) lies under it from wall to wall, so the water is in front of the characters and reflects them. The lake replaces both shallow pools; it has no hazard and every column of it lies under ground, so nobody can fall in (`flashback_rooms_test`, "nobody drowns"). East, a stone block (cols 36-39 rows 0-20, and cols 34-35 rows 4-20 since WORLD-46 so Ivo stops where the drawn cliff starts, x 1088, not in front of it; a third cliff copy, `FallsCliffMid` at y 540, covers that stone where the two copies recede) stops Ivo; the cliff (`falls_cliff`, twice: the lower foot in the water, a second copy above it) and the fall are drawn over it in `Contents/Falls` (z 10: over ground 0, under water 50, so the lake reflects them), the fall from y 44 to the surface (one `Sprite2D`, region 608 px since the lake rose, `AmbientMotion`), its foam on the surface under the fall's centre (x 1216). Dressing by x: bushes 92/712, white bed 132, old tree 250, swing 312, beds 440/520/616, flat stone 816, lantern 880. Every staging, mark, talk, trigger and bloom moved with the floor (y + 352) and, by the fall, west of the cliff's foot (x 1068), which draws over the stagings: flashback 2's flowers 960/1000/1040 (`far_side` 1040); flashback 4's Alba at 1040 facing the fall, Ivo arriving at 886 and stopping behind her at 1000 (the scene mirrored: `speaker_offset` +40). Flashback 1's crossing column runs down the fall (`waterfall_top` y 50 to `waterfall_foot` y 672). The collapse rects (`past_grey`) are 1408x896 at the room's centre. `GardenWell` covers x 3232..4448, y -1304..-384 (feather 32): the targets 0/.05/.1/.15/.4/.8, 1.0 restored, hold at the new foot (`garden_memory_test`).
- **Time of day.** `FactBackdrop` (`scenes/world/environment/backdrop/fact_backdrop.gd`, a `Sky` node beside `Backdrop`) is the only writer of its Backdrop's set: the first `FactBackdropSet` that holds, else the scene's authored set (`waterfall_garden_day`). The past: FLASHBACK_DUE 1 morning, 2 day, 3 afternoon, 4 night, 5 twilight. The present: day, and twilight while FLASHBACK_DUE 5 holds, so the hidden swap meets the same sky. The `Light` staging's overlays stay over the play plane (resized to the room); flashback 5's `SongTint` darkens on top as before.
- **The lantern.** `Props/Lantern` is a `FactStaging`: `Unlit` (`lantern.tscn`, frame 0), `LitDusk` and `Lit` (`lantern_lit.tscn`: frames 1-3 on `AmbientMotion` at 3 fps and a `PointLight2D`, `LanternLight`, whose energy follows the flame's frame, times `strength`, times the memory at the lantern). Past: unlit on flashbacks 1 and 2, `LitDusk` (strength 0.3) on 3, `Lit` on 4 and 5. Present: unlit, `Lit` only while flashback 5 is due, and then its light is the memory the song brings, 0 in the grey. The light's texture was a stepped radial gradient (four flat rings); since "The garden fixed" a smooth falloff. It lights the world canvas, which the lake's screen copy reflects, and Ivo's creature pass (measured: Ivo warms beside it). This revises `architecture/props-and-ambient-life` ("a PointLight2D... rejected") for this one lantern, at the user's request ("a lâmpada pode ter iluminação dinâmica", 2026-11-12), with its rule kept: the light is the place's life and goes with its memory.
- **Playtest** (`playtests/2026-11-12-story05-garden-rebuilt`): flashbacks 1-5 run end to end in the new geometry.

### The garden fixed (2026-11-12; "Corrige sim. Além disso, na foto mais zoomed out, veja a montanha. ela tá bugada" (user, 2026-11-12, on `f5_widest`, `t4_night`, `t3_afternoon`))
- **The mountain.** Cause: the garden's sets kept the valley's horizon row 229 on every layer, but the bank camera stands 788 px over the region's reference camera (horizon 747 px under the floor), and a layer drops on screen by that height times its vertical scroll: far 55, mid 142, near 252 px. Mid and near sat under the bank, so the far layer's mesas and the flat EDGE fill under its forest read as one striped block over the bank, worst at zoom 0.5. Fix in the data: `horizon_row` far 284, mid 371 (229 plus the drop), near 419 (62 px under its pose, so only its crowns show over the bank) in all five `waterfall_garden_*.tres`; at the bank camera mesas, forest, hills and tree crowns nest as in the valley (`garden_twin_test.test_the_garden_layers_stand_in_their_pose_at_the_bank`). The afternoon sun moved up to art y 46 (`cut_backdrop.py` TIMES) so it shows over the raised mesas.
- **The lantern.** A smooth radial falloff (`glow_falloff`, linear between 8 stops, 1 to 0) at `texture_scale` 2.5 (160 px), flame energies 2.6/3.0/2.8: a warm pool on the bank, the post, whoever stands by it and, through the screen copy, the lake. `Backdrop` sets `light_mask` 0 on its layers, so no halo is painted over the sky. `LitDusk` (afternoon): strength 0.12, `texture_scale` 1.0.
- **The grades are `CanvasModulate`s.** `Warm` (1, 0.96, 0.9), `Moonlight` (0.72, 0.76, 0.9) and `Dusk` (white to (0.56, 0.5, 0.72) by its `SongTint`, now writing `color` through `SongTint.property`) tint the world canvas, which the creature pass shares, so Ivo and Alba wear the same light. The multiply rects tinted only the root canvas: Alba's figures (root canvas) were cool and dark, Ivo (creature pass) was not. The light stages cut (`fade_seconds` 0): a `CanvasModulate` cannot fade by alpha. The afternoon sun's additive glow is 0.12 to 0.03.
- **A thinner bank.** `RoomMapNode.lake_rise` 22 in both gardens: the lake's waterline lies 22 px over its painted top (y 650 local), drawn over the bank row's lower earth, so 4 px of earth show under the grass lip; collision and the `.room` are unchanged, the lake still has no hazard. `WaterLayer.surface_inset` may be negative for a lake; a raised lake mirrors at its waterline. The fall's region ends at 652 (608 px) and the foam and `waterfall_foot` stand at 650.
- **Playtest** (`playtests/2026-11-12-story05-garden-fixes`): the five times at zoom 1 and 0.5, flashbacks 3, 4 and 5; the hidden swap's diff shows only motion.

### Alba
- A `Speaker` `alba` (`SPEAKER_ALBA`, portrait).
- A `StoryActor` `alba_actor.tscn` with `AlbaAnimationResolver` (clip consts), used only in scenes, covering the `Alba` staging. Free play shows the staging's figures.
- No `GreyhushShield`, no `AmbientMotion` on the actor.
- Built (step 6, 2026-11-12; `systems/cutscenes`, "Alba"), from the approved art, not placeholders. Corrections: the free-play figure is `alba_figure.tscn`, a `StagedStrip` holding every actor clip, which staging children instance with `loop` set to their own name; `StoryActor.enter` read `flip_h` only from a `Sprite2D`, so it now reads an `AnimatedSprite2D` child's too. The rest clips `stone`, `flowers`, `swing`, `pool_back` and `tree_with_daughter` reuse the strips (`sit_sing`, `pick` looped, `sit`'s last frame, `standing`, `lullaby`); the art has no swinging or back-turned strip.

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
- **`CorruptionEdge` on a root-canvas actor** writes alpha 253 (the unshielded mark) and would also move the actor onto the creature pass. Resolved (step 4): `creature_pass = false` swaps the material in only for the glitch (`systems/cutscenes`, "Added for the flashbacks").
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
- Art not in this plan: Ivo kneeling (flashback 1's returning stands in the `sit` loop), Ivo seated on the ground, the push gesture, the ribbon in hand, Ivo walking with the guitar, Alba laughing (a sound and a clip), the garden's waterfall and its flat stone (drawn 2026-11-12, `systems/props`).

## Decisions (user, 2026-11-11)

- Garden placement: "Pela trilha do Lago (Recommended)": `village_garden` at c2..3 r-2, entered from `lake_waterfall_path`; on a first visit the Frozen Lake title plays before the garden.
- The crossing: "Encenar sem câmera lenta (Recommended)": Ivo held still, sound out, colour from the trigger; no new `WorldFreeze` request.
- The ribbon: "Em toda região restaurada (Recommended)": while flashback 2 or 4 is due, a ribbon shows in every restored guardian's region; no new save data.
- After the final battle: "Seguem depois; epílogo exige o 5º (Recommended)": due flashbacks still play after the world is restored; the epilogue needs all five seen.
- Skipping: "Cenas puláveis, jogo não (Recommended)".
- Death: "Sim, como o resto (Recommended)": a death before a bench forgets a seen flashback.
- Flashback 1's "Mais devagar": "Tirar a fala (Recommended)"; the line is rewritten in the draft without asking for another tempo.
- HUD: "Esconder no passado (Recommended)": the life notes hide while Ivo is in the past.

## Revision (2026-11-16, STORY-07 step 6)

The well's first level was `WORLD_RESTORED → 0` (hidden), so a world restored with flashbacks still unseen showed the garden whole before its time. `GardenWell`'s levels now begin: WORLD_RESTORED and seen 5 → 0 (hidden); WORLD_RESTORED and seen 4 → -0.6, seen 3 → -0.85, seen 2 → -0.9, seen 1 → -0.95, none → -1.0, the same waterfall targets (0.4, 0.15, 0.1, 0.05, 0) at baseline 1.0; then the table above. `garden_memory_test` holds the world-restored rows (`architecture/story-07-epilogue`).

