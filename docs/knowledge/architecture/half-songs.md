---
id: architecture/half-songs
type: architecture
title: Half songs - per-half save facts, partial matcher candidates judged on the sixth note, derived notebook states and page ids
status: active
tags: [songs, memorina, matcher, save, save-fact, notebook, unread, reach-kits, i18n, song-14, plan]
related: [systems/songs-and-the-memorina, systems/notebook, systems/notices, systems/life-benches-death, architecture/notebook-entries-are-derived-from-the-save, architecture/reward-slots-reserve-their-place-in-the-room-text, architecture/room-reachability-audit, bugs/the-notebook-quill-shows-through-a-lesson]
created: 2026-10-28
updated: 2026-10-28
source_files:
  - globals/player_data.gd
  - globals/save_system.gd
  - resources/save_facts/save_fact.gd
  - resources/songs/song.gd
  - scenes/characters/components/song_matcher.gd
  - scenes/characters/ivo/abilities/memorina_component.gd
  - scenes/characters/ivo/player.gd
  - scenes/ui/memorina_hud/note_sheet.gd
  - resources/ui/notebook/notebook_entry.gd
  - scenes/ui/notebook/notebook.gd
  - resources/world/maps/reach_kit.gd
---

# Half songs (SONG-14)

**Status: built** (2026-10-28; "As built" at the end supersedes the Decision where they differ). The design is design 02 §7.2.1, which records the user's decisions. Out of scope: teaching creatures (CORE-04), songbook pickups in reward slots (STORY-06) and the Found tab (UI-14). This item builds the facts, the matcher, the sheet, the notebook states and the one entry point those items will call.

## Context

- Redoma, Chuva, Vendaval and Solstício (`Enums.Song` BELL_JAR 1, SOLSTICE 3, GALE 5, RAIN 7) are learned in two halves: notes 1-3 come from a creature, notes 4-6 from a songbook, and either can come first.
- With one half known, the player may guess the other half on the Memorina. The blanks are not rejected note by note; the sixth note decides. A right guess teaches the song under a name Ivo gives it, and finding the true half later crosses that name out.
- Facts the plan must keep:
  - presence is derived, never recorded (`SaveFact.check` is the one match);
  - death rewinds every gain;
  - the matcher stays pure;
  - call mode is untouched;
  - a component never reads `SaveSystem`;
  - nothing animates on screen through a freeze (`bugs/the-notebook-quill-shows-through-a-lesson`);
  - every notebook text fits its page.
- The Memorina HUD **does not list known songs**: `MemorinaHud.on_drawn` ignores the list and the sheet shows only notes as they are played. The one place it shows a song's notes unprompted is a lesson.

## Options considered

**Save shape.**
- One `Array[int]` bitmask per song (FIRST=1, SECOND=2, GUESSED_x=4/8): compact but opaque, and `SaveFact.index` could not name a single bit. Rejected.
- `guessed: Array[bool]`: once the true half is found, both half flags are true and nothing tells which half was guessed. Rejected.
- **Chosen:** two bool arrays for the known halves plus an int array holding the guessed `SongHalf`. This is the existing flag-array pattern, grown by `migrate()`.

**Which songs can be halved.**
- Hard-coded `[BELL_JAR, SOLSTICE, GALE, RAIN]`: a closed list of content inside code. Rejected.
- Derived as "the song no guardian teaches": couples songs to `GuardianStats`, and the kits still give the second songs today. Rejected.
- **Chosen:** data, `Song.learned_in_halves: bool`, true on the four `.tres` files and pinned by a test (Open/Closed).

**Matcher.**
- A second matcher class for guesses: two matchers fed the same notes would disagree about failure. Rejected.
- Wildcards as a fifth `Enums.Note`: pollutes the input enum and the glyphs. Rejected.
- **Chosen:** every candidate becomes a `SongCandidate` (song + which positions are known). A whole song is all known; call mode builds only whole candidates.

**When a guess is saved.**
- At match time: `progress_changed` fires during the ring-out, the pausable quill starts its fade, and then the performance's freeze holds it on screen. That repeats the lesson-quill bug. Rejected.
- **Chosen:** at `song_played` (after the thaw). An interrupted guess teaches nothing, which is the failure vocabulary that already exists.

**Re-announcing a changed entry.**
- Removing the id from `notebook_read` when the entry changes: that records state, and read ids are merged across deaths. Rejected.
- No re-announcement: the user said "the diary entry changes with that", and a completion would go unseen. Rejected (but see question 4).
- **Chosen:** a derived **page id**: `entry.id` for every plain state, and `entry.id + "@" + state` for the half, by-ear and confirmed states. Unread and the watcher diff work on page ids. Old saves' read ids stay valid, because LEARNED keeps the plain id.

**Kits now.**
- Model the halves in `reach_kits.tres` now, before any creature or songbook exists: the room of each half is not chosen ("slots chosen from the kit report"). Rejected.
- **Chosen:** add the pure rule now. Leave the kit data as is and rewrite the four stale notes. The milestone fields come with the first item that places a half.

## Decision

**Data.**
- `Enums.SongHalf { NONE, FIRST, SECOND }`. Append only, because the save stores it as an int.
- `PlayerData` fields, live data like `learned_songs`. `SaveLedger` needs no change, since its deep copy covers them.
  - `song_first_halves: Array[bool]`: notes 1-3, indexed by `Enums.Song`.
  - `song_second_halves: Array[bool]`: notes 4-6.
  - `guessed_halves: Array[int]`: the `Enums.SongHalf` Ivo completed by ear; NONE when the song was not guessed.
  - `migrate()` grows all three (`resize` fills false and 0 = NONE). Older saves need nothing more: a second song learned whole (F9, a playtest) reads as LEARNED.
- `Song.learned_in_halves: bool` (export).
- `SaveFact.Kind.SONG_PART_KNOWN` (appended): the song is learned or either half is known. `SONG` keeps meaning "playable", so doors and kits are unchanged.

**Pure rule: `SongHalves`** (`resources/songs/song_halves.gd`, RefCounted, static). It is the only code that knows how halves combine; `SaveSystem`, `Player`, the notebook and later `ReachKit` all call it.
- `enum State { UNKNOWN, FIRST_HALF, SECOND_HALF, LEARNED, BY_EAR, BY_EAR_CONFIRMED }`, with `state(data, song) -> State`.
  - LEARNED covers both a song learned whole and one learned from both halves; their pages are the same.
  - CONFIRMED is `guessed != NONE` and that half's own flag is true.
- `known_mask(data, song) -> Array[bool]` (6 entries) and `guessed_mask(data, song) -> Array[bool]`.
- `teach(data, song, half) -> bool`: sets the half; with both halves known it sets `learned_songs`. Returns whether anything changed.
- `guess(data, song) -> bool`: asserts the song is not learned and exactly one half is known; sets `learned_songs` and stores the missing half in `guessed_halves`.

**`SaveSystem`.** It delegates to `SongHalves` and emits `progress_changed` only on a change, as `mark_dialogue_heard` does:
- `knows_song_half(song: Enums.Song, half: Enums.SongHalf) -> bool`
- `learn_song_half(song: Enums.Song, half: Enums.SongHalf) -> void`
- `learn_song_by_ear(song: Enums.Song) -> void`

**Matcher** (`scenes/characters/components/`).
- `SongCandidate` (RefCounted): `song: Song`, `known: Array[bool]`.
  - `static whole(song)`, `static partial(song, known)`;
  - `admits(buffer) -> bool`: the known positions are equal and the blanks take any note;
  - `is_whole() -> bool`.
- `SongMatcher.set_candidates(candidates: Array[SongCandidate])` replaces the `Array[Song]` overload.
- `feed`:
  - MATCHED when the buffer equals a candidate's `song.notes`;
  - PROGRESS when some candidate admits a buffer shorter than 6;
  - otherwise FAILED.
  - Every song has 6 notes and the sequences are unique, so at most one candidate matches, and a buffer of 6 that matches none fails. The rejected note is the sixth: the existing `note_rejected` followed by `sequence_failed`.
- `matched_by_ear() -> bool` is true when the matched candidate is partial.

**`MemorinaComponent`.**
- `try_draw(can_play, known_songs: Array[Song], half_known: Array[SongCandidate] = [])`. The `drawn(known_songs)` signal is unchanged.
- `_candidates()` returns `[SongCandidate.whole(call_song)]` during a call, otherwise the whole candidates plus `half_known`.
- New signal `song_guessed(song: Song)`, emitted just before `song_matched` when `matched_by_ear()`.

**`Player`.**
- `_half_known_candidates()` lists every catalog song that is not learned and has state FIRST_HALF or SECOND_HALF.
- On `song_guessed` it keeps `_guessing = song`. `_on_song_played` calls `SaveSystem.learn_song_by_ear` when `_guessing == song`. `_on_memorina_sheathed` clears `_guessing`, so an interruption teaches nothing.
- `learn_song_half(song: Song, half: Enums.SongHalf) -> bool` is the one entry point for creatures (CORE-04) and songbooks (STORY-06), as `learn_song` is for guardians.
  - It is refused under the same gates as `learn_song` and asserts `song.learned_in_halves`.
  - When the call completes the song, it runs `learn_song(song)`, the whole lesson (question 2).
  - Otherwise it writes the half and emits `song_half_learned(song, half, glyph_set)`.

**Sheet** (`NoteSheet`, `MemorinaHud`).
- `NoteSheet.show_notes(notes, glyphs, count := -1, known: Array[bool] = [])`: an unknown slot shows the exported `blank_texture` on the middle line.
- `MemorinaHud.on_song_half_learned` shows the six slots in the encounter slot and closes like the lesson sheet (`LESSON_SHEET_HOLD`/`FADE`, `TWEEN_PAUSE_PROCESS`). `MemorinaHud` is already ALWAYS, so the pause-mode map gains nothing.
- Nothing is shown on draw: design 02 §6.2 rules out contextual hints (question 1).

**Notebook.**
- `HalfSongPage` (Resource, `resources/ui/notebook/half_song_page.gd`): `half_title_key`, `first_half_body_key`, `second_half_body_key`, `ear_title_key`, `ear_body_key`, `margin_key`, `keys()`.
- `NotebookEntry.halves: HalfSongPage` (null except on the four entries). This is composition: no subclass, no fields for every entry.
- New `NotebookEntry` functions:
  - `title_key_for(data)` and `body_key_for(data)`: the row and page texts per state;
  - `page_id(data) -> StringName`: the plain id, or `id@first`, `id@second`, `id@ear`, `id@confirmed`.
- Every song entry's requirement becomes SONG_PART_KNOWN. `validate()`:
  - accepts SONGS→SONG_PART_KNOWN;
  - requires `halves` exactly where `learned_in_halves` is true;
  - checks `keys()` includes the half keys.
- `NotebookCatalog.entry_of_page(page_id)` strips the suffix.
- `NotebookIndex.present`/`unread`/`newest_unread` and `NotebookWatcher` work on page ids. The notebook marks read the page id it showed. Rows and tabs compare page ids.
- The page per state:
  - **half:** the half title; three glyphs and three `blank_texture` slots; the detail line; the half body for the half known.
  - **by ear:** Ivo's title; the guessed glyphs modulated by `IVO_INK`; Ivo's body.
  - **confirmed:** the real title; under it a new `StruckTitle` (a Label that draws a 1 px line across its text in `_draw`, one line only, which the fit test asserts) holding Ivo's name; the real body; then a new `Margin` label, inside the 81x106 rect.

**Debug and playtests.**
- New action `debug_learn_song_half` (Shift+F9). `PlayerInput.debug_learn_song_half_pressed` leads to `Player.learn_song_half` on the first `learned_in_halves` song that is not learned, with the half it lacks (FIRST first). A second press completes the song with a lesson.
- The runner gets `"song_halves": [[song, half], ...]` (half 1 FIRST, 2 SECOND) and `"songs_by_ear": [song, ...]`, applied after `known_songs`.

**Kits.**
- `reach_kits.tres` keeps `songs` as they are. The four notes change from "modelled as found with the guardian" to "stands in for its two halves (SONG-14) until CORE-04/STORY-06 place them".
- Later, `ReachMilestone` gains `first_halves: Array[Enums.Song]` and `second_halves: Array[Enums.Song]`. `ReachKit.player_data()` calls `SongHalves.teach` for each, so a kit knows a song only when it holds both half milestones. The guardian milestones then drop their second song.
- Kits never model a guess. A guess only adds a song, so it cannot cause a kit trap, and no route may need one.

**i18n** (`i18n/translations.csv`, en and pt_BR, drafted for the user's approval before they are built):
- `NOTEBOOK_SONG_HALF_TITLE`;
- `NOTEBOOK_SONG_{BELL_JAR,SOLSTICE,GALE,RAIN}_{FIRST,SECOND}_HALF_BODY`;
- `SONG_IVO_TITLE_{...}`;
- `NOTEBOOK_SONG_{...}_EAR_BODY`;
- `NOTEBOOK_SONG_EAR_MARGIN`.
- Glyphs and blanks carry no text.

## Build order

1. `Enums.SongHalf`, the `PlayerData` fields, `SongHalves`, `Song.learned_in_halves` on the four `.tres`, `SONG_PART_KNOWN`, the `SaveSystem` API.
2. `SongCandidate` and `SongMatcher`, then `MemorinaComponent`, then the `Player` by-ear wiring.
3. `Player.learn_song_half`, the `NoteSheet` blank (art contract `tools/art/prompts/note_blank.md`, a `make_placeholders.gd` placeholder until delivered), the HUD half sheet, Shift+F9, the runner fields.
4. `HalfSongPage`, the catalog entries, page ids, the notebook render, keys, the fit tests.
5. The kit notes; `systems/songs-and-the-memorina`, `systems/notebook`, `systems/life-benches-death`, the glossary (meia canção → `SongHalf`, de ouvido → `learn_song_by_ear`/`guessed_halves`); the roadmap. Then `verify-gates` and a playtest (`song14_half_songs.json` with `song_halves`: guess right, guess wrong, open the notebook).

## Tests (gdUnit4)

- `tests/resources/songs/song_halves_test.gd`:
  - `test_one_half_leaves_the_song_unlearned`
  - `test_both_halves_in_either_order_learn_it`
  - `test_a_known_half_changes_nothing`
  - `test_a_guess_records_the_missing_half` (both directions)
  - `test_a_guess_needs_exactly_one_half`
  - `test_finding_the_guessed_half_confirms`
  - `test_masks_per_state`
  - `test_a_song_learned_whole_is_learned`
- `song_catalog_test.test_exactly_the_four_second_songs_are_learned_in_halves`.
- `song_matcher_test`:
  - `test_a_wrong_known_note_is_rejected`
  - `test_blanks_take_any_note`
  - `test_a_wrong_guess_fails_on_the_sixth`
  - `test_a_right_guess_matches_by_ear`
  - `test_a_second_half_candidate_checks_four_to_six`
  - `test_right_known_notes_after_a_wrong_guess_fail_on_the_sixth`
  - `test_a_whole_song_beside_a_partial_is_not_by_ear`
  - `test_blanks_suspend_early_rejection_of_other_songs` (pins the consequence below)
- `memorina_component_test`:
  - `test_a_guess_emits_song_guessed_then_song_matched`
  - `test_a_call_ignores_half_known_songs`
- Player suite:
  - `test_a_guess_is_learned_when_the_performance_ends`
  - `test_an_interrupted_guess_teaches_nothing`
  - `test_the_second_half_starts_a_lesson`
  - `test_learn_song_half_refused_without_the_memorina`
- `save_system_song_halves_test`:
  - `test_learn_song_half_emits_progress_changed`
  - `test_a_repeated_half_emits_nothing`
  - `test_learn_song_by_ear_emits`
- `save_ledger_test`: `test_a_death_forgets_a_half_and_a_guess`.
- `player_data_test`: an old save grows the three arrays; round trip.
- `save_fact_test`: `test_song_part_known`.
- `notebook_catalog_test`: half pages exactly on halved songs; every half key in both languages.
- `notebook_index_test`:
  - `test_a_half_song_is_present`
  - `test_completion_reads_unread_again`
  - `test_an_old_plain_read_id_still_reads_a_learned_song`
- `notebook_watcher_test`:
  - `test_a_half_announces`
  - `test_a_completion_announces`
- `notebook_text_fit_test`:
  - `test_every_half_song_state_fits_the_right_page`
  - `test_half_titles_and_ivo_names_fit_the_left_page`
  - `test_the_struck_name_holds_one_line`
  - the glyph-ink test extended to `blank_texture`.
- `note_sheet_test.test_a_mask_draws_blanks`.

## Consequences

- While a SECOND-half candidate is installed, the first three notes of every phrase are accepted, so a typo in a known song is rejected at note 4 or later, not at once. The user's rule ("not refused one by one") implies this, but it is player-visible (question 10).
- `SongMatcher.set_candidates` changes type. Guardians reach the matcher only through the component, but the existing matcher tests change too.
- `notebook_read` now holds page ids. Anything that marks read (the runner's `notebook_read`, tests) must use `page_id(data)` for the non-plain states.
- Struck text and a coloured ink are new on the page. `IVO_INK` must read on the pack glyphs' dark ink; if a modulate does not, a fifth "pencil" `NoteGlyphSet` per device is the fallback.
- `SongCatalog`'s prefix rule is untouched: every song still has 6 notes.

## Open questions for the user

1. "Na pauta da Memorina com as três notas conhecidas e três espaços vazios": the sheet shown at the moment a half is taught (recommended), or something shown on every draw (a contextual hint, against design 02 §6.2)?
2. Finding the second half with no guess: a full lesson (title card and whole track, recommended), or silent?
3. A right guess: the ordinary performance (recommended), or a lesson with Ivo's name on the title card?
4. When an entry changes (half → whole, by ear, confirmed), does it show the quill and the unread mark again? (Recommended: yes, through page ids.)
5. Does a half reveal the real name? (Recommended: no; a generic "Half a song" until it is whole, which is why Ivo has to name a guess.)
6. On a confirmed page, do the guessed notes stay in Ivo's ink? Is the body the real body plus the margin line (recommended), or Ivo's body kept?
7. One margin line for all four songs, or one per song?
8. Does taking a half need the Memorina (recommended: the same gate as a lesson)?
9. Approve the drafted texts (keys above) in en and pt_BR.
10. Accept that blanks suspend early rejection for the other songs (Consequences, first point)?

## User decisions (2026-10-28)

- Q1 "When the half is taught (Recommended)": the sheet shows a half's three notes and three blanks once, when the half is taught; nothing on draw.
- Q5 "No, 'Half a song' (Recommended)": a half shows `NOTEBOOK_SONG_HALF_TITLE` until the song is whole.
- Q2 and Q3 "Both get a full lesson": the second half found starts the whole lesson, and so does a right guess, with Ivo's name on the title card. The guess therefore starts a lesson instead of a performance; it is saved when the lesson starts, like `learn_song`, and the quill waits on `NoticeHold` (`is_in_lesson`), so the save-at-`song_played` rule above is replaced.
- Q7 "One per song (Recommended)": `NOTEBOOK_SONG_<ID>_EAR_MARGIN`, four keys.
- Orchestrator defaults, as recommended in the plan: Q4 a changed entry is unread again (page ids); Q6 the guessed notes stay in Ivo's ink, the body is the real one plus the margin line; Q8 a half needs the Memorina; Q10 blanks suspend early rejection of the other songs. Q9: texts are drafted in the build and shown to the user for approval.

## As built (2026-10-28)

- `SongMatcher.set_candidates(songs: Array[Song], partials: Array[SongCandidate] = [])`: whole songs keep their type; `SongCandidate` is `(song, known)` with `admits`. No `whole`/`partial` constructors, no `_guessing` in `Player`.
- A right guess emits `song_guessed`, the component stays DRAWN, and `Player._on_song_guessed` saves (`learn_song_by_ear`) and starts the lesson (`_begin_lesson`, gates in `_can_take_lesson`).
- `Player.learn_song_half`: a known half returns false; the completing half or the guessed half runs the lesson; any other sheathes a drawn instrument and emits `song_half_learned` (review bugs, all fixed before the commit: `bugs/the-half-song-sheet-stays-transparent-after-a-lesson-or-another-half`, `bugs/a-half-taught-while-the-memorina-is-drawn-cannot-be-guessed-until-redrawn`, `bugs/shift-f9-rolls-ivo-so-the-debug-half-is-refused`, `bugs/ivos-by-ear-page-says-he-made-up-the-ending-when-he-guessed-the-beginning`).
- No `HalfSongPage`: the half title and the two half bodies are shared constants on `NotebookEntry`; `ear_body_key` and `ear_margin_key` are `NotebookEntry` exports; Ivo's title is `Song.ear_title_key`, read by `SongHalves.title_key` (lesson card) and `Notebook.title_key` (rows and page). Per-song half bodies can come with CORE-04 and STORY-06.
- The confirmed page hides the season line to fit 106 px. Debug key F8.
- Tests as built: `song_halves_test`, `song_catalog_test`, `song_matcher_test` (half section), `memorina_component_test` (half section), `save_system_notebook_test` (halves, death), `notebook_index_test`, `notebook_watcher_test`, `notebook_catalog_test`, `notebook_text_fit_test` (both orders), `note_sheet_test`. No Player-level suite exists for lessons; the playtest covers them.
