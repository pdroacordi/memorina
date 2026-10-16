---
id: systems/notices
type: system
title: Notices: the item-acquired notice and the current intent, derived from the save and held through talks and scenes
status: active
tags: [ui, hud, notice, item, intent, save, save-fact, queue, i18n, tween, ui-11]
related: [bugs/a-notice-withdrawn-after-it-left-is-told-twice, bugs/a-withdrawn-intent-comes-back-after-the-intent-ended, systems/songs-and-the-memorina, systems/notebook, systems/screens, systems/story, systems/dialogue, systems/cutscenes, systems/pickups, systems/life-benches-death, architecture/notebook-entries-are-derived-from-the-save, playtests/2026-10-16-ui11-item-and-intent, gotchas/a-killed-tween-never-emits-finished]
created: 2026-10-16
updated: 2026-10-16
source_files:
  - resources/story/intent.gd
  - resources/story/intent_catalog.gd
  - resources/story/intent_catalog.tres
  - scenes/ui/notice/notice.gd
  - scenes/ui/notice/notice_queue.gd
  - scenes/ui/notice/notice_hold.gd
  - scenes/ui/notice/notice_watcher.gd
  - scenes/ui/notice/notice_toast.gd
  - scenes/ui/notice/notice_toast.tscn
  - resources/ui/notebook/notebook_entry.gd
  - resources/ui/notebook/notebook_catalog.gd
  - resources/ui/notebook/notebook_catalog.tres
  - scenes/ui/pause_menu/pause_menu.gd
  - scenes/ui/pause_menu/pause_menu.tscn
  - scenes/ui/screens/screens.gd
  - scenes/world/game.tscn
  - scenes/world/game.gd
  - tools/playtest/playtest_runner.gd
---

# Notices

**Never break:** A notice is derived from the save, never recorded: an item notice is an owned item that became true on `progress_changed`, an intent notice is a change of `IntentCatalog.current`, and a rebuilt world seeds both silently. A notice never shows over a talk, a cutscene, a lesson or a fight: it waits for them to end (`NoticeHold.applies`, the one test both watchers use), and one still sliding in or holding when they begin is withdrawn and shown again after; once it starts to slide out it is told and never shown again. The pause menu shows the intent last told, never one whose notice has not shown. `NoticeWatcher` and `NoticeToast` are pausable; the toast's tween is bound to it (pausable, scaled), never ALWAYS. The current intent is the first that holds, the rule `DialogueSet.current` uses. Every item name and intent fits its line in every language (`notice_text_fit_test`).

## Summary

UI-11, design 06 §5 Pilar 2 and §9. Two kinds of notice share one queue and one view, top right beside the notebook quill: an item Ivo gains (its 16x16 icon and its name) and a change of his intent (one quiet line). The pause menu shows the current intent under its box. No inventory screen, no map marker, no quest list.

## Data

- **Items** reuse the notebook's Items entries (`systems/notebook`): `NotebookEntry.title_key` is the item's name, and `NotebookEntry.icon` (new, 16x16 art px) its icon. `NotebookCatalog.item_entry(item)` finds the entry; `validate()` names an Items entry with no icon. One entry per `Enums.PlayerItem` was already the catalog's rule, so a new item cannot ship without its notice.
- **Intents** (`resources/story/`): `Intent` (`id`, `text_key`, `when` / `unless` `SaveFact`s) and `IntentCatalog` (`intents` in priority order; `current(data)` is the first that holds; `validate()` names an empty or repeated id, a missing or spaced key, a heard / chosen / seen fact with no id). `intent_catalog_test` checks every DIALOGUE_HEARD fact names a catalog dialogue and every key has both languages.
- **The opening's intents** (`intent_catalog.tres`), each gated so at most one holds at any step:

| id | holds | en | pt_BR |
|---|---|---|---|
| `bread` | `daughter_errand` heard, unless `baker_errand` | The round loaf. | O pão redondo. |
| `home` | `baker_errand` heard, unless `daughter_song` | Home. | Para casa. |
| `elder` | `daughter_song` heard, unless `elder_story` | The elder's story. | A história do ancião. |
| `east` | `elder_story` heard, unless `mentor_gift` | The lighthouse, east. | O farol, a leste. |
| `village` | `mentor_gift` heard, unless `elder_return` | Back to the village. | De volta à vila. |

- The texts and the moments are design 05's draft 3 (its "→ Intenção" marks, approved "Aprovar (Recommended)", user, 2026-10-16). A new game has no intent until the daughter asks for the bread, so the first intent is told as a notice after her talk.
- After `elder_return` no intent holds: the pause menu shows no line until the next intent is written. The end condition is UI-11's call (2026-10-16), for the user to confirm; the user gave the flow up to "after the gift, back to the village".
- **The intents read talks, not items**, as the house's stages do (`systems/story`, "The stages read talks"): the bread's grant and `baker_errand` heard land in one talk and rewind together, and a playtest kit that owns items early leaves the intent where the talks put it.

## The queue (`NoticeQueue`, pure, and `Notice`)

- `Notice`: `kind` (`ITEM` or `INTENT`), `item` (an `Enums.PlayerItem`) or `intent_id`.
- `NoticeQueue.gained(before, after)` lists the items owned now that were not (a shorter `before`, an older save, counts the appended items).
- `add_item` queues an item once. `set_intent(id)` does nothing when `id` is the intent it last heard, so a waiting intent keeps its place and the queue stays oldest first. A changed id drops any waiting intent notice and queues `id` unless it is empty or the intent last told; so only the newest change waits, and a change back before its turn tells nothing. The seeded intent counts as told.
- `keep_owned(owned)` drops waiting items a rewind took back. `pop()` returns the oldest (marking an intent told). `push_front(notice)` puts a withdrawn notice back first; a withdrawn intent that is no longer the current one is dropped, and with no intent waiting the told intent becomes the current one (none, when the intent ended), so the pause menu never keeps a stale line (`bugs/a-withdrawn-intent-comes-back-after-the-intent-ended`). `told_intent()` is the intent last popped, or the seeded one.
- Order: the baker's grant lands on her line and `baker_errand` is heard at the talk's end, so the bread is told first, then the way home.

## The watcher (`World/NoticeWatcher`, pausable)

- Exports `notebook` (the notebook catalog), `intents`, `subject` (Ivo). At `_ready` it seeds the owned items and the current intent silently: a new game, a load and a death's rebuild tell nothing.
- On `SaveSystem.progress_changed` it queues the items gained and the new intent.
- `_process` sends one notice at a time: `shown(text_key, icon)` (icon null for an intent), then waits for `on_notice_finished()` (the toast's `finished`). `on_notice_leaving()` (the toast's `leaving`, as its slide-out starts) marks the notice told. Nothing is sent while `is_holding()`, which is `NoticeHold.applies(subject)` (`scenes/ui/notice/notice_hold.gd`: `Player.is_in_lesson()`, `is_in_story()` = a talk or a cutscene, `Guardian.fight_at` where he stands). `NotebookWatcher.is_holding()` calls the same function, so the item notice and the notebook quill wait for the same end and a fix reaches both. Pausable, so nothing is sent under a freeze or a hold.
- A hold that begins while a notice slides in or holds (an auto talk, a scene trigger) emits `withdrawn` and pushes the notice back first. A hold during the slide-out or the gap leaves it alone: it was told (`bugs/a-notice-withdrawn-after-it-left-is-told-twice`). The slide-out may run up to 0.5 s into the hold's first moments.
- `intent_key()` is the key of the intent last told (`NoticeQueue.told_intent()`): the one a notice showed, or the one a rebuilt world was seeded with. `Game._ready` passes it to `Screens.set_intent`, as it passes `CutsceneDirector.can_skip`. So the menu does not say "The elder's story." while the daughter-to-bed scene still plays; it changes when the notice shows.

## The view (`CanvasLayer/NoticeToast`)

- After `NotebookToast`, INHERIT. One 320x180 `Art` root at scale 2 (`systems/screens`, the 2x rule), in art px:
  - `Card/Row`, an HBox from (96, 4) to (296, 20), right-aligned, 4 px apart: `Icon` (16x16, hidden for an intent) and `Text`;
  - the row ends 4 art px left of the quill (HUD (600, 8), art (300, 4)), so an item and its notebook quill show side by side;
  - `Text`: the 8 px text font, cream (0.96, 0.9, 0.72) with a 2 px dark outline (0.13, 0.08, 0.05), the region title's epithet style, so it reads over any room; `TEXT_WIDTH` (180) is the widest text the line holds.
- `show_notice(key, icon)`: slides in from 12 art px right while fading in (0.3 s), holds 2.0 s, emits `leaving`, slides out (0.5 s), waits `gap` (0.25 s) and emits `finished`. One tween bound to the toast: pausable and scaled, like the quill and the region title; under a menu hold it stops where it is.
- `withdraw()` kills the tween and hides at once without `leaving` or `finished` (`gotchas/a-killed-tween-never-emits-finished`).

## The pause menu

- `PauseMenu.intent` (a Callable, set through `Screens.set_intent` to `NoticeWatcher.intent_key`, the intent last told) is asked as the menu opens; `Intent` (a Label in `Box`) shows its text centred from art x 10 to 310, 6 px under the panel's bottom (`INTENT_GAP`), so it follows the box when "Skip scene" grows it (y 148 or 168). Same style as the notice. Hidden when no intent holds; hidden with the box during a quit confirmation.
- The 96 px panel cannot hold the longest intent (about 150 art px), so the line sits under the box on the dim, not inside it.

## Icons

16x16 art px at 2x (32x32 HUD px), the notebook quill's size. Contracts `tools/art/prompts/item_icon_{bread,sword,memorina}.md` (Codex, no outlines per `style.md`); the targets are `make_placeholders.gd` placeholders (flat purple squares) until the user delivers the art. The notebook had no item drawings to reuse: its Items section shows text only, and the pouch tab icon is the section's, not an item's. The notebook's right page does not draw `icon`.

## Text

`ITEM_*` (names), `INTENT_*` in `i18n/translations.csv`. `notice_text_fit_test` measures every Items entry name and intent with the toast's own `Text` label and every intent with the pause menu's `Intent` label, in en and pt_BR, each key translated.

## User decisions

- "não tem nenhuma indicação que eu peguei o pão ou algo assim. Deveria ter um inventário? Algum hud de item acquired? Algo indicando missão ou algo assim?" (user, 2026-10-15, design 06 §1 point 7).
- "Seção no caderno + aviso (Recommended)" (user, 2026-10-16, design 06 §9): an item-acquired notice with an icon when Ivo gets an item, and the item listed in a section of the field notebook; no inventory screen.
- Design 06 §5 Pilar 2: a quiet line of intent that appears when the intent changes and stays in the pause menu; no map marker and no quest list. Design 05, draft 3 (approved 2026-10-16, "Aprovar (Recommended)"), places each "→ Intenção" and "→ Aviso" and gives their text; the build follows it. The orchestrator's brief had "O ancião sabe do farol." / "The elder knows about the lighthouse." for the elder; draft 3's "A história do ancião." / "The elder's story." replaced it.

- The pause menu shows the intent last told, not the live one: "default, 2026-10-16" (the coordinator's call, consistent with design 06 §5, "aparece quando muda e fica no menu de pausa").

## Limits

- F10 (`DebugTrials`) grants the trials' kit, so a debug run shows "Sword" and "Memorina" notices after it.

## Tests

`tests/resources/story/intent_catalog_test.gd` (validation, first-that-holds, the opening's flow, at most one holds per step, items do not move it, facts and keys), `tests/scenes/ui/notice/notice_queue_test.gd` (a withdrawn intent that ended is dropped, one that holds goes back first, an unchanged intent keeps its place), `notice_watcher_test.gd` (silent seed, item name and icon, the bread then the way home one at a time, a rewound item dropped, waits for a talk and a cutscene with a real Ivo, a talk withdraws the notice showing and it shows again, a hold in the slide-out or in the gap tells it once, the menu's intent waits for its notice and a rebuilt world's is the seeded one), `notice_toast_test.gd`, `notice_text_fit_test.gd`; `notice_toast_test` (`leaving` before `finished`); additions to `notebook_catalog_test` (every item has an icon), `screens_test` (the pause menu's intent line), `opening_test` (the baker grants the loaf on "Just the round one."; owning it alone moves nobody) and `reach_kits_test` (the base kit owns the sword alone). Playtest: `tools/playtest/scripts/ui11_item_and_intent.json` (and `_pt`), report `playtests/2026-10-16-ui11-item-and-intent`.
