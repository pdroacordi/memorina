---
id: architecture/settings-screen
type: architecture
title: Settings plan (UI-07) - a thin Settings autoload over pure GameSettings, KeyBindings and BindingRules; one ConfigFile in user://; one SettingsScreen reused by the pause menu and the title; capture through MenuInput; live language through NOTIFICATION_TRANSLATION_CHANGED
status: built
tags: [settings, options, volume, audio-bus, language, locale, i18n, display, window, fullscreen, rebinding, input, keybindings, glyphs, menu, screens, boot, plan]
related: [systems/screens, systems/input, systems/music, systems/notebook, systems/teaching-creatures, architecture/save-slots-and-the-boot-swap, architecture/pause-menu-worldfreeze-reuse, architecture/character-controller-input-split, architecture/music-system, gotchas/a-menu-press-reaches-the-last-node-first, gotchas/gui-focus-moves-once-per-stick-tilt, gotchas/a-stick-is-pressed-on-every-motion-event, gotchas/time-scale-zero-stops-delta-particles-and-time, gotchas/gdunit-runs-from-the-editor-are-not-headless, gotchas/csv-translations-unescape-backslash-n, bugs/the-playtest-runner-adopts-the-legacy-save-before-going-memory-only, bugs/accents-on-a-focused-menu-button-land-on-its-top-highlight, bugs/a-click-during-a-leave-fade-still-reaches-the-menu-buttons, bugs/player-input-edge-state-goes-stale-across-a-pause-menu]
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
  - scenes/ui/settings/setting_row.gd
  - scenes/ui/settings/binding_row.gd
  - scenes/ui/settings/step_bar.gd
  - scenes/ui/menu/menu_input.gd
  - scenes/ui/pause_menu/pause_menu.gd
  - scenes/ui/screens/screens.gd
  - scenes/ui/title/title.gd
  - scenes/ui/key_glyph/key_glyph.gd
  - scenes/ui/key_glyph/binding_names.gd
  - scenes/characters/ivo/player_input.gd
  - resources/ui/memorina/note_glyphs.gd
  - project.godot
---

# Settings plan (UI-07)

**Status: BUILT (2026-11-10); the contract is now `systems/settings`, which records the deviations (rows 11 px, `fixed` folded into `KeyBindings`, `binding_for` in `PlayerInput`, a separate `tools/ui/build_note_glyphs.gd`, a Music preview) and the user's answers to the questions below.** Planned Scope fixed by the user on 2026-11-10 (volume Master/Music/Notes/Effects in 0-10 steps; fullscreen and window 1x/2x/3x of 640x360 with integer scale; rebinding of jump, attack, roll, draw_memorina, the four notes, map and notebook on keyboard and pad, `ui_accept`/`ui_cancel` fixed, a Reset to defaults; language en and pt_BR, first boot from the OS locale, stored once changed; Settings in the pause menu between Resume and Quit to title, and on the title between Continue and Quit game).

## Context

- Settings are global, not per slot, in `user://`. Headless runs and the tool runners never read or write them (`BootPolicy`, `architecture/save-slots-and-the-boot-swap`).
- Screens only asks `WorldFreeze` to hold; every tween under Screens ignores the time scale; the Screens root Control is ALWAYS (`systems/screens`). The pause already holds, so Settings opened from it needs no hold of its own.
- Only `PlayerInput`, `MenuInput` and `InputDevice` read `InputEvent`s or `Input` (`systems/input`, the `verify-gates` scan).
- Today nothing writes bus volumes (`Music` ducks write deck `volume_db`, `MusicMix`), the locale (except tests and the playtest timeline), the window, or `InputMap`.
- Every static menu text is set once with `tr()` in `_ready` (10 scripts), so a live language change shows nothing until a screen is rebuilt.
- Note glyphs in five HUDs (`MemorinaHud`, `GuardianCallHud`, `Notebook`, `TeacherBalloon`, `PhraseSheet`) come from four fixed `NoteGlyphSet` .tres (arrows, WASD, Xbox YAXB, PS). Art exists only for those 16 inputs. A rebound note must not keep showing its old glyph.

## Options considered

1. **Who loads and applies settings before the title.**
   - (a) `Boot` applies them: it runs once, and the pause and title screens would each need load/save/apply. Rejected.
   - (b) Inside `SaveSystem`: per-session save state, already near its 250-line split point. Rejected.
   - (c) Static vars on a class: hidden global state. Rejected.
   - (d) **A thin `Settings` autoload** that delegates to pure RefCounteds. Chosen: preferences are game-wide, outlive every `SceneSwap`, must apply before any scene, and are edited from two composition roots.
2. **File format.** (a) A `Resource` .tres in `user://`: loading a .tres can run a script, and it needs a class. (b) **`ConfigFile` text**: chosen, human-readable, no class, ints for codes.
3. **Rebinding capture.** (a) A fourth reader node: widens the rule and the scan. (b) `InputDevice`: it listens on `window_input`, which cannot consume. (c) **A capture mode on `MenuInput`**: it is already the menu reader, runs before the GUI, and can consume. Chosen; it emits plain codes, so no live `InputEvent` leaves the readers.
4. **Stepping a value.** (a) `HSlider`: it steps on `ui_left`/`ui_right` presses, and a stick is pressed on every motion (`gotchas/a-stick-is-pressed-on-every-motion-event`); unmeasured, no art. (b) A row script in `gui_input`: a new reader. (c) **`MenuInput.page_pressed`** (the existing ui_left/ui_right edge), routed by the owner to the screen and consumed only when the focused row is a value row. Chosen: no new reader, once per tilt.
5. **Live language.** (a) Rebuild screens on change: a world rebuild loses progress. (b) Godot auto-translate with keys in `text`: breaks every test that reads `.text`, and format keys (`TITLE_PLAY_TIME`) cannot auto-translate. (c) **Each script that sets a static text from a key does it in `_retranslate()`, called from `_ready` and from `NOTIFICATION_TRANSLATION_CHANGED`.** Chosen.
6. **Conflicts.** (a) Always refuse: an exchange (jump and attack on the pad) needs a spare button first. (b) Always swap: a swap can create a second conflict (jump A to LB swaps map onto A, which note_down and ui_accept hold). (c) **Swap when exactly one rebindable action conflicts and the table after the swap is legal; otherwise refuse.** Chosen.

## Decision

### Pieces

| Piece | Kind | Responsibility |
|---|---|---|
| `Settings` (`globals/settings/settings.gd`) | thin autoload, first in `[autoload]` | Holds the current `GameSettings` and the captured defaults; the only writer of bus volume/mute, the locale (outside tests and the playtest timeline), the window mode and size, and `InputMap` events of the rebindable and zoom actions. `signal bindings_changed`. API: `volume(bus) -> int`, `set_volume(bus, step)`, `set_fullscreen(on)`, `set_window_scale(scale)`, `set_language(locale)`, `bind(device, action, code) -> BindingRules.Assignment`, `reset_bindings(device)`, `commit()`, `use_memory_only()`, `has_disk() -> bool`. |
| `GameSettings` | RefCounted, pure | Values with defaults and clamping: `volumes: Dictionary[StringName, int]` (bus -> 0..10, default 10), `fullscreen := false`, `window_scale := 2`, `language := ""` (empty follows the OS), `keyboard`/`pad: KeyBindings`. `to_config(cfg)`, `static from_config(cfg, defaults) -> GameSettings`. |
| `SettingsFile` | RefCounted | `_init(dir, debug)`, `read() -> ConfigFile` (null: no disk or absent), `write(cfg) -> bool`, `static file_name(debug) -> String`. Empty dir means no disk, as `SaveSlots`. |
| `SettingsMath` | static, pure | `volume_db(step) -> float` (10 is 0 dB, `40 * log10(step / 10)`, 5 is -12 dB; 0 mutes the bus), `locale_for(os_locale) -> String` (`pt*` -> `pt_BR`, else `en`), `window_size(scale) -> Vector2i` (640x360 times scale), `fits(scale, usable: Vector2i) -> bool`, `step_scale(current, direction, usable) -> int` (skips sizes that do not fit; 1x always fits). |
| `KeyBindings` | RefCounted, pure over ints | One device's managed slot per rebindable action: `Dictionary[StringName, int]` (physical keycode or `JoyButton`). `REBINDABLE`, `static from_input_map(device) -> KeyBindings` (captured once at boot, before any override), `code(action)`, `holders(code)`, `duplicate()`. The fixed events (the arrow set of each note, everything else in an action) are captured beside it and never edited. |
| `BindingRules` | static, pure | `may_share(device, a, b) -> bool`, `reserved(device, code) -> bool`, `valid(bindings, fixed) -> bool`, `assign(bindings, fixed, device, action, code) -> Assignment` (`Outcome { ASSIGNED, SWAPPED, UNCHANGED, REFUSED_RESERVED, REFUSED_TAKEN }`, the other action, the new table). |
| `MenuInput` (changed) | Node, reader | `var capturing: bool`; `signal bind_pressed(device: KeyBindings.Device, code: int)`; `signal capture_cancelled`. While capturing it emits only these two and consumes every key and joypad event (press, release, motion). |
| `SettingsScreen` (`scenes/ui/settings/settings_screen.tscn`) | Control, child of `PauseMenu` and of the title's `Art` | Tabs, pages, rows, status line, two `ConfirmPanel`s, preview players. `var menu_input: MenuInput` (set by the owner). `open()`, `close()` (calls `Settings.commit()`), `step_back() -> bool`, `step(direction) -> bool`. |
| `SettingRow` | Button, `InkButton` variation | Label key, value Label, an optional `StepBar`. Shows `< value >` while focused. |
| `BindingRow` | Button, `InkButton` variation | Action label and the binding name for the page's device. |
| `StepBar` | Control, `_draw()` | Ten cells; redraws only on `set_value`, so it needs no clock under the hold. |
| `BindingNames` (`scenes/ui/key_glyph/binding_names.gd`) | static | `key_text(physical_keycode) -> String` (the layout's label: `OS.get_keycode_string(DisplayServer.keyboard_get_label_from_physical(code))`), `button_key(button, glyph_set) -> String` (a translation key per family). Shared by `KeyGlyph` and `BindingRow`. |
| `NoteGlyphs` (`resources/ui/memorina/note_glyphs.tres`) | Resource | Replaces the four `NoteGlyphSet`s: `ButtonGlyph`s by keycode and by pad button per family, plus a blank note key. `texture(note, glyph_set, lit)` and `label(note, glyph_set)` look up the note action's bound event through `InputDevice.binding_for`. Built by `tools/ui/build_input_glyphs.gd`. |

No new autoload beyond `Settings`. No Resource holds per-player state: the bindings table is runtime data from the project `InputMap` and the file.

### File and boot

`user://settings.cfg` (release) or `user://settings_debug.cfg` (debug, mirroring the slot files):

```
[meta]
version=1
[audio]
master=10
music=10
notes=10
effects=10
[display]
fullscreen=false
window_scale=2
[general]
language="pt_BR"        ; written only once the player picks one; absent follows the OS each boot
[keyboard]
jump=32                 ; physical keycode; only actions that differ from the default
[pad]
roll=2                  ; JoyButton index; only actions that differ from the default
```

- `Settings._ready` runs `BootPolicy.decide(...)` exactly as `SaveSystem` does. **MEMORY** (headless, the playtest runner, the GdUnit runner): no file is read or written and nothing is applied, so tests keep the engine defaults; the screen still changes things live. Otherwise it captures the defaults, reads the file, validates, and applies all four groups in this order: buses, locale, bindings, window. It is first in `[autoload]`, so the locale is set before `Boot` swaps in the title.
- A table that fails `BindingRules.valid` on load (hand edits, or a later default that conflicts) drops that device's overrides with a `push_warning`.
- A window scale that does not fit `screen_get_usable_rect()` falls back to the largest that fits, unsaved; the window is centred on its screen. `project.godot` keeps 1280x720 borderless as the pre-boot size, so the default needs no resize.
- `commit()` writes only when something changed; `SettingsScreen.close()` calls it. Values apply live as they change.

### Bindings: what follows what, and the conflict rule

- **One managed slot per action per device.** On the keyboard, a note's managed slot is its letter key (W/A/S/D by default); the arrow set stays fixed, because the arrows are move and look too. The pad's managed slot is the action's button.
- **Derived, never stored:** `map_zoom_in` takes jump's key and button, `map_zoom_out` takes attack's. In the map, the jump and attack buttons zoom.
- **The letter note set is derived.** `PlayerInput.WASD_KEYS` becomes `is_letter_note_key(code)`: bound to a note action and not an arrow. `glyph_set_for` keeps returning `KEYBOARD_WASD` for it.
- **Fixed, never edited:** `ui_accept` (Enter, keypad Enter, Space, Z, pad A), `ui_cancel` (Esc, pad B), `pause`, `move_*`, `look_*`, `debug_*`, the built-in `ui_*` directions.
- **Reserved (refused):** any code of `pause`, `move_*`, `look_*` or `debug_*` (Esc, arrows, F8-F10, Start, D-pad). On the pad only buttons are capturable: A, B, X, Y, LB, RB, Back, L3, R3. Guide, the misc and paddle buttons, sticks and triggers (axes) are refused.
- **Who may share an input** (groups: MOVE = jump, attack, roll; NOTE = the four notes; DRAW = draw_memorina; TOGGLE = map, notebook; ACCEPT = ui_accept; CANCEL = ui_cancel):

| | MOVE | NOTE | DRAW | TOGGLE | ACCEPT | CANCEL |
|---|---|---|---|---|---|---|
| MOVE | no | pad only | no | no | yes | roll only |
| NOTE | pad only | no | no | no | pad only | pad only |
| DRAW | no | no | - | no | yes | yes |
| TOGGLE | no | no | no | no | no | no |

  - MOVE and NOTE may share on the pad because `Player._as_move` drops a jump, roll or attack while the Memorina is drawn (the default A, B, X).
  - Jump and attack never share `ui_cancel`, because the zooms follow them and `MenuInput` emits a zoom before `back` (precedence pause > notebook > map > zoom > back): B would stop backing out of the map. Roll may (the default B).
  - A toggle shares with nothing: `MenuInput` would emit it instead of `back`, and it opens a screen over a note or a talk.
  - On the keyboard a letter note key shares with nothing, `ui_accept` included: keys are plentiful, a shared key would flip the prompts to the letter set, and Space or Z would advance a talk during a guitar beat.
- **Assigning** (`BindingRules.assign`):
  1. Reserved code: refused, "This one is reserved".
  2. The action already has the code: unchanged.
  3. Every holder of the code may share with the action: assigned.
  4. Exactly one rebindable holder conflicts: the two exchange codes, if the table after the exchange is valid; then "Swapped with {action}".
  5. Otherwise: refused, "Used by {first conflicting action}".
- **Reset to defaults** is one row per device page and asks first (`ConfirmPanel`, No focused). It erases that device's overrides only.

### Capture flow

1. Accept on a `BindingRow` (a Button acts on the `ui_accept` release) sets `menu_input.capturing = true`. The row's value shows `SETTINGS_PRESS_KEY` or `SETTINGS_PRESS_BUTTON`, and a full-rect invisible `CaptureShield` (mouse STOP) shows, so a click cannot reach a tab (`bugs/a-click-during-a-leave-fade-still-reaches-the-menu-buttons`).
2. `MenuInput._input` while capturing:
   - a `pause` press (Esc, Start) emits `capture_cancelled`;
   - a non-echo key press emits `bind_pressed(KEYBOARD, physical_keycode)`;
   - a joypad button press emits `bind_pressed(PAD, button_index)`;
   - it then marks every key and joypad event handled, motion and releases included, so nothing moves focus, presses the row again, or opens or closes a screen. `InputDevice` still sees the press on `window_input` and switches the prompts.
3. `SettingsScreen` ignores a code of the other device (a pad button on the keyboard page), calls `Settings.bind`, and shows the outcome on the status line.
   - Assigned, swapped or unchanged: capture ends and the row refreshes; `Settings.bindings_changed` redraws every prompt.
   - Refused: capture stays open for another press.
4. On leaving capture mode, `MenuInput` re-reads `_left_held`/`_right_held` from `Input`, so a direction held through it is not a new page edge (`bugs/player-input-edge-state-goes-stale-across-a-pause-menu`). The release of the captured press finds no pressed Button and does nothing (measured for the dialogue box, `systems/input`).
5. B on the pad page is a candidate, never a cancel. Esc cancels a pad capture, and Start a keyboard one.

### Layout (pack px, under the screen's 320x180 root at scale 2, `menu_theme.tres`)

- **Pause:** a `Settings` MenuEntry after Resume and Skip scene, before Quit to title. The panel grows by 20 per extra entry, as `SKIP_ROOM` does. With five entries the panel is 132 tall, so the box moves up: panel `BGbox_05A` at (112, 30), banner (120, 18), entries from y 52, and the intent line follows the panel's bottom (162 + 6 at most, ending by 180). Opening Settings hides the box and the intent line.
- **Title:** the column at (124, 92) becomes New game, Continue, Settings, Quit game (y 92 to 168). Opening Settings hides `%Main`.
- **Settings panel:** `BGbox_05A` 304x176 at (8, 2), margins 12/14/12/12, no banner (the slot screen's precedent).
  - Tabs: four 64x16 MenuEntries at y 12, x 26 / 94 / 162 / 230: Sound, General, Keyboard, Pad.
  - The page area is x 24..296, y 32..152, with rows of 12 px (InkButton text has no top highlight to hit the accents, so the 16 px wood rule does not apply). There is room for 10 rows.
  - Status line: Label 272x10 at (24, 154), centred, dark wood, empty unless a message shows.
  - **Sound:** Master volume, Music, Notes, Effects. Label x 24..156; a `StepBar` of ten 8x6 cells 3 apart at x 160..267; the number at x 272..296.
  - **General:** Language (`English` / `Português (Brasil)`), Fullscreen (On / Off), Window size (`2x (1280 x 720)`). Window size is disabled and skipped by focus while fullscreen.
  - **Keyboard / Pad:** nine `BindingRow`s (jump, attack, roll, Memorina, note up, down, left, right, map, notebook), then Reset to defaults. Action name at x 24..200; binding name right-aligned at x 204..296. The rows show names, not glyphs: the input art is 32 px for the 1x HUD and would be scaled again under the 2x root.
  - ConfirmPanel 136x76 at (92, 52); the panel hides while it asks.
- All numbers are starting values; the playtest screenshot checks them against the frame border.

### Navigation (pad and keyboard)

- Opening focuses the Sound tab. Focusing a tab shows its page; the tabs move left and right by native focus neighbours (`page_pressed` is not consumed on a tab).
- Down from a tab goes to the page's first row, and Up from the first row returns to its tab. `focus_neighbor_*` is set when the page changes.
- **On a value row, left/right change the value by one:** the owner routes `page_pressed` (`Screens._on_page` while PAUSE is open, through `PauseMenu.step_setting`; `Title._on_page`) to `SettingsScreen.step(direction)`, and consumes it only when that returns true. Steps clamp at the ends; there is no auto-repeat (the edge is once per press or tilt).
- Accept on a boolean or list row advances it, wrapping; on a volume row it does nothing; on a `BindingRow` it starts capture; on Reset it asks.
- A volume step plays a preview on its bus: Notes and Master play `note_up_g4`, Effects plays `gate_bolt.wav`, on ALWAYS players under the screen. Music has no preview: it stays paused under the hold, and at the title its theme is playing.
- **Back** (pad B or Esc): a confirmation closes onto its row; otherwise Settings closes onto the entry that opened it. In the pause this runs `Screens._on_press` -> `PauseMenu.step_back()` -> `SettingsScreen.step_back()`; on the title it is `Title._step_back`. The world stays held throughout and Screens emits no extra hold or release.

### Prompts after a rebind

- `KeyGlyph`, `TeacherBalloon`, `Notebook`, `MemorinaHud`, `GuardianCallHud` and `PhraseSheet` connect `Settings.bindings_changed` to the redraw they already run on `InputDevice.device_changed`.
- `KeyGlyph`'s label names the event it shows (`BindingNames`), not the action's first key. A pad button with no art (Back, L3, R3) shows its name in the blank key.
- The note HUDs read `NoteGlyphs.texture(note, glyph_set, lit)`. A bound input with no note art draws the blank note key with `label()`; `NoteSheet` slots gain that label.

### Live language

`Settings.set_language` calls `TranslationServer.set_locale`. The scripts with static key texts (`PauseMenu`, `ConfirmPanel`, `Title`, `SlotCard` through `show_saves`, `Notebook`, `SeedShopPanel`, `RegionTitle`, and the new screen) move them into `_retranslate()`, called from `_ready` and from `_notification(NOTIFICATION_TRANSLATION_CHANGED)` behind `is_node_ready()`. Texts translated as they show (dialogue lines, barks, notices) take the new language at their next show. Measure in 4.7 that the notification reaches every node synchronously; if it does not, write a gotcha.

### Text (`i18n/translations.csv`, all through `tr()`)

`PAUSE_SETTINGS`, `TITLE_SETTINGS`; `SETTINGS_TAB_SOUND`, `_GENERAL`, `_KEYBOARD`, `_PAD`; `SETTINGS_VOLUME_MASTER`, `_MUSIC`, `_NOTES`, `_EFFECTS`; `SETTINGS_LANGUAGE`, `SETTINGS_FULLSCREEN`, `SETTINGS_WINDOW_SIZE`, `SETTINGS_WINDOW_SCALE` (`%dx (%d x %d)`, keep three placeholders), `SETTINGS_ON`, `SETTINGS_OFF`; `LANGUAGE_EN`, `LANGUAGE_PT_BR` (each the language's own name in both columns); `ACTION_JUMP`, `_ATTACK`, `_ROLL`, `_DRAW_MEMORINA`, `_NOTE_UP`, `_NOTE_DOWN`, `_NOTE_LEFT`, `_NOTE_RIGHT`, `_MAP`, `_NOTEBOOK`; `SETTINGS_RESET_BINDINGS`, `CONFIRM_RESET_KEYBOARD`, `CONFIRM_RESET_PAD`; `SETTINGS_PRESS_KEY`, `SETTINGS_PRESS_BUTTON`, `SETTINGS_BIND_RESERVED`, `SETTINGS_BIND_TAKEN` (`%s`), `SETTINGS_BIND_SWAPPED` (`%s`); `PAD_XBOX_A`/`_B`/`_X`/`_Y`/`_LB`/`_RB`/`_VIEW`, `PAD_PS_CROSS`/`_CIRCLE`/`_SQUARE`/`_TRIANGLE`/`_L1`/`_R1`/`_CREATE`, `PAD_L3`, `PAD_R3`. Keyboard key names come from the OS layout and are not translated, as `KeyGlyph` does today.

### Tests (gdUnit4, mirroring source paths)

- `tests/globals/settings/settings_math_test.gd`: `volume_db` at 0, 5 and 10, rising monotonically; `locale_for` (`pt_BR`, `pt_PT`, `pt` -> `pt_BR`; `en_US`, `fr_FR`, `""` -> `en`); `window_size`; `fits`/`step_scale` skip sizes over the usable rect.
- `game_settings_test.gd`: defaults; clamping on load (volume 14 -> 10, -2 -> 0, scale 5 -> default); an absent language stays `""`; a round trip; only bindings that differ from the default are written; an invalid table drops that device's overrides.
- `key_bindings_test.gd`: `from_input_map` captures today's defaults (jump Z/A, notes W A S D and Y A X B, ...); the arrow set and the zooms are not managed.
- `binding_rules_test.gd`:
  - the whole share table per device, and the reserved codes (Esc, arrows, F8-F10, Start, D-pad, Guide);
  - pad jump -> Y: assigned, shared with note_up;
  - pad jump -> X: swapped with attack;
  - pad map -> A: refused, used by Jump;
  - pad jump -> B: refused (`ui_cancel`), while roll -> B is assigned;
  - keyboard note_up -> Z: refused, while keyboard jump -> W: swapped with note_up only if the result is valid;
  - unchanged on the own code.
- `settings_file_test.gd`: write and read in a temporary directory; an empty dir writes nothing and reads null; the debug file name.
- `settings_test.gd`: under the suite `Settings.has_disk()` is false and no file exists afterwards (the headless guard); `bind` writes `InputMap` and the zooms follow; `reset_bindings` restores. Every test restores the bindings in `after_test`.
- `tests/scenes/ui/menu/menu_input_test.gd`, capture mode: only `bind_pressed`/`capture_cancelled`; echo ignored; motion consumed, not emitted; page edges re-read on leaving.
- `player_input_test.gd` / `input_device_test`: a rebound letter key gives `KEYBOARD_WASD`, and the old W gives arrows; `binding_for` returns the rebound event.
- `key_glyph_test.gd`: the label names the shown event; it redraws on `bindings_changed`.
- `tests/scenes/ui/settings/settings_screen_test.gd`: focus on open; a tab shows its page; `step()` on a volume row changes it and returns true, on a tab it returns false; accept toggles fullscreen; the capture flow driven by `MenuInput` signals (assigned, refused-stays-open, cancelled); `step_back` from a confirmation returns to Reset.
- `screens_test.gd` / `pause_menu`: Settings opens from its entry; Esc closes Settings, then the pause; the hold count is unchanged; it is ignored while leaving. `title_test.gd`: the entry order and Back onto Settings.
- `settings_text_fit_test.gd`: every key above fits its box in en and pt_BR (tab 56, row labels, values, binding names, status line 272, entries 64, confirmation bodies).
- `retranslate_test.gd`: `set_locale("pt_BR")` with the pause open changes its texts without reopening.
- Add `settings_screen.tscn` to `tools/smoke/scenes.txt`. Playtest: a timeline that rebinds keyboard jump to Space in the pause, resumes and jumps with Space; screenshots of each page in both languages.

## Consequences

- New rule for `systems/screens` and `systems/input`: `Settings` is the only writer of bus volumes, the locale, the window and `InputMap`. Any later control (an accessibility toggle) is a field on `GameSettings`, a row and a key, with no new writer.
- `MenuInput` grows a mode; it stays the menu reader. The `verify-gates` scan is unchanged.
- `NoteGlyphSet` and its four .tres retire in favour of `NoteGlyphs`; five HUD scripts change their export.
- Every static text from now on is set in `_retranslate()`. A text set only in `_ready` is a defect once language can change live.
- A new `systems/settings` entry and its CLAUDE.md row come in the same change (proposed never-break rule: "Settings is the only writer of bus volume, locale, window and InputMap; MEMORY sessions never read or write the settings file; zooms follow jump and attack").

## Questions for the user

1. **Note rebinding:** (a) any key or button, which needs one new art item, a blank note key (normal and selected) in the `hud/memorina` style, plus a labelled fallback in the five note HUDs (recommended); or (b) only exchanging the four default inputs of each set (W A S D, Y A X B), with no new art.
2. Pad buttons with no glyph art (Back/Select, L3, R3): commission glyphs in the pack style, or a name in the blank key? Bind the triggers (LT/RT, axes) too? The plan says no.
3. Under the pause, Music stays stopped ("Para junto"), so the Music volume is heard only at the title. Keep it so?
4. pt_BR for "Settings": "Configurações" (if it fits the 64 px entry) or "Opções"?
5. Keep the window borderless in windowed mode (as today) at 1x/2x/3x?
6. Reset to defaults per device page (as planned) or both devices at once?
7. A separate `settings_debug.cfg` for debug builds (as planned), or one shared file?
