---
id: bugs/memorina-notes-dropped-while-previous-rings
type: bug
title: Correct phrases read as wrong because presses during a ringing note were silently dropped
status: active
severity: high
tags: [memorina, input, call-and-response, guardians, audio]
related: [architecture/guardian-fight-phase-machine]
created: 2026-09-20
updated: 2026-09-20
source_files:
  - scenes/characters/ivo/abilities/memorina_voice.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/guardians/guardian_call.gd
---

## Summary

Each note sample rings 1.6–1.85 s; `Player._on_note_pressed` dropped any press while the
previous note was still sounding, with no feedback. A player playing at a natural tempo
lost notes, and the next accepted press was out of order, so a correctly played phrase
was rejected with the mistake sound.

## Symptom

User report: "The songs that I play to mirror the bosses don't seem to work, even though
I play them right (at least as it is showed), it gets 'em wrong." Reproducible for world
songs too, just less noticed. The headless smoke test never saw it because it waited for
`is_busy()` before every note.

## Root cause

`memorina_voice.gd` exposed only `is_busy()` (true for the whole sample) and
`player.gd` gated `receive_note()` on it. The design text ("a próxima só pode ser tocada
quando o som da anterior termina") was implemented literally against samples far longer
than a playable beat.

## Fix

`MemorinaVoice.can_play_note()` with `min_note_gap` (0.25 s): a new note cuts the ringing
one once the gap has passed; presses inside the gap are dropped as mashing. Player gates
on `can_play_note()`. `GuardianCall` now plays its phrase on a fixed `note_interval`
(0.55 s) so the call sounds like a melody and the answer window is proportionate.
Verified in-engine (`playtests/2026-09-20-bloom-guardian-call`).

## Prevention

Any input gate that silently swallows a press needs either feedback or a buffer; a
silent drop always reads as "the game got it wrong". The playtest timeline
`tools/playtest/scripts/bloom_guardian_call.json` presses notes 0.5 s apart on purpose.
