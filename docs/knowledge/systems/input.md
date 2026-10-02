---
id: systems/input
type: system
title: Input: actions, gamepad layout and device glyphs
status: active
tags: [input, gamepad, glyphs, keybindings]
related: [architecture/character-controller-input-split, gotchas/a-stick-is-pressed-on-every-motion-event]
created: 2026-10-02
updated: 2026-10-02
source_files:
  - scenes/characters/ivo/player_input.gd
  - project.godot
---

# Input: actions, gamepad layout and device glyphs

Moved verbatim from `CLAUDE.md` ("Known gaps") on 2026-10-02. The open items (notebook, pause, map actions) are tracked in `docs/roadmap.md`.

Input map (`project.godot`) defines `move_left`, `move_right`, `jump`, `look_up`, `look_down`, `roll`, `attack`, `draw_memorina`, `note_up`/`note_down`/`note_left`/`note_right` and the debug-only `debug_learn_song` (F9). Every gameplay action has a gamepad binding (the user's layout, 2026-10-01): left stick + D-pad move and look (down sits at a bench, up climbs), A/✕ jump, X/□ attack, B/○ roll, RB/R1 draws the Memorina - and while the instrument is out the face buttons are its notes (Y/△ up, A/✕ down, X/□ left, B/○ right), the same double duty the arrow keys have, kept unambiguous by `move_axis`/`_try_jump`/`_try_roll`/`_try_attack` ignoring input while it is drawn. Look actions have a 0.5 deadzone so a resting stick never peeks or sits, and `look_down_pressed` is the EDGE of down (`PlayerInput._down_held`): a stick reports "pressed" on every motion past its deadzone. A jump, roll or attack press while the instrument is out was a note and is dropped (`Player._as_move`), never buffered. **Prompts draw the player's own device**: `InputDevice` (autoload; the one input node besides `PlayerInput` that reads `InputEvent`s - deliberately, because it must outlive Ivo, who is rebuilt on every death and disabled through every fade, and it reuses `PlayerInput.glyph_set_for` rather than judging events itself) remembers the last device touched as an `Enums.GlyphSet` (via `PlayerInput.glyph_set_for`) and `KeyGlyph` draws the action's binding for it from `InputGlyphs` (`resources/ui/input/`, built by `tools/ui/build_input_glyphs.gd` from `assets/sprites/hud/input/`); a key with no symbol of its own (Z, Shift, C) is the blank key with its name. The design still calls for open-notebook, pause and open-map — add these when that work actually starts, matching the existing signal-based `PlayerInput` pattern.
