---
id: gotchas/a-preloaded-resources-typed-enum-array-reads-as-array-int
type: gotcha
title: A preloaded .tres's Array[Enums.Note] property reads as Array[int] to the analyzer, so passing it to an Array[Enums.Note] parameter is a parse error
status: active
tags: [gdscript, typing, typed-array, enum, preload, parse-error, tests]
related: [systems/story, gotchas/a-typed-array-of-an-inner-class-is-refused-from-another-script]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - tests/scenes/ui/phrase_sheet/phrase_sheet_test.gd
  - resources/story/melody.gd
---

## Summary

Godot 4.7.2, measured 2026-10-15 (STORY-03). In a test, `const MORNING := preload("res://resources/story/morning_song.tres")` and then `_sheet.show_phrase(MORNING.notes, 5, ...)`, where `show_phrase` takes `notes: Array[Enums.Note]`. The import failed with `Invalid argument for "show_phrase()" function: argument 1 should be "Array[Enums.Note]" but is "Array[int]"`. The `.tres` stores the property as `Array[int]([...])`, and the analyzer took that type from the preloaded constant.

## Fix

Copy it into a typed local first: `var notes: Array[Enums.Note] = []` then `notes.assign(MORNING.notes)`. Inside the class, `attempt.melody.notes` (typed through the `Melody` class) passes as it is.
