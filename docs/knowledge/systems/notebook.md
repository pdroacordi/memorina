---
id: systems/notebook
type: system
title: The field notebook: entries derived from the save, the book screen, the watcher and the HUD quill
status: active
tags: [notebook, ui, screens, save, unread, toast, i18n, art]
related: [architecture/notebook-entries-are-derived-from-the-save, bugs/the-notebook-quill-shows-through-a-lesson, bugs/the-notebook-list-cannot-scroll-back-up-past-a-hidden-row, gotchas/gui-focus-skips-a-neighbour-wholly-clipped-by-a-scroll-container, gotchas/autowrapped-rows-settle-over-several-sorts, playtests/2026-10-06-notebook, systems/screens, systems/input, systems/life-benches-death, systems/guardians, systems/greyhush, gotchas/time-scale-zero-stops-delta-particles-and-time, gotchas/a-killed-tween-never-emits-finished]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - resources/ui/notebook/notebook_entry.gd
  - resources/ui/notebook/notebook_catalog.gd
  - resources/ui/notebook/notebook_catalog.tres
  - scenes/ui/notebook/notebook_index.gd
  - scenes/ui/notebook/notebook_watcher.gd
  - scenes/ui/notebook/notebook.gd
  - scenes/ui/notebook/notebook.tscn
  - scenes/ui/notebook/notebook_row.gd
  - scenes/ui/notebook/notebook_cue.gd
  - scenes/ui/notebook/notebook_forgotten.gdshader
  - scenes/ui/notebook_toast/notebook_toast.gd
  - scenes/characters/ivo/player.gd
  - globals/player_data.gd
  - globals/save_ledger.gd
  - globals/save_system.gd
---

# The field notebook

**Never break:** An entry's presence is derived from save facts, never recorded. Every notebook text, and the ink of every note glyph, stays inside its page's text rect in every language (`notebook_text_fit_test`). The book animates only with real-time tweens.

## Summary

UI-03, design 02 "UI" ("Caderno de campo"). E / pad Select toggles it; Esc and B close it. It holds the world like the pause and is refused over an existing freeze or hold (`systems/screens`). Four sections, one tab each: Memories (Ivo's diary), Songs, Items, Guardians. The left page shows the section title and its entry list; the right page shows the focused entry. Plan and options: `architecture/notebook-entries-are-derived-from-the-save`.

## Data

- `NotebookEntry` (Resource): `id`, `section`, `requirement` {SKILL, SONG, ITEM, GUARDIAN_MET, GUARDIAN_RESTORED}, `index` into that `PlayerData` flag array, `title_key`, `detail_key` (a song's season and material), `body_key`, `art` (a guardian portrait). `is_present(data)` is one `match`.
- `NotebookCatalog` (`resources/ui/notebook/notebook_catalog.tres`) holds the 14 entries in story order, which is the order of the approved drafts. `validate()` returns the problems: unique ids, SONGS→SONG, ITEMS→ITEM, GUARDIANS→GUARDIAN_MET, one entry per `Enums.Song`, `PlayerItem` and `Guardian`. The notebook asserts it at `_ready`.
- Memories entries exist only for the recalled skills (ROLL, DOUBLE_JUMP). WALL_CLIMB has none, because no guardian teaches it yet.
- `NotebookIndex` (pure): `present`, `unread`, `added`, `section_unread`, and `newest_unread(catalog, data, recent)`. The last id announced this session that is still unread wins; else the last unread in catalog order.
- `PlayerData.met_guardians` (`migrate()` grows it) is set by `Guardian._on_player_entered` through `SaveSystem.meet_guardian`. GUARDIAN_MET is met by met OR restored, so older saves are correct.
- `PlayerData.notebook_read` (ids). `SaveLedger.rewind` merges the live ids into the committed save, so a death keeps what was read (both `record_death` and `SaveSystem.rewind` go through it).
- `SaveSystem.progress_changed` is emitted by `learn_song`, `unlock_skill`, `set_item_owned`, `restore_guardian` and `meet_guardian`. `mark_notebook_read` does not emit it.

## Watcher and the HUD quill

- `NotebookWatcher` (`World/NotebookWatcher`, pausable, `subject` = Ivo) seeds the present ids silently at `_ready`, so a rebuilt world never announces. On `progress_changed` it queues the ids added since, skipping ids already read, and drops a queued id the save no longer holds. `recent` keeps every announced id for the opening rule.
- It emits `announced(ids)` from `_process`, so nothing shows under a freeze or a hold. It also waits while `is_holding()` is true: `Player.is_in_lesson()` or `Guardian.fight_at(tree, subject.global_position)`, both pulled on demand. A lesson starts unpaused (0.5 s of lead-in) and freezes later, so the pause alone let the quill in (`bugs/the-notebook-quill-shows-through-a-lesson`). A recalled skill's entry therefore waits for the fight, then for the lesson's lead-in and track. F9 lessons wait the same way.
- At emit time it drops ids read while they waited, so an entry read before its hint gets none.
- `NotebookToast` (`CanvasLayer/NotebookToast`, pausable, 32x32 at (600, 8) on the 640x360 HUD) is the pack's quill (Icon 23). It fades in over 0.4 s, holds 3 s and fades out over 0.8 s.

## The screen (`Notebook`, a `MenuScreen` under `Screens`)

- **Art (pack px, one 320x180 `Art` root at scale 2):**
  - book `spellbook.png` 256x160 at (24, 10);
  - page text rects 81x106: left (54, 26), right (167, 26). They sit 6 px inside the paper.
  - Tabs (`tab_0N_normal/selected`, 32x32) are in `Tabs` at (256, 20), 28 px apart, drawn over the right edge of the book. They stick out 13 px, and the selected one is shifted 1 px further out (its art is also 1 px wider).
  - Icons are at (7, 7) in each tab: quill (Lore), note (Songs), pouch (Items), leaf (Guardians).
  - The unread mark (`notebook_mark.tscn`, a 3x3 red dot in a 5x5 dark rim) sits on rows and at (21, 6) on tabs.
- **Animations:** `Flip` (Sprite2D, 8 frames) steps a pack strip with a tween that ignores the time scale, `frame_seconds` (0.05) per frame. The strips are bottom-aligned on the open book, so the strip's y = book y - (strip height - 160).
  - Opening uses `spellbook_opening.png`; closing plays the same strip backwards (the pack's Closing strip is its exact reverse, so it is not shipped).
  - A page turn uses `spellbook_next_page.png` or `spellbook_previous_page.png`.
  - The opening and closing frames rise up to 66 px above the open book and are cut by the top of the screen; the page turn fits.
- **Phases:** SHUT, OPENING, OPEN, TURNING, CLOSING. A closing press reaches `step_back()`, which plays the book shut (from the current frame if it was still opening) and emits `close_requested`; `Screens` then closes and releases. `close()` (a death's `lock()`) shuts at once.
- **Opening:** "Newest unread, else last": the section of `NotebookIndex.newest_unread` with that entry focused, else the section last viewed with its last focused entry. The last viewed section lives in the `Notebook` node, so a death or a load (a new world) starts again from Memories. Kept as built (2026-10-06).
- **Navigation:** up and down move focus between known rows through explicit `focus_neighbor_top` / `_bottom` set by `_link_known_rows` (previous and next known row; itself at either end). The engine's geometric search never reaches a row wholly clipped by the list (`gotchas/gui-focus-skips-a-neighbour-wholly-clipped-by-a-scroll-container`). Left and right (`MenuInput.page_pressed`, consumed by `Screens` only while the notebook is open) turn one section and stop at either end. A tab click turns to that tab. Presses are ignored while the book moves.
- **Rows** (`NotebookRow`, a focusable PanelContainer) wrap inside the page. An unknown entry is "? ? ?" (`NOTEBOOK_UNKNOWN`) at 0.35 alpha and is unfocusable, so the list shows how many exist. The focused row is drawn in red ink.
- **A list longer than the page** (eight songs, several on two lines) scrolls by whole rows. A row not wholly inside the list is hidden, and the ink cues `MoreAbove` / `MoreBelow` in the gutter margin say rows are hidden.
  - `_reframe` starts from `_base_first`: 0 when a section is built, else the first row shown when focus last moved. It scrolls only as far as the focused row needs (the last known row also brings in the placeholders after it). It then pulls rows above back in while every shown row still fits, so a return to a section shows the same rows as the first visit.
  - A 106 px `Tail` under `Rows` lets any row's top reach the list's top, so the scroll is never clamped into an empty top line.
  - The framing reruns on every `Rows.sort_children` from the same base, because autowrapped rows settle over several sorts (`gotchas/autowrapped-rows-settle-over-several-sorts`).
- **Read:** an entry is marked read when it leaves the right page (focus moves, a page turns, the book closes). The row mark and the tab marks update then.
- **Song page:** `SONG_TITLE_*`, the six notes in `NoteGlyphSet` glyphs for `InputDevice.glyph_set` (redrawn on `device_changed`), the season and material line, and the body.
  - The glyphs are 16x16 pack px, 2x like the rest of the book, the approved mockup's size (measured there: 1 texel per pack px, 14 px pitch).
  - `Notes` (a 16 px tall Control) sets them at x -3 + 14 i. The pack glyphs' ink is x 3..11, so the 3 px transparent margin falls outside the page and the ink spans x 0..79 of 81: six fit on one line.
  - `notebook_text_fit_test` checks each glyph's ink rect (`get_used_rect`) in all four glyph sets.
- **Guardian page:** the name, Corrupted / Restored, then "Taught:" with the song (once restored) and each recalled skill learned, then the body. The portrait (`NotebookEntry.art`, an AtlasTexture crop of idle frame 0: Frost 79x60 bust, Bloom 58x44) sits on the LEFT page under the list. The right page has no room for it. While corrupted it wears `notebook_forgotten.gdshader` (`gh_print`, `systems/greyhush`).
- **Fonts:** every notebook text uses the 8 px text font, section titles included. The 17 px title font draws "Guardiões" 91 px wide on an 81 px page.

## Text

`NOTEBOOK_SECTION_*`, `NOTEBOOK_UNKNOWN`, `NOTEBOOK_SONG_*_DETAIL` / `_BODY`, `GUARDIAN_FROST` / `GUARDIAN_BLOOM`, `NOTEBOOK_GUARDIAN_*_BODY`, `NOTEBOOK_GUARDIAN_CORRUPTED` / `_RESTORED` / `_TAUGHT`, `SKILL_ROLL` / `SKILL_DOUBLE_JUMP`, `NOTEBOOK_LORE_*`, `ITEM_*`, `NOTEBOOK_ITEM_*`, all in `i18n/translations.csv`, verbatim from the approved drafts. `notebook_catalog_test` fails on a key with no row. The "Taught:" line joins the names with ", ".

## User decisions

2026-10-02 (`architecture/notebook-entries-are-derived-from-the-save`):
- Entries "Story order".
- Guardian names: "Descriptive for now, I'll name them later".
- Frost body: "Swap it".
- HUD hint timing: "After the fight".

2026-10-06:
- Look: the v2 mockup, with "It is better, but we've got to be careful, the text is overflowing the page" (v1: "Just fit better the layout inside the notebook. The text should have a certain margin. And the markers are floating on the screen, not between pages of the notebook").
- Animations: "Yes, all three".
- Opening: "Newest unread, else last".
- Unknown entries: "? ? ?" placeholders.
- New entries: "HUD hint + marker".
- HUD hint icon: "Quill (Icon 23)".
- Tab icons: "Approve" (quill, note, pouch, leaf).
- Song entry: "The actual name of the song..., Note sequence, Season / material, Short description".
- Guardian entry: "Portrait, Name + state, What it taught, Short text".
- Recalled skills: "Lore -> Ivo's diary".
- Items: "Real tabs, few entries".
- Section titles: pt_BR "Memórias", "Canções", "Itens", "Guardiões" / en "Memories", "Songs", "Items", "Guardians" (the Lore section is titled Memórias / Memories).
- Note glyphs: "Mockup size" (16 pack px each, as in the approved mockup).
- The list longer than the page: "Scroll, as built".
- The opening and closing frames cut at the top of the screen: "Accept the cut".
- Section titles in the text font, and the guardian portrait on the left page: "Accept both".

## Tests

`tests/resources/ui/notebook/notebook_catalog_test.gd`, `tests/scenes/ui/notebook/notebook_index_test.gd`, `notebook_watcher_test.gd`, `notebook_test.gd` (Up and Down sent through `Input.parse_input_event` over a scrolled list), `notebook_text_fit_test.gd` (every entry, both languages, fullest and emptiest save; a mutation that shrinks a page makes it fail), `tests/scenes/ui/notebook_toast/notebook_toast_test.gd`, `tests/scenes/ui/screens/screens_notebook_test.gd`, `tests/globals/save_system_notebook_test.gd`, and additions to `save_ledger_test` and `player_data_test`.
