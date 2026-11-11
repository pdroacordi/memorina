---
id: gotchas/fullscreen-does-nothing-in-an-editor-run
type: gotcha
title: Fullscreen from Settings does nothing when the game is run from the editor
status: active
tags: [display, window, fullscreen, editor, settings]
related: [systems/settings]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - globals/settings/settings.gd
---

## Summary

Run from the Godot editor (F5, game in its own window), Settings' Fullscreen row turns On but the window stays 1280x720 (user, 2026-11-11: "eu liguei o modo fullscreen e nao mudou nada"). Launched outside the editor, the same build goes fullscreen ("Funcionou fora", user, 2026-11-11).

## Details

- Measured 2026-11-11 on 4.7.2 with the committed `Settings._apply_window`: outside the editor, `Settings.set_fullscreen(true)` on the title sets `Window.mode` 3 and the window to 1920x1080, and a `DisplayServer.screen_get_image()` capture shows the title over the whole screen. The launch arguments the editor passes (`--position`, `--windowed`, `--remote-debug`) do not stop it when given by hand.
- So the editor's own control of the game window it started overrides the mode; the code is not at fault. Which editor setting does it is not measured.
- Test display options with the game launched outside the editor:

```bash
"$GODOT_WINDOWED" --path . -- --title
```
