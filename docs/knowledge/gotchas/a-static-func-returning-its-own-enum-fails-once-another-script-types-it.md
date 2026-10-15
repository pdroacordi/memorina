---
id: gotchas/a-static-func-returning-its-own-enum-fails-once-another-script-types-it
type: gotcha
title: A static func typed `-> Side` in the class that declares `enum Side` failed to parse once other scripts typed `DialogueBoxSide.Side`
status: active
tags: [gdscript, typing, enum, static, parse-error, class-name]
related: [systems/dialogue, gotchas/a-typed-array-of-an-inner-class-is-refused-from-another-script]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/ui/dialogue_box/dialogue_box_side.gd
---

## Summary

Godot 4.7.2, `--import`, measured 2026-10-15 (STORY-08). `DialogueBoxSide` (RefCounted, `class_name`) declares `enum Side { TOP, BOTTOM }` and `static func opposite(...) -> Side` returning `Side.TOP`. With `DialogueDirector` (`func _side() -> DialogueBoxSide.Side`), `DialogueBox` (`func place(side: DialogueBoxSide.Side)`) and a test typing `DialogueBoxSide.Side`, the import failed in the declaring script itself: `Cannot return a value of type "DialogueBoxSide.Side" as "Side"` at its own `return Side.TOP`, and the reverse message in the director. Two imports in a row gave the same errors.

## Fix

The static func returns `int` (a `Side` value). Callers keep typing `DialogueBoxSide.Side`; the int converts to the enum where it is returned or passed.

## Gotchas / pitfalls

- Not reduced to a minimal repro: the trigger may be the number of scripts naming the enum, or its use from a static func. Check the import log after adding any static func that returns its own class's enum.
