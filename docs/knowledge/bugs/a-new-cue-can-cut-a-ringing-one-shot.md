---
id: bugs/a-new-cue-can-cut-a-ringing-one-shot
type: bug
title: With both decks busy, a new cue cuts deck 0 even when it is the ringing one-shot, not the one fading
status: fixed
severity: low
tags: [music, decks, one-shot, cutscene]
related: [systems/music, architecture/music-system, systems/cutscenes]
created: 2026-11-03
updated: 2026-11-03
source_files:
  - globals/music/music.gd
---

## Summary

`Music._free_deck` promises to cut "the one fading out" but returns the first non-live deck, which may be a released
one-shot left ringing (the restoration cue), stopping it mid-phrase.

## Symptom

Found in review. A one-shot scene cue (`finale_restoration.tres`, `loops = false`) is released at the scene's end and
rings on deck A while the region theme starts on deck B. If the region request is then replaced (a room change into
another region: release B with a fade, request a new cue) while A still rings, both decks are playing and the new cue
takes deck A when A is `_decks[0]`: the restoration cue stops dead, the music contract says it must not be cut.

## Root cause

music.gd:136-139: the fallback loop picks any deck `!= _live` and calls `stop()`, without checking `deck.ringing` or
preferring the deck with `target == 0`.

## Fix

Not fixed. Prefer a non-ringing deck whose `target` is 0 (the fading one), and only then the lowest-gain deck.

## Prevention

A `music_test` case: ring a one-shot, start and release a loop, request a third cue; assert the one-shot's player is
still playing.
