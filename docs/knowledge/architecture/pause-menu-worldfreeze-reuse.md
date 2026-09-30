---
id: architecture/pause-menu-worldfreeze-reuse
type: architecture
title: Pause menu reuses WorldFreeze verbatim; an ALWAYS-mode input+UI pair owns the toggle and never touches get_tree().paused itself
status: active
tags: [pause, menu, ui, input, worldfreeze, process-mode-always, signals]
related: [architecture/character-controller-input-split]
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/ui/pause_menu/pause_menu.gd
  - scenes/ui/pause_menu/pause_input.gd
  - scenes/world/world_freeze.gd
  - scenes/world/game.tscn
---

## Summary

The pause menu is not a second thing that pauses the game — it is a third caller of the
same two `WorldFreeze` methods a song performance already uses. Its own input node
(`PauseInput`) and its own UI node (`PauseMenu`) both run at `PROCESS_MODE_ALWAYS`, because
once `get_tree().paused` is true only `ALWAYS`/`WHEN_PAUSED` nodes still receive input —
including the input needed to close the menu again.

## Context

`World` in `game.tscn` is `PROCESS_MODE_PAUSABLE`, so `Player`/`PlayerInput` stop receiving
input entirely once the tree is paused — a pause menu's own toggle therefore cannot live
on that side of the tree, or it could open a menu but never close it. Separately,
`WorldFreeze.freeze()`/`thaw()` already exist and its doc comment already anticipates this
exact reuse: "the instrument freezes everything while a performance plays; **a pause menu
will call the same two methods**." `WorldFreeze` is meant to be the *one* writer of
`get_tree().paused` — a second, independent writer would race it: pausing during an active
`SongPerformance`/guardian call (which already froze the tree) and then closing the pause
menu would incorrectly thaw the world out from under a performance that hasn't finished.

## Options considered

- **PauseMenu calls `get_tree().paused` directly.** Rejected: creates a second writer of
  the tree's pause state, contradicting `WorldFreeze`'s own contract, and reintroduces the
  race above with no natural place to resolve it.
- **PauseMenu reads Player/Memorina state to decide whether it's safe to pause.** Rejected:
  couples a generic system menu to gameplay internals it has no business knowing about,
  and the notebook/map screens that will reuse this same shape have even less reason to
  know what a `MemorinaComponent` is.
- **A guard based only on `get_tree().paused`'s current value, decoupled from why it's
  true.** Chosen: `PauseMenu` opens only if the tree isn't already paused, and only ever
  thaws if it was the one that froze it (tracked as a local `_is_open` flag, not by
  inspecting *why* the tree is paused). This needs no knowledge of what else might have
  frozen the world.

## Decision

`PauseInput` (`extends Node`, sibling to `PlayerInput` in spirit but *not* a
`CharacterController` — it carries no movement intent) is the only place that knows about
the `pause` action; it emits a single discrete signal, `pause_toggle_pressed`. `PauseMenu`
(`extends Control`) is the logic node: it owns `_is_open`, opens/closes the menu, and emits
`opened` / `closed` / `quit_requested` — it never calls `get_tree().paused` or `WorldFreeze`
directly. `game.tscn` wires `opened → WorldFreeze.freeze` and `closed → WorldFreeze.thaw`,
the same shape as the existing `performance_started → WorldFreeze.freeze` connection.
Both `PauseInput` and `PauseMenu` sit under a `PauseMenu` root with
`process_mode = PROCESS_MODE_ALWAYS`, matching how `MemorinaHud` already marks itself
`ALWAYS` for the same reason (`memorina_idle` must keep looping on a frozen body).

The open/close guard lives entirely in `PauseMenu`:

```gdscript
func _on_pause_toggle_pressed() -> void:
    if _is_open:
        _close()
    elif not get_tree().paused:
        _open()
    # else: the tree is already paused for some other reason (a performance,
    # a guardian call) - pausing on top of it is refused, not queued.
```

## Consequences

- The notebook and map screens (`CLAUDE.md` "Known gaps") should copy this exact shape:
  their own `ALWAYS`-mode input node + logic node, wired to `WorldFreeze.freeze`/`thaw`
  through scene connections, with the same "refuse to open over an existing freeze" guard.
  None of them needs to know about the others, or about `MemorinaComponent`/`GuardianFight`.
- `WorldFreeze` stays a two-method, single-writer API forever — no ref-counting, no
  "who currently owns the freeze" state. Anything that wants to freeze the world composes
  against it the same way `Player` and `PauseMenu` do; it never grows a third method.
- Because the guard is purely "is the tree already paused," pausing mid-recall (which uses
  `Engine.time_scale`, not `get_tree().paused`) is allowed and freezes the slowed world
  exactly like a normal pause — no special case needed.

## Gotchas / pitfalls

- Don't give `PauseInput` or any future system-input node its own `PROCESS_MODE_ALWAYS`
  override if it's already a child of an `ALWAYS` root — redundant overrides drift out of
  sync if the root's mode ever changes. Set the mode once, on the root Control, the same
  place `MemorinaHud` sets it.
- A menu button (`ResumeButton`, `QuitButton`) still needs to inherit `ALWAYS` through its
  parent to receive `_gui_input`/`pressed` while paused — verify this in the editor's
  "effective" process mode column, not just by reading the scene file, if a button seems to
  do nothing while paused.
