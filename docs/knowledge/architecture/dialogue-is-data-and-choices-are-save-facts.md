---
id: architecture/dialogue-is-data-and-choices-are-save-facts
type: architecture
title: Dialogue is data and choices are save facts - a pure runner, a director, a bottom box that blocks Ivo, Talkables beside props
status: active
tags: [dialogue, story, save, save-fact, ui, input, focus, i18n, plan]
related: [systems/dialogue, systems/screens, systems/input, systems/life-benches-death, systems/notebook, systems/region-title, systems/props, systems/rooms, systems/songs-and-the-memorina, architecture/notebook-entries-are-derived-from-the-save, architecture/doors-and-interiors, architecture/pause-menu-worldfreeze-reuse, architecture/character-controller-input-split, gotchas/a-menu-press-reaches-the-last-node-first, gotchas/gui-focus-moves-once-per-stick-tilt, gotchas/a-typed-array-of-an-inner-class-is-refused-from-another-script, gotchas/a-killed-tween-never-emits-finished, gotchas/autowrapped-rows-settle-over-several-sorts, gotchas/gdunit-await-millis-never-resumes-while-the-tree-is-paused, gotchas/scene-state-lists-only-the-properties-a-scene-file-sets]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - resources/save_facts/save_fact.gd
  - resources/dialogue/dialogue.gd
  - resources/dialogue/dialogue_line.gd
  - resources/dialogue/dialogue_choice.gd
  - resources/dialogue/line_variant.gd
  - resources/dialogue/speaker.gd
  - resources/dialogue/dialogue_set.gd
  - resources/dialogue/dialogue_catalog.gd
  - resources/dialogue/dialogue_catalog.tres
  - scenes/world/dialogue/dialogue_runner.gd
  - scenes/world/dialogue/dialogue_tally.gd
  - scenes/world/dialogue/dialogue_director.gd
  - scenes/world/dialogue/dialogue_beat.gd
  - scenes/world/interactables/talkable/talkable.gd
  - scenes/characters/components/talk_component.gd
  - scenes/ui/dialogue_box/dialogue_box.gd
  - scenes/ui/dialogue_box/dialogue_box.tscn
  - scenes/ui/menu/menu_theme.tres
  - globals/player_data.gd
  - globals/save_system.gd
  - scenes/characters/ivo/player.gd
  - scenes/world/game.tscn
---

> **Status: BUILT** (2026-10-15, STORY-08). The contract is `systems/dialogue`. "Built differently" below lists what changed from this plan; the open questions were answered (end of the note).

## Context

STORY-08: dialogue with response choices. User decisions, 2026-10-15:
- Who speaks: "Story cast + some villagers (Recommended)". The daughter, the elder and the mentor carry the opening (STORY-03); a few villagers get short optional lines that change as the village falls 0.8 → 0.6 → 1.0 (STORY-09). This revises WORLD-10's "Idle villagers, no dialogue" (2026-10-08).
- Choices: "Remembered, later lines vary (Recommended)". Each choice is saved, later conversations swap a line or two, and choices feed the quiet tally of design 01 §9 ("acumulado silencioso", STORY-07). The ending never branches.
- Look: "Bottom box with portraits". Portraits come later through the art pipeline, so the box runs with none.
- The call to adventure: "Playable, impossible to finish (Recommended)" (01 §9.1). Not STORY-08, but a talk must hand off to a scripted beat and resume after it.

Constraints: only `WorldFreeze` writes the clock; only `PlayerInput`, `MenuInput` and `InputDevice` read `InputEvent`s; only benches save; conditions reuse `SaveFact`; every text fits in every language; abilities and songs are never given by the world (01 §5, 02 §4).

## Options considered

**How a talk stops the world.**
- Rejected: a `ScreenRouter` screen that holds. The router keeps one open screen and a pause press closes it, so pause over a talk needs a screen stack; a talk is opened by the world, not a toggle; on a held (paused) tree the router refuses the pause, so a long talk could not be paused.
- Rejected: `WorldFreeze.freeze()`. A freeze belongs to a performance (`freeze()` asserts an unpaused tree), and the guitar beat may freeze.
- **Chosen: block, like the map.** The world runs (villagers keep their memory clock), Ivo hears no input (`block_input`), the pause and the notebook open over a talk and their hold stops the box, which is pausable. The map is refused (`Player.can_open_map()` is false while talking), so the one `PlayerInput.blocked` flag has a single owner at a time.

**Input.** Rejected: a fourth reader (`DialogueInput`), which breaks the three-reader contract and the `verify-gates` scan. Rejected: `MenuInput.accept_pressed`: Z and pad A are `map_zoom_in` first under its one-signal-per-event precedence. **Chosen: GUI focus and Buttons**, like the pause menu: a flat `ContinueArea` Button over the text and one flat Button per choice. A Button acts on the `ui_accept` release; no script reads an event.

**Data.** Rejected: a dialogue addon (its own condition language, input handling and balloon). Rejected for now: a text script plus importer (machinery for a few dozen conversations; revisit if `.tres` authoring hurts). **Chosen: small Resources**, one file per class (`gotchas/a-typed-array-of-an-inner-class-is-refused-from-another-script`).

**Conditions.** Rejected: expression strings (unvalidated, a parallel predicate system). **Chosen: `SaveFact`, extended** with append-only kinds.

**Gameplay effects.** Rejected: effect Resources with `apply()` (a Resource cannot reach scene nodes). Rejected: a runner that calls `SaveSystem` (not pure). **Chosen:** a line's `grants` (an ITEM `SaveFact`, applied by the director) and a line's `cue`, played by a `DialogueBeat` found by group, as `Door.find` does.

**Rewind.** Rejected: death-proof like `notebook_read`. A grant (the mentor's Memorina) rewinds with every gain; if "heard" survived, the mentor would never give it again. **Recommended: heard and responses are live data**, committed by a bench, forgotten by a death. The tally is derived, never stored.

**Starting a talk.** Rejected: the Talkable reads input, or signals a director it cannot be wired to (it is built at runtime from the `.room`). **Chosen: Ivo's body decides**, as with doors: an Up press or a Talkable's auto start, under the door's gates; `Player.talk_started(talkable)`.

## Decision

**Data** (`resources/dialogue/`, one `class_name` per file):
- `Speaker`: `id`, `name_key` (`SPEAKER_<ID>`, empty means no name plate), `portrait: Texture2D` (null leaves the slot empty; the text rect never moves).
- `Dialogue`: `id` (unique, the "heard" key), `once` (skipped once heard), `when` / `unless: Array[SaveFact]`, `lines: Array[DialogueLine]`.
- `DialogueLine`: `speaker`, `text_key` (empty for a cue-only line), `when` / `unless`, `variants: Array[LineVariant]` (the first that holds replaces the text), `ask_id` + `choices: Array[DialogueChoice]` (2..3), `cue: StringName`, `grants: SaveFact` (ITEM only).
- `LineVariant`: `when`, `unless`, `text_key`. This is how "a later line varies": a variant gated on `RESPONSE_CHOSEN`.
- `DialogueChoice`: `id` (unique across the catalog), `text_key`, `tone: int` (`DialogueChoice.Tone`, append-only), `reply: Array[DialogueLine]` (no choices inside: one level, then the talk rejoins).
- `DialogueSet`: one talker's `dialogues` in priority order; `current(data)` is the first whose gates hold; `pending(data)` is `current` if not yet heard (auto start).
- `DialogueCatalog` (`dialogue_catalog.tres`): every set; `validate() -> PackedStringArray` (unique ids, choice count, no nested choices, ITEM-only grants, facts naming known dialogue and choice ids, no `\n` in keys).
- `SaveFact.Kind` appends `GUARDIANS_RESTORED_AT_LEAST` (`index` is the count, the key `RegionMemory.steps` uses: the village's 0.6 is 2), `DIALOGUE_HEARD` and `RESPONSE_CHOSEN`, read through a new `@export var id: StringName`; `check(kind, index, data, fact_id := &"")`, so doors and notebook entries are unchanged.

**Pure runner** (`DialogueRunner`, RefCounted): `_init(dialogue, data)`; `advance() -> Step` {LINE, CHOICES, CUE, END}; `speaker()`, `text_key()` (variant resolved), `grant()` on LINE; `choices()`, `ask_id()`, `choose(i) -> DialogueChoice` on CHOICES (queues the reply); `cue()` on CUE. An ask line yields LINE then CHOICES; a line with a cue yields LINE then CUE. Gates read `data` plus the choices made in this run, so a variant follows a choice made earlier in the same talk. It writes nothing. `DialogueTally.count(catalog, data) -> Dictionary[int, int]` (tone → count) is pure too.

**Save**: `PlayerData.dialogues_heard: Array[StringName]` and `responses: Dictionary[StringName, StringName]` (ask id → choice id; re-asking overwrites, so each question counts once). `SaveSystem.is_dialogue_heard`, `mark_dialogue_heard` (at END only), `response_to(ask_id)`, `record_response(ask_id, choice_id)`; both writers emit `progress_changed`. Old saves load empty; `SaveLedger` changes nothing.

**World side**:
- `Talkable` (`scenes/world/interactables/talkable/`, Area2D on layer 6, masking the Player body like `Door`): legend `t`, kind ENTITY, reach role CONTENT. Params: `talk` (required, a `DialogueSet` path), `auto_start`, `presence` (min region baseline, forwarded to a composed `RegionPresence`, so it leaves with its villager), `width_cells` / `height_cells` (default 2x2). A `look_up` `KeyGlyph` prompt shows while Ivo is in reach, a dialogue is current and no talk runs. Auto start arms on body entry, fires after `auto_delay` (0.4 s, past an arrival fade) and re-arms only after he leaves. It sits beside the villager prop and never on it: a prop carries no gameplay (`systems/props`).
- `TalkComponent` (`scenes/characters/components/`): `reachable()` and `auto_ready()` over the `DoorSensor` overlaps.
- `Player`: `_door_buffer` becomes the Up buffer; `_try_door` first, then `_try_talk(on_floor)`, both under one extracted gate list (on the floor, no roll, swing, knockback, climb, wall slide, Memorina, call, recall, stair or fight). New: `talk_started(talkable)`, `begin_talk(at)` (`block_input`, faces `at`), `end_talk()`, `is_talking()`. The villager prop does not turn.

**Director** (`World/DialogueDirector`, pausable, exports `catalog`): `start(talkable)` builds a runner from `talkable.current(data)`, emits `talk_began(at)`, applies each `grants` through `SaveSystem.set_item_owned`, records responses and heard. At a CUE it emits `box_closed` and `talk_ended`, calls `DialogueBeat.find(tree, cue).start()`, awaits `finished`, re-emits `talk_began` and goes on; no beat pushes an error and goes on. `interrupt()` (hurt, hazard) closes, frees Ivo, records no heard; beats are not interrupted. `DialogueBeat` (Node, group `dialogue_beats`): `cue`, `start()`, `finish()`, `started`, `finished`. STORY-03's guitar composes one; during a beat Ivo is free and the box hidden.

**Box** (`CanvasLayer/DialogueBox`, after `GuardianCallHud`, before `Fade`; INHERIT, so pausable): it never reads the save. One 320x180 `Art` root at scale 2 (`systems/screens`, the 2x rule), the wood theme (`BGbox_05A`, `menu_theme.tres`, 8 px font). Starting numbers, which a mockup settles: panel 304x60 at (8, 114), portrait slot 48x48 at the left, name plate on the top edge, text rect 3 rows (`TEXT_ROWS`). An ask line keeps its question on 1 row (`QUESTION_ROWS`) with up to 3 choice rows of 12 px (`MAX_CHOICES`). Choices are flat Buttons whose focused row is red ink like the notebook's, not `Button_01A`, so 12 px rows avoid the accent clash 16 px fixed. Typing: `visible_ratio` tweened at `chars_per_second` (40) on a pausable tween with `set_ignore_time_scale(true)`. `visible_characters_behavior` is AFTER_SHAPING, so words do not jump lines as they type. The first press completes the line (kill, then set the ratio: `gotchas/a-killed-tween-never-emits-finished`), the next emits `advanced`. Choices sent while typing wait for it. Focus: `ContinueArea` on a line, the first choice on an ask; explicit neighbours, itself at either end. Closing releases focus (a hidden focused Button takes the next `ui_accept`); `NOTIFICATION_UNPAUSED` grabs it back, because closing the pause or notebook releases GUI focus. Signals `advanced`, `chosen(index)`; methods `show_line(speaker, text_key)`, `show_choices(keys)`, `close()`.

**Wiring (`game.tscn`)**: `Player.talk_started` → `DialogueDirector.start`; `talk_began` / `talk_ended` → `Player.begin_talk` / `end_talk`; `line_shown`, `choices_shown`, `box_closed` → `DialogueBox`; `DialogueBox.advanced` / `chosen` → the director; `Player.hurt` and `fell_into_hazard` → `interrupt`. `NotebookWatcher.is_holding()` adds `subject.is_talking()`, so a granted item's quill waits for the talk to end.

**Text**: `SPEAKER_<ID>`, `DLG_<DIALOGUE_ID>_<NN>`, `..._V<k>`, `DLG_CHOICE_<CHOICE_ID>`; the box draws no other text (the next mark is a glyph). `dialogue_text_fit_test`: in every CSV locale each line and variant wraps within its rows at the text width, each choice within one row, each name within the plate, every key filled and not equal to itself. It measures with the box's own Labels (`get_line_count()` at a fixed width), never container sorts (`gotchas/autowrapped-rows-settle-over-several-sorts`).

## Consequences

- A talk adds no `WorldFreeze` writer, no input reader and no router screen. The pause-mode map gains `DialogueDirector` and `DialogueBox` as INHERIT, never ALWAYS: a hold stops typing, and a freeze never shows the box.
- A villager's line keyed on the village step repeats `RegionMemory.steps`' count as a `GUARDIANS_RESTORED_AT_LEAST` fact: change both together.
- The tally reading (STORY-07) can change without migrating a save: only answers are stored.
- `room_files_test` checks every `t`'s `talk` is in the catalog; the legend entry regenerates `docs/maps/README.md` (`map_guide_test`).
- Pitfalls: a Button acting on a release with no press before it is believed inert, but verify it with `parse_input_event` (an auto start with Z held). Box tests that hold go through `WorldFreeze` and wait on `create_timer(t, true, false, true)` (`gotchas/gdunit-await-millis-never-resumes-while-the-tree-is-paused`). The stick moves choice focus once per tilt (`gotchas/gui-focus-moves-once-per-stick-tilt`).

## Build order

1. `SaveFact` kinds, `PlayerData` fields, `SaveSystem` API; `save_fact_test`, `save_ledger_test` (a rest keeps, a death forgets), `player_data_test`.
2. Resources and `DialogueCatalog.validate()`; `dialogue_catalog_test`, `dialogue_set_test`.
3. `DialogueRunner`, `DialogueTally`; `dialogue_runner_test` (order, `when` / `unless` skips, variant by data and by this run's choice, reply then rejoin, LINE then CUE, cue-only, grant, END repeats), `dialogue_tally_test`.
4. `DialogueBox` and `dialogue_box_test` (real-time typing, complete then advance, focus, regrab after a hold) and `dialogue_text_fit_test`.
5. `DialogueDirector`, `DialogueBeat`; `dialogue_director_test` (heard only at END, interrupt, beat round trip, grant).
6. `Talkable`, `TalkComponent`, `Player`, legend `t`; `talkable_test`, Player tests (door wins, gates, map refused, no jump from the closing Z).
7. `game.tscn` wiring, the watcher hold, `tools/smoke/scenes.txt`.
8. One approved slice conversation, a playtest timeline, `systems/dialogue` and its `CLAUDE.md` row.

## Open questions, answered (2026-10-15)

1. Block: a talk blocks Ivo like the map, the world keeps running, the pause and the notebook may open over it, the map is refused.
2. Heard and answers are live data: a bench commits them, a death forgets them.
3. `Tone { NONE, HOLD_ON, LET_GO }` (append only); the tally stays derived and STORY-07 decides how it is read.
4. Role names on the plate (`SPEAKER_ELDER`, `SPEAKER_DAUGHTER`, `SPEAKER_MENTOR`); the mentor stays unnamed. The portrait slot runs empty until the art is approved.
5. Bottom box, the 2x rule, the wood theme, a name plate, choices inside the box. The numbers moved (below).
6. No story text is approved yet: STORY-08 ships a debug fixture in the winter trial instead of a slice conversation; the opening is drafted separately.
7. 40 chars/s real time, the first press completes, the second advances, no voice blips.

## Built differently (2026-10-15)

- **Box numbers.** The frame of `BGbox_05A` is 9 px thick on every side, so the planned 60 px panel left 42 px of paper, short of a question row and three 12 px choices (45 px). Built: panel 304x68 at (8, 106), paper (17, 115) to (303, 165), portrait 48x48 at (18, 116), text 230 px wide at (72, 117), choices from (72, 129), name plate 16 px tall (`Button_01A`) at (18, 99), next mark 16x16 at (287, 158).
- **The next mark** is the `jump` `KeyGlyph`: Z and pad A are both `ui_accept`, and `ui_accept`'s first key is Enter.
- **`InkButton`**, a theme variation in `menu_theme.tres`, draws the choices and the `ContinueArea`: empty styles, ink text, red ink when focused.
- **The director goes straight from an asking LINE to CHOICES** (`DialogueRunner.asks()`); the box holds the choices until the question is typed. A LINE then CUE still waits for a press.
- **An interrupt during a beat does nothing**, and a beat that leaves the tree resumes the talk like `finished`.
- **Gates**: `SaveFact.gates_pass(when, unless, data)`. The runner reads a shallow copy of the save whose `responses` is its own, so this run's answers count without writing the save.
- **Player**: the shared gates are `_free_for_up`; the buffer is `_up_buffer` (`UP_BUFFER`, renamed from `DOOR_BUFFER`). `_try_talk` ticks the buffer. A due auto start waits while `PlayerInput.blocked` is set (an open map), so a talk never starts and then unblocks under the map.
- **Talkable prompt** stands 8 px over its zone (`PROMPT_GAP`); it reads Ivo's `is_talking()` from the body in reach.
- **Box placement** (user, 2026-10-15, after the first playtest showed the bottom box over Ivo's feet): "Opposite the speakers (Recommended)": the box opens in the screen half the speakers aren't in. In most rooms (floor low on screen) that's the top; it goes to the bottom only when they stand high. Same box and portraits. Built as the pure `DialogueBoxSide.opposite` (the mean screen y of the speaker and Ivo), decided by the director when a talk begins or resumes (`box_placed`) and held by `DialogueBox.place`; at the top the plate hangs under the panel's lower edge.
- **A beat keeps Ivo in the talk** (STORY-08 review, `bugs/a-beat-that-ends-resumes-the-talk-without-the-start-gates`): a cue emits `talk_paused`, not `talk_ended`, so the map stays refused through the beat; a director out of the tree drops the talk unheard; the resume goes through `resume_wanted` → `Player.request_talk_resume` → `talk_resumed` under the start gates → `DialogueDirector.resume`.
- **The speaker's point**: `Talkable.speaker_offset` (px to the villager beside it) is where Ivo faces (`bugs/ivo-faces-the-talkable-not-the-villager-beside-it`).
- **The reach audit cannot read a talk**: `ReachKit.of()` packs kind and index, and no kit holds a heard dialogue or an answer, so a way gated on a talk is never open to a kit (documented in `systems/dialogue`, Limits).
