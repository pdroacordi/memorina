---
id: bugs/a-swordless-ivo-spends-the-arena-trigger-so-the-fight-never-starts-on-return
type: bug
title: A swordless Ivo entering an arena spends the guardian's one-shot ArenaTrigger, so back with the sword the fight never starts while the room stays cached
status: fixed
severity: medium
tags: [guardian, arena, trigger, sword, story-33, residency, latent]
related: [systems/guardians, systems/rooms, bugs/a-cutscene-trigger-in-a-first-visited-room-never-arms]
created: 2026-11-17
updated: 2026-11-17
source_files:
  - scenes/characters/guardians/guardian.gd
  - scenes/characters/components/player_proximity_trigger.gd
  - scenes/world/rooms/room.gd
  - tests/scenes/world/interactables/fight_wall/fight_wall_test.gd
---

## Summary

STORY-33's second guard refuses the fight to a swordless Ivo after the arena's one-shot trigger has already turned itself off. If he comes back with the sword while the arena's contents are still cached, nothing starts the fight. The guardian stays DORMANT until the room is evicted or the world is rebuilt.

## Symptom

Found in review (STORY-33). Repro in principle: give Ivo no sword (a debug trial, a playtest timeline with `"owned_items": []`, or any future route that skips the Old Bridge wall). Walk into an arena: no fight, as intended. Leave, get the sword, come back before `RoomResidency` evicts the room: no fight, no `FightWall`, no `meet_guardian`. The guard exists for exactly this case, and in this case it leaves the guardian unfightable.

## Root cause

- `PlayerProximityTrigger._on_body_entered` (`player_proximity_trigger.gd:15-16`) sets `monitoring` false (deferred) **before** it emits `player_entered`. It fires once per instance.
- `Guardian._on_player_entered` (`guardian.gd:322-325`) now returns while `not _player.is_armed()` and does not re-arm the trigger.
- `Room.deactivate()` (`room.gd:80-83`) only sets `PROCESS_MODE_DISABLED` and hides the contents. `activate()` wakes the same instance, so the trigger's `monitoring` stays false. Only `evict()`, an expiry or a world rebuild makes a fresh trigger.
- `fight_wall_test.test_without_the_sword_no_fight_begins_and_the_wall_stays_open` calls `guardian.call(&"_on_player_entered")` directly, twice, so it skips the trigger and passes.

## Fix

Not fixed. Options, best first:
1. Re-arm on a refusal: when `_on_player_entered` refuses, re-arm the trigger once Ivo has left it. Do not set `monitoring = true` while he still overlaps: the trigger would fire again on the next flush, be refused, and repeat every frame. Alternatively, in `_notification(NOTIFICATION_ENABLED)`, set `_arena_trigger.monitoring = true` while the phase is still DORMANT. That covers a return after the room has idled.
2. Gate in the trigger rather than the guardian, so the trigger does not consume itself for a body that is refused.

## Prevention

Drive the refusal test through the trigger itself: teleport Ivo into the `ArenaTrigger` shape without the sword, move him out, grant the sword, move him back in, and assert PRESSURE. Never call `_on_player_entered` directly. General rule: a guard added behind a one-shot trigger must either run before the trigger spends itself or re-arm it.

## Fix (2026-11-17)

`PlayerProximityTrigger.stays_open` with a public `close()`: the guardian sets `stays_open` in `_ready` and closes the trigger only once a fight begins, after the sword check. A refused entry leaves monitoring on, so Ivo's next entry fires again; while he stays inside, no new `body_entered` comes, so nothing repeats. Enemies keep the default (close on the first entry). Test: `fight_wall_test.test_without_the_sword_no_fight_begins_and_the_wall_stays_open` now moves Ivo through the trigger, out and back armed.
