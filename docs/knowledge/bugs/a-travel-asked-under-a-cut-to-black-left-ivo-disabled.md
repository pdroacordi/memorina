---
id: bugs/a-travel-asked-under-a-cut-to-black-left-ivo-disabled
type: bug
title: A flashback's travel back asked in the same frame as the leaving's 0 s cut to black left Ivo DISABLED in the present
status: resolved
severity: high
tags: [travel, fade, deferred, flashback, process-mode, story-05]
related: [systems/life-benches-death, systems/cutscenes, playtests/2026-11-12-story05-flashback-5, gotchas/disabling-a-body-inside-its-own-physics-step-errors-its-move]
created: 2026-11-12
updated: 2026-11-12
source_files:
  - scenes/world/game.gd
---

## Summary

Flashback 5's playtest returned Ivo kneeling in the present and he never moved again: `process_mode` 4 (DISABLED), the
kneel and the stand-up never played.

## Cause

`Game.travel` disables Ivo with `set_deferred` and then awaits `Fade.to_colour(colour, 0)`, whose `faded` is emitted
deferred. The leaving scene's last step is its own 0 s cut to black, which had already queued a `faded` earlier in the
same frame. With no talk to wait out (flashbacks 1-4 end inside a talk, a frame later), `FlashbackDirector` asked for the
travel in that frame: the earlier `faded` resumed the travel first, Ivo landed and was set to INHERIT, and then the
queued DISABLED landed on top.

## Fix

`Game.travel` awaits one physics frame after the cover, covered or not, so the deferred disable is always in before the
move. A transparent colour (the hidden swap) takes the same frame and no cover.

## Lesson

A deferred `set` and an awaited deferred signal are ordered by when each was queued, not by the code that awaits them.
Never rely on a 0 s fade's `faded` to order a deferred write: await a frame.
