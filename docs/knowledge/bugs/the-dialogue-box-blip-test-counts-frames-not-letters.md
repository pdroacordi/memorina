---
id: bugs/the-dialogue-box-blip-test-counts-frames-not-letters
type: bug
title: The dialogue box's blip test fails when process frames run slower than the typing
status: open
severity: low
tags: [tests, dialogue, sound, timing, flaky]
related: [systems/dialogue, systems/sound-effects]
created: 2026-11-23
updated: 2026-11-23
source_files:
  - tests/scenes/ui/dialogue_box/dialogue_box_test.gd
  - scenes/ui/dialogue_box/dialogue_box.gd
---

## Summary

`test_a_typed_line_blips_in_the_speakers_pitch` expects 11 blips for a 32-letter line and got 6 on
2026-11-23, every run, on clean commit 9ca29d9d (a detached worktree) as well as on the working tree.
It passed twice earlier the same day on the same machine.

## Root cause

`DialogueBox._process` asks `VoiceBlips.due` once per process frame, so at most one blip sounds per
frame. When several letters (40 per second) land between two frames, the blips for the skipped
boundaries are lost. The count depends on the frame rate of the headless run, not only on the text.

## Fix

Not fixed. Either play every blip boundary crossed since the last frame (the count then matches the text,
which is also right for a slow machine in play), or let the test step frames at a fixed delta.
Roadmap TECH-16.
