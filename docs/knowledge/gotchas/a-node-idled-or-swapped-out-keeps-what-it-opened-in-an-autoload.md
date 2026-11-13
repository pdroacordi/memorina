---
id: gotchas/a-node-idled-or-swapped-out-keeps-what-it-opened-in-an-autoload
type: gotcha
title: A node in an idled room gets no _exit_tree, and a node freed mid-flow skips its flow's own cleanup, so what it opened in an autoload stays open
status: active
tags: [autoload, process-mode, residency, exit-tree, music, duck, muffle, cleanup]
related: [bugs/a-quit-to-title-mid-scene-leaves-the-music-muffled, bugs/the-mill-lure-keeps-the-lullaby-playing-in-the-mill-house, systems/rooms, systems/music, gotchas/an-area2d-emits-body-exited-when-disabled-or-removed]
created: 2026-11-13
updated: 2026-11-13
source_files:
  - scenes/world/rooms/room.gd
  - scenes/world/rooms/room_residency.gd
  - globals/music/music.gd
---

## Summary

Autoloads (`Music`, `WorldFreeze`, `SaveSystem`) outlive rooms and world swaps. A world node that opens named state in
one of them, such as `Music.duck(id, ..)` or `Music.muffle(id, ..)`, has two ways to leave that state open by mistake.

## Details

- **Idle, not freed.** `Room.deactivate()` sets the contents to `PROCESS_MODE_DISABLED` and hides them. Nodes inside
  receive `NOTIFICATION_DISABLED`, not `NOTIFICATION_EXIT_TREE`, and their `_process`/`_physics_process` stop. Cleanup
  in `_exit_tree`, or a per-frame "is Ivo still here" check, never runs. A door trip idles the room he leaves in the
  same frame he lands, so a per-frame check never gets one last look.
- **Freed mid-flow.** A director whose `_exit_tree` only drops its state (for example `CutsceneDirector._exit_tree`)
  skips the cleanup that its normal end would run. Quit to title (`SceneSwap.replace`) is the path that does this
  without any interrupt first.
- `Music.request(cue, layer, owner)` is released when its owner leaves the tree, not when it is disabled. Since
  2026-11-13 named ducks and muffles take an owner too and close when it is freed, leaves the tree or is disabled
  (`systems/music`, "Owners").

## Gotchas / pitfalls

- Release on `NOTIFICATION_DISABLED` as well as `_exit_tree`, or make the autoload own the lifetime through an owner
  node.
- `Area2D` overlap is not a substitute: a disabled area reports `body_exited`
  (`gotchas/an-area2d-emits-body-exited-when-disabled-or-removed`), but a script that polls overlaps from its own
  physics step stops polling.
