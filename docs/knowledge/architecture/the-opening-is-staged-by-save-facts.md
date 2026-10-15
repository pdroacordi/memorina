---
id: architecture/the-opening-is-staged-by-save-facts
type: architecture
title: The opening is staged by save facts - FactStaging picks a pose by priority, beats borrow Ivo, a gesture ask has no question
status: active
tags: [story, dialogue, staging, save-fact, beat, guitar, mentor, notebook, plan]
related: [systems/dialogue, architecture/dialogue-is-data-and-choices-are-save-facts, systems/pickups, systems/props, architecture/props-and-ambient-life, systems/songs-and-the-memorina, systems/guardians, systems/greyhush, systems/notebook, architecture/notebook-entries-are-derived-from-the-save, systems/life-benches-death, systems/rooms, systems/world, systems/input, architecture/character-controller-input-split, architecture/room-reachability-audit, bugs/a-beat-that-ends-resumes-the-talk-without-the-start-gates, bugs/the-kit-check-counts-a-guardian-arena-as-an-exit-before-the-guardian-exists, gotchas/a-killed-tween-never-emits-finished, gotchas/an-explicit-process-mode-escapes-a-disabled-ancestor, gotchas/json-numbers-are-floats-so-array-has-an-int-misses-them, gotchas/flattening-a-shrunk-codex-cut-erases-small-pictograms]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/environment/props/fact_staging.gd
  - resources/save_facts/fact_stage.gd
  - scenes/world/dialogue/dialogue_beat.gd
  - scenes/world/dialogue/dialogue_director.gd
  - scenes/world/dialogue/dialogue_runner.gd
  - resources/dialogue/dialogue_catalog.gd
  - scenes/ui/dialogue_box/dialogue_box.gd
  - scenes/characters/ivo/player_input.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/player_animation_resolver.gd
  - resources/ui/notebook/notebook_entry.gd
  - globals/save_system.gd
  - globals/boot_policy.gd
  - tools/playtest/playtest_runner.gd
---

> **Status: BUILT** (2026-10-15, STORY-03). Script: draft 2, "Approve draft 2 (Recommended)" (user, 2026-10-15), Acts 1, 3 and 4. Phase A (the mechanisms) and phase B (the rooms' stages, talks, beats and texts) are built; the contract is `systems/story`, the run `playtests/2026-10-15-story03-opening`.

## Context

The opening changes the same rooms many times as story facts accrue: the daughter asleep, up with the guitar, in bed turned to the wall, at the guitar or humming, at 0.6 by repeated drawings; the elder mid-story with two children, then alone; the mentor holding the Memorina, empty-handed, in stasis. Talks must hand off to beats that need Ivo's notes (the guitar), his pose (the guitar, the Memorina) or his stillness, and two of the three remembered choices are gestures with no question line. Constraints: presence derived, never recorded (`systems/pickups`, `systems/notebook`); a prop carries no gameplay (`systems/props`); three input readers only (`systems/input`); `WorldFreeze` is the only clock writer; the reach audit cannot read talks (`systems/dialogue` Limits); no song taught, no Memorina fact touched outside the mentor's grant; "presence" already names `EnemySight.PRESENCE` and `RegionPresence`.

## Options considered

**Staging.** (a) `FactPresence`, one visible/hidden node per pose: the wall guitar is shown "unless bread heard AND song unheard, or HOLD return pending", which `when`/`unless` lists cannot say without duplicate sprites. (b) Beats writing `visible`: two writers, and a death rebuild would lose it. (c) **Chosen: `FactStaging`**, a node that shows exactly one of its children, picked by the first `FactStage` (`when`, `unless`, `show`) that holds, in priority order, exactly as `DialogueSet.current()` picks a talk. One stage with one child is presence; exceptions are earlier stages. `RegionPresence` stays as is.

**Mid-talk visuals.** A cue-only line's grant applied as its beat starts lets a fact flip the mentor's pose at the right instant. For the guitar (no fact flips during the beat): rejected (a) a story `PlayerItem` (forces a notebook ITEM entry and tab), (b) splitting the talk into two dialogues (breaks the one choice). **Chosen: `FactStaging.stand_in(child)`**, asked by a beat, shows that child until the picked stage next changes (the talk's END flips it), then drops. FactStaging stays the only writer.

**Guitar input.** Rejected: a reader in the beat (a fourth reader); keeping `PlayerInput.blocked` (it disables the node, so no notes). **Chosen:** `PlayerInput.notes_only` (axes read 0, only `note_pressed` is emitted); `Player` routes notes to the director instead of `MemorinaComponent` while a beat holds them; the director hands them to its current beat.

**Guitar sheet.** Rejected: extending `MemorinaHud` (tied to the instrument's lifecycle and the call); a CanvasLayer inside room contents (draw order against the HUD layer is undefined at equal `layer`, and a hidden room does not hide a CanvasLayer). **Chosen:** a light `PhraseSheet` HUD in `game.tscn`'s `CanvasLayer` composing a `NoteSheet` at the encounter slot (`NoteSheet.encounter_x(w, 0, 0)`, `encounter_y()`), fed by director relays.

**Gesture asks.** Rejected: a speaker line "…" as the question (changes the script's order). **Chosen: a silent ask**: an asking line with no text and no speaker is valid; the box opens with no plate, portrait or text and shows the choices at once. A cue inside a reply already validates and runs (replies are queued lines; only an ask inside a reply is refused), so a gesture whose reply is a beat needs no change.

**The elder's reveal portrait.** Rejected: a per-line `DialogueLine.portrait` override (touches the line, runner, `line_shown`'s signature, the box and four suites for one line). **Chosen:** a second `Speaker`, `elder_model.tres` (`SPEAKER_ELDER`, portrait the 48 art px base close-up), as `mentor_stasis.tres` does for the mentor's stasis portrait. Revisit if many lines need it.

**Beats in rooms.** Rejected: a legend entity (beats carry no surface, collision or reach role, and point at props, which live outside the `.room`). **Chosen:** beat scenes under a `Beats` Node2D in the contents scene, beside `Props`; Talkables stay legend `t`.

**Fences.** Rejected: gating them on `DIALOGUE_HEARD elder_return` (the kits cannot read talks; design 04 §2 says "na prática, um portão que lê esse fato do save"). **Chosen:** they stay on `owns_memorina.tres`. The east gate, added after the user's 2026-10-15 decision below, does read a talk; the kits learned to (`ReachKit` packs the id).

## Decision

**`FactStage`** (`resources/save_facts/fact_stage.gd`): `when`, `unless: Array[SaveFact]`, `show: StringName` (a child name; empty hides all), `fade_seconds` (cross-fade into it at runtime). **`FactStaging`** (`scenes/world/environment/props/fact_staging.gd`, Node2D under `Props`, INHERIT): static pure `pick(stages, data) -> int`; applies instantly at `_ready`, on `progress_changed` cross-fades the outgoing and incoming child's `modulate.a` on one pausable scaled tween bound to itself (kill and snap on a new change, `gotchas/a-killed-tween-never-emits-finished`); `stand_in(child)` / `release()`. Never put `RegionPresence` on its direct child (nest it one level down).

**Dialogue changes:** `validate()` accepts an ask with no text when it has no speaker and no variants; the box opens on `show_choices` when hidden. A grant on a cue-only line is valid and applied as its CUE starts (also when no beat is found). `talk_paused(hold, pose, at)`. `DialogueBeat` gains `hold: Hold { FREE, STILL, NOTES }`, `pose: Pose { NONE, GUITAR, MEMORINA }` (held after the beat until the next beat or the talk's end), `face: NodePath` (Ivo faces it), `receive_note(note, glyph_set)` → `note_received`, and `phrase_shown(notes, count)`, `phrase_lit(index)`, `phrase_closed` which the director re-emits to `PhraseSheet`. `Player.pause_talk(hold, pose, at)`: STILL keeps the block; NOTES sets `notes_only`; `beat_note_pressed(note, glyph_set)` → `DialogueDirector.hear_note`. A resume ignores a block the beat itself holds (`_try_talk` reads `_input.blocked` today). The box renders `~word~` as a brief stutter (pure `StutterText.parse`; the fit test measures the stripped text).

**Data:** `Melody` (`notes: Array[Enums.Note]`, `beats`, `beat_seconds`; `onsets(count, tempo)`): `morning_song.tres` = E G E D C D E C = RIGHT UP RIGHT LEFT DOWN LEFT RIGHT DOWN (`ivo.tscn`: UP G4, RIGHT E4, LEFT D4, DOWN C4), beats 1 1 1.5 0.5 1 1 1 2.5 at 0.42 s. Not a `Song`, never in `SongCatalog`. `GuitarAttempt` (`melody`, `gap_index`, `end_after_silence` 2.0 s, `end_after_dead_presses` 3, `min_gap` 0.08 s): `guitar_first.tres` gap 5, `guitar_again.tres` gap 4. Pure `GuitarPhrase.press(note) -> {PLAYED, MISSED, DEAD}`: before the gap a right note plays and lights, a wrong one sounds its string and stays; at the gap any press is DEAD (a muted thump). `played() <= gap_index < notes.size()` by construction.

**Beats** (`scenes/world/story/`): `GuitarBeat` (NOTES, GUITAR; four `guitar_*.wav` and the muted thump; `stand_ins`); `StagedBeat` (STILL or FREE; optional stand-ins, an `AudioStream` or a `Melody` through a pausable `MelodyPlayer`, an optional non-acting pulse through a `PulseEmitter` with `song_acts = false` and its own `PulseStats`, `duration`). Every player INHERIT; no `TIME`, no `WorldFreeze`. The camera does nothing (one-screen interiors are already framed).

**Facts.** The errand is `DIALOGUE_HEARD baker_errand` (no `PlayerItem`). Stages (priority order):

| Node | Stages |
|---|---|
| Daughter (village_house) | Drawing (≥2 guardians) · Standing (MEMORINA, heard `daughter_return`) · AtGuitar (MEMORINA, `guitar_try_again`) · Humming (MEMORINA) · InBedTurned (heard `daughter_song`) · HoldingOut (heard `baker_errand`) · Asleep |
| Wall guitar | none (MEMORINA, `guitar_try_again`, unless heard `daughter_return`) · OnWall (heard `daughter_song`) · none (heard `baker_errand`) · OnWall; child Lowered for a stand-in |
| Drawings | three `drawing_house` (≥2) · sun, house, heart |
| Elder's audience | two children (unless heard `elder_story`); the square's children the reverse |
| Mentor | Stasis (heard `mentor_gift`, fade 1.5 s) · EmptyHand (MEMORINA, fade 0.5 s) · Holding |

**Talks** (`DLG_<ID>_<NN>`, choices `DLG_CHOICE_<ID>`): `daughter_errand` (bed `t`, Up); `baker_errand` (once; cue `baker_loaves` on "And the long one for—"); `daughter_song` (auto, once, when `baker_errand`): line, cue `guitar_first`, silent ask `morning_song` (`guitar_try_again` HOLD_ON → cue `guitar_again`; `guitar_lower` LET_GO → cue `guitar_lowered`, the hum of four), "…"; `daughter_turned` ("…"); `elder_story` (auto, once, when `daughter_song`): the asking line is "It had an end. It had a good end." (`elder_wait` / `elder_painting`, the latter a STILL beat facing the painting); `mentor_gift` (auto, once): line + cue `mentor_phrase`, line, cue-only line granting MEMORINA with cue `mentor_gift` (pose MEMORINA, hum, warm pulse at the pair), silent ask `mentor_flicker` (`memorina_again` → `memorina_flat`; `memorina_lower` → `memorina_lowered`), "Yours ~too~. Maybe. If you—", END → Stasis fades in; `mentor_stasis` ("…", speaker `mentor_stasis.tres`); `elder_return` (auto, once, MEMORINA; speaker `elder_model.tres`); `daughter_return` (auto, once, MEMORINA; cue-only `daughter_guitar` when `guitar_try_again`, `daughter_hum_five` when `guitar_lower`, then "That's a strange one."); `daughter_eyes` (≥2; variant on `guitar_lower`); `elder_empty` (auto, once, ≥2). Each place the daughter stands has its own `t`.

**Notebook:** `NotebookEntry.fact_id` passed to `SaveFact.check`; `mentor_short` in Memories (LORE takes any requirement), DIALOGUE_HEARD `mentor_gift`; `notebook_catalog_test` checks a DIALOGUE_HEARD entry names a catalog dialogue.

**New game:** release spawns in village_house with nothing (`_new_game`). Debug kept the sword and Memorina, and `-- --new-game --opening` (pure rule in `BootPolicy`) gave none; STORY-14 retired both, so every build starts with nothing (`systems/life-benches-death`). The runner gains `"dialogues_heard"` and `"responses"`.

## User answers (2026-10-15)

In the user's words:
- Q1, wrong notes before the gap: "Sounds, doesn't advance (Recommended)".
- Q2, the elder's return: "In his house, maybe heard late (Recommended)". The fences stay on `owns_memorina`.
- Q5, transitions: "Short cross-fade (Recommended)".
- Q9, the baker: "Draw it: two baker stills (Recommended)".

Defaults taken from this plan's recommendations, not asked (default, 2026-10-15):
- Q10, at the gap: a muted thump;
- the children stay in the elder's house until his story, then are in the square;
- the elder's story only after the guitar scene;
- the mentor's phrase G E D C (UP RIGHT LEFT DOWN), not a song, teaches nothing;
- pulse colours winter (his phrase) and spring (the flicker);
- the mentor's short entry in Memories;
- "[Play it again]" uses a new flat-note sound;
- the daughter after the return and at 0.6 is the standing still by the drawings.

## Built in phase A (2026-10-15)

- **GuitarPhrase**'s timing lives in `GuitarBeat`: `min_gap`, the silence and the dead presses. The pure rule is the press alone.
- **PhraseSheet** composes `NoteSheet` with a new `slot_count` (8 for the morning song); since STORY-14 at the Memorina's `icon_scale` on a widened frame (`systems/story`). It closes when its beat ends.
- **A beat's pose** reads in the resolver as `Player.held_pose()`. The guitar strums on `Player.just_strummed()`, a pulse taken at the top of `_process_motion`, with `request_replay`.
- **`ivo_sheet_test`** lets `ivo_guitar.png` use the guitar prop's colours (`HELD_PROPS`).
- **`story_beats_test`** reads every contents scene's `cue` properties against the catalog's cues: one beat per cue, and none unnamed.

## The opening's order (user, 2026-10-15)

Asked "A player can walk east to the lighthouse before the song and the elder's story, skipping the call to adventure. How should the opening hold together?", the user chose "East gate shut until the elder points east (Recommended)": "The village's east gate stays closed (the existing gate barrier) until the elder's story has been heard; his "East. It's still there." is when it opens. The opening always plays in order. The reach audit learns that the opening's talks are part of the starting kit." Built: a `FactBarrier` on `heard_elder_story.tres` at village_gate_east's east end; the reach kits gained an `opening` milestone (the errand, the song, the story) and `ReachKit` packs a dialogue fact's id; the house's and the mentor's stages read `mentor_gift` heard instead of owning the Memorina, so a debug save shows the same morning (`systems/story`).

## Built in phase B (2026-10-15)

- The baker's two loaves come on their own cue after "Round one?" (`baker_two_loaves`).
- The hummed return is its own dialogue (`daughter_return_hum`), and the eyes talk is in the bed's set.
- Her standing still is by the wall under the drawings.
- Doors hide their prompt during a talk.
- The playtest runner gained `"teleport"`.
- The rest follows the tables above (`systems/story`, "The opening").

## Consequences

- Every cue has exactly one beat in the world (`DialogueBeat.find` takes the first): a test scans the contents scenes against the catalog.
- A grant now has two timings (LINE, or its beat's start). The notebook quill still waits for the talk's end.
- STORY-09 adds the villagers' voices to `baker.tres` and the other sets.
- `ReachWorldLoader` can record a Talkable's granted items so `ReachKitCheck.given` counts lighthouse_interior for the Memorina milestone (the bug's Prevention rule: the game now hands it over).
- Script changes for the user: the gesture asks show no question; "Ivo walks to it" becomes turning to the painting; she "goes back to bed" and the mentor's stasis are cross-fades; "He goes out and opens the fences" becomes fences already open on return, the elder's talk heard whenever Ivo next enters his house.
