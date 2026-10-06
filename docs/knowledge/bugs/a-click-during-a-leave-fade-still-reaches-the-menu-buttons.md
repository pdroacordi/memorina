---
id: bugs/a-click-during-a-leave-fade-still-reaches-the-menu-buttons
type: bug
title: During the 0.5 s fade after Quit to title or after picking a slot, a mouse click still reaches the menu's buttons, which can release the hold or erase a slot
status: fixed
severity: low
tags: [title, pause, menu, mouse, fade, blackout, save, slots, guard]
related: [architecture/save-slots-and-the-boot-swap, architecture/pause-menu-worldfreeze-reuse, systems/screens, gotchas/a-menu-press-reaches-the-last-node-first]
created: 2026-10-02
updated: 2026-10-06
source_files:
  - scenes/ui/screens/screens.gd
  - scenes/ui/screens/screens.tscn
  - scenes/ui/pause_menu/pause_menu.gd
  - scenes/ui/title/title.gd
  - scenes/ui/title/title.tscn
  - scenes/ui/title/slot_screen.gd
---

## Summary

The UI-05 "leaving" guards cover presses routed through `MenuInput` and the play path, and focus is
released, but the buttons stay visible and clickable under a fade whose `mouse_filter` is IGNORE.
Found by code review on 2026-10-02; not reproduced in a run.

## Symptom

- Pause menu: Quit to title, Yes. During the 0.5 s Blackout, click No on the still-visible
  confirmation, then Resume. `Screens.close()` sends `release_requested`, the world runs under the
  black, then the swap to the title happens anyway. The plan's "stay frozen" decision is broken.
- Title: pick a slot (or confirm an overwrite). During the 0.5 s fade, click another used slot's
  Erase and Yes, or (New game, all slots used) another card and Yes. `SlotScreen._erase` /
  `_overwrite` delete that slot. `_overwrite` deletes before `Title._play` checks `_leaving`.

## Root cause

- `Screens._leave_for_title` (`screens.gd:66-73`) sets `_leaving` and `_locked`, which only
  `_on_press` reads. `close()` and the pause menu's button signals are not gated, and the
  ConfirmPanel is left open.
- `Blackout` (`screens.tscn`) and the title's `Fade` (`title.tscn`) have `mouse_filter = 2`
  (IGNORE), so clicks pass through them. Nothing hides the mouse (no `mouse_mode` anywhere).
- `Title._leaving` (`title.gd:85-92`) guards `_play`, `_open_slots`, `_quit` and `_step_back`, not
  `SlotScreen`'s erase and overwrite paths (`slot_screen.gd:189-207`).

## Fix

Fixed 2026-10-06 (UI-05 round 3).
- `Screens._leave_for_title` sets the Blackout's `mouse_filter` to STOP. The Blackout covers the menu, so clicks stop there.
- Screens drops the pause menu's Resume and Quit game relays while leaving (`_unless_leaving`).
- `Title._play` sets the Fade's `mouse_filter` to STOP.
- `Title` owns every `SaveSystem` call. `_on_erase_confirmed` and `_on_overwrite_confirmed` return while `_leaving`, so no slot is deleted once a slot is chosen. `SlotScreen` only emits.

Evidence:
- `screens_test` `test_buttons_pressed_while_leaving_neither_release_nor_quit` emits No, Resume, Quit game and its Yes during the Blackout: requests stay `["hold"]`, and the Blackout is STOP.
- `title_test` `test_buttons_pressed_while_leaving_erase_and_overwrite_nothing` emits Erase+Yes and a second overwrite+Yes after the first overwrite: the saves list is unchanged.

## Prevention

A "nothing is obeyed while leaving" test should also emit the visible buttons' `pressed`
(`No`, `Resume`, a card's `Erase` + `Yes`), not only `MenuInput` presses.
