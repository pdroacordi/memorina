---
id: playtests/2026-10-02-title-and-slots
type: playtest
title: The title and save slots (UI-05) - every flow passes in en and pt_BR, with keys and pad, and arrivals land in the bench's room; accents vanish on a focused button and the runner adopts a legacy save
status: active
build: ea921a9 + uncommitted UI-05 working tree (no source change during the session)
area_tested: "Boot, the title (main and slot screens), three debug slots, pause > Quit to title, Continue to Downtown and Lighthouse, deaths after Continue"
tags: [title, save, slots, boot, pause, quit-to-title, gamepad, i18n, playtest]
related: [architecture/save-slots-and-the-boot-swap, systems/screens, bugs/a-teleported-ivo-enters-the-room-he-left, bugs/a-click-during-a-leave-fade-still-reaches-the-menu-buttons, bugs/the-playtest-runner-adopts-the-legacy-save-before-going-memory-only, bugs/accents-on-a-focused-menu-button-land-on-its-top-highlight, playtests/2026-10-02-pause-menu]
created: 2026-10-02
updated: 2026-10-02
ratings: { fun: 0, fluidity: 4, aesthetics: 4 }
screenshots:
  - screenshots/2026-10-02-title-and-slots/main_no_saves_en.png
  - screenshots/2026-10-02-title-and-slots/disabled_continue_zoom.png
  - screenshots/2026-10-02-title-and-slots/continue_latest_focused_pt_BR.png
  - screenshots/2026-10-02-title-and-slots/erase_confirm_en.png
  - screenshots/2026-10-02-title-and-slots/after_last_erase_en.png
  - screenshots/2026-10-02-title-and-slots/overwrite_confirm_pt_BR.png
  - screenshots/2026-10-02-title-and-slots/quit_to_title_blackout_sheet.png
  - screenshots/2026-10-02-title-and-slots/continue_lighthouse_arrival_en.png
  - screenshots/2026-10-02-title-and-slots/accent_on_button_bevel_pt_BR.png
---

## What was tested

The playtest runner cannot reach the title: it calls `use_memory_only()`, and the title reads slot
files. So a scratch `SceneTree` driver (`-s`) booted `res://scenes/boot/boot.tscn` with `-- --title`.
Godot 4.7.2 console build, windowed, debug.

Each run had its own `APPDATA` under the session scratchpad. Slot files were seeded headless with
`ResourceSaver`:
- some: Downtown in slot 1 (`saved_at` 100) and Lighthouse in slot 3 (`saved_at` 200);
- full: all three slots;
- last: slot 2 only;
- none.

Input was raw `InputEventKey` (Enter, Escape, arrows, Down for sitting), `InputEventJoypadButton`
(A 0, B 1, Start 6, D-pad 11 to 14) and seven-event stick tilts, all through
`Input.parse_input_event`. Every claim about focus, pause, time scale and rooms comes from log
lines, not frames:
- the GUI focus owner;
- `paused`, `Engine.time_scale`;
- `Game._current_room`, the region;
- the memory field's baseline and season against the region's;
- the camera bounds against the room bounds;
- the slot files on disk.

The real `save_debug.tres` md5 was `990dc788715ef9f873fc063428d39d1d` before and after the session.

There were 14 runs: none, some and full in en and pt_BR, plus last, New game with free slots, pad,
background drift, debug boot without `--title`, the runner over a legacy save, and two re-runs with
memory logging. No run logged an engine error or warning.

## Findings

1. **No saves: pass** (`main_no_saves_en.png`).
   - New game is focused. Continue is disabled with `focus_mode` NONE.
   - Down from New game lands on Quit game, and Up returns, so Continue is skipped.
   - New game fades the title out in 0.5 s and arrives in BloomHollow (authored start; no bench yet).
     Extra Enter/Esc presses during the fade did nothing.
   - No file exists until the first rest. After sitting on the Downtown bench, `save_debug_1.tres`
     holds `downtown_bench`, Downtown's uid, `REGION_HOME_VILLAGE` and play time 7.4 s.
   - With slots 1 and 3 used, New game went straight to slot 2.
2. **Some saves: pass** (`continue_latest_focused_pt_BR.png`).
   - Continue is focused. It opens the slot screen on slot 3, the latest `saved_at`.
   - Up/Down move only between slots 1 and 3; the empty slot 2 is greyed and skipped.
   - Esc and pad B both return to main with Continue focused.
   - Loading slot 3 arrived at `room=Lighthouse`. The camera bounds equal the room bounds
     (4496.5, -538, 1920x602). The memory field is at FrostEdge's 0.20 and season 0
     (`continue_lighthouse_arrival_en.png`).
   - Loading Downtown arrived at `room=Downtown`: bounds (-1363.75, -538), HomeVillage at 0.80,
     season 3.
   - The stale-room bug (`bugs/a-teleported-ivo-enters-the-room-he-left`) did not recur in 8
     bench arrivals (Continue or debug boot) and 18 death rebuilds.
3. **Erase: pass** (`erase_confirm_en.png`, `after_last_erase_en.png`).
   - Right from a used card reaches its Erase. The confirmation opens with No focused.
   - Esc, and Enter on No, both return focus to that same Erase.
   - Yes deletes the file and greys the card; focus goes to the remaining card.
   - Erasing the only save while continuing returned to main with Continue greyed and New game
     focused.
4. **All three full: pass** (`overwrite_confirm_pt_BR.png`).
   - New game opens the slot screen with every card pickable, slot 1 focused. Up/Down visit all three.
   - Picking a used card asks to overwrite, with No focused. Esc and No return to the card.
   - Yes deletes the old file at once, then starts fresh. The next rest wrote play time 7.6 s (the old
     save had 3h 07m) and kept slots 2 and 3.
   - A consequence to know: a player who overwrites and quits before the first bench has an empty
     slot. The question says the saved game will be erased, so this matches the text.
5. **Pause > Quit to title: pass** (`quit_to_title_blackout_sheet.png`).
   - Down from Resume reaches Quit to title. Its confirmation opens on No; Esc and No return to
     Quit to title.
   - On Yes, the world stays held (`paused=true`, `time_scale=0`) through the whole blackout. The
     mean frame luminance goes 62, 31, 17, 4 at 0.1 s steps.
   - The title appears 0.5 to 0.55 s after Yes on a running clock, with Continue focused, and fades
     in over about 0.5 s.
   - Enter, Esc, pad A and Start sent during the blackout did nothing: one swap, no error.
   - Continue then reloaded the slot at its bench in Downtown.
   - Mouse clicks during the fade were not tested. They are the open
     `bugs/a-click-during-a-leave-fade-still-reaches-the-menu-buttons`.
6. **Death after Continue, 3 times in each of 2 rooms and 2 languages: pass.**
   - Each `take_damage(999)` rebuilt the world with Ivo seated at (-1104, 0) in Downtown or
     (4592, 0) in Lighthouse.
   - Each rebuild had the same camera bounds, centre and memory baseline as the arrival.
   - The death marks moved play time from 7 s to 30 s, as the ADR describes.
7. **Gamepad: pass.**
   - On main, D-pad down/up and each stick tilt moved focus by one entry, skipping nothing extra.
   - On the slot screen: stick up from slot 3 reached slot 1 (skipping empty slot 2), stick right
     reached Erase, and D-pad left/right moved between card and Erase.
   - A opened the erase confirmation on No. B closed it back to Erase, and B again returned to main
     on Continue. Start on main did nothing.
   - A loaded the slot (Lighthouse). In game, Start opened the pause menu and the D-pad reached
     Quit to title. A opened its confirmation on No, and B returned.
8. **Feel and look** (inferred from frames; the motion is not observed).
   - The five layers drift left at their authored rates: the front trees at 8 game px/s (16 window
     px per second, measured frame to frame), deeper bands slower. The lower ~170 window px under
     the trees is a flat slab and does not move.
   - Whether the drift feels calm or sluggish needs a human.
   - The logo (grey lettering, coloured flute) reads clearly against the light sky in both
     languages.
   - Slot cards read well in both languages: region, bench and "3h 07m"; the cedilla in "Praça" is
     fine.
   - The disabled state changes only the text colour, (245, 229, 184) to (211, 155, 132), on an
     unchanged fill (189, 106, 98) (`disabled_continue_zoom.png`). It reads as disabled up close,
     but it is the weakest cue on the screen.
   - The erase/overwrite confirmation hides the list, so "this game" has no slot shown beside it.
9. **Bug: accents on a focused button** (`accent_on_button_bevel_pt_BR.png`).
   - The focused pause entry "Voltar ao título" reads "titulo".
   - The focused "Não" loses the upper half of its patched tilde.
   - The accent's top pixel is drawn on the 1 px top highlight. Filed as
     `bugs/accents-on-a-focused-menu-button-land-on-its-top-highlight`.
10. **Bug: the playtest runner adopts a legacy save.**
    - A windowed runner session over a seeded `save_debug.tres` left `save_debug_1.tres` behind:
      `adopt_legacy()` runs in `SaveSystem._ready` before the runner's `use_memory_only()`.
    - Filed as `bugs/the-playtest-runner-adopts-the-legacy-save-before-going-memory-only`.
    - Debug boot without `--title` went straight to the game on slot 1 (Downtown), as designed.

What frames cannot show: input latency, how long the 0.5 s fades feel, audio, and whether the drift
reads as "forgotten woods" in motion.

## Ratings rationale

- **Fun 0**: not applicable to menus. This follows the pause-menu session's convention.
- **Fluidity 4**:
  - every focus move, back and confirm landed on the first press, on keys and pad;
  - no flow left focus nowhere or on a hidden control;
  - quit-to-title holds the world under its blackout;
  - every arrival and rebuild settled in the right room.
  - Not a 5 because latency and the fades' pacing were not felt, only timed.
- **Aesthetics 4**:
  - the wood style, the logo and the greyed parallax agree;
  - the cards are readable in both languages.
  - Held below 5 by:
    - the lost accent on focused pt_BR buttons;
    - a disabled state carried only by the text colour;
    - the flat lower quarter of the title.
