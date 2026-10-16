---
id: bugs/a-notice-withdrawn-after-it-left-is-told-twice
type: bug
title: A notice that has already slid out is still "showing" to NoticeWatcher until the toast's gap ends, so a talk or a scene starting then withdraws it and it is told a second time
status: fixed
severity: low
tags: [notice, toast, watcher, withdraw, hold, tween, ui-11]
related: [systems/notices, gotchas/a-killed-tween-never-emits-finished, systems/dialogue, systems/cutscenes]
created: 2026-10-16
updated: 2026-10-16
source_files:
  - scenes/ui/notice/notice_watcher.gd
  - scenes/ui/notice/notice_toast.gd
  - scenes/ui/notice/notice_queue.gd
---

## Summary

FIXED 2026-10-16 (UI-11), low (UI-11 review, 2026-10-16). `NoticeWatcher._showing` stays set until the toast emits `finished`, and the toast emits it
only after the slide-out and the `gap`. A hold (a talk, a cutscene, a lesson, a fight) that begins after the notice has
left the screen still withdraws it and pushes it back first, so the player sees the same notice again after the hold.

## Symptom

A notice slides in, holds 2.0 s and slides out. If a hold begins in the 0.25 s `gap` after it has gone, the same notice
("Round loaf", "Home.") shows again in full once the talk or scene ends. This can happen with an auto talk, a
`CutsceneTrigger` whose delay ends then, or a guardian fight starting then. During the 0.5 s slide-out the notice is
still on screen, but the replay restarts it from the beginning.

The contract (`systems/notices`) withdraws only "one that is showing when they begin", and this notice is no longer
showing.

## Root cause

- `scenes/ui/notice/notice_toast.gd:50-52`: `tween_callback(_art.hide)`, then `tween_interval(gap)`, then
  `tween_callback(finished.emit)`. The art is hidden a full `gap` before `finished`.
- `scenes/ui/notice/notice_watcher.gd:30-35`: while `is_holding()`, any non-null `_showing` goes through
  `_queue.push_front(_showing)` and `withdrawn`. Only `on_notice_finished()` (line 43) clears `_showing`.
- `withdraw()` kills the tween, so `finished` never comes (`gotchas/a-killed-tween-never-emits-finished`). The
  pushed-back notice is popped and shown again after the hold.

## Fix

Fixed 2026-10-16: `NoticeToast` emits `leaving` as its slide-out starts; `NoticeWatcher.on_notice_leaving()` clears
`_showing` (the notice is told) and a separate `_view_busy` waits for `finished`. A hold withdraws and re-queues only a
notice still sliding in or holding; in the slide-out or the gap it is left alone. Tests:
`notice_watcher_test.test_a_hold_during_the_slide_out_does_not_tell_it_again` and
`test_a_hold_during_the_gap_does_not_tell_it_again` (a real toast with 1.5 s windows, a talk begun and ended in each),
`notice_toast_test.test_it_says_it_is_leaving_before_it_finishes`.

Options considered:
- The toast reports when the notice has left (a `left` signal at `_art.hide`, or `finished` moved there). The gap
  becomes a pausable wait in the watcher, and a withdraw after `left` drops the notice.
- Or the watcher asks the view, through a Callable as `PauseMenu.intent` does, whether the notice is past its hold, and
  re-queues it only if it is not.

## Prevention

`notice_watcher_test` covers a withdraw only at the start of a notice. Add a case that finishes the slide-out (the toast
has hidden but has not emitted `finished`) and then begins a talk, and assert that nothing is shown after `end_talk()`.
