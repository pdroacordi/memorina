---
id: gotchas/a-freed-object-in-a-deferred-call-fails-its-typed-argument
type: gotcha
title: A deferred call bound to an object freed before the flush errors on its typed parameter, before the method can check it
status: active
tags: [call_deferred, typing, free, ui]
related: [systems/notebook]
created: 2026-10-06
updated: 2026-10-06
source_files:
  - scenes/ui/notebook/notebook.gd
---

## Summary

`method.call_deferred(node)` with `node` freed before the deferred flush logs
`ERROR: Error calling deferred method: '...': Cannot convert argument 1 from Object to Object.`
when the parameter is typed (`func _frame_list(focused: NotebookRow)`). The method never runs, so an
`is_instance_valid()` check inside it cannot help.

## Details

- Measured in 4.7.2, windowed (UI-03, 2026-10-06): a notebook page turn freed the list rows while a
  deferred `_frame_list(row)` bound to the focused row was pending. The log had six such errors.
  `notebook_test` stayed green, because headless never hit that timing.
- Fix used: store the object in a field and defer a call with no arguments
  (`_framed = row; _reframe.call_deferred()`), which tests `is_instance_valid(_framed)` and
  `is_queued_for_deletion()` itself.

## Gotchas / pitfalls

- The failure is timing-dependent: it shows in a windowed run and not in the headless suite.
