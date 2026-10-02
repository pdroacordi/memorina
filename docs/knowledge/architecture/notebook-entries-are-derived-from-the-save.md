---
id: architecture/notebook-entries-are-derived-from-the-save
type: architecture
title: Notebook entries are derived from save facts, never recorded; a watcher diffs them on progress_changed to announce new ones
status: active
tags: [notebook, ui, save, resources, unread, toast, plan]
related: [architecture/pause-menu-worldfreeze-reuse, architecture/the-life-loop-rewinds-by-reloading, architecture/save-slots-and-the-boot-swap, systems/guardians, systems/songs-and-the-memorina]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - resources/ui/notebook/notebook_entry.gd
  - resources/ui/notebook/notebook_catalog.gd
  - scenes/ui/notebook/notebook_index.gd
  - scenes/ui/notebook/notebook_watcher.gd
  - scenes/ui/notebook/notebook.gd
  - scenes/ui/notebook_toast/notebook_toast.gd
  - globals/save_system.gd
  - globals/save_ledger.gd
  - globals/player_data.gd
---

> **Status: planned** (2026-10-02, roadmap UI-03). Nothing here is built yet.

## Context

The user's decisions (2026-10-02): E / pad Select opens the field notebook, which freezes the
world. It has four sections:
- **Lore:** Ivo's diary, including a short entry when a skill is recalled in a guardian fight, and
  later bearer fragments and letters (STORY-04/06).
- **Songs:** title, notes in the player's glyphs, season or material, and a description.
- **Items.**
- **Guardians:** portrait grey while corrupted and in colour once restored, name and state, what
  it taught, and a short text.

A new entry fades a small book icon in on the HUD for a few seconds, and the entry keeps an unread
marker in the book until it is read. Death rewinds every gain since the last bench, so an entry
for a song lost to a death must vanish with the song.

## Options considered

**Where presence comes from.**
- Rejected: record unlocked entry ids in `PlayerData` at every grant site. Every grant site must
  remember to do it, and it is a second truth that can disagree with `learned_songs` and the others.
- **Chosen: derive presence from facts the save already holds.** `NotebookEntry.requirement` plus
  `index` names one `PlayerData` field. Only facts that are new to the game become new fields:
  `met_guardians` now, and `found_lore` with STORY-06. Rewind is then correct for free.

**Entry model.**
- Rejected: a subclass per section (`SongEntry extends NotebookEntry`). It builds a project-class
  hierarchy, which `CLAUDE.md` reserves for real is-a on engine classes.
- Rejected: a union resource with a `song`/`stats` field for each section, because it duplicates
  data.
- **Chosen: one `NotebookEntry` (id, section, requirement, index, title/detail/body keys, art).**
  Each page looks up its subject in the catalogs that already exist: the songs page uses
  `SongCatalog.get_song(index)`, and the guardians page uses its exported `Array[GuardianStats]` for
  the song and the recalled skills it taught. A song's notes stay in `Song`.

**Detecting a new entry.**
- Rejected: an explicit announce call at each grant site, which couples gameplay to UI.
- **Chosen: a `NotebookWatcher`** that recomputes the set of present ids on the new
  `SaveSystem.progress_changed` signal and queues the difference. It seeds itself silently at
  `_ready`, so a world rebuilt after a death or a load never toasts.

**Read markers.**
- Rejected: let them rewind with the rest of the save. An entry read after the bench would show as
  unread again after a death.
- **Chosen: `PlayerData.notebook_read` survives death.** `SaveLedger.record_death` merges the live
  ids into the committed save, because what the player has read is a fact about the player, like a
  death mark.

**When the icon shows.**
- Rejected: show it on the frame of the gain. That puts the icon over the lesson cinematic, and over
  the recall the design wants confirmed "pós-combate" (02 §4).
- **Proposed** (the user's confirmation is pending): the watcher and the toast are PAUSABLE, so
  nothing shows during a freeze. The watcher also holds its queue while
  `Guardian.fight_at(tree, ivo_position)` is true. It reads that state on demand, as `_try_sit`
  does, and is never told it by a pushed flag.

## Decision

- `NotebookEntry` (Resource): `id: StringName`, `section: Section` {LORE, SONGS, ITEMS,
  GUARDIANS}, `requirement: Requirement` {SKILL, SONG, ITEM, GUARDIAN_MET, GUARDIAN_RESTORED},
  `index: int`, `title_key`, `detail_key`, `body_key`, `art: Texture2D`.
  `is_present(data) -> bool` is a single `match` over the requirements. GUARDIAN_MET is met by
  `met_guardians` OR `restored_guardians`, so older saves stay correct.
- `NotebookCatalog` (Resource): `entries` in display order. `validate()` asserts:
  - ids are unique;
  - each section's requirement matches it (SONGS→SONG, ITEMS→ITEM, GUARDIANS→GUARDIAN_MET);
  - there is one entry per `Enums.Song`, `PlayerItem` and `Guardian`.
- `NotebookIndex` (RefCounted, pure): `present(catalog, data)`, `unread(catalog, data)`,
  `added(before, after)`, `section_unread(catalog, data, section)`.
- `SaveSystem.progress_changed` is emitted by `learn_song`, `unlock_skill`, `set_item_owned`,
  `restore_guardian` and `meet_guardian`. `mark_notebook_read(id)` does NOT emit it.

## Consequences

- A new kind of unlock is a `Requirement` member, a `PlayerData` field and a `match` arm. The
  `match` is kept, because the set of save facts is closed and small.
- Every key a catalog entry names must exist in `i18n/translations.csv`. The catalog test reads the
  CSV.
- Entries are listed in catalog order, not in the order they were found. A found order would need
  a timestamp in the save.
