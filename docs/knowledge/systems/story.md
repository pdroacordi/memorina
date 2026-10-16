---
id: systems/story
type: system
title: Story staging and beats: FactStaging picks a pose by save facts, beats borrow Ivo, the guitar can never finish the song
status: active
tags: [story, staging, save-fact, beat, guitar, melody, dialogue, opening]
related: [architecture/the-opening-is-staged-by-save-facts, playtests/2026-10-15-story03-opening, systems/dialogue, systems/props, systems/input, systems/notebook, systems/life-benches-death, systems/pickups, gotchas/a-killed-tween-never-emits-finished, gotchas/a-removed-subtree-emits-tree-exiting-later-siblings-first, gotchas/json-numbers-are-floats-so-array-has-an-int-misses-them, gotchas/a-preloaded-resources-typed-enum-array-reads-as-array-int]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - resources/save_facts/fact_stage.gd
  - scenes/world/environment/props/fact_staging.gd
  - resources/story/melody.gd
  - resources/story/guitar_attempt.gd
  - resources/story/morning_song.tres
  - resources/story/guitar_first.tres
  - resources/story/guitar_again.tres
  - scenes/world/story/guitar_phrase.gd
  - scenes/world/story/guitar_beat.gd
  - scenes/world/story/staged_beat.gd
  - scenes/world/story/staged_strip.gd
  - scenes/world/story/melody_player.gd
  - scenes/world/dialogue/dialogue_beat.gd
  - scenes/world/dialogue/dialogue_director.gd
  - scenes/ui/phrase_sheet/phrase_sheet.gd
  - scenes/ui/dialogue_box/stutter_text.gd
  - scenes/characters/ivo/player_input.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/player_animation_resolver.gd
  - globals/boot_policy.gd
  - resources/dialogue/village/
  - resources/save_facts/village_at_six_tenths.tres
  - tools/audio/synth_story_placeholders.py
---

# Story staging and beats

**Never break:** A scene's pose is derived from save facts, never recorded: a `FactStaging` is the only writer of its children's visibility, picks its stage from the save on ready and on `progress_changed`, and a beat only asks it for a stand-in. Beats run on the pausable, scaled clock and never touch `WorldFreeze` or `TIME`. The guitar can never finish the morning song (`played() <= gap_index < notes.size()`).

## Summary

STORY-03: the mechanisms (phase A) and the opening's content (phase B), both built 2026-10-15. Plan: `architecture/the-opening-is-staged-by-save-facts`. Script: `docs/design/05_roteiro.md` (draft 2, "Approve draft 2 (Recommended)", user, 2026-10-15). The opening changes the same rooms many times as story facts accrue; talks hand off to beats that need Ivo's notes, his pose or his stillness; two of its remembered choices are gestures with no question.

## Staging (`FactStage`, `FactStaging`)

- `FactStage` (`resources/save_facts/fact_stage.gd`): `when` / `unless` (SaveFacts), `show` (a child name; empty hides every child), `fade_seconds` (0.5 by default).
- `FactStaging` (`scenes/world/environment/props/fact_staging.gd`, a Node2D under a contents scene's `Props`, INHERIT) shows exactly one of its children: the first stage that holds, in priority order, as `DialogueSet.current()` picks a talk. `FactStaging.pick(stages, data)` is the pure rule; -1 when none holds.
  - At `_ready` it shows its stage at once, so a world rebuilt after a death or a load shows the saved pose with no fade.
  - On `progress_changed`, when the pick changes, it cross-fades the outgoing and the incoming child's `modulate.a` over the new stage's `fade_seconds` on one tween bound to itself (pausable, scaled). A new change mid-fade snaps the running fade to its end first (`gotchas/a-killed-tween-never-emits-finished`).
  - `stand_in(child)` shows that child at once, until the picked stage next changes (the talk's end flips it) or `release()`.
  - Never put `RegionPresence` on a direct child: it would fight the staging over `visible`. Nest it one level down.
  - `cover()` / `uncover()` (STORY-15, `systems/cutscenes`): a cutscene's `StoryActor` stands for the shown child. Covered, the staging hides itself (its own `visible`) and keeps re-picking silently; uncovered it snaps any fade and shows its pick, or a live stand-in, at once. The director records SCENE_SEEN before it uncovers, so the rest after a scene is derived.

## Beats

- `DialogueBeat` (`systems/dialogue`) gains:
  - `hold` (`Hold { FREE, STILL, NOTES }`, STILL by default): FREE lets Ivo move; STILL keeps the talk's block; NOTES lets only the four note inputs through.
  - `pose` (`Pose { NONE, GUITAR, MEMORINA }`): held from the beat's start until the next beat or the talk's end.
  - `face` (a NodePath; empty keeps the speaker): Ivo turns to it as the beat starts.
  - `receive_note(note, glyph_set)` → `note_received`; `phrase_shown(notes, count, glyph_set)`, `phrase_lit(index)`, `phrase_closed`, which the director relays to the `PhraseSheet` (and closes when the beat ends).
- **`GuitarBeat`** (`scenes/world/story/guitar_beat.tscn`; NOTES, GUITAR): plays a `GuitarAttempt` with `GuitarPhrase`. It shows the phrase up to its gap, sounds each press (a right note: its string, lit on the sheet; a wrong note: its string, nothing lit; at the gap: `guitar_muted`), drops a press inside `min_gap` (0.08 s), and ends after `end_after_dead_presses` (3) presses or `end_after_silence` (2 s) at the gap. Silence before the gap waits. `stand_ins` (`{FactStaging path: child}`) are stood in as it starts.
- **`StagedBeat`** (`scenes/world/story/staged_beat.tscn`; STILL by default): stand-ins, a `stream` or a `melody` (its first `melody_count` notes through a `MelodyPlayer` with `voices`), an optional pulse (`pulse_song` for its colours, `pulse_stats`, `pulse_at`) through its `PulseEmitter` child with `song_acts = false`, and `duration` scaled seconds, at least the melody's length. `release_stand_ins` gives its stand-ins back to their staging's picked stage when it ends (the mentor's phrase), through `FactStaging.release(child)`, which acts only while `child` is still the stand-in, so a beat never undoes a later beat's; otherwise they last until the stage changes (the gift).
- **`StagedStrip`** (`scenes/world/story/staged_strip.gd`, an `AnimatedSprite2D`): a FactStaging child that moves while shown: `intro` once, then `loop`, from the first frame each time it is shown, stopped when hidden. It runs on the pausable, scaled clock like the beat that stands it in, so it is not ambient motion (`systems/props`); the staging stays the only writer of its visibility.
- **`MelodyPlayer`**: sounds a `Melody`'s notes on their onsets on the pausable, scaled clock; `note_played(index)`, `finished`.
- Beats live in a contents scene under a `Beats` Node2D beside `Props`; Talkables stay legend `t`. Every cue a talk names has exactly one beat, and every beat answers a named cue (`story_beats_test`).

## The guitar's rules (`GuitarPhrase`, pure)

- `press(note) -> {PLAYED, MISSED, DEAD}`. Before the gap a right note plays (and lights); a wrong one sounds its string and does not advance ("Sounds, doesn't advance (Recommended)", user, 2026-10-15). At the gap every press is DEAD, a muted thump (the plan's default, 2026-10-15).
- `played() <= gap_index < notes.size()` by construction; `guitar_phrase_test` presses every sequence of seven (all 4^7) and the melody twice over.
- `Melody` (`resources/story/melody.gd`): `notes`, `beats`, `beat_seconds`; `onsets(count, tempo)`, `duration(count, tempo)`, `validate()`. Never a `Song`: it is in no `SongCatalog` and teaches nothing.
- `morning_song.tres`: E G E D | C D E C on the Memorina's inputs (UP G4, RIGHT E4, LEFT D4, DOWN C4) = RIGHT UP RIGHT LEFT DOWN LEFT RIGHT DOWN, beats 1 1 1.5 0.5 1 1 1 2.5 at 0.42 s ("Approve melody (Recommended)", user, 2026-10-15).
- `GuitarAttempt`: `guitar_first.tres` (gap 5: he stops after the fifth note) and `guitar_again.tres` (gap 4: one note earlier on "[Try again]").

## The opening (phase B)

Script: `docs/design/05_roteiro.md`, Acts 1, 3 and 4, its wording kept in both languages. Ivo has no spoken lines; his three choices are gestures or an answer to a question, each a HOLD_ON and a LET_GO.

**Data** (`resources/dialogue/story/`):
- One set per Talkable: `daughter_bed`, `daughter_near`, `daughter_guitar`, `baker`, `elder`, `mentor`, `mentor_stasis`.
- New speakers: `baker` (`SPEAKER_BAKER`, no portrait), `elder_model` (the elder with the lighthouse model's base, `elder_model.png`), `mentor_stasis`.
- Text keys: `DLG_<DIALOGUE>_<NN>` and `DLG_CHOICE_<CHOICE>`.

**Melodies and pulses:** `resources/story/mentor_phrase.tres` (G E D C = UP RIGHT LEFT DOWN, beats 1 1 1 2) and `story_pulse_stats.tres` (radius 96, a breath long).

**The Memories entry:** `lore_mentor` (DIALOGUE_HEARD `mentor_gift`), titled "The keeper of the lighthouse", first in the Memories section.

| Room (legend `t`) | Talks, in priority order | Stagings under `Props` | Beats under `Beats` |
|---|---|---|---|
| village_house: bed (col 2, Up, on her in bed at x 58), by the door (col 3, auto, `auto_delay` 0, on her at x 84), at the guitar (col 9, auto, 3 cells) | bed: `daughter_eyes` (≥2; LET variant), `daughter_errand` (unless `baker_errand`), `daughter_turned` (after the song, until the gift); door: `daughter_song` (once, after the errand, until the gift), `daughter_return_hum` (once, gift + `guitar_lower`); guitar: `daughter_return` (once, gift + `guitar_try_again`) | `Daughter` (girl-only children over the `ChildBed` prop, STORY-15): AtGuitar (gift + Try again, until `daughter_return`) · Standing (≥2; gift) · InBedTurned (SCENE_SEEN `daughter_to_bed`, or `daughter_song` heard) · HoldingOut · Asleep. `WallGuitar`: none (gift + Try again, until the return) · OnWall (after the song) · none (after the errand, until the gift) · OnWall; child Lowered. `Drawings`: Repeated (≥2) · Usual | `guitar_first`, `guitar_again` (GuitarBeat, stand-in Standing), `guitar_lowered` (the guitar Lowered, `daughter_hum_four`), `daughter_guitar` (her four notes on the strings), `daughter_hum_five`, `daughter_to_bed` (a `CutsceneBeat`: she goes to bed, `systems/cutscenes`) |
| village_bakery (col 6, Up) | `baker_errand` (once) | `Baker`: Idle (the inhabitant), stand-ins TwoLoaves, OneLoaf | `baker_two_loaves` (0.6 s), `baker_loaves` (1.2 s) |
| village_elder (col 10, auto, between the elder and the painting) | `elder_story` (once, after the song; asks "It had an end…": `elder_wait` / `elder_painting`), `elder_return` (once, `mentor_gift` heard; speaker `elder_model`), `elder_empty` (once, ≥2) | `Audience`: Listening (the two children by the new bench) until `elder_story` or 0.6, fade 1 s | `elder_painting` (Ivo faces the painting, 1.5 s) |
| village_square | none | `Children`: Playing after `elder_story` or at 0.6 (the two children moved here) | none |
| lighthouse_interior (col 8 on the gallery, auto; col 7, Up) | `mentor_gift` (once); `mentor_stasis` (after the gift) | `Mentor`: Stasis (`mentor_gift` heard, 1.5 s) · Holding (the empty hand with `memorina_in_hand` over it); the phrase's beat stands in Playing (a `StagedStrip`: `raise.png` 5 frames at 10 fps, then `play.png` 6 frames looped at 8 fps; the strips draw the flute, so `memorina_in_hand` is hidden with Holding) and releases it at its end; the gift's beat stands EmptyHand in | `mentor_phrase` (the phrase on the Memorina's notes, a winter pulse at `Pair`), `mentor_gift` (the grant lands; pose MEMORINA, the woman's hum, a spring pulse), `memorina_flat`, `memorina_lowered` |

- **The opening's start:** a new game has no bench and no items in any build (STORY-14), so Ivo starts where `game.tscn` places him: in village_house, with the daughter asleep (`opening_test`).
- **The village's interiors are calm** (STORY-14): `home_village.tscn` sets `Region.calm_interiors`, so `Room.is_calm()` holds in every village interior. Game copies it to `Player.calm` where it changes rooms, and `Player._can_use_sword` refuses the swing while calm: an attack press does nothing (`player_calm_room_test`). It replaced the unused `CombatDisabledZone` counter. It is on the Region because Room triggers regenerate.
- **The opening plays in order.** village_gate_east's way east is a `FactBarrier` (legend `X`, col 38, the chained village gate) on `heard_elder_story.tres` (DIALOGUE_HEARD `elder_story`; both of his choices end that talk). No text explains it; the gate just stays closed. The errand comes before the song (`daughter_song` when `baker_errand`), the song before the story (`elder_story` when `daughter_song`), and the story before the lighthouse.
- **The stages read talks, not items.** Where the gate makes the order certain, the house's and the mentor's stages and talks read `mentor_gift` heard instead of owning the Memorina, which the same talk grants. A save that owns the sword and the Memorina early (a playtest's kit) still shows the daughter asleep, the guitar on the wall and the mentor holding the instrument; the morning plays the same. Only the fences (`owns_memorina.tres`) and the Memorina's own uses read the item.
- **The bench empties at 0.6 too** (`GUARDIANS_RESTORED_AT_LEAST 2`), and the square's children play there from the elder's story or 0.6.
- **A beat's `face` holds until the talk's end**: the talk resumes facing it, not the speaker (`DialogueDirector._facing`). The elder's talk starts east of him (col 10), so "[Look at the painting]" turns Ivo away from him and the elder speaks behind him.
- **Built differently from the plan:**
  - The baker takes two loaves on a cue after "Round one?" (`baker_two_loaves`) before `baker_loaves`.
  - The hummed return is its own dialogue (`daughter_return_hum`) at the door's Talkable, because she stands somewhere else after each choice and a dialogue lives in one set.
  - `daughter_eyes` is in the bed's set, so it is Up only.
  - Her standing still is by the wall under the drawings (x 44, facing east), so Ivo talks to her from beside the bed without standing in the door's reach.
  - The elder's audience fades out over 1 s and appears in the square with no fade.
- **Doors hide their Up prompt while Ivo is talking** (`Door._physics_process` refreshes it while he is in reach), since a door is refused until the talk ends.
- **The choices' Portuguese** ("[Tentar de novo]", "[Baixar o violão]", "[Esperar por ele]", "[Olhar o quadro]", "[Tocar de novo]", "[Baixá-la]") is not in the script; it is the orchestrator's translation, for the user to review.

## Ivo in a beat

- `Player.pause_talk(hold, pose, at)`, wired from `DialogueDirector.talk_paused(hold, pose, at)`:
  - STILL keeps (or takes) the talk's block;
  - NOTES sets `PlayerInput.notes_only`: only `note_pressed` is emitted and every axis reads 0, so no reader is added. `Player` sends the note to `beat_note_pressed`, not to `MemorinaComponent`, and `DialogueDirector.hear_note` passes it to the beat;
  - FREE frees him.
- **The resume rule:** `_try_talk` resumes a talk under the start gates, but a block the STILL beat itself holds is the talk's own and does not refuse it.
- **Poses:** `held_pose()` and `just_strummed()` are read by `PlayerAnimationResolver`: GUITAR loops `guitar_hold`, and plays `guitar_strum` once on each note (a note mid-strum restarts it), then the hold again; MEMORINA plays `memorina_draw` then `memorina_idle` without drawing the instrument (the component stays sheathed). The pose drops at `end_talk`, and he lowers the flute (`memorina_lower`).
- **Clips (STORY-10):** both run the six frames of `assets/sprites/characters/ivo/ivo_guitar.png` (128x128, a strumming loop: PixelLab frames 0,1,2,3,2,1; contract `tools/art/prompts/ivo_guitar.md`). `guitar_hold` loops them at 6 fps (1 s) so he is never still holding the guitar; `guitar_strum` plays them once at 12 fps (0.5 s). The user: "the sprite for playing the guitar is very wrong. Not the style of Ivo character. Better redo it. Also, transform it into animation, not static. Simple animation" (2026-10-15). `ivo_sheet_test` holds them to the floor line and lets the sheet use the guitar prop's own colours (`HELD_PROPS`); `player_beat_test` checks the loop moves, a note strums and a second note restarts it (`playtests/2026-10-15-story10-guitar`).
- **The Memorina in the story (STORY-11):** Ivo's Memorina clips are the ones every performance uses (`systems/animation`). The mentor raises and plays his own flute during `mentor_phrase` (`StagedStrip` Playing, above): "Should have an animation for when playing memorina too." (user, 2026-10-15). The strips face west like his stills, 128x128 with his feet on row 125; frame (24, 6) is the stills' (0, 0), so the strip sits at offset (-61, -126) from the stills' position, flipped east.
- **The guitar's sheet (STORY-14; STORY-13's dedicated guitar frame will replace the nine-patch):** "os botoes do hud do violão estão muito pequenos, diferente do hud da memorina" (user, 2026-10-15). `PhraseSheet` uses the Memorina's glyph scale (1.5) and column width (11 art px, 22 px). Eight columns need a staff 22 art px longer, so the frame is 300 px wide: a `NinePatchRect` of `memorina_hud.png` (margins 50 and 26 art px, the staff tiled between them) drawn at scale 2. `NoteSheet` takes its px per art px from its height (`SOURCE_HEIGHT`) and lengthens the staff by whatever its width exceeds the art's at that scale, so the frame's width is the one number; the Memorina's 256x128 frame is unchanged (`phrase_sheet_test.test_its_glyphs_and_columns_match_the_memorina_sheet`).
- **The talks in the opening (STORY-14):** every `t` is centred on its speaker. In the house (re-laid in STORY-15), the song's talk (col 3) is centred on the girl holding the guitar out at x 84 (`speaker_offset` -28, `reach_west` 60, `reach_east` 21): 81 px wide and 23 px short of the door at col 4, with `auto_delay` 0 so Ivo stops at its east edge, east of her. The bed's talk (col 2, Up) is centred on her in bed at x 58 (`reach_west` 26, `reach_east` 40): 30 px short of the door. The elder's (col 8, on him) reaches 80 px east of him and none west, so Ivo stands between him and the painting. Every auto talk is at least 80 px wide: narrower than about 72 px, a run through it leaves before `auto_delay` (0.4 s) passes (bugs/the-daughters-song-talk-needs-ivo-inside-her-and-a-run-past-never-starts-it; `talkable_rooms_test`, `player_talk_test.test_running_through_an_auto_talk_starts_it`). The lighthouse's two talks were already on the mentor.
- **The daughter goes to bed (STORY-15, `systems/cutscenes`):** after "…" on either answer the song's last line cues `daughter_to_bed`, a cutscene that replaced the InBedTurned cross-fade: she lowers her eyes, turns her back on Ivo, walks west to the bed, crouches, lies down onto the mattress, and the frame closes in. The house was re-laid for it and for the user's bigger bed (48x30): `Props/ChildBed` at x 56 against the west wall; the staging's children are the girl only, each a `Sprite2D` at her feet: Asleep and InBedTurned are `lie_down.png`'s last frame, flipped, 12 px up on the mattress at x 58 (the old composites `child_bed_asleep`/`child_bed_turned` were deleted: the 11 px bed hid her head), HoldingOut at x 84, Standing at x 90 (she stands between the bed and Ivo during the song). The talks' numbers are in the table above.
- **The daughter's poses (STORY-12):** "The child in the second shown frame is too static (and too different from the one in the first shwon frame)" (user, 2026-10-15).
  - Standing (`daughter/standing.png`, 8 frames, ping-pong) and HoldingOut (`daughter/guitar_out.png`, 6 frames, ping-pong baked in) are 64x64 strips of the same girl as her guitar pose. They breathe through `AmbientMotion` at 6 fps on the memory clock, like the villagers (`systems/props`, Inhabitants), and FactStaging stays the only writer of their visibility.
  - Both face east as drawn, with no flip. Since STORY-15 Standing is at x 90 and HoldingOut at x 84, by the bed's foot; Ivo is east of her in every scene that shows them.
  - Feet are on row 61, so the offset is (-32 or -26, -62) and the feet stand on the floor (y 288) in every frame (`opening_test.test_the_daughter_moves_as_a_strip_with_her_feet_on_the_floor`).
  - The seated guitar pose stays a still; the in-bed stages are the `lie_down` clip's last frame (STORY-15).

## Village voices (STORY-09)

"Story cast + some villagers (Recommended)" (user, 2026-10-15); the lines are design 05's "Village voices (STORY-09)" table ("Approve draft 2 (Recommended)"), word for word, en and pt_BR. One optional line per villager, Up to talk, by memory step; forgetting shows in behaviour and nobody comments on it. The 1.0 Return is STORY-07.

- **The step:** `resources/save_facts/village_at_six_tenths.tres` (GUARDIANS_RESTORED_AT_LEAST 2) is the 0.6 condition of every voice. `village_voices_test` ties it, and every GUARDIANS_RESTORED_AT_LEAST in the village's contents scenes, to the key `home_village.tscn`'s `Memory.steps` gives 0.6 at, so a retuned step fails the test instead of leaving the voices behind. The voices know 0.8 and 0.6 only, and the 0.6 fact has no upper bound: the same test fails on any `Memory.steps` key above 2. **STORY-07** (the Return, 1.0) must give every voice an `unless` for its step before adding it.
- **Talkables** (legend `t`, on the speaker's cell, the zone centred on the speaker: STORY-14, `systems/dialogue`):
  - square col 18 on the boy (`speaker_offset` 8), reaching 16 px east of him so the bell tower door at col 20 keeps 24 px (bugs/the-boys-talk-prompt-shows-over-the-bell-tower-door-and-up-enters-the-tower);
  - square col 32 on the water carrier (`speaker_offset` 10). She is flipped to face east, away from the well's shaft, so Ivo talks to her from in front, close, over the well's lip;
  - lane west col 17 on the seller, `presence` 0.7 so it leaves with him;
  - tavern col 14, row 20, on the taverner (`speaker_offset` 12);
  - bakery col 7 on the baker.
  - **Rule:** a talk zone keeps more than Ivo's body width (22 px) from every door zone on its row, or both prompts show and Up takes the door. A door beside a talk wins: the talk is trimmed on the door's side only (`village_voices_test.test_no_talk_stands_within_a_body_of_a_door`, every room with a talk).
- **Sets** (`resources/dialogue/village/`, speakers with a name plate and no portrait):

| Who | 0.8 | 0.6 |
|---|---|---|
| Baker (`story/baker.tres`) | `baker_errand` while due; then `baker_cough` once (the greeting `DLG_BAKER_ERRAND_01` again, then the cough line); then `baker_again` (the greeting alone, every time) | `baker_06` (the errand still wins while due) |
| Taverner | `taverner_quiet` | none: no prompt |
| Water carrier | `water_carrier_water` | `water_carrier_06` ("…") |
| Seller | `seller_apples` | gone with him (Talkable `presence` 0.7) |
| Boy | `boy_statues`, once the children are in the square (`elder_story`) | `boy_alone` (the girl leaves at 0.6) |

- **The cough says the greeting first** so it is said "in passing" (01 §9) and never comes out of nowhere; it is `once` and needs `baker_errand` heard. The baker's FactStaging is untouched: no new line has a cue. A death before a bench forgets it like any heard talk, so it can play again: "Keep it: a death rewinds what was heard, so the baker's cough can play again before a bench. It's consistent with the rest of the save." (user, 2026-10-15).
- **The taverner's two mugs** (design 05: "He sets two mugs on the counter, one in front of the patron's empty seat, and waits."): a `Mugs` FactStaging in village_tavern shows `AtSix` (two `tavern/mug.tscn`) on `village_at_six_tenths.tres`, so their presence is derived like every stage. One stands on the bar counter's top by the taverner (448, 636). The patron's seat is the bench at x 604 by table A, east of the counter's end (x 482), so the other stands on table A's west end in front of that bench (636, 652). `prop_grounding_test` holds both to their support (`SUPPORTED`). Up on him at 0.6 gives nothing: the gesture is the line.
- **Not built (behaviour, art needed):** the water carrier holding the full bucket at the well at 0.6 (she keeps her idle loop), and the baker going back to the dough after the cough line (she keeps her idle). Neither is staged; each needs a pose strip.

## The box and the notebook

- **Silent ask** (a gesture): an asking line with no text, no speaker and no variants is valid (`DialogueCatalog.validate`). The box opens on `show_choices` with no plate, portrait or text, its choices focused at once.
- **A grant on a cue-only line** is valid and lands as its CUE starts (before the beat; also when no beat is found).
- **Stutter:** `~word~` in a line is a brief stutter ("Yes, a brief stutter (Recommended)", user, 2026-10-15). `StutterText.parse` strips the marks and keeps each word's start. The box types to the word's first letter, holds it `stutter_hold` (0.22 s), takes it back, waits `stutter_gap` (0.08 s) and types the word. The fit test measures the stripped text, which is what the box shows.
- `NotebookEntry.fact_id` is passed to `SaveFact.check`, so a Memories entry can follow a talk (DIALOGUE_HEARD). `NotebookCatalog.validate` names a dialogue requirement with no `fact_id`, and `notebook_catalog_test` checks every such id is in the dialogue catalog.

## New game and playtests

- A new game starts with nothing in every build (STORY-14). A playtest timeline without `owned_items` gets the runner's kit (the sword and the Memorina); F10 gives the trials' kit.
- The playtest runner's `"dialogues_heard": [ids]` and `"responses": {ask: choice}` seed the save (strings, so `gotchas/json-numbers-are-floats-so-array-has-an-int-misses-them` does not bite).

## Sounds

`tools/audio/synth_story_placeholders.py` (the orchestrator's) writes stand-ins into `assets/audios/sfx/story/` until the user's recordings replace them ("Placeholders now, yours later (Recommended)", user, 2026-10-15):
- `guitar_{c,d,e,g}.wav`, and `guitar_muted.wav` (the press at the gap);
- `wife_hum_opening.wav` (the flicker);
- `daughter_hum_four.wav` and `daughter_hum_five.wav` (a child's hum, thinner and less steady);
- `memorina_flat.wav` ("[Play it again]").

`guitar_beat.tscn` maps the strings UP G, DOWN C, LEFT D, RIGHT E.

## User decisions (2026-10-15)

On the opening's order, asked "A player can walk east to the lighthouse before the song and the elder's story, skipping the call to adventure. How should the opening hold together?": "East gate shut until the elder points east (Recommended)": "The village's east gate stays closed (the existing gate barrier) until the elder's story has been heard; his "East. It's still there." is when it opens. The opening always plays in order. The reach audit learns that the opening's talks are part of the starting kit."


Answers to the plan's questions, in the user's words:
- Wrong notes before the gap: "Sounds, doesn't advance (Recommended)".
- The elder's return: "In his house, maybe heard late (Recommended)". The fences stay on `owns_memorina`.
- Transitions: "Short cross-fade (Recommended)".
- The baker: "Draw it: two baker stills (Recommended)".

Defaults taken from the plan's recommendations (default, 2026-10-15; not asked):
- at the gap, a muted thump;
- the children stay in the elder's house until his story, then are in the square;
- the elder's story only after the guitar scene;
- the mentor's phrase G E D C (UP RIGHT LEFT DOWN), not a song, teaches nothing;
- pulse colours winter (his phrase) and spring (the flicker);
- the mentor's short entry in Memories;
- "[Play it again]" uses a new flat-note sound;
- the daughter after the return and at 0.6 is the standing pose by the drawings (an idle loop since STORY-12).

## Tests

- **Pure rules:** `tests/scenes/world/environment/props/fact_staging_test.gd`, `tests/resources/story/melody_test.gd`, `tests/scenes/world/story/guitar_phrase_test.gd`, `tests/globals/boot_policy_test.gd`, `tests/scenes/ui/dialogue_box/stutter_text_test.gd`.
- **Beats:** `tests/scenes/world/story/guitar_beat_test.gd`, `staged_beat_test.gd`, `story_beats_test.gd`; `tests/scenes/ui/phrase_sheet/phrase_sheet_test.gd`.
- **Ivo:** `tests/scenes/characters/ivo/player_beat_test.gd` (`Input.parse_input_event`).
- **Village voices:** `tests/resources/dialogue/village/village_voices_test.gd` (the step tie, the baker's order and once line, each villager by step, catalog and plates).
- **Additions to existing suites:** `dialogue_director_test` (a cue-only grant, the silent ask, hold, pose, face, notes and phrase relays), `dialogue_catalog_test`, `dialogue_box_test` (the silent open, the stutter), `notebook_catalog_test`.
