---
id: bugs/accents-on-a-focused-menu-button-land-on-its-top-highlight
type: bug
title: On a focused menu button the acute and the tilde are drawn on the 1 px top highlight, so "Voltar ao título" reads "Voltar ao titulo" and "Não" loses half its tilde
status: fixed
severity: low
tags: [menu, font, i18n, pt-br, button, theme, accent, tilde]
related: [systems/screens, playtests/2026-10-02-title-and-slots, playtests/2026-10-02-pause-menu]
created: 2026-10-02
updated: 2026-10-06
source_files:
  - scenes/ui/menu/menu_theme.tres
  - tools/fonts/patch_tilde.py
  - scenes/ui/pause_menu/pause_menu.tscn
---

## Summary

On the pause menu's 14 px `Button_01A` entries, the 8 px text font draws the accent of a lowercase
letter two pack pixels above the ascender. On the focused (Selected) style the upper accent pixel
falls on the button's 1 px top highlight row: cream (245, 229, 184) on peach (255, 194, 161). It
nearly vanishes there.

## Symptom

Found in the UI-05 playtest (pt_BR, 2026-10-02):
- `screenshots/2026-10-02-title-and-slots/accent_on_button_bevel_pt_BR.png`, left: the focused
  pause entry "Voltar ao título" reads "Voltar ao ti tulo". The acute's top pixel is on the
  highlight and its lower pixel is a lone dot over the "i".
- The same image, right: the focused "Não" in a confirmation shows only the lower half of the
  patched tilde wave. The upper half sits on the highlight row.
- The same strings in a body `Label` ("Voltar ao título?") are fine.

Pack-pixel rows through "título" on the focused button:
- 95: outline;
- 96: highlight, with the accent's top pixel;
- 97: the accent's second pixel;
- 98: ascender tops;
- 99 to 101: x-height;
- 102: one orange row;
- 103: bottom bevel.

## Root cause

- The text sits high in the 14 px entry: one face row below the baseline, none above the ascender.
- The acute and the patched tilde (`tools/fonts/patch_tilde.py`, a 5 px wave) rise two rows above
  lowercase ascenders, onto the stylebox's top highlight.
- The content margins are L4 T5 R4 B6 (`menu_theme.tres`). They place the text box and do not
  clip it.

## Fix

Fixed 2026-10-06 by the user's decision "Taller entries": every `MenuEntry` grew from 14 to 16 pack px.
- This covers pause entries, the title column, confirmation Yes/No and Erase.
- The text sits one row lower, so the acute and the tilde fall below the highlight row.
- The pause panel grew to 96x92 at (112, 50), banner at (120, 38), entries at (124, 72) to (196, 128): still centred.
- The confirmation's Yes/No sit at y 46..62 inside its 76 px panel.

Evidence: `scratchpad/ui05/shots_r3/pt_BR_accents_zoom4x.png` (4x) shows the focused "Voltar ao título" with the whole acute on orange, and the focused "Não" with its whole tilde wave below the highlight.

## Prevention

- Zoom every new pt_BR button label at 4x in its focused state.
- An accent on a capital (É, Ã) would rise one row higher still.
