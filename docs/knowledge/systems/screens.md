---
id: systems/screens
type: system
title: Screens: the menu system (pause now; notebook, map and title later)
status: active
tags: [menu, pause, screens, ui, focus, theme, hold, i18n]
related: [architecture/pause-menu-worldfreeze-reuse, architecture/save-slots-and-the-boot-swap, architecture/notebook-entries-are-derived-from-the-save, architecture/map-reveal-seen-cells-per-room, systems/input, systems/songs-and-the-memorina, gotchas/a-menu-press-reaches-the-last-node-first, gotchas/gui-focus-moves-once-per-stick-tilt, gotchas/time-scale-zero-stops-delta-particles-and-time, playtests/2026-10-02-pause-menu]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - scenes/ui/screens/screens.gd
  - scenes/ui/screens/screen_router.gd
  - scenes/ui/menu/menu_input.gd
  - scenes/ui/menu/menu_screen.gd
  - scenes/ui/menu/menu_entry.gd
  - scenes/ui/menu/confirm_panel.gd
  - scenes/ui/menu/menu_theme.tres
  - scenes/ui/pause_menu/pause_menu.gd
  - scenes/world/game.tscn
  - tools/fonts/patch_tilde.py
---

# Screens: the menu system

**Never break:** Screens only asks `WorldFreeze` to hold and releases only what it held; the Screens root Control is ALWAYS, never its CanvasLayer; every tween under Screens ignores the time scale.

## Summary

One ALWAYS `Screens` Control owns which menu screen is open. `MenuInput` turns presses into signals, the pure `ScreenRouter` decides the next screen, and `Screens` applies the decision and asks `WorldFreeze` to hold or release through signals. Today only the pause menu exists (UI-02). The notebook (UI-03), map (UI-04) and title (UI-05) plug into the same router.

## Tree and wiring (`game.tscn`)

- `ScreenLayer` is a CanvasLayer at layer 2, process mode INHERIT, the last child of `Game`, after `World`. `_input` reaches it first (`gotchas/a-menu-press-reaches-the-last-node-first`).
- `Screens` is a full-rect Control, process mode ALWAYS, `mouse_filter` IGNORE. Its children are `MenuInput`, `Dim` (black at 0.55 alpha) and `PauseMenu`.
- Connections in `game.tscn`:
  - `hold_requested` → `WorldFreeze.hold`
  - `release_requested` → `WorldFreeze.release`
  - `quit_game_requested` → `Game.quit_game`
  - `World/Player.died` → `Screens.lock`

## Deciding and applying

- **`ScreenRouter.decide(open, press, tree_paused, locked) -> Kind`** is pure; `screen_router_test` covers the whole table.
  - From NONE, a toggle opens its screen only on a running tree that is not locked. So nothing opens over a performance or lesson.
  - While a screen is open, its own toggle, `back` or `pause` closes it, and the other toggles are ignored.
- **`Screens._on_press`** applies the decision:
  - A kind with no scene yet (notebook, map) stays shut.
  - A press that closes a screen first offers `step_back()`, so an inner panel closes before the screen does.
  - Any press it acts on is consumed with `set_input_as_handled()`. B is both back and roll: unconsumed, the B that resumes would also roll.
- **Hold.** `HOLDING = [PAUSE, NOTEBOOK]`. Entering a holding screen emits `hold_requested`; leaving one emits `release_requested`. `Dim` is visible exactly while a holding screen is open. The map never holds: it will only block Ivo.
- **Lock.** `lock()` closes everything, releases, and refuses until a death rebuilds the world.

## Screens

- **Adding a screen:** a `MenuScreen` scene (`open()`, `close()`, `step_back() -> bool`) as a child of `Screens`, one entry in `_screens`, and its kind in `HOLDING` if it holds.
- **`PauseMenu`:** Resume and Quit game. Opening focuses Resume.
  - Quit game hides the box and opens the `ConfirmQuit` panel with No focused.
  - Back or No returns to the box with Quit game focused. Yes emits `quit_game_requested`.
  - Adding Quit to title (UI-05) is one `MenuEntry`, one signal and one relay in `Screens`.
- **`ConfirmPanel`** (`scenes/ui/menu/confirm_panel.tscn`, reusable by the title's slot erase): the `body_key` export holds the question's translation key. It emits `confirmed` / `cancelled`, and `open()` focuses No.

## Focus

- Opening a screen focuses its first entry. Closing releases GUI focus, because a hidden focused Button would still take the next `ui_accept`.
- A Button acts on the `ui_accept` release, so a Resume press never reaches the unpaused `PlayerInput`.
- The stick moves focus once per tilt (measured; `systems/input`).
- `MenuEntry` (extends Button) swaps `theme_type_variation` to `MenuEntryFocused` while focused. Godot draws the focus stylebox over the pressed one, so a focus style would hide Pressed.

## Look

- **The 2x rule:** each screen's art lives under ONE root Control of 320x180 with `scale = 2`, authored in pack pixels. Nothing below it is scaled again. The HUD stays 1x.
- **Pause layout (pack px):**
  - panel `BGbox_05A`: 96x88 at (112, 52), 9-slice margins 12/14/12/12;
  - banner `BannerMedium_04A`: 80x32 at (120, 40), straddling the panel top, margins 10/13/10/15;
  - entries: 72x14, 4 px apart;
  - confirmation: 136x76, centred.
- **`menu_theme.tres`:**
  - text font `memorina_text_font_size_8.ttf` at 8;
  - labels in dark wood (0.32, 0.2, 0.25);
  - buttons: `Button_01A` Normal / Selected / Pressed as StyleBoxTextures (margins L4 T5 R4 B6), cream text with no outline (any outline fills the letter counters at 8 px);
  - `BannerTitle` variation: `memorina_title_outline_font_size_20.ttf` at 20.
  - All three fonts import with antialiasing off.
- **The tilde.** The pack's 8 px font drew ã õ ñ Ã Õ Ñ with an umlaut-like tilde. `tools/fonts/patch_tilde.py` rebuilds the font from the pack original with a 5 px wave at the base letter's advance; it is byte-reproducible. The title fonts draw a wavy tilde already.
- Art: `assets/sprites/hud/menu/`, from Franuka's RPG UI pack, credited in `CREDITS.md`.

## Real time under a hold

- Under a hold `Engine.time_scale` is 0, so every `_process` delta is 0 (`gotchas/time-scale-zero-stops-delta-particles-and-time`).
- Every tween under `Screens` uses `set_ignore_time_scale(true)`.
- A frame-stepped animation is a tween, never `_process(delta)`.
- `Fade.real_time` is for the UI-05 Blackout.
- A `KeyGlyph` blink shows nothing under a hold, so no held screen relies on one.

## Text

`PAUSE_TITLE`, `PAUSE_RESUME`, `PAUSE_QUIT_GAME`, `CONFIRM_QUIT_GAME`, `CONFIRM_YES`, `CONFIRM_NO` in `i18n/translations.csv`, set through `tr()` in `_ready`. A `\n` in the CSV becomes a newline. `CONFIRM_QUIT_GAME` puts the question on its own line; the body Label uses `line_spacing = 0` to fit three lines in the panel.

## User decisions, 2026-10-02

- Entries: "Resume, Settings, Quit to title, Quit game". Settings arrives with UI-07 and Quit to title with UI-05; neither is built yet.
- Style "A wood": `BGbox_05A` + `BannerMedium_04A` + `Button_01A`.
- Behind the menu: "Dim, Ivo stops". Revised by "Stop everything" (`systems/songs-and-the-memorina`, Freeze and hold).
- Art scale: "2x for menus".
- Quit asks first ("Confirm"), with "No focused". Back from the confirmation: "Back to menu".
- Text look: "Accept as built".
- The tilde: "Patch the glyph".
- Pad: "Start / Select / LB" and "A confirm, B back" (`systems/input`).

## Tests

`tests/scenes/ui/screens/screen_router_test.gd`, `screens_test.gd`, `tests/scenes/ui/menu/menu_input_test.gd`, `tests/scenes/world/world_freeze_test.gd`.
