---
id: bugs/a-guardian-lunge-turned-to-follow-a-player-who-rolled-under-it
type: bug
title: A guardian's pounce or charge turned in mid-swing to follow a player who rolled under it
status: fixed
severity: medium
tags: [guardians, ai, facing, lunge, roll, core-09]
related: [systems/guardians, bugs/pogo-over-a-guardian-is-a-free-ride, playtests/2026-10-11-core09-retune]
created: 2026-10-11
updated: 2026-10-11
source_files:
  - scenes/characters/guardians/guardian_ai.gd
  - scenes/characters/guardians/guardian.gd
  - tests/scenes/characters/guardians/guardian_ai_test.gd
---

## Summary

`Guardian._process_motion` sets `velocity.x = facing * lunge_speed` on every frame of a lunging swing, and faces `GuardianAI.facing_intent()` on every frame. That intent is the player's side whenever the guardian is not walking. When Ivo rolled under a Bloom pounce, the guardian turned in the air and came down on him.

## Symptom

CORE-09 Bloom exchange (`tools/playtest/scripts/core09_bloom_exchange.json`): Ivo rolls into the pounce at t 1.70 and they cross at t 2.02. From then until the landing at t 2.31, their offset stays about -18 px while both move right at about 340 px/s. The landing put the guardian on him, and its contact box hit him (hp 3 -> 2).

## Root cause

The facing fix for a player standing on top of a guardian (`bugs/pogo-over-a-guardian-is-a-free-ride`) made the guardian look at the player whenever it stands still. During a swing `direction` is 0, so it counted as standing still. Because the lunge velocity is derived from `facing` on each frame, the lunge turned with the look.

## Fix

`facing_intent()` returns 0 while `_swinging`, and `face_towards(0)` keeps the current facing. A telegraph still tracks the player, and `_on_attack_telegraphed` squares the guardian up at its start, so a move is aimed when its swing begins and keeps that aim to the end. After the fix the pounce lands 155 px past the roll and Ivo is not hit. The same applies to the Frost charge, the move that teaches the roll.

## Prevention

`guardian_ai_test.gd`: a telegraph follows the player; a swing does not turn when the player crosses under it; after the swing it faces the player again. Rule: a velocity derived from facing every frame needs its facing committed for as long as the move lasts.
