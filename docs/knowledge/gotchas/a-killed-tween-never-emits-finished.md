---
id: gotchas/a-killed-tween-never-emits-finished
type: gotcha
title: A Tween that is kill()ed never emits `finished`, so any coroutine awaiting it hangs for ever
status: active
tags: [tween, await, coroutine, fade, async]
related: [bugs/a-second-fall-during-the-respawn-clear-sinks-forever]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/fade.gd
  - scenes/world/game.gd
---

## Summary

`Tween.finished` fires only when the tween runs to completion. `kill()` invalidates the
tween without emitting anything. An `await tween.finished` still pending when another
caller kills that tween never resumes, and nothing reports that it is stuck.

## Details

`Fade._tween_color` (fade.gd:18-23) kills the previous tween and returns the new tween's
`finished`. This is safe only while callers never overlap; if they do, the caller that
started first stays suspended.

In `Game`, both the room transition (game.gd:39-61) and the hazard beat (game.gd:65-78)
await `Fade`. If they overlap, the first one never reaches its cleanup
(`_is_transitioning = false`, `process_mode = INHERIT`, `_respawning = false`). The result
is a disabled player or a guard that stays set for good.

## Gotchas / pitfalls

- A suspended coroutine leaks and logs no error. It only shows up later, as a flag that
  never clears.
- Safe patterns:
  - Return your own signal, emitted both when the tween completes and when it is
    superseded.
  - Before `kill()`, run `if _tween: _tween.finished.emit()`. This is legal because
    `finished` is an ordinary signal.
  - Tag each request with a generation counter, and have stale awaiters exit.
- `Player._await_lesson_track` already follows the same rule for its own waits ("kept as
  a coroutine only because both waits always end").
