---
id: systems/settings
type: system
title: Settings (UI-07): volumes, display, language and rebinding, one file in user://, one screen in the pause menu and the title
status: active
tags: [settings, options, volume, audio-bus, language, locale, i18n, display, window, fullscreen, rebinding, input, keybindings, glyphs, menu, screens, boot, ui-07]
related: [architecture/settings-screen, gotchas/a-new-inputevent-is-not-for-all-devices, bugs/a-rebound-pad-button-answers-only-joypad-0, bugs/a-binding-refused-by-ui-accept-shows-the-raw-key-action-ui-accept, bugs/a-hand-edited-keyboard-code-of-0-silently-unbinds-the-action, bugs/closing-the-window-with-settings-open-forgets-the-changes, bugs/settings-rows-measure-12-px-so-reset-to-defaults-sits-on-the-status-line, playtests/2026-11-10-ui07-settings, systems/screens, systems/input, systems/music, systems/notebook, architecture/save-slots-and-the-boot-swap, gotchas/translation-changed-reaches-every-node-before-set-locale-returns, gotchas/headless-has-no-keyboard-layout, gotchas/find-child-skips-nodes-a-script-built, gotchas/a-script-run-with-s-cannot-compile-classes-that-name-autoloads, gotchas/a-stick-is-pressed-on-every-motion-event, bugs/player-input-edge-state-goes-stale-across-a-pause-menu]
created: 2026-11-10
updated: 2026-11-10
source_files:
  - globals/settings/settings.gd
  - globals/settings/game_settings.gd
  - globals/settings/settings_file.gd
  - globals/settings/settings_math.gd
  - globals/settings/key_bindings.gd
  - globals/settings/binding_rules.gd
  - globals/audio_buses.gd
  - scenes/ui/settings/settings_screen.gd
  - scenes/ui/settings/settings_screen.tscn
  - scenes/ui/settings/setting_row.gd
  - scenes/ui/settings/binding_row.gd
  - scenes/ui/settings/step_bar.gd
  - scenes/ui/menu/menu_input.gd
  - scenes/ui/pause_menu/pause_menu.gd
  - scenes/ui/screens/screens.gd
  - scenes/ui/title/title.gd
  - scenes/ui/key_glyph/key_glyph.gd
  - scenes/ui/key_glyph/binding_names.gd
  - scenes/ui/memorina_hud/note_glyph.gd
  - scenes/ui/memorina_hud/note_sheet.gd
  - scenes/characters/ivo/player_input.gd
  - resources/ui/memorina/note_glyphs.gd
  - resources/ui/memorina/note_glyphs.tres
  - tools/ui/build_note_glyphs.gd
  - tools/art/draw_input_key_blank.py
  - project.godot
---

# Settings (UI-07)

**Never break:** `Settings` is the only writer of bus volume and mute, the locale (outside tests and the playtest timeline), the window mode and size, and the InputMap events of the rebindable actions and the zooms. MEMORY sessions (`BootPolicy`) never read or write the settings file and apply nothing at boot. The zooms follow jump and attack; they are derived, never stored.

The plan and the options weighed are `architecture/settings-screen`; this entry is what was built.

## Pieces

| Piece | Kind | Does |
|---|---|---|
| `Settings` (`globals/settings/settings.gd`) | autoload, first in `[autoload]` | Holds the current `GameSettings` and the defaults captured from the project InputMap at boot; applies, changes and commits. `signal bindings_changed`. |
| `GameSettings` | RefCounted, pure | Volumes (bus -> 0..10), `fullscreen`, `window_scale` (1..3), `language` (empty follows the OS), the two `KeyBindings`; `from_config` clamps, `to_config` writes. |
| `SettingsFile` | RefCounted | `user://settings.cfg`, or `settings_debug.cfg` in debug builds. An empty dir is no disk. |
| `SettingsMath` | static, pure | `volume_db` (10 is 0 dB, `40 * log10(step / 10)`, 5 is -12 dB, 0 mutes), `locale_for` (`pt*` -> `pt_BR`, else `en`), window sizes and the scales that fit the usable screen. |
| `KeyBindings` | RefCounted, pure over ints | One device's managed code per rebindable action, plus the `ui_accept` / `ui_cancel` codes and the reserved codes of that device. |
| `BindingRules` | static, pure | The share table, the reserved check, `valid` and `assign` (outcomes ASSIGNED, SWAPPED, UNCHANGED, REFUSED_RESERVED, REFUSED_TAKEN). |
| `SettingsScreen` (`scenes/ui/settings/`) | Control, unscaled, under a 2x `Art` root | Tabs, pages, rows, status line, two reset `ConfirmPanel`s, the `CaptureShield`, four ALWAYS preview players. |
| `SettingRow`, `BindingRow`, `StepBar` | Button (InkButton), Button, Control | A value row with `< value >` while focused; a binding row; ten cells drawn only on change. |
| `BindingNames` | static | A key's name from the OS layout (`OS.get_keycode_string(keyboard_get_label_from_physical)`, not translated); a pad button's name by a `PAD_*` key per family. |
| `NoteGlyphs` + `NoteGlyph` | Resource + TextureRect | Note glyphs by the bound event; an input with no note art draws the blank note key with `BindingNames`' name on it. |

## File and boot

```
[meta]      version=1
[audio]     master, music, notes, effects = 0..10
[display]   fullscreen, window_scale
[general]   language            ; written only once picked; absent follows the OS each boot
[keyboard]  <action>=<physical keycode>   ; only actions that differ from the default
[pad]       <action>=<JoyButton>          ; only actions that differ from the default
```

- `Settings._ready` runs `BootPolicy.decide` as `SaveSystem` does. MEMORY (headless, the playtest runner, the GdUnit runner): no file is read or written, nothing is applied; the screen still changes things live. Otherwise it reads, validates and applies buses, locale, bindings, window, in that order. Being first in `[autoload]`, the locale is set before `Boot` swaps in the title.
- A table `BindingRules.valid` refuses on load drops that device's overrides with a `push_warning`. Out-of-range values clamp (volumes) or fall back (scale, language).
- `project.godot` keeps the 1280x720 override as the pre-boot size and no longer sets `borderless`: a windowed game has a normal frame. A saved scale that does not fit `screen_get_usable_rect()` falls back to the largest that fits, unsaved; the window is centred. Fullscreen is `Window.MODE_FULLSCREEN`; the stretch stays `canvas_items` with integer scale.
- Values apply live as they change. `SettingsScreen.close()` calls `Settings.commit()`, which writes only when the encoded settings differ from what was last read or written. A window close (X, Alt+F4) commits too: `Settings` handles `NOTIFICATION_WM_CLOSE_REQUEST`, so a quit with the screen open keeps its changes (`bugs/closing-the-window-with-settings-open-forgets-the-changes`).
- `Settings.use_memory_only()` exists for parity with `SaveSystem`; the runners are already MEMORY through `BootPolicy`.

## Bindings

- **Rebindable:** jump, attack, roll, draw_memorina, note_up/down/left/right, map, notebook, on keyboard and pad. **Fixed:** `ui_accept` (Enter, keypad Enter, Space, Z, pad A), `ui_cancel` (Esc, pad B), `pause`, `move_*`, `look_*`, `debug_*`, the built-in `ui_*` directions.
- **One managed slot per action per device.** A note's keyboard slot is its letter key (W A S D by default); its arrow stays. The pad slot is the action's button. `Settings` swaps the managed event in place, keeping each action's event order and deadzone. Every event it writes has `device = -1`, as the project's do: an event made with `.new()` is for pad 0 or device 16 only (`gotchas/a-new-inputevent-is-not-for-all-devices`, `bugs/a-rebound-pad-button-answers-only-joypad-0`).
- **Derived:** `map_zoom_in` takes jump's key and button, `map_zoom_out` attack's. The letter note set is derived too: `PlayerInput.is_letter_note_key(code)` is "bound to a note action and not an arrow", so a rebound note key gives `KEYBOARD_WASD` prompts and the old W gives arrows.
- **Reserved (refused):** every code of `pause`, `move_*`, `look_*`, `debug_*` (Esc, the arrows, F8-F10, Start, the D-pad). On the pad only A, B, X, Y, LB, RB, Back, L3, R3 may be bound; Guide, the misc and paddle buttons are refused, and sticks and triggers are axes, never captured. On the keyboard a code `<= KEY_NONE` or one `OS.get_keycode_string` cannot name is refused too, so a hand-edited file with one drops that device's overrides (`bugs/a-hand-edited-keyboard-code-of-0-silently-unbinds-the-action`).
- **Who may share an input** (MOVE = jump, attack, roll; NOTE = the four notes; DRAW = draw_memorina; TOGGLE = map, notebook):

| | MOVE | NOTE | DRAW | TOGGLE | ui_accept | ui_cancel |
|---|---|---|---|---|---|---|
| MOVE | no | pad only | no | no | yes | roll only |
| NOTE | pad only | no | no | no | pad only | pad only |
| DRAW | no | no | - | no | yes | yes |
| TOGGLE | no | no | no | no | no | no |

  Why each cell is what it is: `architecture/settings-screen`, Bindings.
- **Assigning a press** (`BindingRules.assign`, in order): a reserved code is refused ("This one is reserved"); the action's own code is unchanged; if every holder may share, it is assigned; if exactly one rebindable holder conflicts and the table after exchanging their codes is valid, they swap ("Swapped with {action}"); otherwise it is refused ("Used by {first conflicting action}", rebindable holders in REBINDABLE order before `ui_accept`, `ui_cancel`, which are named "Confirm" and "Back", `ACTION_UI_ACCEPT` / `ACTION_UI_CANCEL`).
  - Examples (tests): pad jump -> Y is assigned beside note_up; pad jump -> X swaps with attack; pad map -> A is refused, used by Jump; pad jump -> B is refused while roll may hold B; keyboard note_up -> Z is refused (jump and `ui_accept`); keyboard map -> E swaps with notebook; keyboard jump -> W is refused, because the swap would leave note_up on Z, which `ui_accept` holds.
- **Reset to defaults** is the last row of each device page and asks first (`ConfirmPanel`, No focused); it erases that device's overrides only.

## Capture

1. Accept on a `BindingRow` (a Button acts on the `ui_accept` release) sets `MenuInput.capturing`. The row shows "Press a key" / "Press a button"; the full-rect `CaptureShield` (mouse STOP) keeps clicks off the tabs.
2. While capturing, `MenuInput._input` marks every key and pad event handled (press, release, motion) before emitting, and emits only `capture_cancelled` (a `pause` press: Esc or Start, from either page) or `bind_pressed(device, code)` (a non-echo key press as its physical keycode, a pad button press). `InputDevice` still sees the press on `window_input` and switches the prompts.
3. `SettingsScreen` ignores a code of the other device, calls `Settings.bind` and writes the outcome on the status line. Assigned, swapped or unchanged ends the capture; a refusal keeps it open for another press. Cancelling clears the status line, and so does the focus leaving a row.
4. Leaving capture re-reads `_left_held` / `_right_held` from `Input`, so a direction held through it is not a page edge. The release of the captured press finds no pressed Button and does nothing.
5. B on the pad page is a candidate, never a cancel.

## Screen

- Opened from the pause menu (entry between Skip scene and Quit to title) and from the title (between Continue and Quit game); see `systems/screens`. It is a child of each owner's 2x `Art` root and is authored unscaled in pack px.
- Layout (pack px): `BGbox_05A` 320x180 at (0, 0), the whole screen: at (8, 2) the HUD's life notes (1x (8, 8) to (48, 24)) showed around its transparent top-left corner, and the frame's opaque part starts 2 px in and 4 px down, so the full size covers them without a Screens or HUD change; tabs 64x16 at y 12, x 26 / 94 / 162 / 230 (Sound, General, Keyboard, Pad); pages at (24, 31) 272 wide; rows **11 px** (the plan's 12 does not hold eleven binding rows above the status line; InkButton has no top highlight for accents to hit). The theme's InkButton margins (1 top, 2 bottom) over the 9 px line make a Button 12 px, so `SettingRow.compact` gives every row one `StyleBoxEmpty` with 1 px above and below (`bugs/settings-rows-measure-12-px-so-reset-to-defaults-sits-on-the-status-line`; the test measures the laid-out rows); status line 272x10 at (24, 154); reset confirmation 136x76 at (92, 52), the sheet hidden while it asks.
  - Sound: Master volume, Music, Notes, Effects; a `StepBar` of ten 8x6 cells 3 apart at row x 136; the number right-aligned from row x 248.
  - General: Language (each language's own name), Fullscreen (On / Off), Window size (`%dx (%d x %d)`), disabled and skipped by focus while fullscreen.
  - Keyboard / Pad: ten `BindingRow`s (action name, then the binding's name right-aligned from row x 180), then Reset to defaults. Names, not glyphs: the input art is 32 px for the 1x HUD.
- Navigation: opening focuses the Sound tab; focusing a tab shows its page, and the shown page's tab keeps the Selected look (`MenuEntryFocused`) while a row has the focus; tabs move left and right by focus neighbours; down from a tab is the page's first row, up from the first row is its tab; rows never move sideways.
- **Left / right on a value row step it by one** and clamp: the owner routes `MenuInput.page_pressed` (`Screens._on_page` through `PauseMenu.step_setting`; `Title._on_page`) to `SettingsScreen.step(direction)` and consumes it only when that returns true. Accept advances a list row and wraps (Language, Fullscreen, Window size); on a volume row it does nothing.
- **Back** (B, Esc): a reset question closes onto its row; otherwise Settings closes onto the entry that opened it (`PauseMenu.step_back` / `Title._step_back`). The pause's hold is untouched: Settings adds no `WorldFreeze` request.
- **Volume preview:** each step plays a short sample on that row's bus from an ALWAYS player under the screen, heard under the pause hold: Master and Notes `note_up_g4.mp3`, Effects `gate_bolt.wav`, Music the first 1.5 s of `menu_title.ogg` (measured audible from 0 s, -19.6 dB mean), faded out on a real-time tween, in the pause only: at the title `music_preview` is off, because the theme already plays on the Music bus and a second copy layered over it (the orchestrator's call, 2026-11-10: "skip the Music-bus preview at the title, since the theme is audible there; keep it in the pause"). The world's music stays paused under the hold; nothing here routes background music.

## Prompts after a rebind

`Settings.bindings_changed` redraws every prompt: `KeyGlyph` (its label names the event it shows; a pad button with no art, Back, L3, R3, shows its family's name on the blank key), `NoteSheet` (the Memorina, guardian-call and phrase sheets), `TeacherBalloon`, `Notebook`, the Settings rows. `NoteGlyphs` (`resources/ui/memorina/note_glyphs.tres`, built by `tools/ui/build_note_glyphs.gd`) replaced the four `NoteGlyphSet` .tres; its blank note key `assets/sprites/hud/memorina/input_key_blank_{normal,selected}.png` is the pack's W key with the letter cleared (`tools/art/draw_input_key_blank.py`, contract `tools/art/prompts/input_key_blank.md`).

## Live language

`Settings.set_language` calls `TranslationServer.set_locale`; the notification reaches every node before it returns (`gotchas/translation-changed-reaches-every-node-before-set-locale-returns`). Static key texts are set in `_retranslate()`, from `_ready` and `NOTIFICATION_TRANSLATION_CHANGED`: `PauseMenu` (and its intent line), `ConfirmPanel`, `Title`, `SlotCard`, `SeedShopPanel` (rows, count and said line while open), `RegionTitle` (the card showing), `KeyGlyph`, `SettingsScreen` and its rows. The notebook rebuilds its texts on open. **A text set only in `_ready` is a defect now that language changes live.**

## Text

`PAUSE_SETTINGS`, `TITLE_SETTINGS` ("Opções" / "Settings"); `SETTINGS_TAB_*`, `SETTINGS_VOLUME_*`, `SETTINGS_LANGUAGE`, `SETTINGS_FULLSCREEN`, `SETTINGS_WINDOW_SIZE`, `SETTINGS_WINDOW_SCALE` (keep three placeholders), `SETTINGS_ON`, `SETTINGS_OFF`, `LANGUAGE_EN`, `LANGUAGE_PT_BR`, `ACTION_*` (one per rebindable action), `SETTINGS_RESET_BINDINGS`, `CONFIRM_RESET_KEYBOARD`, `CONFIRM_RESET_PAD`, `SETTINGS_PRESS_KEY`, `SETTINGS_PRESS_BUTTON`, `SETTINGS_BIND_RESERVED`, `SETTINGS_BIND_TAKEN` / `_SWAPPED` (`%s`), `ACTION_UI_ACCEPT`, `ACTION_UI_CANCEL` (the fixed holders a refusal names), `PAD_XBOX_*`, `PAD_PS_*`, `PAD_L3`, `PAD_R3`. `settings_text_fit_test` measures every one against its box in en and pt_BR.

## Adding a setting

A field on `GameSettings` (with its clamp in `from_config` and its key in `to_config`), a row on a page, a text key and its fit check. No new writer: `Settings` applies it.

## Tests

`tests/globals/settings/` (`settings_math_test`, `game_settings_test`, `key_bindings_test`, `binding_rules_test`, `settings_file_test`, `settings_test`), `tests/scenes/ui/settings/` (`settings_screen_test`, `settings_text_fit_test`, `retranslate_test`), `tests/scenes/ui/key_glyph/key_glyph_test.gd`, the capture cases in `menu_input_test`, the rebound letter key in `player_input_test`, the named blank key in `note_sheet_test`, the Settings entries in `screens_test` and `title_test`. Every test that binds restores both devices in `after_test`.

## User decisions, 2026-11-10

Quoted as answered:
- Volume: "Geral + 3 buses (Recommended)": Master, Music, Notes, Effects (Sfx), 0-10 steps.
- Display: "Tela cheia + escala (Recommended)": fullscreen on/off, window 1x/2x/3x, integer scale kept. Window: "Com moldura (Recommended)": a normal framed window when not fullscreen.
- Rebinding: "Teclado e controle (Recommended)": gameplay actions on both devices, ui_accept/ui_cancel fixed, Reset to defaults. Notes: "Qualquer tecla (Recommended)": notes take any key or button; one blank note-key glyph derived from the existing note/key glyph art, with the binding's name drawn on it.
- Language: "Idioma do sistema (Recommended)": first boot follows the OS locale (pt* -> pt_BR, else en).
- Volume preview: "Tocar uma amostra (Recommended)": each volume step plays a short sample on that slider's bus (Master/Music/Notes/Sfx), from an ALWAYS player so it is heard under the pause hold; the world music itself stays stopped.
- PT text for Settings: "Opções (Recommended)" (pt_BR "Opções", en "Settings").
- Defaults the coordinator set the same day: pad Back/L3/R3 shown by name on the blank key; triggers not bindable; Reset per device page (asks first); debug builds use `settings_debug.cfg`.
- The orchestrator's call after the playtest, 2026-11-10: "skip the Music-bus preview at the title, since the theme is audible there; keep it in the pause".
