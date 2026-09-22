---
id: bugs/lesson-title-card-survives-a-cut-fade
type: bug
title: The last song's title card came back on the next guardian, because a second handler cut its fade-out short
status: fixed
severity: medium
tags: [lesson, cinematic, tween, signals, ordering]
related: [architecture/memory-runs-through-pause, playtests/2026-09-22-lesson-polish]
created: 2026-09-22
updated: 2026-09-22
source_files:
  - scenes/ui/lesson_cinematic/lesson_cinematic.gd
  - scenes/characters/guardians/guardian.gd
---

## Summary

`LessonCinematic.on_lesson_finished` fades the letterbox, the dim AND the title card out
together, then hides the node. A restored `Guardian` also listens for
`performance_finished` (to release the camera and the lights it staged), and its handler
runs LAST, so it emitted `call_unstaged` while that fade was still running.
`on_call_unstaged` called `_kill()` and started its own dim-only fade - the card's tween
died at whatever alpha it had reached, typically 1.0. The node hid with a fully opaque
card inside it, and the next thing to `show()` that layer - the next guardian going
lucid - put the previous song's title back on screen.

## Symptom

User, round 8: beat the Bloom Guardian, walked to the next one, and "the first time the
memorina hud opened, the title of the song i had learned before was still there". The
evidence was already in the previous round's log and went unread: `cine=false card=1.00`
after the lesson.

## Root cause

Two handlers of one signal, with the second cancelling the first's tween. Godot calls
connections in order, and the guardian's runtime connection is made after the scene's,
so `on_lesson_finished` always lost.

## Fix

- `_lesson_active` is set from the lesson's first frame until its frame has fully
  closed; `on_call_unstaged` returns early while it is set. The lesson owns the layer.
- Every way out now ends in `_finish()`: hide AND `_reset()` to the authored state, so
  no half-run fade can leave anything visible behind.
- `on_call_staged` sets the card's alpha to 0 before showing: a call names no piece, and
  it never inherits one.

## Prevention

Two rules. A node that fades several children out together must not depend on the tween
completing - reset the state in the callback, because anything can kill a tween. And
when two handlers of the same signal both drive one node's visuals, one of them has to
own it; "whichever runs last wins" is not an ordering anyone can read from the scene.
