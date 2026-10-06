---
id: systems/screens
type: system
title: Screens: the menu system (pause, and the title; notebook and map later)
status: active
tags: [menu, pause, screens, ui, focus, theme, hold, i18n]
related: [architecture/pause-menu-worldfreeze-reuse, architecture/save-slots-and-the-boot-swap, architecture/notebook-entries-are-derived-from-the-save, architecture/map-reveal-seen-cells-per-room, systems/input, systems/songs-and-the-memorina, gotchas/a-menu-press-reaches-the-last-node-first, gotchas/gui-focus-moves-once-per-stick-tilt, gotchas/time-scale-zero-stops-delta-particles-and-time, playtests/2026-10-02-pause-menu, playtests/2026-10-02-title-and-slots, bugs/a-click-during-a-leave-fade-still-reaches-the-menu-buttons, bugs/accents-on-a-focused-menu-button-land-on-its-top-highlight]
created: 2026-10-02
updated: 2026-10-06
source_files:
  - scenes/ui/screens/screens.gd
  - scenes/ui/screens/screen_router.gd
  - scenes/ui/menu/menu_input.gd
  - scenes/ui/menu/menu_screen.gd
  - scenes/ui/menu/menu_entry.gd
  - scenes/ui/menu/confirm_panel.gd
  - scenes/ui/menu/menu_theme.tres
  - scenes/ui/pause_menu/pause_menu.gd
  - scenes/ui/title/title.gd
  - scenes/ui/title/slot_screen.gd
  - scenes/ui/title/slot_card.gd
  - scenes/ui/title/flute_pulse.gd
  - scenes/ui/title/title_grey.gdshader
  - scenes/world/game.tscn
  - tools/fonts/patch_tilde.py
---

# Screens: the menu system

**Never break:** Screens only asks `WorldFreeze` to hold and releases only what it held; the Screens root Control is ALWAYS, never its CanvasLayer; every tween under Screens ignores the time scale.

## Summary

One ALWAYS `Screens` Control owns which menu screen is open. `MenuInput` turns presses into signals, the pure `ScreenRouter` decides the next screen, and `Screens` applies the decision and asks `WorldFreeze` to hold or release through signals. The pause menu (UI-02) is the only router screen today; the notebook (UI-03) and map (UI-04) will plug in. The title (UI-05) is not a router screen: it is its own composition root that reuses the menu kit (see "Title").

## Tree and wiring (`game.tscn`)

- `ScreenLayer` is a CanvasLayer at layer 2, process mode INHERIT, the last child of `Game`, after `World`. `_input` reaches it first (`gotchas/a-menu-press-reaches-the-last-node-first`).
- `Screens` is a full-rect Control, process mode ALWAYS, `mouse_filter` IGNORE. Its children are `MenuInput`, `Dim` (black at 0.55 alpha), `PauseMenu` and `Blackout` (a `Fade` with `real_time = true`, last, so it covers the menu).
- Connections in `game.tscn`:
  - `hold_requested` → `WorldFreeze.hold`
  - `release_requested` → `WorldFreeze.release`
  - `quit_to_title_requested` → `Game.quit_to_title`
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
- **`PauseMenu`:** Resume, Quit to title, Quit game. Opening focuses Resume.
  - Quit to title and Quit game each hide the box and open their own confirmation (`ConfirmQuitToTitle`, `ConfirmQuit`) with No focused.
  - Back or No returns to the box with the entry that asked focused (`_asked_by`). Yes emits `quit_to_title_requested` / `quit_game_requested`.
- **Leaving for the title** (`Screens._leave_for_title`): the world stays held.
  - `_leaving` and `_locked` are set, the Blackout's `mouse_filter` becomes STOP, and focus is released.
  - The Blackout fades in real time, then `quit_to_title_requested` → `Game.quit_to_title` swaps deferred. `WorldFreeze._exit_tree` gives the title a running clock.
  - While leaving, every `MenuInput` press is consumed and ignored, and the menu's Resume and Quit game relays are dropped (`_unless_leaving`). Neither a key nor a click releases the hold or quits under the black.
- **`ConfirmPanel`** (`scenes/ui/menu/confirm_panel.tscn`, reusable by the title's slot erase): the `body_key` export holds the question's translation key. It emits `confirmed` / `cancelled`, and `open()` focuses No.

## Focus

- Opening a screen focuses its first entry. Closing releases GUI focus, because a hidden focused Button would still take the next `ui_accept`.
- A Button acts on the `ui_accept` release, so a Resume press never reaches the unpaused `PlayerInput`.
- The stick moves focus once per tilt (measured; `systems/input`).
- `MenuEntry` (extends Button) swaps `theme_type_variation` to `MenuEntryFocused` while focused. Godot draws the focus stylebox over the pressed one, so a focus style would hide Pressed.

## Look

- **The 2x rule:** each screen's art lives under ONE root Control of 320x180 with `scale = 2`, authored in pack pixels. Nothing below it is scaled again. The HUD stays 1x.
- **Entries are 16 pack px tall** (user decision 2026-10-06, "Taller entries"). At 14 px the 8 px font's accents (í, the patched tilde) fell on the Selected style's top highlight row (`bugs/accents-on-a-focused-menu-button-land-on-its-top-highlight`). Every `MenuEntry` is 16 px: pause, title column, confirmation Yes/No, Erase.
- **Pause layout (pack px):**
  - panel `BGbox_05A`: 96x92 at (112, 50), 9-slice margins 12/14/12/12;
  - banner `BannerMedium_04A`: 80x32 at (120, 38), straddling the panel top, margins 10/13/10/15;
  - entries: 72x16, 4 px apart, from (124, 72) to (196, 128);
  - confirmation: 136x76 at (92, 52), Yes/No 48x16 at y 46 inside it.
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
- `Fade.real_time` is set on the Blackout, which runs under the hold.
- A `KeyGlyph` blink shows nothing under a hold, so no held screen relies on one.

## Text

`PAUSE_TITLE`, `PAUSE_RESUME`, `PAUSE_QUIT_TO_TITLE`, `PAUSE_QUIT_GAME`, `CONFIRM_QUIT_TO_TITLE`, `CONFIRM_QUIT_GAME`, `CONFIRM_YES`, `CONFIRM_NO`; the title's `TITLE_NEW_GAME`, `TITLE_CONTINUE`, `TITLE_QUIT_GAME`, `TITLE_ERASE`, `TITLE_EMPTY_SLOT`, `TITLE_PLAY_TIME` (`%dh %02dm`: keep both placeholders), `CONFIRM_ERASE`, `CONFIRM_OVERWRITE`; and the place names `REGION_*` / `BENCH_*`, all in `i18n/translations.csv`, set through `tr()` in `_ready`. A `\n` in the CSV becomes a newline. `CONFIRM_QUIT_GAME` puts the question on its own line; the body Label uses `line_spacing = 0` to fit three lines in the panel.

## User decisions, 2026-10-02

- Entries: "Resume, Settings, Quit to title, Quit game". Quit to title is built (UI-05); Settings arrives with UI-07.
- Style "A wood": `BGbox_05A` + `BannerMedium_04A` + `Button_01A`.
- Behind the menu: "Dim, Ivo stops". Revised by "Stop everything" (`systems/songs-and-the-memorina`, Freeze and hold).
- Art scale: "2x for menus".
- Quit asks first ("Confirm"), with "No focused". Back from the confirmation: "Back to menu".
- Text look: "Accept as built".
- The tilde: "Patch the glyph".
- Pad: "Start / Select / LB" and "A confirm, B back" (`systems/input`).

## Title (UI-05)

`scenes/ui/title/title.tscn` is a composition root, PAUSABLE so it never inherits ALWAYS from the playtest runner. Boot or Quit to title swaps it in; `SceneSwap` swaps it out when a slot is played. It reuses `MenuInput`, `MenuEntry`, `ConfirmPanel`, `menu_theme.tres` and `Fade`, under one 320x180 `Art` root at scale 2.

- **Background:** the woods' five background layers on band 0 (region 1024x346, the spring band), each a `Parallax2D` with `repeat_size` 1024 and `autoscroll` -1, -2, -4, -6, -8 px/s from sky to front. All wear `title_grey_material`, the forgotten print (`systems/greyhush`). Sky at y 0, trees at y 14.
- **Logo:** `assets/sprites/hud/title/memorina_logo.png`, 160x48 at (80, 6).
- **Flute pulse:** behind the logo, `FlutePulse` (96x36 at (110, 24), under the pipes at logo x 38..117, y 24..47) breathes the four season colours, winter to summer left to right.
  - It is a dithered ellipse in pack pixels. Its reach and its alpha (peak 0.45, the user's "Stronger (~0.45)", 2026-10-06) follow a 4 s real-time breath set from script; the shader reads neither `TIME` nor `FRAGCOORD`.
  - The four colours are the season palettes' tints, summer included (gold): the user's "Palette gold", 2026-10-06.
- **Main screen:** a column of 72x16 entries at (124, 92): New game, Continue, Quit game. Settings will be one more entry between Continue and Quit game.
  - With no used slot, Continue is disabled with `focus_mode` NONE; its text uses `font_disabled_color` (cream at 0.4).
  - Opening focuses Continue when it is enabled, else New game.
  - Quit game quits without asking: nothing is unsaved at the title.
- **New game** starts at once in the first empty slot. With all three used, it opens the slot screen for a new game.
- **Continue** opens the slot screen to load.
- **Slot screen** (`SlotScreen`, purpose LOAD or NEW): three `SlotCard`s, 204x30 rows at (58, 58), 4 apart, no banner.
  - A used card shows the region and bench names and the play time. An empty card shows Empty, in `SlotTextDisabled` when it cannot be picked. Erase (40x16) sits beside each used card.
  - LOAD focuses the latest save; empty cards are disabled and skipped.
  - NEW focuses the oldest save. Picking a used card asks `CONFIRM_OVERWRITE` with No focused; an empty card (after an erase) starts at once.
  - Erase asks `CONFIRM_ERASE` with No focused. Erasing the last save while loading returns to main.
  - Back closes a confirmation onto what asked, else returns to main focused on the entry that opened the screen. Esc (`pause`) and B (`ui_cancel`) both only step back on the title.
  - `SlotScreen` only shows and asks; it emits `chosen`, `erase_confirmed` and `overwrite_confirmed`. `Title` owns the saves list and every `SaveSystem` call.
- **Leaving:** a chosen slot sets `Title._leaving`, stops the mouse on the full-screen Fade, releases focus, begins the slot's session, fades to black and swaps deferred. While leaving, every key, click and confirmation (erase, overwrite) is ignored.

## User decisions, UI-05

2026-10-02:
- "in the first menu only four buttons (three for now, i guess): new game, continue, settings and quit. save selection should be a second screen."
- Continue: "Opens the slot screen". New game: "First empty slot". With no save, Continue is "Greyed out". Erase: "Beside each used slot". The slot screen: "No banner". Continue's focus: "Last played".
- Release builds boot the title; debug builds boot "Straight to game". Three slots. Play time counts menu time. The place names and menu texts as they stand in `translations.csv` were approved.
- Logo: "Lettering + pan flute", "Grey, colour in flute", "B: flute under", "Snap to world palette".

2026-10-06:
- "Vazio" / "Empty" for an empty slot: approved.
- Overwrite focus: "Oldest save".
- Corrupt slot: "Treat as empty" (`systems/life-benches-death`).
- Title background: "Drift + pulse".
- Entry height: "Taller entries".

## Tests

`tests/scenes/ui/screens/screen_router_test.gd`, `screens_test.gd` (with buttons pressed while leaving), `tests/scenes/ui/menu/menu_input_test.gd`, `tests/scenes/world/world_freeze_test.gd`, `tests/scenes/ui/title/title_test.gd`, `slot_screen_test.gd`.
