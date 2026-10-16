---
id: bugs/a-withdrawn-intent-comes-back-after-the-intent-ended
type: bug
title: NoticeQueue.push_front keeps a withdrawn intent when the intent changed to none while it showed, so a stale intent is told after the hold
status: fixed
severity: low
tags: [notice, intent, queue, withdraw, stale, ui-11, latent]
related: [systems/notices, bugs/a-notice-withdrawn-after-it-left-is-told-twice]
created: 2026-10-16
updated: 2026-10-16
source_files:
  - scenes/ui/notice/notice_queue.gd
  - scenes/ui/notice/notice_watcher.gd
---

## Summary

FIXED 2026-10-16 (UI-11), low, latent (UI-11 review, 2026-10-16; no current talk order reaches it). `push_front` drops a withdrawn intent
only when a newer intent notice is waiting. If the intent changed to none (or to the one told before it) while the
notice showed, nothing waits, so the old intent is queued again and shown after the hold, though it no longer holds.

## Symptom

1. Intent A pops and shows, and `_told_intent` becomes A.
2. While A is on screen, the save changes so no intent holds (today only `elder_return` heard does this).
   `set_intent(&"")` queues nothing.
3. A hold begins: the watcher calls `push_front(A)`. No intent waits, so A is queued.
4. After the hold, A is shown, but `IntentCatalog.current` is null and the pause menu shows no line.

The same happens if the intent changes back to the intent told before A: `set_intent` skips it, because it differs
from `_told_intent` only through A.

## Root cause

`scenes/ui/notice/notice_queue.gd:53-56` decides staleness by whether another intent waits. It does not compare the
withdrawn intent with the current one. `notice_watcher.gd:32` passes no current intent to compare with.

## Fix

Fixed 2026-10-16: `NoticeQueue` keeps the id `set_intent` last heard (`_current_intent`). `push_front` drops a withdrawn
intent that is not the current one, and with no intent waiting sets the told intent to the current one, so the pause
menu (which shows the told intent) drops it too. `set_intent` with an unchanged id does nothing, so a waiting intent
keeps its place. Tests: `notice_queue_test.test_a_withdrawn_intent_that_ended_is_dropped`,
`test_a_withdrawn_intent_that_still_holds_goes_back_first`, `test_an_unchanged_intent_keeps_its_place`.

Suggested at filing: `push_front` (or the watcher before calling it) should re-queue a withdrawn intent only if it is still the
current intent: compare `notice.intent_id` with `_intent_id(SaveSystem.player_data)` in the watcher, or store the
latest `set_intent` id in the queue and drop any intent that differs from it.

Related, also latent: `set_intent` (lines 29-34) erases a waiting intent and appends it again even when the id is
unchanged. Any `progress_changed` that comes later therefore moves a waiting intent behind items queued after it, which
breaks the class's "oldest first" docstring. Keep a waiting intent in place when its id is unchanged.

## Prevention

Add `notice_queue_test` cases: pop A, `set_intent(&"")`, `push_front(A)`, and assert the queue is empty; and queue
intent A, add an item, `set_intent(A)` again, and assert the order is still [A, item].
