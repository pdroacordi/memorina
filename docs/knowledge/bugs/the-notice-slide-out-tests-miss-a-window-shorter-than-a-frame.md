---
id: bugs/the-notice-slide-out-tests-miss-a-window-shorter-than-a-frame
type: bug
title: The notice slide-out tests poll a 0.02 s window, so one slow frame skips it and they time out
status: resolved
severity: low
tags: [tests, notices, tween, flaky, timing]
related: [systems/notices, bugs/a-notice-withdrawn-after-it-left-is-told-twice]
created: 2026-11-11
updated: 2026-11-11
source_files:
  - tests/scenes/ui/notice/notice_watcher_test.gd
---

# The notice slide-out tests poll a 0.02 s window, so one slow frame skips it and they time out

## Symptom

`test_a_hold_during_the_slide_out_does_not_tell_it_again` and `test_a_hold_during_the_gap_does_not_tell_it_again` failed with "waited 300 frames" on 2026-11-11 from about 13:57, on `9afdfdbc` and later alike, while other Godot runs (playtests, another session's suite) loaded the machine. Earlier full runs that day passed them.

## Root cause

`_shown_with_toast` set the toast's `slide_in` and `hold` to 0.01 s each, then polled `_watcher.is_showing()` once per frame. The watcher emits `shown` in its `_process`, and the toast's tween runs its whole 0.02 s and the `leaving` callback within the same frame when that frame's delta is over 0.02 s, so `_showing` is null again before the poll looks. No game code was wrong.

## Fix

The helper waits until `shown` was received (`not _shown.is_empty()`), which no frame length can skip. The tests then wait for the long slide-out (1.5 s) and gap (1.5 s) windows as before.

## Prevention

A test that polls per frame for a state must not give that state a window shorter than a slow frame (tens of ms under load). Wait on the signal that starts it, or make the window long.
