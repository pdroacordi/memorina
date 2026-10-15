---
id: bugs/ivo-faces-the-talkable-not-the-villager-beside-it
type: bug
title: begin_talk faces the Talkable's origin, which sits beside the villager, so Ivo can turn his back on the one he talks to
status: fixed
severity: low
tags: [dialogue, talkable, facing, props, story-08]
related: [systems/dialogue, systems/props]
created: 2026-10-15
updated: 2026-10-15
source_files:
  - scenes/world/dialogue/dialogue_director.gd
  - scenes/world/interactables/talkable/talkable.gd
  - scenes/characters/ivo/player.gd
---

## Summary

FIXED 2026-10-15 (STORY-08 review, before commit). It was latent: no villager Talkable is placed yet; the winter-trial fixture has no prop. `DialogueDirector.start` passes `talkable.global_position` as `at`, and `Player.begin_talk` faces `signf(at.x - x)`. The contract places a Talkable beside its villager prop, never on it (`systems/props`), so `at` is not where the speaker stands.

## Symptom

Legend `t` uses anchor FEET, so the origin is its cell's bottom centre. The default zone is 2 cells (64 px) centred on that origin, and it reaches the centre of the neighbouring cell, where the villager stands. When Ivo stands between the villager and the Talkable's origin, `begin_talk` turns him toward the origin, which is away from the villager. This happens in half of the zone on the villager's side. The prop does not turn either ("The prop does not turn to Ivo"), so the two stand back to back.

## Root cause

`scenes/world/dialogue/dialogue_director.gd:39` (`_at = talkable.global_position`), `scenes/characters/ivo/player.gd:1122-1125`. `Talkable` has no notion of where its speaker stands.

## Fix

Fixed 2026-10-15. `Talkable.speaker_offset` (px along x from its origin to the villager; a `t` param, in the legend and `docs/maps/README.md`) and `Talkable.speaker_position()`. `DialogueDirector.start` faces Ivo toward that point and places the box from it. Tests: `player_talk_test.test_he_faces_the_speaker_not_the_talkable` (Ivo between the origin and a speaker 48 px right, facing left, turns right), `dialogue_director_test.test_the_talk_faces_the_speaker_beside_the_talkable`.

## Prevention

A `player_talk_test` case with Ivo between a speaker point and the Talkable's origin, asserting he faces the speaker.
