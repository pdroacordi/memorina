---
id: bugs/respawn-teleports-a-dead-ivo
type: bug
title: If Ivo dies while sinking (an enemy's hit during the fade), Game still respawns the corpse onto the bank
status: fixed
severity: low
tags: [water, hazard, respawn, death, game]
related: [bugs/a-second-fall-during-the-respawn-clear-sinks-forever]
created: 2026-09-23
updated: 2026-09-23
source_files:
  - scenes/world/game.gd
  - scenes/characters/ivo/player.gd
  - scenes/characters/character.gd
---

## Summary

The hazard grants no i-frames (character.gd:118-123). The `hurt` clip hides the hurtbox
for only 0.333 s of the 0.5 s fade, so a hitbox can still land on Ivo in the remaining
time. If that hit kills him, `Game` still calls `respawn()` (game.gd:70), and `respawn()`
(player.gd:855) has no `is_dead()` guard. It clears `_sinking` and teleports the corpse
to the bank, which then plays its death clip as the screen clears.

## Symptom

Found in review of 84ada2e. Reasoned from the code, not reproduced. It needs a hitbox
that reaches into the pool; the Downtown BruteShadow is in the same room as the pool.

## Root cause

Nothing re-checks for death after `await _fade.to_black()`, so a death that happens during
the beat goes unnoticed.

## Fix

Not fixed. After the await, `Game` should check `_player.is_dead()` and abandon the
respawn, clearing to the death state instead. `respawn()` should also refuse a dead body.

## Prevention

Every `await` in a composition-root beat should re-check, once it resumes, the
preconditions the beat started from.

## Resolution (2026-09-23)

`Game` only respawns a living Ivo (`if not _player.is_dead()`), and `Player.respawn()` asserts it.
