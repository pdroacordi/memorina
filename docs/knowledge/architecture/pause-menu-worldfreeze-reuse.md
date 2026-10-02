---
id: architecture/pause-menu-worldfreeze-reuse
type: architecture
title: Pause menu reuses WorldFreeze verbatim; an ALWAYS-mode input+UI pair owns the toggle and never touches get_tree().paused itself
status: active
tags: [pause, menu, ui, input, worldfreeze, process-mode-always, signals, screens, notebook, map, hold, time-scale, audio]
related: [architecture/character-controller-input-split, architecture/memory-runs-through-pause, architecture/played-pulses-hold-in-a-pause, architecture/save-slots-and-the-boot-swap, architecture/map-reveal-seen-cells-per-room, architecture/notebook-entries-are-derived-from-the-save, gotchas/playtest-clock-pauses-with-the-tree, gotchas/a-stick-is-pressed-on-every-motion-event, systems/songs-and-the-memorina]
created: 2026-09-20
updated: 2026-10-02
source_files:
  - scenes/ui/pause_menu/pause_menu.gd
  - scenes/ui/menu/menu_input.gd
  - scenes/ui/screens/screens.gd
  - scenes/ui/screens/screen_router.gd
  - scenes/world/world_freeze.gd
  - scenes/world/game.tscn
  - scenes/world/fade.gd
  - scenes/world/memory/greyhush_common.gdshaderinc
  - scenes/world/memory/greyhush_renderer.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/ivo/ivo.tscn
  - scenes/characters/ivo/abilities/memorina_voice.gd
  - scenes/ui/recall_prompt/recall_prompt.gd
  - tools/playtest/playtest_runner.gd
  - project.godot
---

> **Revised twice on 2026-10-02** (see the end).
> 1. One shared `MenuInput` and a `Screens` router replace the per-screen `PauseInput`. A
>    performance may only start on Ivo's pausable clock. `Ivo/AnimationTree` is ALWAYS only
>    during a performance.
> 2. A menu now HOLDS the world and a performance FREEZES it. `WorldFreeze.hold()` pauses the
>    tree AND sets the time scale to 0, so everything stops, the ALWAYS memory layer included.
>    This replaces "two methods forever".
>
> The original decision below still holds where the revisions do not change it.

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

## Revision (2026-10-02)

This revision plans the notebook (UI-03), the map (UI-04) and the title (UI-05) together, on the user's
decisions of 2026-10-02. None of the files above existed yet. What changed and why:

**One input node and one router, not a pair per screen.** The first Consequence ("each
screen copies the shape") breaks at three screens:
- The map does NOT freeze (user decision), so a "tree already paused" guard cannot stop
  pause-over-map or map-over-notebook. Each screen would have to know the others are open.
- Esc is both `pause` and the default `ui_cancel`, so two nodes would each act on one key press.

Now:
- `MenuInput` (`scenes/ui/menu/menu_input.gd`, `extends Node`) is the one node besides
  `PlayerInput` and `InputDevice` that reads `InputEvent`s.
  - It emits at most ONE signal per event, with the screen toggles taking precedence over
    `back_pressed`: `pause_pressed`, `notebook_pressed`, `map_pressed`, `back_pressed`,
    `page_pressed(direction)`, `zoom_pressed(direction)`.
  - A stick-bound press is an edge (`gotchas/a-stick-is-pressed-on-every-motion-event`).
  - The map's pan is a polled property, `pan: Vector2`.
- `ScreenRouter` (pure, tested) decides `decide(open, press, tree_paused, locked) -> Kind`.
  - A screen opens only from NONE, and only when the tree is not paused and not locked.
  - While a screen is open, its own toggle, `back` or `pause` closes it. Other toggles are ignored.
- `Screens` (`scenes/ui/screens/`, root Control ALWAYS on its own CanvasLayer above the HUD)
  applies the decision.
  - It emits `freeze_requested` / `thaw_requested` for the pause and the notebook, wired in
    `game.tscn` to `WorldFreeze.freeze` / `thaw`. The second revision renames these to hold/release.
  - It emits `player_blocked(bool)` for the map, wired to `Player.set_input_blocked`.
  - `Player.died → Screens.lock` closes anything open and refuses until the world reloads.
- `PauseMenu` only emits `resume_requested`, `quit_to_title_requested` and `quit_game_requested`.
- The "only thaws what it froze" rule stands, now owned by `Screens` instead of `PauseMenu`.

**A performance must start on Ivo's pausable clock.** `MemorinaVoice` is ALWAYS, so its
`note_finished` reaches `Player._on_note_finished` while a menu holds the tree, and that calls
`SongPerformance.play()`. The excerpt then plays under the pause menu, and its `finished → thaw`
unpauses the world under a menu that is still open. `_await_lesson_track` has the same path.
- The voice callback now only marks the performance ready, and `_process_motion` (pausable) starts it.
- `WorldFreeze.freeze()` asserts the tree is not already paused, so any future overlap fails
  loudly instead of thawing someone else's freeze.
- No ref-count was added: with the start moved, every freeze has exactly one owner at a time.

**`Ivo/AnimationTree` is ALWAYS only during a performance.** ALWAYS was there for `memorina_idle`
under a performance. Under a menu it made Ivo move in a stopped world. It also let clip-keyed
tracks (`Hurtbox:monitorable` in the roll and hurt clips, the hitbox shapes) run on while his
logic was frozen. Now `ivo.tscn` connects `performance_started → AnimationTree.set_process_mode`
(binds ALWAYS) and `performance_finished → set_process_mode` (binds INHERIT); the tree's
authored mode is INHERIT.

**A freeze runs at time scale 1; a world that leaves the tree resets the clock.** Pausing
mid-recall left `Engine.time_scale` at 0.2, so every ALWAYS menu tween and strip ran at a
fifth of its speed.
- `WorldFreeze.freeze()` sets the scale to 1. `thaw()` returns it to `slow_scale` if a recall is
  still on (`_slowed`), unless a hit-stop is mid-flight. WorldFreeze is still the only writer.
- `_exit_tree()` sets the scale to 1 and unpauses, so leaving a frozen world for the title
  (`architecture/save-slots-and-the-boot-swap`) starts the title on a running clock.
- The map never freezes, so it pans in real seconds (`delta / Engine.time_scale`, as `KeyGlyph` does).
- The second revision replaces the reasoning here for menus.

**The playtest runner would hang.** It counts `_elapsed` in a pausable `_process`
(`gotchas/playtest-clock-pauses-with-the-tree`), so a timeline that opens the pause menu
can never send the press that closes it, and `max_duration` never fires.
- The runner becomes ALWAYS.
- Its timeline clock still counts only unpaused time, unless the timeline says `"clock": "real"`.
  `max_duration` is always real time.
- `game.tscn`'s root is set to PAUSABLE explicitly, so it does not inherit ALWAYS from the runner.

## Revision (2026-10-02, second): a menu holds, a performance freezes

**Context.** The user decided (2026-10-02) that behind the pause menu and the notebook, "Stop
everything". With the UI-02 implementation, a menu called `WorldFreeze.freeze()`, which pauses
the tree at time scale 1. Everything on the pause-mode map kept moving behind the menu:
- the memory layer (SeasonMask, the Greyhush renderer, CreatureMask, every ColorPulse,
  RegionWeather's particles);
- the life notes' sway;
- SaveMark, MemorinaHud and LessonCinematic tweens;
- every `TWEEN_PAUSE_PROCESS` tween (the camera zoom, pair and push-in, and
  `RegionMemory`'s lift and mark-erase);
- Ivo's ALWAYS `MemorinaVoice`.

The greyhush shader's ragged-edge re-roll reads `TIME` (`greyhush_common.gdshaderinc`,
`gh_sector_wobble`).

A playtest opened the menu in two windows and found both still running under it:
- **The ring-out** (last note to performance start): the voice kept ringing.
- **The lesson's 0.5 s lead-in**: `LessonCinematic` and the camera's `push_in` kept going.

A PERFORMANCE must keep today's behaviour: it freezes time, not memory
(`architecture/memory-runs-through-pause`).

**Options considered.**
- *A separate `MenuHold` node that stops things.* Rejected: it would be a second writer of
  the tree's pause state or of the time scale.
- *Tell each ALWAYS node about the hold, by signal or group, and have it stop itself.*
  Rejected: about a dozen sites (the nodes above, plus every `TWEEN_PAUSE_PROCESS` tween,
  which has no node to tell). Every future ALWAYS node would also have to remember to opt in.
- *Refuse the menu in the ring-out and the lead-in* (`Screens` asks Player "is a song pending?",
  as `_try_sit` asks `Guardian.fight_at`). Rejected:
  - It does not stop anything else: a pulse in flight, the life notes, weather, a camera zoom.
  - It couples `Screens` to `Player`.
  - It drops a deliberate press. A swallowed press reads as broken input
    (`bugs/memorina-notes-dropped-while-previous-rings`).
- **Chosen: `WorldFreeze.hold()` / `release()`, a second pair beside `freeze()` / `thaw()`.**
  `hold()` pauses the tree AND sets `Engine.time_scale` to 0.
  - Every ALWAYS `_process` / `_physics_process` then gets a delta of 0.
  - Every tween and timer that does not ignore the time scale stops, `TWEEN_PAUSE_PROCESS`
    included.
  - `CPUParticles2D` stops: RegionWeather's and the pulses' particles are CPU particles,
    stepped by the scaled process delta.
  - Nothing has to be told. The lead-in and the ring-out are held, not refused: the lead-in
    timer is on Ivo's pausable clock, and the cinematic and camera tweens stop with the scale.

**Decision.**
- `WorldFreeze` (still the only writer of `paused` and `time_scale`) gains `hold()`, `release()`
  and a static `is_held() -> bool`. `is_held()` is backed by a `static var`, reset in `_ready`
  and `_exit_tree`.
  - `hold()` asserts the tree is not paused; there is one owner at a time, as with `freeze`.
  - `_running_scale()` checks in this order: held → 0, frozen → 1, hit-stop, recall slow, 1.
  - `release()` unpauses and returns to `_running_scale()`.
  - A hit-stop timer that ends during a hold leaves the scale at 0.
- `Screens`: `FREEZING` becomes `HOLDING`, and `freeze_requested` / `thaw_requested` become
  `hold_requested` / `release_requested`. `game.tscn` wires them to `WorldFreeze.hold` /
  `release`. A performance keeps `freeze` / `thaw`.
- **Explicit handling for what does not read the scaled clock.** There are three kinds of
  leak, and a new ALWAYS node that reads real time must join this list:
  1. **Shader `TIME`.** The greyhush ragged edge reads a new global `greyhush_time`
     (`project.godot` `[shader_globals]`). `GreyhushRenderer._process` advances it from its
     scaled `delta` and wraps it at 3600 s. So it runs through a performance freeze (scale 1),
     slows with a recall, and stops under a hold. It does not depend on whether engine `TIME`
     follows the time scale, which was not measured. This is the last `TIME` in the project's
     shaders; water and the burned shadow already ban it.
  2. **ALWAYS audio.** `MemorinaVoice._process` sets `_player.stream_paused = WorldFreeze.is_held()`.
     This is a pull, like `Guardian.fight_at`, so a node created mid-hold is right too, and
     there is no `get_node` chain. `SongPerformance` cannot be playing under a hold, because
     a menu is refused while a performance holds the tree. It asserts this instead. Pausable
     players (a guardian's call voice) are paused by the engine with the tree (verify once in
     the playtest).
  3. **World tweens that ignore the time scale.** `RecallPrompt._step_tween` drops
     `TWEEN_PAUSE_PROCESS` and binds to its pausable node, so no pause runs it.
     `set_ignore_time_scale` stays for the recall slow.
- **Menus run on real time.** They are the only thing that moves under a hold. Every tween in
  the `Screens` subtree uses `set_ignore_time_scale(true)`. A frame-stepped strip, such as the
  notebook's page turn, is a tween of that kind, never `_process(delta)`, because delta is 0.
  `Fade` gains `@export var real_time: bool`, true on the `Screens` Blackout. A real-time
  `KeyGlyph` blink (`delta / time_scale`) shows 0 under a hold, so a held screen must not
  rely on it. The map never holds and is unaffected.

**Consequences.**
- "WorldFreeze stays a two-method API forever" is revised. There are two pause verbs because
  there are two meanings:
  - **freeze** stops time and keeps memory moving (a performance or lesson);
  - **hold** stops everything (a menu).
- The rule for a new ALWAYS node: if it animates from anything but the scaled delta (`TIME`,
  ticks, `set_ignore_time_scale`, an audio stream), it must stop while `WorldFreeze.is_held()`.
- `architecture/memory-runs-through-pause` still holds for freezes. Its boundary ("memory may
  move under a pause") now applies to a performance freeze only, never to a hold.
- The playtest runner's world clock (`_elapsed += delta`) stops under a hold, so menu
  timelines must use `"clock": "real"`, which reads ticks.
- `Engine.time_scale = 0` is a new state for this project. Run the smoke test and one menu
  playtest with the console open before building on it.
- Tests:
  - `world_freeze_test`: `hold()` gives paused, scale 0 and `is_held()`; `release()` after
    `slow()` gives `slow_scale`; `freeze()` still gives 1; `_exit_tree` clears `is_held`.
    Assert within one frame.
  - `screens_test`: pause and notebook emit `hold_requested`; the map emits nothing.
  - Playtest (`"clock": "real"`): with the menu open for 2 real seconds over the ring-out, the
    lesson lead-in and a pulse in flight, two screenshots are identical (pulse radius,
    life-note frame, greyhush edge, letterbox) and the voice is silent; release resumes the
    performance with no double thaw.
