---
id: bugs/recall-move-range-exceeds-hitbox-reach
type: bug
title: The Bloom burst was thrown from farther than its hitbox reached, so the airborne recall almost never opened
status: fixed
severity: high
tags: [guardians, qte, recall, hitbox, tuning]
related: [architecture/guardian-fight-phase-machine, playtests/2026-09-21-bloom-fight-acts]
created: 2026-09-21
updated: 2026-09-21
source_files:
  - resources/characters/guardians/bloom_guardian/bloom_burst.tres
  - scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn
  - scenes/characters/guardians/guardian_ai.gd
---

## Summary

`GuardianAI` starts a move as soon as the player is within `GuardianAttack.attack_range`,
but nothing ties that number to the reach of the hitbox the clip keys. The Bloom burst had
`attack_range = 140` and a hitbox 70 px wide each side (`CircleShape2D` r=10 scaled 7x),
so it was thrown from where it could not launch Ivo; the double-jump recall is
`requires_airborne`, so the prompt never opened and the move was simply spent.

## Symptom

"It is pretty difficult to make the QTE happen" (user, round 4). Combined with the fight
being restorable on hits alone, most runs ended without the skill.

## Root cause

Two numbers authored independently: the `.tres` range and the clip's keyed
`Hitbox/CollisionShape2D:scale`. The AI reads one, the clip draws the other.

## Fix

`bloom_burst.tres`: `attack_range 140 -> 64`. The gate that makes the recall mandatory
(`GuardianFight.set_recall_pending`) and the guardian throwing the move at once when the
hits saturate (`GuardianAI.request_recall`) landed in the same change, so the move now
comes when it can land.

## Prevention

Not asserted: the reach of a keyed hitbox is not readable from a resource at startup
without evaluating the clip. Rule of thumb, now in CLAUDE.md: a move's `attack_range`
must not exceed the reach its clip's hitbox keys, and a launch move that carries an
airborne recall must be able to reach Ivo from where it is thrown.
