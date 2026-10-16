---
id: systems/dialogue
type: system
title: Dialogue: talks as data, choices as save facts, a director, a bottom box that blocks Ivo, Talkables beside props
status: active
tags: [dialogue, story, save, save-fact, ui, input, focus, i18n]
related: [architecture/dialogue-is-data-and-choices-are-save-facts, playtests/2026-10-15-story08-dialogue, bugs/a-beat-that-ends-resumes-the-talk-without-the-start-gates, bugs/an-up-press-in-a-due-auto-start-zone-never-expires, bugs/ivo-faces-the-talkable-not-the-villager-beside-it, gotchas/a-removed-subtree-emits-tree-exiting-later-siblings-first, gotchas/a-static-func-returning-its-own-enum-fails-once-another-script-types-it, systems/screens, systems/input, systems/life-benches-death, systems/notebook, systems/props, systems/rooms, systems/songs-and-the-memorina, gotchas/a-menu-press-reaches-the-last-node-first, gotchas/gui-focus-moves-once-per-stick-tilt, gotchas/a-killed-tween-never-emits-finished, gotchas/autowrapped-rows-settle-over-several-sorts, gotchas/gdunit-await-millis-never-resumes-while-the-tree-is-paused, gotchas/a-typed-array-of-an-inner-class-is-refused-from-another-script]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - resources/save_facts/save_fact.gd
  - resources/dialogue/speaker.gd
  - resources/dialogue/dialogue.gd
  - resources/dialogue/dialogue_line.gd
  - resources/dialogue/dialogue_choice.gd
  - resources/dialogue/line_variant.gd
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
  - scenes/ui/dialogue_box/dialogue_box_side.gd
  - scenes/characters/ivo/player.gd
  - globals/player_data.gd
  - globals/save_system.gd
  - scenes/world/game.tscn
---

# Dialogue

**Never break:** A talk adds no `WorldFreeze` writer, no input reader and no router screen: it blocks Ivo like the map, and the map is refused from its start to its end, a beat included. A talk resumes after a beat only under the start gates, and writes nothing once its world is swapped out. Conditions are `SaveFact`s; heard and answers are live data (a bench commits them, a death forgets them); the tally is derived, never stored. Every dialogue text fits the box in every language (`dialogue_text_fit_test`). `DialogueDirector` and `DialogueBox` are INHERIT (pausable), never ALWAYS.

## Summary

STORY-08. Plan, options and the reasons: `architecture/dialogue-is-data-and-choices-are-save-facts`. A conversation is data (`resources/dialogue/`); a pure `DialogueRunner` steps it against the save; `DialogueDirector` (`World/DialogueDirector`) runs a talk and writes what it leaves in the save; `DialogueBox` (`CanvasLayer/DialogueBox`) shows it. Ivo starts a talk with Up at a `Talkable` (legend `t`), or a Talkable starts it on its own.

## Data (`resources/dialogue/`, one `class_name` per file)

- `Speaker`: `id`, `name_key` (`SPEAKER_<ID>`; empty shows no plate), `portrait` (null leaves the slot empty). `speakers/` holds the elder, `elder_model`, the daughter, the mentor, `mentor_stasis`, the baker, the taverner, the water carrier, the seller and the boy; plate names `SPEAKER_<ROLE>` (the villagers have no portrait).
- `Dialogue`: `id` (unique, the heard key), `once` (closed once heard), `when` / `unless`, `lines`.
- `DialogueLine`: `speaker`, `text_key` (empty for a cue-only line), `when` / `unless`, `variants` (the first `LineVariant` that holds replaces the text), `ask_id` + `choices` (2..3), `cue`, `grants` (an ITEM `SaveFact`).
- `DialogueChoice`: `id` (unique across the catalog), `text_key`, `tone` (`Tone { NONE, HOLD_ON, LET_GO }`, append only), `reply` (lines with no choices; the talk then rejoins).
- `DialogueSet`: one talker's dialogues in priority order. `current(data)` is the first open one; `pending(data)` is `current` while unheard (what an auto start says).
- `DialogueCatalog` (`dialogue_catalog.tres`) lists every set. `validate()` names: empty or duplicate dialogue, ask and choice ids; a line with no text and no cue, text with no speaker; 1 or 4+ choices; a question inside a reply, with no question text, or with a cue; a grant that is not an ITEM or sits on a cue-only line; a `DIALOGUE_HEARD` or `RESPONSE_CHOSEN` fact naming no known id; a key with a newline or space. The director asserts it at `_ready` in debug builds.
- **Conditions are `SaveFact`s.** `Kind` appends `GUARDIANS_RESTORED_AT_LEAST` (`index` is the count; the village's 0.6 step is 2, `RegionMemory.steps`: change both together), `DIALOGUE_HEARD` and `RESPONSE_CHOSEN`, read through `SaveFact.id`. `SaveFact.check(kind, index, data, fact_id := &"")`, so doors and notebook entries are unchanged. `SaveFact.gates_pass(when, unless, data)` is the one gate test.

## Save

- `PlayerData.dialogues_heard: Array[StringName]` and `responses: Dictionary[StringName, StringName]` (ask id to choice id; asked again, the new answer replaces the old, so each question counts once). Old saves load empty.
- `SaveSystem.is_dialogue_heard`, `mark_dialogue_heard` (at END only), `response_to(ask_id)`, `record_response(ask_id, choice_id)`; both writers emit `progress_changed`.
- Live data: `SaveLedger` changes nothing, so a bench commits them and a death forgets them, like a grant the talk gave.
- `DialogueTally.count(catalog, data) -> Dictionary[int, int]` counts answers by tone. Nothing reads it yet (STORY-07).

## The runner (`DialogueRunner`, pure)

`advance() -> Step` {LINE, CHOICES, CUE, END}. An asking line yields LINE then CHOICES; a line with a cue yields LINE then CUE; a cue-only line yields CUE; END repeats. Gates and variants read a view of the save plus the answers chosen in this run, so a later line follows an answer given earlier in the same talk. `choose(i)` queues the reply before the rest. It writes nothing.

## The director (`World/DialogueDirector`, pausable)

- `start(talkable)` calls `start_dialogue(talkable.current(data), talkable.speaker_position())`; a cutscene's `CutsceneTalk` calls `start_dialogue(dialogue, at)` too (STORY-15, `systems/cutscenes`), which refuses (false) while a talk runs. It runs the dialogue: `box_placed(side)`, `talk_began(at)` with `at` the speaker's point (`Talkable.speaker_position()`), then each step. On LINE it applies `grants` (`SaveSystem.set_item_owned`) and emits `line_shown`; an asking line goes straight on to CHOICES (`choices_shown(keys, silent)`), which the box shows once the question is typed. A silent ask (a gesture) clears the box's plate, portrait and text, open or not, and shows its choices at once.
- `advance()` (the box's press on a typed line) and `choose(i)` (records the answer) step on. END marks the dialogue heard, then `box_closed` and `talk_ended`.
- A CUE applies a cue-only line's grant, closes the box and emits `talk_paused(hold, pose, at)`: the beat's `hold` (STILL by default; FREE frees Ivo, NOTES lets only the notes through), its `pose` and the point it faces (`systems/story`). Ivo stays in the talk. It then starts `DialogueBeat.find(tree, cue)`. A cue with no beat pushes an error and goes on. When the beat emits `finished` or leaves the tree:
  - if the director is out of the tree, the world is being swapped out (a death after its rewind, a quit): the talk is dropped unheard and writes nothing (`gotchas/a-removed-subtree-emits-tree-exiting-later-siblings-first`);
  - otherwise it emits `resume_wanted` and waits; Ivo answers `talk_resumed` under the start gates, and `resume()` places the box again, emits `talk_began` and steps on.
- `interrupt()` (`Player.hurt`, `fell_into_hazard`) closes and frees Ivo, and the dialogue stays unheard. During a beat it does nothing: the talk is in the beat's hands. While the talk waits to resume, it ends it unheard.
- `DialogueBeat` (Node, group `dialogue_beats`): `cue`, `start()`, `finish()`, `started`, `finished`. STORY-03's guitar composes one.

## Ivo and the Talkable

- `Talkable` (`scenes/world/interactables/talkable/`, Area2D on layer 6 masking the Player body, like `Door`). Legend `t` (ENTITY, reach role CONTENT), required param `talk` (a `DialogueSet` path in the catalog: `room_files_test`). Params `auto_start`, `presence` (min region baseline; it composes a `RegionPresence`, so it leaves with its villager), `reach_west` / `reach_east` (px each side of the speaker, `Talkable.REACH` 48 by default) and `height_cells` (2, rising from its floor), `auto_delay` (0.4 s), `speaker_offset` (px along x from its origin to the speaker; Ivo faces that point, and the box is placed from it).
- **The zone is centred on the speaker** (STORY-14; "O radius do diálogo também tá esquisito. Eu preciso chegar por trás da aguadeira pra conseguir disparar o dialogo com ela. E bem longe" (user, 2026-10-15)): about a cell and a half each way, with the prompt over the speaker's head. Put the `t` on the speaker's cell. Where a door stands within reach, trim that side only (`reach_west`/`reach_east`, non-negative, summing above 0; `_ready` asserts it) so the two zones keep more than 22 px apart and the door wins (`talkable_rooms_test`, every room file). An auto talk is at least 80 px wide, or a run through it never starts it.
- It stands on the speaker's cell, its zone centred on the speaker (STORY-14); the villager prop itself carries no gameplay (`systems/props`) and does not turn to Ivo.
- The `look_up` `KeyGlyph` prompt stands 8 px over the zone, above the speaker, while Ivo is in reach, a dialogue is current and no talk runs.
- **A prompt shows exactly where a press works** (STORY-14): the Up prompts of a Talkable, a Door and an ItemPickup read `Player.reaches(area)`, the same 12 px door sensor Up and auto starts read, not Ivo's 22 px body (`player_talk_test`, `player_door_test`, `player_pickup_test`: prompt and `reachable()` agree across each edge). The bench's Down prompt still reads the body.
- An auto start arms when Ivo enters, is due after `auto_delay` while a dialogue is pending, fires once, and arms again only after he leaves.
- `TalkComponent` (`Ivo/Talks`) reads the `DoorSensor` overlaps: `reachable()` (a shown Talkable with a current dialogue) and `auto_ready()`.
- `Player`: the Up buffer is `_up_buffer` (`UP_BUFFER`, 0.1 s), ticked every frame in `_process_motion` whichever branch ran. `_try_door` first, then `_try_talk`, both under `_free_for_up` (on the floor; no roll, swing, knockback, climb, wall slide, Memorina, stair, call, recall or fight). A door in reach wins, and a talk wins over an item pickup (`systems/pickups`). A refused Up is spent; a refused auto start stays due, and none fires while `PlayerInput.blocked` (the map's) or a talk runs. Emits `talk_started(talkable)`.
- `begin_talk(at)` blocks input and faces `at`; `pause_talk(hold, pose, at)` (a beat) keeps the block for STILL, sets `notes_only` for NOTES, frees him for FREE, and keeps him in the talk; doors and item pickups are refused while he is in a talk (`bugs/up-takes-a-door-during-a-free-beat-and-strands-the-talk`); `request_talk_resume()` makes `_try_talk` emit `talk_resumed` once the start gates hold; `end_talk()` unblocks and ends it. `is_talking()` is true from `begin_talk` to `end_talk`, a beat included, and `can_open_map()` is false for all of it. Since STORY-15 `PlayerInput.blocked` is written only by `Player._refresh_block()`: in a talk, the talk's listening (or the map); else a cutscene; else the map (`systems/cutscenes`).
- `NotebookWatcher.is_holding()` (`NoticeHold.applies`) includes `is_in_story()` (a talk or a cutscene), so a granted item's quill waits for the talk to end; `NoticeWatcher` holds the same way, so the item-acquired notice and the intent line show after the talk (`systems/notices`).
- Grants today: the baker's "Just the round one." (the round loaf, `Enums.PlayerItem.BREAD`, UI-11) and the mentor's gift (the Memorina).

## The box (`CanvasLayer/DialogueBox`)

- After `GuardianCallHud`, before `Fade`; INHERIT, so a pause or the notebook (both hold) stops it. It never reads the save.
- **Placement** ("Opposite the speakers (Recommended)", below): `DialogueBoxSide.opposite(speaker_ys, screen_height)` (pure) puts the box in the screen half the speakers are not in. The mean screen y of the speaker's point and Ivo's feet (through `listener.get_canvas_transform()`) at or below the middle opens it at the top; above the middle, at the bottom. The director decides once when a talk begins or resumes (`box_placed`), and `DialogueBox.place` holds it for the whole talk. In most rooms the floor is low on screen, so the box opens at the top.
- One 320x180 `Art` root at scale 2 (`systems/screens`, the 2x rule), `menu_theme.tres`; every piece sits under `Art/Box`. Pack px for the bottom box; the top box moves `Box` by `TOP_SHIFT` (-86), so its panel runs from y 20 to 88, under the life notes and the HUD quill (HUD y 8 to 40), which would otherwise draw over its frame:
  - panel `BGbox_05A` 304x68 at (8, 106), 9-slice 12/14/12/12; its paper runs 9 px inside the frame;
  - portrait slot 48x48 at (18, 116), empty while a speaker has no portrait;
  - name plate `Button_01A` 16 px tall on the box's inner edge: at the bottom, at (18, 99) over the panel's top edge (`PLATE_Y_BOTTOM`); at the top, under its lower edge (`PLATE_Y_TOP` 165, art y 79 to 95), so it never leaves the screen. Cream `SlotText`, as wide as the name plus 6 px a side, at most `PLATE_MAX_WIDTH` (120);
  - text 230x36 at (72, 117): `TEXT_ROWS` 3 rows of 12 px (9 px font, 3 px spacing). It never moves for a portrait;
  - a question keeps `QUESTION_ROWS` 1 row; its choices are `InkButton`s 230x12 from (72, 129), up to `MAX_CHOICES` 3, ending at the paper's edge (165);
  - the next mark: the `jump` `KeyGlyph` (Z / pad A, both `ui_accept`), 16x16 at (287, 158) on the panel's bottom edge, shown when a line is typed.
- These numbers differ from the plan's starting ones (panel 60 tall at y 114): the frame's measured 9 px border left 42 px of paper, too short for a question and three 12 px choices.
- `InkButton` (a theme variation in `menu_theme.tres`): empty styles, ink text (0.32, 0.2, 0.25), red ink (0.72, 0.24, 0.16) when focused, like the notebook's rows.
- **Typing:** `visible_ratio` tweened at `chars_per_second` (40) on a tween bound to the box (pausable) with `set_ignore_time_scale(true)` (real time under a recall's slow). `VC_CHARS_AFTER_SHAPING`, so words do not jump lines. The first press completes the line (kill, set the ratio, `gotchas/a-killed-tween-never-emits-finished`); the next emits `advanced`. Choices sent while typing wait for it.
- **Focus and input:** no script reads an event. `ContinueArea` (a text-less `InkButton` over the text) holds focus on a line; on a question the first choice does. Explicit neighbours, itself at either end and on both sides. A Button acts on the `ui_accept` release after a press, so a release with no press (Z held into an auto start) does nothing. `close()` releases focus held inside the box; `NOTIFICATION_UNPAUSED` grabs it back, because closing the pause or the notebook releases it.
- **The closing press does not jump:** `PlayerInput` is disabled while talking, so the press never reaches it, and the release that ends the talk runs after `_input` (`gotchas/a-menu-press-reaches-the-last-node-first`); re-enabling resyncs jump as released.

## Wiring (`game.tscn`)

`DialogueDirector.listener` is `../Player`. `Player.talk_started` → `DialogueDirector.start`; `talk_began` / `talk_paused` / `talk_ended` → `Player.begin_talk` / `pause_talk` / `end_talk`; `resume_wanted` → `Player.request_talk_resume`; `Player.talk_resumed` → `DialogueDirector.resume`; `box_placed` → `DialogueBox.place`; `line_shown`, `choices_shown`, `box_closed` → `DialogueBox.show_line`, `show_choices`, `close`; `DialogueBox.advanced` / `chosen` → `advance` / `choose`; `Player.hurt` and `fell_into_hazard` → `interrupt`.

## Text

`SPEAKER_<ID>` for plates. Story keys follow `DLG_<DIALOGUE_ID>_<NN>`, `..._V<k>` for variants, `DLG_CHOICE_<CHOICE_ID>`; the trial fixture's keys are `DIALOGUE_TRIAL_*`. The box draws no other text. `dialogue_text_fit_test` checks every catalog line and variant against its rows, every choice in one row, every speaker file's name in the plate, in every CSV locale, each key filled and not equal to itself, measured with the box's own Labels at their fixed width. `dialogue_catalog_test` checks every key has a CSV row.

## The trial fixture

No story text is approved yet (STORY-03 drafts the opening), so the only talk is a debug fixture: `t` at `trials_winter/winter_trial` col 8 (x 272, floor y 6000, beside the trial spawn at x 160), `resources/dialogue/trials/trial_talk.tres`. `trial_first` (once): the elder, a nameless speaker, the elder's question `trial_keep` (`trial_keep_hold` HOLD_ON, `trial_keep_let_go` LET_GO, a reply each), a closing line. `trial_after` (after `trial_first` is heard): one line whose variant follows the answer. Playtest timeline: `tools/playtest/scripts/dialogue_trial.json`; the run is `playtests/2026-10-15-story08-dialogue`, whose first run showed the bottom box over Ivo's feet; with the placement decision the box opens at the top there.

## User decisions

2026-10-15 (STORY-08 plan):
- Who speaks: "Story cast + some villagers (Recommended)".
- Choices: "Remembered, later lines vary (Recommended)".
- Look: "Bottom box with portraits". Portraits come later through the art pipeline, after approval; the box runs with none.
- The call to adventure: "Playable, impossible to finish (Recommended)" (a talk hands off to a scripted beat and resumes after it).

2026-10-15 (open questions, as relayed by the orchestrator):
- A talk blocks Ivo like the map; the world keeps running; the pause and the notebook may open over a talk; the map is refused while talking. `WorldFreeze` gets no new writer.
- Heard and chosen responses are live data: a bench commits them, a death forgets them.
- `DialogueChoice.tone`: `Tone { NONE, HOLD_ON, LET_GO }` (append only). The tally is derived, never stored; STORY-07 decides how it is read.
- Speaker plates show role names for now (`SPEAKER_ELDER`, `SPEAKER_DAUGHTER`, `SPEAKER_MENTOR`); the mentor stays unnamed. The portrait slot exists and runs empty; the text does not move whether or not a portrait exists.
- Typing at 40 chars/s real time; the first press completes the line, the second advances. No voice blips for now.
- Box: bottom box, 2x pixel rule, the wood theme, a speaker name plate, choices inside the box.
- Input: no new InputEvent reader; GUI focus and Buttons like the pause menu.

2026-10-15, after the first playtest showed the bottom box over Ivo's feet: box placement "Opposite the speakers (Recommended)": the box opens in the screen half the speakers aren't in. In most rooms (floor low on screen) that's the top; it goes to the bottom only when they stand high. Same box and portraits.

## Story beats (STORY-03, `systems/story`)

- A silent ask (no text, no speaker, no variants) is valid: a gesture; the box opens on its choices alone.
- A grant on a cue-only line is valid and lands as its CUE starts (also with no beat).
- `talk_paused(hold, pose, at)`: the beat's `Hold` (FREE, STILL, NOTES), `Pose` (NONE, GUITAR, MEMORINA) and the point it faces. `Player.pause_talk` applies them; a STILL beat's own block does not refuse the resume.
- `DialogueDirector.hear_note` passes Ivo's notes to a NOTES beat. `phrase_shown` / `phrase_lit` / `phrase_closed` are relayed to `CanvasLayer/PhraseSheet`.
- `~word~` in a text is a brief stutter (`StutterText`); the box shows the text without the marks.

## Limits

- **The reach audit reads talks the kits hold.** `ReachKit.of()` packs a `DIALOGUE_HEARD` or `RESPONSE_CHOSEN` fact as its kind and the id's place in `ReachKit._ids`. A `ReachMilestone.dialogues` list sets what a kit has heard: every kit holds the `opening` milestone (the errand, the song, the elder's story), so the east gate on `heard_elder_story.tres` is open to them all (`systems/story`). A way gated on any other talk reads as closed to every kit until a milestone holds it. `GUARDIANS_RESTORED_AT_LEAST` packs whole (its count is the index).
- `DialogueBoxSide.opposite` returns `int` (`gotchas/a-static-func-returning-its-own-enum-fails-once-another-script-types-it`).

## Tests

`tests/resources/save_facts/save_fact_test.gd`, `tests/globals/save_system_dialogue_test.gd`, `save_ledger_test.gd`, `player_data_test.gd`, `tests/resources/dialogue/dialogue_catalog_test.gd`, `dialogue_set_test.gd` (with `dialogue_fixture.gd`), `tests/scenes/world/dialogue/dialogue_runner_test.gd`, `dialogue_tally_test.gd`, `dialogue_director_test.gd`, `tests/scenes/ui/dialogue_box/dialogue_box_test.gd` (either side stays on screen, the plate on the inner edge), `dialogue_box_side_test.gd`, `dialogue_text_fit_test.gd`, `tests/scenes/world/interactables/talkable/talkable_test.gd`, `tests/scenes/characters/ivo/player_talk_test.gd` (Z through `Input.parse_input_event`: the closing press, Z held into an auto start), `room_files_test.test_every_talkable_set_is_in_the_dialogue_catalog`.
