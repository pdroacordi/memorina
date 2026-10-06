---
id: bugs/the-notebook-quill-shows-through-a-lesson
type: bug
title: The notebook's HUD quill fades in during a lesson's lead-in and stays on screen through the whole lesson
status: fixed
severity: medium
tags: [notebook, toast, hud, guardians, lesson, freeze, pause]
related: [systems/notebook, architecture/notebook-entries-are-derived-from-the-save, systems/guardians, architecture/memory-runs-through-pause]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - scenes/ui/notebook/notebook_watcher.gd
  - scenes/ui/notebook_toast/notebook_toast.gd
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/ivo/player.gd
---

## Summary

The watcher holds its queue only while `Guardian.fight_at()` is true. A restoration sets the phase
to RESTORED (so `fight_at` is false at once), but the lesson's freeze starts 0.5 s or more later. In
that gap the pausable watcher announces, the quill fades in, and the freeze then stops its tween
with the quill shown. The user decided "After the fight", and the plan rejected an icon over the
lesson cinematic.

## Symptom

Found in review of UI-03 (not yet seen in a playtest). The last note of a guardian's answer
restores it. Within about 0.4 s the quill (`CanvasLayer/NotebookToast`, 32x32 at (600, 8)) fades in
on top of the lesson's top letterbox bar. It stays there for the whole lesson track, then holds
3 s and fades after the thaw. F9 (`debug_learn_song`) shows the same without a guardian, because
nothing holds the queue outside a fight.

## Root cause

- `Guardian.is_fighting_at` (`guardian.gd:191`) is false in RESTORED. `_restore` (`guardian.gd:471`)
  calls `SaveSystem.restore_guardian` and `Player.learn_song`, which emits `progress_changed`. The
  song entry joins the recalled-skill entries already queued during the fight.
- `Player.learn_song` (`player.gd:648`) sets `_lead_in_left = lesson_lead_in` (0.5 s). The
  performance, and with it `performance_started` → `WorldFreeze.freeze` (`game.tscn`), starts only in
  `_tick_pending_performance` (`player.gd:600`), once the lead-in has run out and `_voice.is_busy()`
  is false. The tree is not paused until then.
- `NotebookWatcher._process` (`notebook_watcher.gd:24`) runs on the next idle frame, sees no fight,
  and emits `announced`. `NotebookToast.show_hint` starts a pausable tween (fade in 0.4 s). The
  freeze then pauses that tween, so the quill stays at the alpha it had reached.
- `NotebookToast` is a later child of `CanvasLayer` than `LessonCinematic`, so it draws above the
  letterbox bars.

## Fix

Fixed 2026-10-06 (UI-03 round 2). `Player.is_in_lesson()` is true from `learn_song` until the track's
`performance_finished`, or until a sheathe or an abort clears the pending lesson. `NotebookWatcher.is_holding()`
pulls it on demand next to `Guardian.fight_at`, so the queue waits through the lead-in and the frozen track,
F9 lessons included. The watcher also drops ids read while they waited, at emit time.

- Test: `notebook_watcher_test.test_a_lesson_holds_the_queue_until_its_track_ends` (a real Ivo, no
  guardian; it fails on the old `is_holding`).
- Windowed run, a GALE lesson with no guardian (APPDATA redirected): quill alpha 0.00 at 0.3 s
  (lead-in, unpaused) and 0.00 at 2.8 s (paused, track playing); the track ended 76.5 s later, and
  0.9 s after it the alpha was 1.00.

## Prevention

"Nothing shows under a freeze" covers only paused frames. Any beat that starts unpaused and freezes
later (a lesson's lead-in, a note still ringing) leaves a gap that a pausable announcer will fill.
Gate on the beat itself, not on the pause.
